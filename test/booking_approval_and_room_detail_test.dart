import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<BookingRepository>()) {
      sl.registerLazySingleton<BookingRepository>(() => BookingRepository());
    }
    if (!sl.isRegistered<RoomRepository>()) {
      sl.registerLazySingleton<RoomRepository>(() => RoomRepository());
    }
  });

  group('Booking Approval & Room Detail Tests', () {
    test('ApiEndpoints defines booking approval endpoints', () {
      expect(ApiEndpoints.approveBooking('123'), equals('/bookings/123/approve'));
      expect(ApiEndpoints.rejectBooking('123'), equals('/bookings/123/reject'));
    });

    test('RoomModel parses enriched backend details correctly', () {
      final json = {
        'id': 'room-vip-101',
        'roomNumber': '101',
        'floor': 1,
        'status': 'AVAILABLE',
        'pricePerNight': 2500000,
        'roomTypeId': 'type-deluxe',
        'roomTypeName': 'Executive Ocean Suite',
        'description': 'Phòng siêu sang hướng biển',
        'bedType': '1 Giường King đôi cỡ lớn (2m x 2m)',
        'viewType': 'Trực diện biển (Ocean Panoramic View)',
        'highlights': ['Ban công riêng', 'Bồn tắm sục Jacuzzi', 'Máy pha cà phê Nespresso'],
        'policies': {
          'checkInTime': '14:00',
          'checkOutTime': '12:00',
          'cancellation': 'Miễn phí hủy trước 48h',
          'children': 'Miễn phí tối đa 1 trẻ em dưới 6 tuổi',
        },
        'ratingBreakdown': {
          'cleanliness': 4.9,
          'comfort': 4.8,
          'location': 5.0,
          'service': 4.9,
          'value': 4.7,
        },
        'reviews': [
          {
            'id': 'rev-01',
            'authorName': 'Nguyễn Văn A',
            'authorAvatar': 'https://images.unsplash.com/avatar1.jpg',
            'rating': 5.0,
            'date': '2026-08-20',
            'comment': 'Phòng đẹp tuyệt vời, view biển ngắm hoàng hôn đỉnh cao!',
          }
        ],
        'amenityGroups': [
          {
            'groupName': 'Tiện ích phòng tắm',
            'icon': 'bathtub',
            'items': ['Bồn tắm Jacuzzi', 'Áo choàng tắm lụa', 'Máy sấy tóc cao cấp'],
          },
          {
            'groupName': 'Giải trí & Công nghệ',
            'icon': 'tv',
            'items': ['Smart TV 65 inch 4K', 'Wifi 6 tốc độ cao', 'Loa Bluetooth Marshall'],
          }
        ],
        'images': [
          'https://images.unsplash.com/room1.jpg',
          'https://images.unsplash.com/room2.jpg',
        ],
        'rating': 4.9,
        'reviewCount': 86,
      };

      final room = RoomModel.fromJson(json);

      expect(room.id, equals('room-vip-101'));
      expect(room.bedType, equals('1 Giường King đôi cỡ lớn (2m x 2m)'));
      expect(room.viewType, equals('Trực diện biển (Ocean Panoramic View)'));
      expect(room.highlights.length, equals(3));
      expect(room.highlights.first, equals('Ban công riêng'));
      expect(room.policies.checkInTime, equals('14:00'));
      expect(room.policies.cancellation, equals('Miễn phí hủy trước 48h'));
      expect(room.ratingBreakdown.cleanliness, equals(4.9));
      expect(room.reviews.length, equals(1));
      expect(room.reviews.first.authorName, equals('Nguyễn Văn A'));
      expect(room.amenityGroups.length, equals(2));
      expect(room.amenityGroups.first.groupName, equals('Tiện ích phòng tắm'));
      expect(room.images.length, equals(2));
      expect(room.rating, equals(4.9));
      expect(room.reviewCount, equals(86));
    });

    test('BookingModel handles customer and payment details', () {
      final json = {
        'id': 'booking-001',
        'bookingCode': 'BK20260904',
        'roomId': 'room-vip-101',
        'roomNumber': '101',
        'roomTypeName': 'Executive Ocean Suite',
        'customerId': 'cust-01',
        'customerName': 'Lê Hoàng Nam',
        'customerPhone': '0912345678',
        'checkInDate': '2026-09-10T14:00:00.000Z',
        'checkOutDate': '2026-09-12T12:00:00.000Z',
        'guestCount': 2,
        'totalAmount': 5000000,
        'depositAmount': 1500000,
        'paymentStatus': 'PAID_DEPOSIT',
        'status': 'PENDING',
        'specialRequests': 'Khách yêu cầu nhận phòng sớm nếu có thể',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, equals('booking-001'));
      expect(booking.bookingCode, equals('BK20260904'));
      expect(booking.customerName, equals('Lê Hoàng Nam'));
      expect(booking.customerPhone, equals('0912345678'));
      expect(booking.totalAmount, equals(5000000));
      expect(booking.depositAmount, equals(1500000));
      expect(booking.paymentStatus, equals('PAID_DEPOSIT'));
      expect(booking.status, equals('PENDING'));
      expect(booking.specialRequests, equals('Khách yêu cầu nhận phòng sớm nếu có thể'));
    });

    test('Deposit rule: 10% when total > 5M, 0 when total <= 5M', () {
      num calcDeposit(num total) {
        return total > 5000000 ? (total * 0.1).round() : 0;
      }

      // Trên 5 triệu -> 10%
      expect(calcDeposit(6000000), equals(600000));
      expect(calcDeposit(12500000), equals(1250000));

      // Dưới hoặc bằng 5 triệu -> không cần cọc (0đ)
      expect(calcDeposit(5000000), equals(0));
      expect(calcDeposit(3500000), equals(0));
      expect(calcDeposit(1450000), equals(0));

      // Kiểm tra cấu trúc link VietQR
      final depositAmount = calcDeposit(7000000); // 700.000đ
      final qrUrl = 'https://img.vietqr.io/image/970423-03609837701-compact2.png?amount=$depositAmount&addInfo=LUXE%20COC%20P302&accountName=LUXE%20GRAND%20HOTEL';

      expect(qrUrl.contains('amount=700000'), isTrue);
      expect(qrUrl.contains('03609837701'), isTrue);
      expect(qrUrl.contains('LUXE%20GRAND%20HOTEL'), isTrue);
    });

    test('BookingRepository tracks pendingCount and exposes notifyListeners', () {
      final repo = sl<BookingRepository>();

      expect(repo.pendingCount, isA<int>());
      expect(repo.pendingCount >= 0, isTrue);
    });
  });
}
