import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/admin/screens/occupancy_detail_screen.dart';
import 'package:hotel_app/features/admin/screens/pending_bookings_screen.dart';
import 'package:hotel_app/features/admin/screens/today_check_ins_screen.dart';
import 'package:hotel_app/features/admin/screens/today_check_outs_screen.dart';

class MockDetailDioClient implements DioClient {
  final List<String> requestedPaths = [];
  @override
  late final Dio dio;

  MockDetailDioClient() {
    final now = DateTime.now();
    final todayStr = now.toIso8601String();

    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);

            if (options.path == ApiEndpoints.analyticsOccupancyByType) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'roomTypeName': 'Standard Queen Double',
                        'totalRooms': 6,
                        'occupiedRooms': 1,
                        'occupancyRate': 16.7,
                        'basePrice': 1200000,
                      },
                    ],
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.rooms) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': '101',
                        'roomNumber': '101',
                        'floor': 1,
                        'status': 'AVAILABLE',
                        'pricePerNight': 1200000,
                        'roomTypeName': 'Standard Queen Double',
                      },
                      {
                        'id': '103',
                        'roomNumber': '103',
                        'floor': 1,
                        'status': 'OCCUPIED',
                        'pricePerNight': 1200000,
                        'roomTypeName': 'Standard Queen Double',
                      },
                    ],
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.bookings) {
              final allBookings = <Map<String, dynamic>>[
                      {
                        'id': 'bk_01',
                        'bookingCode': 'BK-2026-088',
                        'roomId': '201',
                        'roomNumber': '201',
                        'roomTypeName': 'Deluxe Ocean View',
                        'floor': 2,
                        'customerName': 'Trần Thị Mai',
                        'customerPhone': '0987654321',
                        'checkInDate': todayStr,
                        'checkOutDate': now.add(const Duration(days: 3)).toIso8601String(),
                        'guestCount': 2,
                        'totalAmount': 5400000,
                        'depositAmount': 2000000,
                        'status': 'CONFIRMED',
                      },
                      {
                        'id': 'bk_co_01',
                        'bookingCode': 'BK-2026-075',
                        'roomId': '302',
                        'roomNumber': '302',
                        'roomTypeName': 'Deluxe Ocean Panorama',
                        'floor': 3,
                        'customerName': 'Vũ Minh Tuấn',
                        'customerPhone': '0933445566',
                        'checkInDate': now.subtract(const Duration(days: 2)).toIso8601String(),
                        'checkOutDate': todayStr,
                        'guestCount': 2,
                        'totalAmount': 4000000,
                        'paymentStatus': 'PARTIALLY_PAID',
                        'status': 'CHECKED_IN',
                      },
                      {
                        'id': 'bk_pb_01',
                        'bookingCode': 'BK-2026-102',
                        'roomId': '501',
                        'roomNumber': '501',
                        'roomTypeName': 'Presidential Penthouse',
                        'floor': 5,
                        'customerName': 'Đặng Quốc Hưng',
                        'customerPhone': '0918889999',
                        'checkInDate': now.add(const Duration(days: 6)).toIso8601String(),
                        'checkOutDate': now.add(const Duration(days: 10)).toIso8601String(),
                        'guestCount': 3,
                        'nights': 4,
                        'totalAmount': 18000000,
                        'depositAmount': 5000000,
                        'status': 'PENDING',
                        'specialRequests': 'Yêu cầu setup bánh sinh nhật',
                      },
              ];

              // Mô phỏng bộ lọc phía máy chủ của API mới:
              // ?status=A,B & checkInFrom/checkInTo & checkOutFrom/checkOutTo
              final query = options.queryParameters;
              DateTime? dayBound(String key, {required bool endOfDay}) {
                final raw = query[key];
                if (raw == null) return null;
                final parsed = DateTime.tryParse(raw.toString());
                if (parsed == null) return null;
                return endOfDay
                    ? DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59)
                    : DateTime(parsed.year, parsed.month, parsed.day);
              }

              final statuses = (query['status']?.toString() ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList();
              final checkInFrom = dayBound('checkInFrom', endOfDay: false);
              final checkInTo = dayBound('checkInTo', endOfDay: true);
              final checkOutFrom = dayBound('checkOutFrom', endOfDay: false);
              final checkOutTo = dayBound('checkOutTo', endOfDay: true);

              final filtered = allBookings.where((b) {
                if (statuses.isNotEmpty && !statuses.contains(b['status'])) {
                  return false;
                }
                final checkIn = DateTime.parse(b['checkInDate'] as String);
                final checkOut = DateTime.parse(b['checkOutDate'] as String);
                if (checkInFrom != null && checkIn.isBefore(checkInFrom)) return false;
                if (checkInTo != null && checkIn.isAfter(checkInTo)) return false;
                if (checkOutFrom != null && checkOut.isBefore(checkOutFrom)) return false;
                if (checkOutTo != null && checkOut.isAfter(checkOutTo)) return false;
                return true;
              }).toList();

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    // API mới bọc danh sách trong `data.data` kèm `data.meta`
                    'data': {
                      'data': filtered,
                      'meta': {
                        'total': filtered.length,
                        'page': 1,
                        'limit': 20,
                        'totalPages': 1,
                      },
                    },
                  },
                ),
              );
            }

            // Check-in
            if (options.path.contains('/check-in')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'bk_01',
                      'bookingCode': 'BK-2026-088',
                      'roomId': '201',
                      'roomNumber': '201',
                      'roomTypeName': 'Deluxe Ocean View',
                      'checkInDate': todayStr,
                      'checkOutDate': now.add(const Duration(days: 3)).toIso8601String(),
                      'guestCount': 2,
                      'status': 'CHECKED_IN',
                    },
                  },
                ),
              );
            }

            // Check-out
            if (options.path.contains('/check-out')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'booking': {
                        'id': 'bk_co_01',
                        'bookingCode': 'BK-2026-075',
                        'roomId': '302',
                        'roomNumber': '302',
                        'checkInDate': now.subtract(const Duration(days: 2)).toIso8601String(),
                        'checkOutDate': todayStr,
                        'guestCount': 2,
                        'status': 'CHECKED_OUT',
                      },
                      'invoice': {
                        'id': 'INV-2026-001',
                        'invoiceCode': 'INV-001',
                        'roomAmount': 4000000,
                        'servicesAmount': 0,
                        'discount': 0,
                        'tax': 400000,
                        'finalAmount': 4400000,
                        'paidAmount': 4400000,
                        'paymentStatus': 'PAID',
                      },
                    },
                  },
                ),
              );
            }

            // Cancel
            if (options.path.contains('/cancel')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'bk_pb_01',
                      'bookingCode': 'BK-2026-102',
                      'roomId': '501',
                      'checkInDate': now.add(const Duration(days: 6)).toIso8601String(),
                      'checkOutDate': now.add(const Duration(days: 10)).toIso8601String(),
                      'guestCount': 3,
                      'status': 'CANCELLED',
                    },
                  },
                ),
              );
            }

            // Fallback 404
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                ),
              ),
            );
          },
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

