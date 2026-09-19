import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../shared/widgets/in_app_notification_banner.dart';
import '../../di/injection_container.dart';
import '../../features/notifications/models/app_notification_model.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../constants/role_enum.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';

/// Handler xử lý tin nhắn ngầm khi ứng dụng bị tắt hoàn toàn (Terminated state)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  final title = notification?.title ??
      message.data['title']?.toString() ??
      'Luxe Grand Hotel';
  final body = notification?.body ??
      message.data['body']?.toString() ??
      message.data['message']?.toString() ??
      '';
  final messageId = message.messageId ??
      'fcm_bg_${DateTime.now().millisecondsSinceEpoch}';

  debugPrint('📩 [FCM Background] Nhận được tin nhắn khi app đã kill: $messageId - $title');

  // 1. Lưu thông báo trực tiếp vào SharedPreferences ngầm
  await NotificationRepository.saveRawNotificationToStorage(
    title: title,
    body: body,
    id: messageId,
    category: message.data['category']?.toString(),
    data: message.data,
    actionRoute: message.data['route']?.toString() ?? message.data['actionRoute']?.toString(),
  );

  // 2. Nếu tin nhắn là data-only (không có notification payload từ FCM),
  // hệ thống Android sẽ không tự hiện thông báo. Ta kích hoạt local notification hiển thị đẹp:
  if (notification == null && title.isNotEmpty) {
    try {
      final localNotif = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const initSettings = InitializationSettings(android: androidSettings);
      await localNotif.initialize(settings: initSettings);

      const channel = AndroidNotificationChannel(
        'hotel_reminder_channel',
        'Thông báo trả phòng & dịch vụ',
        description: 'Kênh nhận thông báo hạn trả phòng từ khách sạn',
        importance: Importance.max,
        playSound: true,
      );

      await localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await localNotif.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@drawable/ic_notification',
            color: const Color(0xFFD97706),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Luxe Grand Hotel',
            ),
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('⚠️ [FCM Background] Lỗi hiển thị local notification: $e');
    }
  }
}

