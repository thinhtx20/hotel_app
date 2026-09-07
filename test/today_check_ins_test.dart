import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/admin/screens/today_check_ins_screen.dart';
import 'package:hotel_app/shared/widgets/custom_button.dart';

class MockTodayCheckInsDioClient implements DioClient {
  final List<String> requestedPaths = [];
  Map<String, dynamic>? lastQueryParams;
  final List<Map<String, dynamic>> mockBookings;

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) {}

  MockTodayCheckInsDioClient({this.mockBookings = const []}) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            lastQueryParams = options.queryParameters;

            if (options.method == 'GET' &&
                options.path == ApiEndpoints.bookings) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': mockBookings,
                    'meta': {
                      'total': mockBookings.length,
                      'page': 1,
                      'limit': 100,
                      'totalPages': mockBookings.isEmpty ? 0 : 1,
                    },
                  },
                ),
              );
            }

            if (options.method == 'POST' &&
                options.path == ApiEndpoints.checkIn('bk_confirmed_1')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'bk_confirmed_1',
                      'bookingCode': 'BK-CONF-01',
                      'roomId': 'room_101',
                      'roomNumber': '101',
                      'roomTypeName': 'Deluxe City View',
                      'status': 'CHECKED_IN',
                      'customerName': 'Nguyễn Văn Chờ',
                      'customerPhone': '0911223344',
                      'actualCheckIn': DateTime.now().toIso8601String(),
                      'checkInDate': DateTime.now().toIso8601String(),
                      'checkOutDate': DateTime.now()
                          .add(const Duration(days: 2))
                          .toIso8601String(),
                      'guestCount': 2,
                      'totalAmount': 1500000,
                      'depositAmount': 500000,
                    },
                  },
                ),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
              ),
            );
          },
        ),
      );
  }
}

void main() {
  group('TodayCheckInsScreen Comprehensive Tests', () {
    testWidgets(
        'renders header counters, tabs, walk-in badge, and performs check-in',
        (tester) async {
      final mockClient = MockTodayCheckInsDioClient(
        mockBookings: [
          {
            'id': 'bk_confirmed_1',
            'bookingCode': 'BK-CONF-01',
            'roomId': 'room_101',
            'roomNumber': '101',
            'roomTypeName': 'Deluxe City View',
            'status': 'CONFIRMED',
            'customerName': 'Nguyễn Văn Chờ',
            'customerPhone': '0911223344',
            'checkInDate': DateTime.now().toIso8601String(),
            'checkOutDate': DateTime.now()
                .add(const Duration(days: 2))
                .toIso8601String(),
            'guestCount': 2,
            'totalAmount': 1500000,
            'depositAmount': 500000,
          },
          {
            'id': 'bk_walkin_2',
            'bookingCode': 'BK-WALK-02',
            'roomId': 'room_102',
            'roomNumber': '102',
            'roomTypeName': 'Standard Single',
            'status': 'CHECKED_IN',
            'customerName': 'Lê Thu Hà (Lễ Tân)',
            'customerPhone': '0903334455',
            'specialRequests':
                '[Walk-in] Khách: Trần Văn Vãng Lai • SĐT: 0988776655 • CCCD/Passport: 123456789',
            'actualCheckIn': DateTime.now().toIso8601String(),
            'checkInDate': DateTime.now().toIso8601String(),
            'checkOutDate': DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String(),
            'guestCount': 1,
            'totalAmount': 800000,
            'depositAmount': 0,
          },
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckInsScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header Tiêu đề & Thống kê
      expect(find.text('Nhận Phòng Hôm Nay'), findsOneWidget);
      expect(find.textContaining('Dự kiến: 2'), findsOneWidget);
      expect(find.textContaining('Đã nhận: 1'), findsOneWidget);
      expect(find.textContaining('Chờ: 1'), findsOneWidget);

      // 2. Tabs
      expect(find.text('Tất cả (2)'), findsOneWidget);
      expect(find.text('Chờ nhận (1)'), findsOneWidget);
      expect(find.text('Đã nhận (1)'), findsOneWidget);

      // 3. Khách vãng lai: Tên hiển thị là tên trích xuất từ specialRequests
      expect(find.textContaining('Trần Văn Vãng Lai'), findsOneWidget);
      expect(find.text('0988776655'), findsOneWidget);
      expect(find.text('Vãng lai'), findsOneWidget);
      expect(find.text('ĐÃ NHẬN PHÒNG'), findsOneWidget);
      expect(find.text('Dịch vụ'), findsOneWidget);

      // 4. Khách chờ nhận phòng: có nút Check-in ngay
      expect(find.textContaining('Nguyễn Văn Chờ'), findsOneWidget);
      expect(find.text('CHỜ CHECK-IN'), findsOneWidget);
      expect(find.text('Check-in ngay'), findsOneWidget);

      // 5. Kiểm tra FAB Walk-in
      expect(find.text('Nhận phòng tại quầy (Walk-in)'), findsOneWidget);

      // 6. Lọc Tab: Chờ nhận
      await tester.tap(find.text('Chờ nhận (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nguyễn Văn Chờ'), findsOneWidget);
      expect(find.textContaining('Trần Văn Vãng Lai'), findsNothing);

      // 7. Lọc Tab: Đã nhận
      await tester.tap(find.text('Đã nhận (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trần Văn Vãng Lai'), findsOneWidget);
      expect(find.textContaining('Nguyễn Văn Chờ'), findsNothing);

      // 8. Quay lại Tất cả
      await tester.tap(find.text('Tất cả (2)'));
      await tester.pumpAndSettle();

      // 9. Thực hiện Check-in cho đơn chờ
      await tester.tap(find.text('Check-in ngay'));
      await tester.pumpAndSettle();

      // Dialog xác nhận mở ra
      expect(find.text('Xác nhận Nhận phòng'), findsOneWidget);
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // SnackBar hiển thị thành công
      expect(find.textContaining('Đã nhận phòng thành công'), findsOneWidget);
      // Đơn đã chuyển thành ĐÃ NHẬN PHÒNG
      expect(find.text('ĐÃ NHẬN PHÒNG'), findsNWidgets(2));
    });

    testWidgets('Empty state displays actionable Walk-in button',
        (tester) async {
      final emptyMockClient = MockTodayCheckInsDioClient(mockBookings: []);

      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckInsScreen(dioClient: emptyMockClient),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Không có lượt nhận phòng'), findsOneWidget);
      // Nút hành động CustomButton trong Empty State
      expect(find.byType(CustomButton), findsOneWidget);
      // FAB và Empty state button
      expect(find.text('Nhận phòng tại quầy (Walk-in)'), findsNWidgets(2));
    });
  });
}