void main() {
  group('Admin Detail Screens Widget Tests', () {
    late MockDetailDioClient mockClient;

    setUp(() {
      mockClient = MockDetailDioClient();
    });

    testWidgets('OccupancyDetailScreen renders summary, hero card, pills and room list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OccupancyDetailScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Chi tiết Tỷ lệ Lấp đầy'), findsOneWidget);
      expect(find.text('Theo dõi công suất phòng theo thời gian thực'), findsOneWidget);

      // Kiểm tra thẻ Hero
      expect(find.text('Công suất phòng hiện tại'), findsOneWidget);

      // Kiểm tra các nhãn thống kê trạng thái phòng
      expect(find.textContaining('Có khách:'), findsOneWidget);
      expect(find.textContaining('Trống:'), findsOneWidget);
      expect(find.textContaining('Dọn dẹp:'), findsOneWidget);

      // Kiểm tra thanh tìm kiếm
      expect(find.byType(TextField), findsOneWidget);

      // Tìm kiếm phòng
      await tester.enterText(find.byType(TextField), '101');
      await tester.pumpAndSettle();

      expect(find.text('P.101'), findsOneWidget);
    });

    testWidgets('TodayCheckInsScreen renders header, tabs and booking cards',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckInsScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // Tiêu đề
      expect(find.text('Nhận Phòng Hôm Nay'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Tất cả ('), findsOneWidget);
      expect(find.textContaining('Chờ nhận ('), findsOneWidget);
      expect(find.textContaining('Đã nhận ('), findsOneWidget);

      // Nút nhận phòng
      expect(find.text('Check-in ngay'), findsOneWidget);

      // Nhấn nút nhận phòng để mở dialog xác nhận
      await tester.tap(find.text('Check-in ngay'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận Nhận phòng'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // Nhấn xác nhận
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Kiểm tra snackbar thông báo thành công
      expect(find.textContaining('Đã nhận phòng thành công'), findsOneWidget);
    });

    testWidgets('TodayCheckOutsScreen renders header, tabs and check-out actions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckOutsScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // Tiêu đề
      expect(find.text('Trả Phòng Hôm Nay'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Tất cả ('), findsOneWidget);
      expect(find.textContaining('Chờ trả ('), findsOneWidget);
      expect(find.textContaining('Đã trả ('), findsOneWidget);

      // Nút xác nhận trả phòng
      expect(find.text('Trả phòng & Xuất HĐ'), findsOneWidget);

      // Mở sheet trả phòng
      await tester.tap(find.text('Trả phòng & Xuất HĐ'));
      await tester.pumpAndSettle();

      expect(find.text('Thủ tục Trả phòng & Xuất Hóa đơn'), findsOneWidget);
      expect(find.text('Xác nhận Trả phòng & Xuất Hóa đơn'), findsOneWidget);

      // Xác nhận
      await tester.tap(find.text('Xác nhận Trả phòng & Xuất Hóa đơn'));
      await tester.pumpAndSettle();

      expect(
        find.text('Hóa đơn đã xuất thành công'),
        findsOneWidget,
      );
    });

    testWidgets('PendingBookingsScreen renders tabs and check-in / reject flows',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PendingBookingsScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // Tiêu đề
      expect(find.text('Đơn Phòng Chờ Xác Nhận'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Chờ xác nhận'), findsWidgets);
      expect(find.textContaining('Đã duyệt'), findsOneWidget);
      expect(find.textContaining('Đã từ chối'), findsOneWidget);

      // Các nút thao tác
      expect(find.text('Nhận phòng'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);

      // Thử nhận phòng ngay
      await tester.tap(find.text('Nhận phòng'));
      await tester.pumpAndSettle();

      expect(find.text('Nhận phòng ngay'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Nhận phòng'), findsWidgets);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nhận phòng').last);
      await tester.pumpAndSettle();

      expect(find.text('Khách đã nhận phòng thành công!'), findsOneWidget);
    });

    testWidgets('TodayCheckInsScreen back button triggers back action',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckInsScreen(dioClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
    });

    testWidgets('TodayCheckOutsScreen back button triggers back action',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TodayCheckOutsScreen(dioClient: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
    });
  });
}
