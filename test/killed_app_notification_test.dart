import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_app/core/services/push_notification_service.dart';
import 'package:hotel_app/features/notifications/models/app_notification_model.dart';
import 'package:hotel_app/features/notifications/repositories/notification_repository.dart';

class _MockRouter {
  String? navigatedRoute;
  void go(String route) {
    navigatedRoute = route;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Killed App Notification & Cold Start Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PushNotificationService.pendingNotificationPayload = null;
    });

    test('saveRawNotificationToStorage saves notification in SharedPreferences when app is killed', () async {
      await NotificationRepository.saveRawNotificationToStorage(
        title: 'Nhắc nhở trả phòng',
        body: 'Phòng 302 sắp đến giờ trả phòng',
        id: 'bg_notif_123',
        category: 'booking',
        data: {'route': '/my-bookings', 'bookingId': 'bk_999'},
        actionRoute: '/my-bookings',
      );

      final repo = NotificationRepository();
      await repo.init();

      expect(repo.notifications.any((n) => n.id == 'bg_notif_123'), isTrue);
      final savedItem = repo.notifications.firstWhere((n) => n.id == 'bg_notif_123');
      expect(savedItem.title, equals('Nhắc nhở trả phòng'));
      expect(savedItem.body, equals('Phòng 302 sắp đến giờ trả phòng'));
      expect(savedItem.category, equals(AppNotificationCategory.booking));
      expect(savedItem.actionRoute, equals('/my-bookings'));
      expect(savedItem.isRead, isFalse);
    });

    test('refreshFromStorage loads notifications saved in background without re-seeding', () async {
      final repo = NotificationRepository();
      await repo.init();
      final initialCount = repo.notifications.length;

      // Giả lập app nhận thêm thông báo khi đang chạy ngầm / bị kill
      await NotificationRepository.saveRawNotificationToStorage(
        title: 'Thanh toán thành công',
        body: 'Hóa đơn INV_100 đã được thanh toán',
        id: 'bg_payment_456',
        category: 'payment',
      );

      // Gọi refreshFromStorage để cập nhật
      await repo.refreshFromStorage();

      expect(repo.notifications.length, equals(initialCount + 1));
      expect(repo.notifications.first.id, equals('bg_payment_456'));
      expect(repo.notifications.first.category, equals(AppNotificationCategory.payment));
    });

    test('Cold Start deep-linking consumes pendingNotificationPayload to correct target route', () {
      final mockRouter = _MockRouter();

      PushNotificationService.pendingNotificationPayload = {
        'title': 'dsfsdfsf',
        'body': 'sdfsdfdsfsdffdsfdfdfsdwer',
        'route': '/my-bookings',
      };

      expect(PushNotificationService.pendingNotificationPayload, isNotNull);

      PushNotificationService.consumePendingNotification(mockRouter);

      expect(mockRouter.navigatedRoute, equals('/my-bookings'));
      expect(PushNotificationService.pendingNotificationPayload, isNull);
    });

    test('Cold Start deep-linking fallback to actionRoute or /my-bookings when route not specified', () {
      final mockRouter = _MockRouter();

      PushNotificationService.pendingNotificationPayload = {
        'actionRoute': '/notifications',
      };

      PushNotificationService.consumePendingNotification(mockRouter);

      expect(mockRouter.navigatedRoute, equals('/notifications'));
      expect(PushNotificationService.pendingNotificationPayload, isNull);
    });
  });
}
