import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/app_notification_model.dart';

/// Repository quản lý toàn diện lịch sử thông báo, cài đặt kiểu hiển thị và bộ đếm chưa đọc.
class NotificationRepository extends ChangeNotifier {
  static const String _storageKey = 'hotel_app_notifications_v1';
  static const String _prefStyleKey = 'hotel_app_notification_preferred_style';
  static const String _prefBookingKey = 'hotel_app_notif_booking_enabled';
  static const String _prefPaymentKey = 'hotel_app_notif_payment_enabled';
  static const String _prefServiceKey = 'hotel_app_notif_service_enabled';
  static const String _prefPromoKey = 'hotel_app_notif_promo_enabled';
  static const String _prefHapticKey = 'hotel_app_notif_haptic_enabled';
  static const String _prefSoundKey = 'hotel_app_notif_sound_enabled';

  final List<AppNotificationModel> _notifications = [];
  bool _isInitialized = false;

  /// Bộ đếm số lượng thông báo chưa đọc (Reactivity cho UI badge)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Kiểu hiển thị thông báo ưa thích của người dùng
  AppNotificationStyle _preferredStyle = AppNotificationStyle.luxuryBanner;
  AppNotificationStyle get preferredStyle => _preferredStyle;

  // Các thiết lập danh mục
  bool _bookingEnabled = true;
  bool _paymentEnabled = true;
  bool _serviceEnabled = true;
  bool _promoEnabled = true;
  bool _hapticEnabled = true;
  bool _soundEnabled = true;

  bool get bookingEnabled => _bookingEnabled;
  bool get paymentEnabled => _paymentEnabled;
  bool get serviceEnabled => _serviceEnabled;
  bool get promoEnabled => _promoEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get soundEnabled => _soundEnabled;

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Khởi tạo và tải dữ liệu từ SharedPreferences, sau đó đồng bộ với Backend
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Tải cài đặt kiểu hiển thị ưa thích
      final savedStyle = prefs.getString(_prefStyleKey);
      if (savedStyle != null) {
        try {
          _preferredStyle = AppNotificationStyle.values.byName(savedStyle);
        } catch (_) {}
      }

      // 2. Tải các cài đặt toggle
      _bookingEnabled = prefs.getBool(_prefBookingKey) ?? true;
      _paymentEnabled = prefs.getBool(_prefPaymentKey) ?? true;
      _serviceEnabled = prefs.getBool(_prefServiceKey) ?? true;
      _promoEnabled = prefs.getBool(_prefPromoKey) ?? true;
      _hapticEnabled = prefs.getBool(_prefHapticKey) ?? true;
      _soundEnabled = prefs.getBool(_prefSoundKey) ?? true;

