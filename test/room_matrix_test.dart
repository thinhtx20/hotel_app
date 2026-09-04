import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/receptionist/screens/room_matrix_screen.dart';
import 'package:hotel_app/shared/models/room_model.dart';

class MockMatrixDioClient implements DioClient {
  final List<String> requestedPaths = [];
  dynamic lastData;
  bool shouldThrow = false;
  @override
  late final Dio dio;

  MockMatrixDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            lastData = options.data;
            if (shouldThrow) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: 'Connection error',
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
                        'roomTypeName': 'Tiêu chuẩn',
                      },
                      {
                        'id': '102',
                        'roomNumber': '102',
                        'floor': 1,
                        'status': 'OCCUPIED',
                        'pricePerNight': 1500000,
                        'roomTypeName': 'Deluxe',
                      },
                      {
                        'id': '201',
                        'roomNumber': '201',
                        'floor': 2,
                        'status': 'AVAILABLE',
                        'pricePerNight': 1800000,
                        'roomTypeName': 'VIP Suite',
                      },
                    ],
                  },
                ),
              );
            }

            // Update status endpoint
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'Cập nhật thành công'},
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
  group('RoomModel copyWith Tests', () {
    test('copyWith updates status while retaining other fields', () {
      final room = RoomModel(
        id: '101',
        roomNumber: '101',
        floor: 1,
        status: RoomStatus.available,
        pricePerNight: 1200000,
        roomTypeId: 'deluxe-1',
        roomTypeName: 'Deluxe City View',
        description: 'Phòng sang trọng',
        amenities: ['Wifi', 'Minibar'],
      );

      final updated = room.copyWith(status: RoomStatus.cleaning);

      expect(updated.id, equals('101'));
      expect(updated.roomNumber, equals('101'));
      expect(updated.floor, equals(1));
      expect(updated.status, equals(RoomStatus.cleaning));
      expect(updated.pricePerNight, equals(1200000));
      expect(updated.roomTypeId, equals('deluxe-1'));
      expect(updated.roomTypeName, equals('Deluxe City View'));
      expect(updated.amenities, equals(['Wifi', 'Minibar']));
    });
  });

  group('RoomMatrixScreen Widget Tests', () {
    testWidgets('RoomMatrixScreen renders rooms and updates status without full screen reload', (tester) async {
      final mockDioClient = MockMatrixDioClient();

      await tester.pumpWidget(
        MaterialApp(
          home: RoomMatrixScreen(dioClient: mockDioClient),
        ),
      );

      // Wait for initial fetch
      await tester.pumpAndSettle();

      // Verify title & stats
      expect(find.text('Sơ Đồ Buồng Phòng'), findsOneWidget);
      expect(find.text('TRỐNG'), findsOneWidget);
      expect(find.text('CÓ KHÁCH'), findsOneWidget);
      expect(find.text('DỌN DẸP'), findsOneWidget);

      // Verify rooms rendered
      expect(find.text('101'), findsOneWidget);
      expect(find.text('102'), findsOneWidget);
      expect(find.text('201'), findsOneWidget);

      // Tap room 101 to open quick action sheet
      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title & action buttons
      expect(find.text('Phòng 101'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sẵn sàng (Hiện tại)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Dọn dẹp'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Có khách'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Đặt cọc'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Bảo trì'), findsOneWidget);

      // Tap 'Dọn dẹp' button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Dọn dẹp'));
      await tester.pump(); // Sheet dismisses, optimistic update applied

      // CRITICAL CHECK:
      // The screen must NOT be replaced by a full-screen CircularProgressIndicator!
      // Room 101 and floor 1 must remain visible and rendered!
      expect(find.text('101'), findsOneWidget);
      expect(find.text('TẦNG 1'), findsOneWidget);
      expect(find.text('TẦNG 2'), findsOneWidget);

      // Verify optimistic update updated room 101 to 'Đang dọn dẹp'
      expect(find.text('Đang dọn dẹp'), findsWidgets);

      // Settle remaining animations and snackbar
      await tester.pumpAndSettle();

      // Verify API was called with the correct status
      expect(mockDioClient.requestedPaths, contains(ApiEndpoints.updateRoomStatus('101')));
      expect(mockDioClient.lastData, equals({'status': 'CLEANING'}));

      // Verify SnackBar success message with Vietnamese label
      expect(find.text('Đã cập nhật phòng 101 sang Đang dọn dẹp'), findsOneWidget);
    });

    testWidgets('RoomMatrixScreen reverts status on API failure and shows error SnackBar', (tester) async {
      final mockDioClient = MockMatrixDioClient();

      await tester.pumpWidget(
        MaterialApp(
          home: RoomMatrixScreen(dioClient: mockDioClient),
        ),
      );
      await tester.pumpAndSettle();

      // Configure mock to fail on subsequent requests
      mockDioClient.shouldThrow = true;

      // Tap room 101
      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();

      // Tap 'Có khách'
      await tester.tap(find.text('Có khách'));
      await tester.pump(); // Optimistic update
      await tester.pumpAndSettle(); // Failure handled and rollback

      // Verify room 101 is rolled back to 'Phòng trống'
      expect(find.text('101'), findsOneWidget);
      expect(find.text('Không thể cập nhật phòng 101. Đã khôi phục trạng thái cũ.'), findsOneWidget);
    });
  });
}
