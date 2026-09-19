import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_app/features/notifications/models/app_notification_model.dart';
import 'package:hotel_app/features/notifications/repositories/notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationRepository Tests', () {
    late NotificationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = NotificationRepository();
      await repo.init();
    });

    test('Initializes with default seed notifications and unread count', () {
      expect(repo.notifications.isNotEmpty, isTrue);
      expect(repo.unreadCount, greaterThan(0));
      expect(repo.unreadCountNotifier.value, equals(repo.unreadCount));
      expect(repo.preferredStyle, equals(AppNotificationStyle.luxuryBanner));
    });

    test('addNotification prepends notification and increments unread count', () async {
      final initialCount = repo.notifications.length;
      final initialUnread = repo.unreadCount;

      final newNotif = AppNotificationModel(
        id: 'test_new_1',
        title: 'Thông báo thử nghiệm',
        body: 'Nội dung thông báo thử nghiệm',
        category: AppNotificationCategory.booking,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await repo.addNotification(newNotif);

      expect(repo.notifications.length, equals(initialCount + 1));
      expect(repo.notifications.first.id, equals('test_new_1'));
      expect(repo.unreadCount, equals(initialUnread + 1));
      expect(repo.unreadCountNotifier.value, equals(initialUnread + 1));
    });

    test('markAsRead updates notification status and decrements unread count', () async {
      final unreadItem = repo.notifications.firstWhere((n) => !n.isRead);
      final prevUnread = repo.unreadCount;

      await repo.markAsRead(unreadItem.id);

      final updated = repo.notifications.firstWhere((n) => n.id == unreadItem.id);
      expect(updated.isRead, isTrue);
      expect(repo.unreadCount, equals(prevUnread - 1));
      expect(repo.unreadCountNotifier.value, equals(prevUnread - 1));
    });

    test('markAllAsRead marks all items as read', () async {
      expect(repo.unreadCount, greaterThan(0));

      await repo.markAllAsRead();

      expect(repo.unreadCount, equals(0));
      expect(repo.unreadCountNotifier.value, equals(0));
      expect(repo.notifications.every((n) => n.isRead), isTrue);
    });

    test('deleteNotification removes item from list', () async {
      final target = repo.notifications.first;
      final targetId = target.id;
      final prevLength = repo.notifications.length;

      await repo.deleteNotification(targetId);

      expect(repo.notifications.length, equals(prevLength - 1));
      expect(repo.notifications.any((n) => n.id == targetId), isFalse);
    });

    test('setPreferredStyle updates style and persists', () async {
      expect(repo.preferredStyle, equals(AppNotificationStyle.luxuryBanner));

      await repo.setPreferredStyle(AppNotificationStyle.dynamicIsland);
      expect(repo.preferredStyle, equals(AppNotificationStyle.dynamicIsland));

      await repo.setPreferredStyle(AppNotificationStyle.glassCard);
      expect(repo.preferredStyle, equals(AppNotificationStyle.glassCard));
    });

    test('updateCategorySettings toggles notification channels', () async {
      expect(repo.bookingEnabled, isTrue);
      expect(repo.paymentEnabled, isTrue);

      await repo.updateCategorySettings(booking: false, payment: false);

      expect(repo.bookingEnabled, isFalse);
      expect(repo.paymentEnabled, isFalse);
      expect(repo.serviceEnabled, isTrue);
    });
  });
}
