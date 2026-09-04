import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';

void main() {
  group('Swagger / OpenAPI Model Alignment Tests', () {
    test('UserModel maps avatar and createdAt correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'customer@hotel.com',
        'fullName': 'Nguyen Van A',
        'phone': '0912345678',
        'avatar': 'https://example.com/avatar.jpg',
        'role': 'CUSTOMER',
        'isActive': true,
        'createdAt': '2026-09-03T07:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.avatar, 'https://example.com/avatar.jpg');
      expect(user.role, UserRole.customer);
      expect(user.createdAt, isNotNull);

      final outJson = user.toJson();
      expect(outJson['avatar'], 'https://example.com/avatar.jpg');
      expect(outJson['createdAt'], contains('2026-09-03'));
    });

    test('RoomModel parses backend Swagger fields and fallbacks to roomType images', () {
      final json = {
        'id': 'room-101',
        'roomNumber': '101',
        'floor': 1,
        'status': 'AVAILABLE',
        'pricePerNight': 1200000,
        'images': [],
        'amenities': [],
        'roomType': {
          'id': 'rt-deluxe',
          'name': 'Deluxe Ocean View',
          'code': 'DLX-OV',
          'description': 'Phòng sang trọng hướng biển',
          'basePrice': 1200000,
          'sizeSqM': 42.5,
          'capacityAdults': 2,
          'capacityChildren': 1,
          'images': ['https://example.com/deluxe.jpg'],
          'amenities': ['Wifi', 'Ban công']
        },
        'rating': 4.9,
        'reviewCount': 48,
        'notes': 'View thoáng đãng'
      };

      final room = RoomModel.fromJson(json);
      expect(room.id, 'room-101');
      expect(room.roomNumber, '101');
      expect(room.images, contains('https://example.com/deluxe.jpg'));
      expect(room.amenities, contains('Wifi'));
      expect(room.roomTypeCode, 'DLX-OV');
      expect(room.description, 'Phòng sang trọng hướng biển');
      expect(room.sizeSqM, 42.5);
      expect(room.capacityAdults, 2);
      expect(room.capacityChildren, 1);
      expect(room.rating, 4.9);
      expect(room.reviewCount, 48);
      expect(room.notes, 'View thoáng đãng');
    });

    test('BookingModel parses canCancel, paymentStatus, nights and nested customer/room', () {
      final json = {
        'id': 'bk-001',
        'bookingCode': 'BK-2026-0829',
        'roomId': 'room-101',
        'checkInDate': '2026-09-10T14:00:00.000Z',
        'checkOutDate': '2026-09-12T12:00:00.000Z',
        'guestCount': 2,
        'totalAmount': 2400000,
        'depositAmount': 500000,
        'status': 'CONFIRMED',
        'paymentStatus': 'PARTIAL',
        'canCancel': true,
        'nights': 2,
        'room': {
          'roomNumber': '101',
          'roomType': {'name': 'Deluxe Ocean View'}
        },
        'customer': {
          'fullName': 'Nguyen Van Khach',
          'phone': '0901234567'
        }
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.id, 'bk-001');
      expect(booking.roomNumber, '101');
      expect(booking.customerName, 'Nguyen Van Khach');
      expect(booking.paymentStatus, 'PARTIAL');
      expect(booking.canCancel, isTrue);
      expect(booking.nightsCount, 2);
    });

    test('InvoiceModel parses payments array with paidAt and cashierName', () {
      final json = {
        'id': 'inv-001',
        'invoiceCode': 'INV-2026-0089',
        'roomAmount': 3600000,
        'servicesAmount': 200000,
        'discount': 0,
        'tax': 0,
        'finalAmount': 3800000,
        'paidAmount': 3800000,
        'paymentStatus': 'PAID',
        'roomNumber': '101',
        'customerName': 'Nguyen Van A',
        'items': [
          {
            'name': 'Tiền thuê phòng P.101',
            'quantity': 1,
            'unitPrice': 3600000,
            'amount': 3600000
          }
        ],
        'payments': [
          {
            'amount': 3800000,
            'paymentMethod': 'CREDIT_CARD',
            'paidAt': '2026-09-03T07:00:00.000Z',
            'cashierName': 'Le Thu Ngan'
          }
        ]
      };

      final invoice = InvoiceModel.fromJson(json);
      expect(invoice.id, 'inv-001');
      expect(invoice.invoiceCode, 'INV-2026-0089');
      expect(invoice.items.length, 1);
      expect(invoice.items.first.title, 'Tiền thuê phòng P.101');
      expect(invoice.items.first.unitPrice, 3600000);
      expect(invoice.transactions.length, 1);
      expect(invoice.transactions.first.paymentMethod, 'CREDIT_CARD');
      expect(invoice.transactions.first.cashierName, 'Le Thu Ngan');
      expect(invoice.remainingAmount, 0);
    });

    test('ApiEndpoints defines all necessary backend routes', () {
      expect(ApiEndpoints.login, '/auth/login');
      expect(ApiEndpoints.changePassword, '/auth/change-password');
      expect(ApiEndpoints.usersMe, '/users/me');
      expect(ApiEndpoints.invoiceSummary, '/invoices/summary');
      expect(ApiEndpoints.services, '/services');
      expect(ApiEndpoints.roomsSearch, '/rooms/search');
    });
  });
}