      // 3. Tải danh sách thông báo đã lưu
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
        _notifications.clear();
        for (final item in list) {
          try {
            _notifications.add(AppNotificationModel.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      } else {
        _seedDefaultNotifications();
        await _persist();
      }

      _updateUnreadCount();
      notifyListeners();

      // 4. Đồng bộ thêm danh sách thông báo từ Backend (nếu người dùng đã đăng nhập)
      fetchFromBackend().catchError((_) {});
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] Lỗi khởi tạo: $e');
      if (_notifications.isEmpty) {
        _seedDefaultNotifications();
      }
      _updateUnreadCount();
    }
  }

  /// Nạp lại dữ liệu từ bộ nhớ cục bộ để nhận các thông báo đã lưu khi app chạy ngầm hoặc bị tắt (Kill App)
  Future<void> refreshFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
        _notifications.clear();
        for (final item in list) {
          try {
            _notifications.add(AppNotificationModel.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] Lỗi refreshFromStorage: $e');
    }
  }

  /// Lưu thông báo trực tiếp vào SharedPreferences mà không cần khởi tạo instance.
  /// Được gọi từ Background Isolate (firebaseMessagingBackgroundHandler) khi ứng dụng đã bị Kill.
  static Future<void> saveRawNotificationToStorage({
    required String title,
    required String body,
    String? id,
    String? category,
    Map<String, dynamic>? data,
    String? actionRoute,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      final List<dynamic> list = rawJson != null && rawJson.isNotEmpty
          ? (jsonDecode(rawJson) as List<dynamic>)
          : [];

      final notifId = id ?? 'fcm_bg_${DateTime.now().millisecondsSinceEpoch}';

      // Tránh lưu trùng lặp nếu đã tồn tại
      final exists = list.any((item) => item is Map && item['id']?.toString() == notifId);
      if (exists) return;

      final catEnum = _resolveCategoryEnum(category, title);

      final newItem = AppNotificationModel(
        id: notifId,
        title: title,
        body: body,
        category: catEnum,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
        actionRoute: actionRoute ?? data?['route']?.toString() ?? '/my-bookings',
      );

      list.insert(0, newItem.toJson());
      if (list.length > 50) {
        list.removeLast();
      }

      await prefs.setString(_storageKey, jsonEncode(list));
      debugPrint('💾 [FCM Background] Đã lưu thông báo ngầm vào SharedPreferences: $notifId');
    } catch (e) {
      debugPrint('⚠️ [FCM Background] Lỗi lưu thông báo ngầm: $e');
    }
  }

  static AppNotificationCategory _resolveCategoryEnum(String? category, String title) {
    final lower = '${category ?? ''} ${title.toLowerCase()}';
    if (lower.contains('trả phòng') ||
        lower.contains('nhận phòng') ||
        lower.contains('đặt phòng') ||
        lower.contains('booking') ||
        lower.contains('check-in') ||
        lower.contains('check-out') ||
        lower.contains('room')) {
      return AppNotificationCategory.booking;
    }
    if (lower.contains('hóa đơn') ||
        lower.contains('thanh toán') ||
        lower.contains('invoice') ||
        lower.contains('payment') ||
        lower.contains('tiền')) {
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

  /// Đồng bộ thông báo thực tế từ Backend
  Future<void> fetchFromBackend() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get(ApiEndpoints.notifications);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
        bool hasChanges = false;
        final existingIds = _notifications.map((n) => n.id).toSet();

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty && !existingIds.contains(id)) {
              _notifications.add(AppNotificationModel.fromJson(item));
              existingIds.add(id);
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _updateUnreadCount();
          notifyListeners();
          await _persist();
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [NotificationRepository] Chưa thể đồng bộ thông báo từ BE: $e');
    }
  }

  /// Gửi yêu cầu kích hoạt thông báo thử nghiệm từ Backend
  Future<bool> sendBackendTestNotification({
    String? title,
    String? body,
    String? category,
  }) async {
    try {
      final dio = DioClient().dio;
      final payload = <String, dynamic>{};
      if (title != null) payload['title'] = title;
      if (body != null) payload['body'] = body;
      if (category != null) payload['category'] = category;

      await dio.post(ApiEndpoints.notificationsTest, data: payload);
      await fetchFromBackend();
      return true;
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] Lỗi gửi test notification lên BE: $e');
      return false;
    }
  }

  /// Thêm một thông báo mới vào danh sách
  Future<void> addNotification(AppNotificationModel notification) async {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
    await _persist();
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
      notifyListeners();
      await _persist();

      try {
        await DioClient().dio.patch(ApiEndpoints.markNotificationRead(id));
      } catch (_) {}
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead() async {
    bool hasChange = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChange = true;
      }
    }
    if (hasChange) {
      _updateUnreadCount();
      notifyListeners();
      await _persist();

      try {
        await DioClient().dio.patch(ApiEndpoints.notificationsReadAll);
      } catch (_) {}
    }
  }

  /// Xóa một thông báo theo ID
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      _updateUnreadCount();
      notifyListeners();
      await _persist();
    }
  }

  /// Xóa toàn bộ thông báo
  Future<void> clearAll() async {
    _notifications.clear();
    _updateUnreadCount();
    notifyListeners();
    await _persist();
  }

  /// Cập nhật kiểu hiển thị thông báo ưa thích
  Future<void> setPreferredStyle(AppNotificationStyle style) async {
    _preferredStyle = style;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefStyleKey, style.name);
    } catch (_) {}
  }

  /// Cập nhật các cài đặt nhận thông báo
  Future<void> updateCategorySettings({
    bool? booking,
    bool? payment,
    bool? service,
    bool? promo,
    bool? haptic,
    bool? sound,
  }) async {
    if (booking != null) _bookingEnabled = booking;
    if (payment != null) _paymentEnabled = payment;
    if (service != null) _serviceEnabled = service;
    if (promo != null) _promoEnabled = promo;
    if (haptic != null) _hapticEnabled = haptic;
    if (sound != null) _soundEnabled = sound;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (booking != null) await prefs.setBool(_prefBookingKey, booking);
      if (payment != null) await prefs.setBool(_prefPaymentKey, payment);
      if (service != null) await prefs.setBool(_prefServiceKey, service);
      if (promo != null) await prefs.setBool(_prefPromoKey, promo);
      if (haptic != null) await prefs.setBool(_prefHapticKey, haptic);
      if (sound != null) await prefs.setBool(_prefSoundKey, sound);
    } catch (_) {}
  }

  /// Reset dữ liệu phiên làm việc
  void clearSession() {
    _notifications.clear();
    _updateUnreadCount();
    notifyListeners();
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = unreadCount;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('⚠️ [NotificationRepository] Lỗi lưu trữ: $e');
    }
  }

  void _seedDefaultNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      AppNotificationModel(
        id: 'notif_1',
        title: 'Nhắc nhở thời gian trả phòng',
        body: 'Phòng Deluxe 302 của Quý khách đến hạn trả phòng lúc 12:00 hôm nay. Quý khách có thể gia hạn hoặc làm thủ tục trực tuyến.',
        category: AppNotificationCategory.booking,
        style: AppNotificationStyle.luxuryBanner,
        createdAt: now.subtract(const Duration(minutes: 8)),
        isRead: false,
        actionLabel: 'Xem chuyến đi',
        actionRoute: '/my-bookings',
      ),
      AppNotificationModel(
        id: 'notif_2',
        title: 'Hóa đơn dịch vụ mới',
        body: 'Dịch vụ Room Service ẩm thực đêm tại phòng 302 đã được tạo. Tổng cộng: 350.000đ.',
        category: AppNotificationCategory.payment,
        style: AppNotificationStyle.dynamicIsland,
        createdAt: now.subtract(const Duration(minutes: 32)),
        isRead: false,
        actionLabel: 'Xem hóa đơn',
        actionRoute: '/my-bookings',
      ),
      AppNotificationModel(
        id: 'notif_3',
        title: 'Dịch vụ buồng phòng hoàn tất',
        body: 'Nhân viên buồng phòng đã dọn dẹp sạch sẽ và bổ sung trà, nước suối tại phòng của Quý khách.',
        category: AppNotificationCategory.service,
        style: AppNotificationStyle.glassCard,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
        actionLabel: 'Dịch vụ',
        actionRoute: '/services',
      ),
      AppNotificationModel(
        id: 'notif_4',
        title: 'Ưu đãi Đặc quyền Thành viên VIP',
        body: 'Tặng Quý khách Voucher giảm 20% khi trải nghiệm bữa tối Hoàng Gia tại Rooftop Paradise.',
        category: AppNotificationCategory.promotion,
        style: AppNotificationStyle.bottomToast,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionLabel: 'Nhận ưu đãi',
        actionRoute: '/services',
      ),
      AppNotificationModel(
        id: 'notif_5',
        title: 'Chào mừng Quý khách đến với Paradise',
        body: 'Chúc Quý khách một kỳ nghỉ tuyệt vời và thư thái tại Paradise Resort & Luxury Hotel.',
        category: AppNotificationCategory.system,
        style: AppNotificationStyle.dialogAlert,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }
}
