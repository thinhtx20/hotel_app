import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/receptionist/widgets/room_stay_actions.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';

class MockWalkInDioClient implements DioClient {
  final List<String> requestedPaths = [];
  Map<String, dynamic>? lastPostData;
  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) {}

  MockWalkInDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);

          if (options.method == 'POST' && options.path == ApiEndpoints.bookings) {
            lastPostData = options.data is Map<String, dynamic>
                ? options.data as Map<String, dynamic>
                : null;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'data': {
                    'id': 'bk_new_walk_in',
                    'bookingCode': 'BK-WALKIN-01',
                    'roomId': options.data['roomId'],
                    'status': 'CONFIRMED',
                    'checkInDate': options.data['checkInDate'],
                    'checkOutDate': options.data['checkOutDate'],
                    'guestCount': options.data['guestCount'],
                    'totalAmount': 950000,
                    'depositAmount': options.data['depositAmount'],
                    'specialRequests': options.data['specialRequests'],
                  },
                },
              ),
            );
          }

          if (options.method == 'POST' && options.path == ApiEndpoints.checkIn('bk_new_walk_in')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'id': 'bk_new_walk_in',
                    'bookingCode': 'BK-WALKIN-01',
                    'roomId': 'room_12107',
                    'status': 'CHECKED_IN',
                    'actualCheckIn': DateTime.now().toIso8601String(),
                    'checkInDate': DateTime.now().toIso8601String(),
                    'checkOutDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                    'guestCount': 1,
                    'totalAmount': 950000,
                    'depositAmount': 0,
                    'specialRequests': '[Walk-in] Khách: Nguyễn Văn Tuấn • SĐT: 0912345678',
                  },
                },
              ),
            );
          }

          if (options.method == 'GET' && options.path == ApiEndpoints.bookings) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [],
                  'meta': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 1},
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
  group('BookingModel Display Helpers Tests', () {
    test('returns customerName directly when present', () {
      final booking = BookingModel(
        id: '1',
        roomId: 'r1',
        customerName: 'Nguyễn Văn A',
        customerPhone: '0901234567',
        checkInDate: DateTime.now(),
        checkOutDate: DateTime.now().add(const Duration(days: 1)),
        guestCount: 1,
        totalAmount: 1000000,
        status: 'CHECKED_IN',
      );

      expect(booking.displayCustomerName, 'Nguyễn Văn A');
      expect(booking.displayCustomerPhone, '0901234567');
    });

    test('extracts customer info from specialRequests for walk-in booking without user', () {
      final booking = BookingModel(
        id: '2',
        roomId: 'r2',
        customerName: null,
        customerPhone: null,
        specialRequests: '[Walk-in] Khách: Lê Hoàng Nam • SĐT: 0987654321 • CCCD/Passport: 001200000000',
        checkInDate: DateTime.now(),
        checkOutDate: DateTime.now().add(const Duration(days: 1)),
        guestCount: 1,
        totalAmount: 1500000,
        status: 'CHECKED_IN',
      );

      expect(booking.displayCustomerName, 'Lê Hoàng Nam');
      expect(booking.displayCustomerPhone, '0987654321');
    });

    test('falls back to "Khách vãng lai" when no name exists', () {
      final booking = BookingModel(
        id: '3',
        roomId: 'r3',
        checkInDate: DateTime.now(),
        checkOutDate: DateTime.now().add(const Duration(days: 1)),
        guestCount: 1,
        totalAmount: 500000,
        status: 'CHECKED_IN',
      );

      expect(booking.displayCustomerName, 'Khách vãng lai');
      expect(booking.displayCustomerPhone, isNull);
    });
  });

  group('BookingRepository walkInCheckIn Tests', () {
    test('creates CONFIRMED booking and checks in immediately', () async {
      final mockDioClient = MockWalkInDioClient();
      final repo = BookingRepository(dioClient: mockDioClient);

      final now = DateTime.now();
      final checkout = now.add(const Duration(days: 2));

      final result = await repo.walkInCheckIn(
        roomId: 'room_12107',
        checkInDate: now,
        checkOutDate: checkout,
        guestCount: 2,
        depositAmount: 500000,
        paymentMethod: 'CASH',
        customerName: 'Nguyễn Văn Tuấn',
        customerPhone: '0912345678',
        customerIdentity: '001200000000',
        notes: 'Khách đến nhận phòng sớm',
      );

      expect(result.id, 'bk_new_walk_in');
      expect(result.status, 'CHECKED_IN');
      expect(mockDioClient.requestedPaths, contains(ApiEndpoints.bookings));
      expect(mockDioClient.requestedPaths, contains(ApiEndpoints.checkIn('bk_new_walk_in')));

      final payload = mockDioClient.lastPostData!;
      expect(payload['roomId'], 'room_12107');
      expect(payload['status'], 'CONFIRMED');
      expect(payload['guestCount'], 2);
      expect(payload['depositAmount'], 500000);
      expect(payload['specialRequests'], contains('Nguyễn Văn Tuấn'));
      expect(payload['specialRequests'], contains('0912345678'));
      expect(payload['specialRequests'], contains('001200000000'));
    });
  });

  group('RoomStayActions Walk-in UI Tests', () {
    testWidgets('shows walk-in check-in button when room is available with no bookings', (tester) async {
      final mockDioClient = MockWalkInDioClient();
      final repo = BookingRepository(dioClient: mockDioClient);

      final room = RoomModel(
        id: 'room_12107',
        roomNumber: '12107',
        floor: 1,
        pricePerNight: 950000,
        status: RoomStatus.available,
      );

      bool walkInTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomStayActions(
              room: room,
              bookingRepository: repo,
              canCheckIn: true,
              canCheckOut: true,
              onCheckIn: (_) {},
              onCheckOut: (_) {},
              onWalkInCheckIn: () {
                walkInTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Phòng đang trống & sẵn sàng'), findsOneWidget);
      expect(find.text('Phòng này chưa có đơn nào cần làm thủ tục nhận / trả phòng.'), findsOneWidget);
      expect(find.text('Nhận phòng khách vãng lai (Walk-in)'), findsOneWidget);

      await tester.tap(find.text('Nhận phòng khách vãng lai (Walk-in)'));
      await tester.pump();

      expect(walkInTapped, isTrue);
    });
  });
}
