import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      sl.registerLazySingleton<RoomRepository>(() => RoomRepository());
    }
  });

  group('RoomStatus & RoomModel Tests', () {
    test('RoomStatus.fromString parses PENDING_APPROVAL and REJECTED', () {
      expect(RoomStatus.fromString('PENDING_APPROVAL'), equals(RoomStatus.pendingApproval));
      expect(RoomStatus.fromString('PENDING'), equals(RoomStatus.pendingApproval));
      expect(RoomStatus.fromString('REJECTED'), equals(RoomStatus.rejected));
      expect(RoomStatus.fromString('AVAILABLE'), equals(RoomStatus.available));
    });

    test('RoomTypeModel.fromJson parses complete backend JSON', () {
      final json = {
        'id': 'type-123',
        'name': 'Deluxe Ocean Panorama',
        'code': 'DLX-OV',
        'description': 'Phòng Deluxe view biển',
        'basePrice': 1250000,
        'capacityAdults': 2,
        'capacityChildren': 1,
        'sizeSqM': 40,
        'amenities': ['Wifi', 'Ban công'],
        'images': ['https://images.unsplash.com/test.jpg'],
      };
      final roomType = RoomTypeModel.fromJson(json);
      expect(roomType.id, equals('type-123'));
      expect(roomType.name, equals('Deluxe Ocean Panorama'));
      expect(roomType.basePrice, equals(1250000));
      expect(roomType.amenities.length, equals(2));
    });

    test('RoomModel.fromJson parses pending room correctly', () {
      final json = {
        'id': 'room-99',
        'roomNumber': '901',
        'floor': 9,
        'status': 'PENDING_APPROVAL',
        'pricePerNight': 2000000,
        'roomTypeId': 'type-123',
        'roomTypeName': 'Deluxe Ocean Panorama',
        'amenities': ['Wifi', 'Bồn tắm'],
        'images': ['https://images.unsplash.com/test.jpg'],
      };
      final room = RoomModel.fromJson(json);
      expect(room.roomNumber, equals('901'));
      expect(room.status, equals(RoomStatus.pendingApproval));
      expect(room.roomTypeName, equals('Deluxe Ocean Panorama'));
    });

    test('RoomRepository filtering works correctly', () {
      final repo = sl<RoomRepository>();
      final pending = repo.pendingRooms;
      final approved = repo.approvedRooms;
      final rejected = repo.rejectedRooms;

      expect(pending, isA<List<RoomModel>>());
      expect(approved, isA<List<RoomModel>>());
      expect(rejected, isA<List<RoomModel>>());
    });
  });
}