/// Service quản lý Push Notification toàn diện cho dự án
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hotel_reminder_channel',
    'Thông báo trả phòng & dịch vụ',
    description: 'Kênh nhận thông báo hạn trả phòng từ khách sạn',
    importance: Importance.max,
    playSound: true,
  );

  static bool _isInitialized = false;

  /// Biến lưu tạm payload khi người dùng bấm mở thông báo từ trạng thái Kill App (Cold Start)
  static Map<String, dynamic>? pendingNotificationPayload;

  /// Callback chuyển hướng khi người dùng chạm vào thông báo
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Khởi tạo toàn bộ luồng Push Notification
  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationClick,
  }) async {
    if (_isInitialized) return;
    _isInitialized = true;
    onNotificationTap = onNotificationClick;

    // 1. Đăng ký background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Yêu cầu quyền thông báo (Bắt buộc với Android 13+)
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [FCM] Quyền thông báo: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️ [FCM] Lỗi xin quyền thông báo: $e');
    }

    // 3. Khởi tạo Notification Channel & Local Notifications cho Android
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationPayload(data);
          } catch (_) {}
        }
      },
    );

    // Đăng ký kênh ưu tiên cao trên Android
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Cấu hình hiển thị notification khi app đang mở ở foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Xử lý khi app mở từ trạng thái TẮT HOÀN TOÀN (Terminated / Cold Start)
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '🚀 [FCM] Mở app từ thông báo FCM (Terminated): ${initialMessage.data}');
        final payload = Map<String, dynamic>.from(initialMessage.data);
        if (initialMessage.notification != null) {
          payload['title'] ??= initialMessage.notification!.title;
          payload['body'] ??= initialMessage.notification!.body;
        }
        _captureNotificationPayload(payload);
      }

      final localDetails = await _localNotif.getNotificationAppLaunchDetails();
      if (localDetails != null && localDetails.didNotificationLaunchApp) {
        final payloadStr = localDetails.notificationResponse?.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          try {
            debugPrint(
                '🚀 [LocalNotif] Mở app từ Local Notification (Terminated): $payloadStr');
            final data = jsonDecode(payloadStr) as Map<String, dynamic>;
            _captureNotificationPayload(data);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Lỗi kiểm tra getInitialMessage / launch details: $e');
    }

    // 5. Xử lý khi app mở từ trạng thái CHẠY ẨN (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '📱 [FCM] Người dùng chạm thông báo (Background): ${message.data}');
      _handleNotificationPayload(message.data);
    });

    // 6. Xử lý khi app ĐANG MỞ (Foreground): Hiển thị In-App Luxury Banner nổi sang trọng
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '⚡ [FCM] Nhận tin nhắn khi đang mở app: ${message.notification?.title}');
      final notification = message.notification;
      final title = notification?.title ??
          message.data['title']?.toString() ??
          'Luxe Grand Hotel';
      final body = notification?.body ??
          message.data['body']?.toString() ??
          message.data['message']?.toString() ??
          '';

      final categoryEnum = _resolveAppNotificationCategory(message.data, title);
      final categoryTitle = _resolveCategory(message.data, title);
      final icon = _resolveIcon(message.data, title);

      // Lưu trữ vào NotificationRepository và kiểm tra cài đặt bật/tắt của người dùng
      if (sl.isRegistered<NotificationRepository>()) {
        final notifRepo = sl<NotificationRepository>();
        notifRepo.addNotification(
          AppNotificationModel(
            id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            body: body,
            category: categoryEnum,
            createdAt: DateTime.now(),
            data: message.data,
            actionRoute: message.data['route']?.toString() ?? '/my-bookings',
          ),
        );

        bool isAllowed = true;
        if (categoryEnum == AppNotificationCategory.booking && !notifRepo.bookingEnabled) isAllowed = false;
        if (categoryEnum == AppNotificationCategory.payment && !notifRepo.paymentEnabled) isAllowed = false;
        if (categoryEnum == AppNotificationCategory.service && !notifRepo.serviceEnabled) isAllowed = false;
        if (categoryEnum == AppNotificationCategory.promotion && !notifRepo.promoEnabled) isAllowed = false;

        if (!isAllowed) {
          debugPrint('ℹ️ [FCM] Người dùng đã tắt nhận thông báo danh mục $categoryTitle');
          return;
        }
      }

      // Hiển thị In-App Notification theo phong cách người dùng đã chọn
      InAppNotificationBanner.show(
        title: title,
        body: body,
        data: message.data,
        notificationCategory: categoryEnum,
        category: categoryTitle,
        icon: icon,
        onTap: () => _handleNotificationPayload(message.data),
      );
    });

    // 7. Lấy Token & đồng bộ lên Backend
    await syncTokenWithServer();

    // 8. Lắng nghe nếu Firebase đổi Token mới
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 [FCM] Token được làm mới: $newToken');
      await _sendTokenToBackend(newToken);
    });
  }

  /// Lấy FCM Device Token của máy
  static Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint('⚠️ [FCM] Lỗi getToken: $e');
      return null;
    }
  }

  /// Đồng bộ FCM Token hiện tại lên Backend
  static Future<void> syncTokenWithServer() async {
    final token = await getDeviceToken();
    if (token != null && token.isNotEmpty) {
      debugPrint('🔑 [FCM] Device Token: $token');
      await _sendTokenToBackend(token);
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = DioClient().dio;
      // Thử gọi API cập nhật FCM Token riêng
      try {
        await dio.patch(ApiEndpoints.fcmToken, data: {'fcmToken': token});
        debugPrint('✅ [FCM] Đã cập nhật token lên ${ApiEndpoints.fcmToken}');
      } catch (_) {
        // Fallback: cập nhật vào thông tin người dùng nếu endpoint riêng chưa có
        await dio.patch(ApiEndpoints.usersMe, data: {'fcmToken': token});
        debugPrint('✅ [FCM] Đã cập nhật token qua ${ApiEndpoints.usersMe}');
      }
    } catch (e) {
      // Bỏ qua nếu người dùng chưa đăng nhập
      debugPrint('ℹ️ [FCM] Bỏ qua gửi token (chưa đăng nhập hoặc lỗi mạng): $e');
    }
  }

  static void _captureNotificationPayload(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    } else {
      pendingNotificationPayload = data;
    }
  }

  /// Kích hoạt điều hướng sau khi AppRouter và giao diện đã sẵn sàng (dành cho Cold Start từ Kill App)
  static void consumePendingNotification(dynamic router) {
    final payload = pendingNotificationPayload;
    if (payload == null) return;
    pendingNotificationPayload = null;

    debugPrint('🎯 [FCM Cold Start] Thực hiện điều hướng sau khi mở từ trạng thái kill: $payload');
    _navigateWithPayload(router, payload);
  }

  static void _handleNotificationPayload(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
      return;
    }
    _navigateWithPayload(AppRouter.router, data);
  }

  /// Ánh xạ route phù hợp và an toàn dựa theo dữ liệu thông báo và vai trò người dùng
  static String resolveTargetRoute(Map<String, dynamic> data, {UserRole? role}) {
    String? raw = data['route']?.toString() ?? data['actionRoute']?.toString();

    // Nếu không chỉ định route, mặc định chọn theo vai trò
    if (raw == null || raw.trim().isEmpty) {
      if (role == UserRole.admin) return '/admin/rooms';
      if (role == UserRole.receptionist) return '/receptionist/today';
      return '/my-bookings';
    }

    raw = raw.trim();
    if (!raw.startsWith('/')) {
      raw = '/$raw';
    }

    // Role-specific mapping: Nếu là nhân viên, không điều hướng vào route khách hàng
    if (role == UserRole.admin) {
      if (raw == '/my-bookings' || raw.startsWith('/my-bookings')) {
        return '/admin/rooms';
      }
      if (raw == '/services') {
        return '/admin/services';
      }
    } else if (role == UserRole.receptionist) {
      if (raw == '/my-bookings' || raw.startsWith('/my-bookings')) {
        return '/receptionist/today';
      }
      if (raw == '/services') {
        return '/receptionist';
      }
    }

    return raw;
  }

  static void _navigateWithPayload(dynamic router, Map<String, dynamic> data) {
    try {
      // 1. Gỡ bỏ ngay lập tức bất kỳ In-App banner nào đang hiển thị để tránh kẹt overlay
      InAppNotificationBanner.dismiss(immediately: true);

      // 2. Lấy role hiện tại từ AuthBloc nếu có
      UserRole? currentRole;
      try {
        if (sl.isRegistered<AuthBloc>()) {
          final authState = sl<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            currentRole = authState.user.role;
          }
        }
      } catch (_) {}

      final targetRoute = resolveTargetRoute(data, role: currentRole);

      debugPrint('📍 [FCM Navigation] Điều hướng an toàn tới route: $targetRoute');
      if (router != null) {
        router.go(targetRoute);
      } else if (AppRouter.router != null) {
        AppRouter.router!.go(targetRoute);
      } else {
        pendingNotificationPayload = data;
      }
    } catch (e) {
      debugPrint('⚠️ [FCM Navigation] Lỗi điều hướng: $e');
    }
  }

  /// Hiển thị thông báo trên thanh thông báo Android với giao diện nâng cấp (Gold Accent, Logo, BigText)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotif.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@drawable/ic_notification',
          color: const Color(0xFFD97706),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Luxe Grand Hotel',
          ),
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  static String _resolveCategory(Map<String, dynamic> data, String title) {
    final lower = '${title.toLowerCase()} ${data['type'] ?? ''} ${data['category'] ?? ''}';
    if (lower.contains('trả phòng') || lower.contains('check-out') || lower.contains('checkout')) {
      return 'Nhắc nhở trả phòng';
    }
    if (lower.contains('nhận phòng') || lower.contains('check-in') || lower.contains('checkin')) {
      return 'Nhận phòng';
    }
    if (lower.contains('dịch vụ') || lower.contains('service')) {
      return 'Dịch vụ phòng';
    }
    if (lower.contains('hóa đơn') || lower.contains('thanh toán') || lower.contains('invoice') || lower.contains('payment')) {
      return 'Hóa đơn & Thanh toán';
    }
    return 'Thông báo khách sạn';
  }

  static IconData _resolveIcon(Map<String, dynamic> data, String title) {
    final lower = '${title.toLowerCase()} ${data['type'] ?? ''}';
    if (lower.contains('trả phòng') || lower.contains('check-out') || lower.contains('checkout')) {
      return Icons.hourglass_top_rounded;
    }
    if (lower.contains('nhận phòng') || lower.contains('check-in') || lower.contains('checkin')) {
      return Icons.meeting_room_rounded;
    }
    if (lower.contains('dịch vụ') || lower.contains('service')) {
      return Icons.room_service_rounded;
    }
    if (lower.contains('hóa đơn') || lower.contains('thanh toán') || lower.contains('invoice') || lower.contains('payment')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  static AppNotificationCategory _resolveAppNotificationCategory(
      Map<String, dynamic> data, String title) {
    final lower = '${title.toLowerCase()} ${data['type'] ?? ''} ${data['category'] ?? ''}';
    if (lower.contains('trả phòng') ||
        lower.contains('nhận phòng') ||
        lower.contains('đặt phòng') ||
        lower.contains('check-in') ||
        lower.contains('check-out') ||
        lower.contains('room')) {
      return AppNotificationCategory.booking;
    }
    if (lower.contains('hóa đơn') ||
        lower.contains('thanh toán') ||
        lower.contains('tiền') ||
        lower.contains('invoice') ||
        lower.contains('payment')) {
      return AppNotificationCategory.payment;
    }
    if (lower.contains('dịch vụ') ||
        lower.contains('buồng phòng') ||
        lower.contains('service') ||
        lower.contains('spa')) {
      return AppNotificationCategory.service;
    }
    if (lower.contains('ưu đãi') ||
        lower.contains('khuyến mãi') ||
        lower.contains('voucher') ||
        lower.contains('vip') ||
        lower.contains('giảm giá')) {
      return AppNotificationCategory.promotion;
    }
    return AppNotificationCategory.system;
  }
}
