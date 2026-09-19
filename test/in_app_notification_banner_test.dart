import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/notifications/models/app_notification_model.dart';
import 'package:hotel_app/shared/widgets/app_error_display.dart';
import 'package:hotel_app/shared/widgets/in_app_notification_banner.dart';

void main() {
  group('InAppNotificationBanner 5 Styles Tests', () {
    // 1. Test Modern Luxury Banner
    testWidgets('Renders InAppNotificationBanner with Modern Luxury UI elements',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  InAppNotificationBanner.show(
                    context: context,
                    title: 'Nhắc nhở trả phòng',
                    body: 'Phòng Deluxe 302 đến hạn trả phòng lúc 12:00.',
                    style: AppNotificationStyle.luxuryBanner,
                    category: 'Nhắc nhở trả phòng',
                    icon: Icons.hourglass_top_rounded,
                  );
                },
                child: const Text('Kích hoạt thông báo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Kích hoạt thông báo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('LUXE CONCIERGE'), findsOneWidget);
      expect(find.text('Nhắc nhở trả phòng'), findsNWidgets(2));
      expect(find.text('Phòng Deluxe 302 đến hạn trả phòng lúc 12:00.'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    // 2. Test Dynamic Island Capsule
    testWidgets('Renders Dynamic Island Capsule with expansion and dismiss',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showDynamicIsland(
                    context: context,
                    title: 'Hóa đơn dịch vụ mới',
                    body: 'Dịch vụ Room Service đã được tạo',
                    category: 'Thanh toán',
                  );
                },
                child: const Text('Mở Dynamic Island'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Dynamic Island'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Hóa đơn dịch vụ mới'), findsOneWidget);
      expect(find.byIcon(Icons.unfold_more_rounded), findsOneWidget);

      // Chạm nút mở rộng
      await tester.tap(find.byIcon(Icons.unfold_more_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byIcon(Icons.unfold_less_rounded), findsOneWidget);

      // Chạm đóng
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hóa đơn dịch vụ mới'), findsNothing);
    });

    // 3. Test Frosted Glass Card
    testWidgets('Renders Frosted Glass Card with action button',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showGlassCard(
                    context: context,
                    title: 'Dọn phòng hoàn tất',
                    body: 'Buồng phòng đã sạch sẽ',
                    category: 'Dịch vụ',
                    onTap: () => tapped = true,
                  );
                },
                child: const Text('Mở Glass Card'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Glass Card'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Dọn phòng hoàn tất'), findsOneWidget);
      expect(find.text('Chi tiết'), findsOneWidget);

      await tester.tap(find.text('Chi tiết'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    // 4. Test Floating Bottom Toast
    testWidgets('Renders Floating Bottom Toast above bottom bar',
        (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showBottomToast(
                    context: context,
                    title: 'Voucher 20% Rooftop',
                    body: 'Ưu đãi ăn tối VIP',
                    onTap: () => actionClicked = true,
                  );
                },
                child: const Text('Mở Bottom Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Bottom Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Voucher 20% Rooftop'), findsOneWidget);
      expect(find.text('Xem'), findsOneWidget);

      await tester.tap(find.text('Xem'));
      await tester.pump();
      expect(actionClicked, isTrue);
    });

    // 5. Test Luxury Modal Dialog
    testWidgets('Renders Luxury Modal Dialog with dual actions',
        (tester) async {
      bool viewClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showDialogAlert(
                    context: context,
                    title: 'Xác nhận nâng hạng phòng',
                    body: 'Quý khách đã được nâng cấp lên Suite',
                    category: 'Đặc quyền VIP',
                    onTap: () => viewClicked = true,
                  );
                },
                child: const Text('Mở Modal Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Xác nhận nâng hạng phòng'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      expect(find.text('Xem ngay'), findsOneWidget);

      await tester.tap(find.text('Xem ngay'));
      await tester.pump();
      expect(viewClicked, isTrue);
    });
  });
}
