import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/constants/role_permissions.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/core/services/push_notification_service.dart';
import 'package:hotel_app/di/injection_container.dart' as di;
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/features/notifications/models/app_notification_model.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/widgets/in_app_notification_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await di.sl.reset();
    await di.initDependencies();
  });

  group('PushNotificationService Route Resolution & Banner Dismiss Tests', () {
    test('resolveTargetRoute adapts routes according to user role', () {
      // Customer
      expect(
        PushNotificationService.resolveTargetRoute({'route': '/my-bookings'}, role: UserRole.customer),
        equals('/my-bookings'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({'route': 'my-bookings'}, role: UserRole.customer),
        equals('/my-bookings'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({}, role: UserRole.customer),
        equals('/my-bookings'),
      );

      // Admin
      expect(
        PushNotificationService.resolveTargetRoute({'route': '/my-bookings'}, role: UserRole.admin),
        equals('/admin/rooms'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({'route': '/services'}, role: UserRole.admin),
        equals('/admin/services'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({}, role: UserRole.admin),
        equals('/admin/rooms'),
      );

      // Receptionist
      expect(
        PushNotificationService.resolveTargetRoute({'route': '/my-bookings'}, role: UserRole.receptionist),
        equals('/receptionist/today'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({'route': '/services'}, role: UserRole.receptionist),
        equals('/receptionist'),
      );
      expect(
        PushNotificationService.resolveTargetRoute({}, role: UserRole.receptionist),
        equals('/receptionist/today'),
      );
    });

    testWidgets('Tapping DialogAlert banner immediately removes overlay and unblocks touches', (tester) async {
      bool bannerTapped = false;
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => buttonTapped = true,
                child: const Text('Touch Me'),
              ),
            ),
          ),
        ),
      );

      InAppNotificationBanner.show(
        context: tester.element(find.byType(Scaffold)),
        title: 'Cảnh báo hệ thống',
        body: 'Vui lòng kiểm tra phòng',
        style: AppNotificationStyle.dialogAlert,
        onTap: () {
          bannerTapped = true;
        },
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Xem ngay'), findsOneWidget);

      // Click "Xem ngay"
      await tester.tap(find.text('Xem ngay'));
      await tester.pump();
      expect(bannerTapped, isTrue);

      // Wait a short time, then click the background button
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Touch Me'));
      await tester.pump();

      expect(buttonTapped, isTrue);
    });

    testWidgets('Tapping LuxuryBanner removes overlay immediately', (tester) async {
      bool bannerTapped = false;
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => buttonTapped = true,
                child: const Text('Touch Me Luxury'),
              ),
            ),
          ),
        ),
      );

      InAppNotificationBanner.show(
        context: tester.element(find.byType(Scaffold)),
        title: 'Hạn trả phòng',
        body: 'Phòng 302',
        style: AppNotificationStyle.luxuryBanner,
        onTap: () {
          bannerTapped = true;
        },
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Xem'), findsOneWidget);

      await tester.tap(find.text('Xem'));
      await tester.pump();
      expect(bannerTapped, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Touch Me Luxury'));
      await tester.pump();

      expect(buttonTapped, isTrue);
    });
  });

  group('NotificationsScreen Tap & Detail Bottom Sheet Tests', () {
    testWidgets('Tapping notification card opens detail sheet and enables safe navigation', (tester) async {
      final authBloc = di.sl<AuthBloc>();
      final user = UserModel(
        id: 'customer_1',
        email: 'customer@hotel.com',
        fullName: 'Customer Test',
        role: UserRole.customer,
      );
      authBloc.emit(AuthAuthenticated(user));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));

      router.go('/notifications');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Nhắc nhở thời gian trả phòng'), findsOneWidget);

      // Tap on the first card
      await tester.tap(find.text('Nhắc nhở thời gian trả phòng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Detail sheet should be visible with ElevatedButton and "Đóng" button
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.text('Đóng'), findsOneWidget);

      // Tap action button inside detail sheet
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should safely navigate to /my-bookings without crash or freeze
      expect(router.routerDelegate.currentConfiguration.uri.toString(), equals('/my-bookings'));
    });

    testWidgets('Tapping notification without actionRoute shows detail sheet and closes cleanly', (tester) async {
      final authBloc = di.sl<AuthBloc>();
      final user = UserModel(
        id: 'customer_1',
        email: 'customer@hotel.com',
        fullName: 'Customer Test',
        role: UserRole.customer,
      );
      authBloc.emit(AuthAuthenticated(user));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));

      router.go('/notifications');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Find notif_5 ("Chào mừng Quý khách đến với Paradise")
      final itemFinder = find.text('Chào mừng Quý khách đến với Paradise');
      await tester.scrollUntilVisible(
        itemFinder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Detail sheet is shown with "Đóng" button
      expect(find.text('Đóng'), findsOneWidget);

      await tester.tap(find.text('Đóng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Detail sheet closes cleanly, still on /notifications
      expect(router.routerDelegate.currentConfiguration.uri.toString(), equals('/notifications'));
    });
  });

  group('AppRouter ErrorBuilder Fallback Test', () {
    testWidgets('Invalid route displays errorBuilder fallback instead of crashing', (tester) async {
      final authBloc = di.sl<AuthBloc>();
      final user = UserModel(
        id: 'customer_1',
        email: 'customer@hotel.com',
        fullName: 'Customer Test',
        role: UserRole.customer,
      );
      authBloc.emit(AuthAuthenticated(user));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to non-existent route
      router.go('/some-invalid-route-12345');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Không tìm thấy trang yêu cầu'), findsOneWidget);
      expect(find.text('Quay về trang chính'), findsOneWidget);

      // Tap return to home
      await tester.tap(find.text('Quay về trang chính'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.routerDelegate.currentConfiguration.uri.toString(), equals(UserRole.customer.homeRoute));
    });
  });
}
