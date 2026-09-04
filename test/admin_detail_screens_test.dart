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
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);

            if (options.path == ApiEndpoints.analyticsOccupancyDetail) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'summary': {
                        'totalRooms': 20,
                        'occupiedRooms': 4,
                        'availableRooms': 10,
                        'cleaningRooms': 2,
                        'reservedRooms': 3,
                        'maintenanceRooms': 1,
                        'occupancyRate': 20.0,
                      },
                      'byRoomType': [
                        {
                          'roomTypeName': 'Standard Queen Double',
                          'totalRooms': 6,
                          'occupiedRooms': 1,
                          'occupancyRate': 16.7,
                          'basePrice': 1200000,
                        },
                      ],
                      'rooms': [
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
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.todayCheckIns) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'totalExpected': 2,
                      'checkedInCount': 1,
                      'pendingCheckInCount': 1,
                      'bookings': [
                        {
                          'id': 'bk_01',
                          'bookingCode': 'BK-2026-088',
                          'roomId': '201',
                          'roomNumber': '201',
                          'roomTypeName': 'Deluxe Ocean View',
                          'floor': 2,
                          'customerName': 'Trần Thị Mai',
                          'customerPhone': '0987654321',
                          'checkInDate': '2026-09-04T14:00:00Z',
                          'checkOutDate': '2026-09-07T12:00:00Z',
                          'guestCount': 2,
                          'totalAmount': 5400000,
                          'depositAmount': 2000000,
                          'status': 'CONFIRMED',
                        },
                        {
                          'id': 'bk_02',
                          'bookingCode': 'BK-2026-082',
                          'roomId': '105',
                          'roomNumber': '105',
                          'roomTypeName': 'Standard Queen',
                          'floor': 1,
                          'customerName': 'Lê Hoàng Long',
                          'customerPhone': '0901234567',
                          'checkInDate': '2026-09-04T12:30:00Z',
                          'checkOutDate': '2026-09-05T12:00:00Z',
                          'actualCheckIn': '2026-09-04T12:35:00Z',
                          'guestCount': 1,
                          'totalAmount': 1200000,
                          'depositAmount': 1200000,
                          'status': 'CHECKED_IN',
                        },
                      ],
                    },
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.todayCheckOuts) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'totalExpected': 2,
                      'checkedOutCount': 1,
                      'pendingCheckOutCount': 1,
                      'bookings': [
                        {
                          'id': 'bk_co_01',
                          'bookingCode': 'BK-2026-075',
                          'roomId': '302',
                          'roomNumber': '302',
                          'roomTypeName': 'Deluxe Ocean Panorama',
                          'floor': 3,
                          'customerName': 'Vũ Minh Tuấn',
                          'customerPhone': '0933445566',
                          'checkInDate': '2026-09-02T14:00:00Z',
                          'checkOutDate': '2026-09-04T12:00:00Z',
                          'guestCount': 2,
                          'totalAmount': 4000000,
                          'paymentStatus': 'PARTIALLY_PAID',
                          'status': 'CHECKED_IN',
                        },
                      ],
                    },
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.pendingBookings) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'totalPending': 1,
                      'bookings': [
                        {
                          'id': 'bk_pb_01',
                          'bookingCode': 'BK-2026-102',
                          'roomNumber': '501',
                          'roomTypeName': 'Presidential Penthouse',
                          'floor': 5,
                          'customerName': 'Đặng Quốc Hưng',
                          'customerPhone': '0918889999',
                          'checkInDate': '2026-09-10T14:00:00Z',
                          'checkOutDate': '2026-09-14T12:00:00Z',
                          'guestCount': 3,
                          'nights': 4,
                          'totalAmount': 18000000,
                          'depositAmount': 5000000,
                          'status': 'PENDING',
                          'specialRequests': 'Yêu cầu setup bánh sinh nhật',
                        },
                      ],
                    },
                  },
                ),
              );
            }

            // Check-in, check-out, approve, reject responses
            if (options.path.contains('/check-in') ||
                options.path.contains('/check-out') ||
                options.path.contains('/approve') ||
                options.path.contains('/reject')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'Thành công'},
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
      expect(find.text('Lượt Nhận Phòng Hôm Nay'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Tất cả ('), findsOneWidget);
      expect(find.textContaining('Chờ nhận ('), findsOneWidget);
      expect(find.textContaining('Đã nhận ('), findsOneWidget);

      // Nút nhận phòng
      expect(find.text('Xác nhận Nhận phòng'), findsWidgets);

      // Nhấn nút nhận phòng để mở dialog xác nhận
      await tester.tap(find.text('Xác nhận Nhận phòng').first);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận Nhận phòng'), findsWidgets);
      expect(find.text('Xác nhận'), findsOneWidget);

      // Nhấn xác nhận
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Kiểm tra snackbar thông báo thành công
      expect(find.text('Đã làm thủ tục nhận phòng thành công!'), findsOneWidget);
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
      expect(find.text('Lượt Trả Phòng Hôm Nay'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Tất cả ('), findsOneWidget);
      expect(find.textContaining('Chờ trả ('), findsOneWidget);
      expect(find.textContaining('Đã trả ('), findsOneWidget);

      // Nút xác nhận trả phòng
      expect(find.text('Xác nhận Trả phòng'), findsWidgets);

      // Mở dialog trả phòng
      await tester.tap(find.text('Xác nhận Trả phòng').first);
      await tester.pumpAndSettle();

      expect(find.text('Đã kiểm tra minibar & đồ đạc'), findsOneWidget);
      expect(find.text('Xác nhận Trả phòng'), findsWidgets);

      // Xác nhận
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận Trả phòng').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Đã hoàn tất trả phòng! Phòng đã được chuyển sang trạng thái Dọn dẹp.'),
        findsOneWidget,
      );
    });

    testWidgets('PendingBookingsScreen renders tabs and approve/reject flows',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PendingBookingsScreen(dioClient: mockClient),
        ),
      );

      await tester.pumpAndSettle();

      // Tiêu đề
      expect(find.text('Đơn Đặt Phòng Chờ Duyệt'), findsOneWidget);

      // Tabs
      expect(find.textContaining('Chờ duyệt ('), findsOneWidget);
      expect(find.textContaining('Đã duyệt ('), findsOneWidget);
      expect(find.textContaining('Đã từ chối ('), findsOneWidget);

      // Các nút thao tác
      expect(find.text('Duyệt đơn'), findsWidgets);
      expect(find.text('Từ chối'), findsWidgets);

      // Thử duyệt đơn
      await tester.tap(find.text('Duyệt đơn').first);
      await tester.pumpAndSettle();

      expect(find.text('Phê duyệt Đơn phòng'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Duyệt đơn'), findsWidgets);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Duyệt đơn').last);
      await tester.pumpAndSettle();

      expect(find.text('Đã phê duyệt đơn đặt phòng thành công!'), findsOneWidget);
    });
  });
}
