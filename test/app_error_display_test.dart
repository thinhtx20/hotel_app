import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_error.dart';
import 'package:hotel_app/shared/widgets/app_error_display.dart';

void main() {
  group('AppErrorDisplay Widget Tests', () {
    testWidgets('AppNotification.showError renders snackbar with BE message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppNotification.messengerKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showError(
                    context,
                    const ApiError(
                      statusCode: 400,
                      message: 'Email hoặc mật khẩu không chính xác',
                      errors: ['Email sai định dạng', 'Mật khẩu quá ngắn'],
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show error
      await tester.tap(find.text('Show Error'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Complete slide-in

      // Verify UI displays the error message and status code
      expect(find.text('Email hoặc mật khẩu không chính xác'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      expect(find.text('Email sai định dạng'), findsOneWidget);
      expect(find.text('Mật khẩu quá ngắn'), findsOneWidget);
    });

    testWidgets('AppErrorView renders error message and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: const ApiError(
                statusCode: 500,
                message: 'Lỗi kết nối cơ sở dữ liệu',
              ),
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Lỗi kết nối cơ sở dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
    });
  });
}
