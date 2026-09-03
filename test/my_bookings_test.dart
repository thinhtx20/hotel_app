import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/customer/screens/my_bookings_screen.dart';
import 'package:hotel_app/shared/models/booking_model.dart';

void main() {
  group('BookingModel Tests', () {
    test('BookingModel.fromJson parses complete backend JSON correctly', () {
      final json = {
        'id': '7cd5148f-5867-412a-b56b-a9914fa90d71',
        'bookingCode': 'BK-2026-004',
        'customerId': '37d2189e-41e4-4e6d-8aa1-72b025c14c8d',
        'roomId': '8733b02d-b785-4f30-bd0e-bb08bd74c5d9',
        'checkInDate': '2026-09-04T04:35:00.737Z',
        'checkOutDate': '2026-09-07T04:35:00.737Z',
        'guestCount': 3,
        'totalAmount': 2850000,
        'depositAmount': 1000000,
        'status': 'CONFIRMED',
        'specialRequests': 'Gia đình có em bé',
        'room': {
          'id': '8733b02d-b785-4f30-bd0e-bb08bd74c5d9',
          'roomNumber': '203',
          'floor': 2,
          'roomType': {
            'name': 'Superior City View',
            'basePrice': 950000,
          },
        },
        'customer': {
          'fullName': 'Nguyễn Văn A',
          'email': 'customer@hotel.com',
          'phone': '0912345678',
        },
      };

      final model = BookingModel.fromJson(json);

      expect(model.id, '7cd5148f-5867-412a-b56b-a9914fa90d71');
      expect(model.bookingCode, 'BK-2026-004');
      expect(model.roomNumber, '203');
      expect(model.roomTypeName, 'Superior City View');
      expect(model.floor, 2);
      expect(model.customerName, 'Nguyễn Văn A');
      expect(model.status, 'CONFIRMED');
      expect(model.totalAmount, 2850000);
      expect(model.depositAmount, 1000000);
      expect(model.guestCount, 3);
      expect(model.nightsCount, 3);
    });

    test('BookingModel handles null / empty fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'bk-minimal',
        'roomId': 'room-1',
      };

      final model = BookingModel.fromJson(json);
      expect(model.id, 'bk-minimal');
      expect(model.status, 'PENDING');
      expect(model.totalAmount, 0);
      expect(model.depositAmount, 0);
      expect(model.guestCount, 1);
    });

    test('BookingModel parses cancellationReason correctly', () {
      final json = <String, dynamic>{
        'id': 'bk-cancelled',
        'roomId': 'room-1',
        'status': 'CANCELLED',
        'cancellationReason': 'Thay đổi lịch trình',
      };

      final model = BookingModel.fromJson(json);
      expect(model.status, 'CANCELLED');
      expect(model.cancellationReason, 'Thay đổi lịch trình');
    });
  });

  group('MyBookingsScreen Widget Tests', () {
    testWidgets('renders MyBookingsScreen with header and all status tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyBookingsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify Header
      expect(find.text('Đơn Đặt Phòng'), findsOneWidget);
      expect(find.text('Lịch sử & trạng thái phòng của bạn'), findsOneWidget);

      // Verify Tabs
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đã xác nhận'), findsOneWidget);
      expect(find.text('Đang ở'), findsOneWidget);
      expect(find.text('Đã hoàn tất'), findsOneWidget);
      expect(find.text('Đã hủy'), findsOneWidget);
    });
  });
}
