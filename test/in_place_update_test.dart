import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/admin/screens/service_catalog_screen.dart';
import 'package:hotel_app/features/customer/screens/room_search_screen.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/models/service_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/repositories/service_repository.dart';

class MockServiceRepo extends ServiceRepository {
  List<ServiceModel> mockServices = [
    const ServiceModel(id: 's1', name: 'Giặt ủi', unitPrice: 50000),
    const ServiceModel(id: 's2', name: 'Ăn sáng tại phòng', unitPrice: 150000),
  ];

  @override
  Future<List<ServiceModel>> fetchServices({bool forceRefresh = false}) async {
    return List.from(mockServices);
  }

  @override
  Future<ServiceModel> createService(Map<String, dynamic> payload) async {
    final item = ServiceModel(
      id: 's3',
      name: payload['name'],
      unitPrice: payload['price'],
    );
    mockServices.add(item);
    return item;
  }

  @override
  Future<ServiceModel> updateService(String id, Map<String, dynamic> payload) async {
    final item = ServiceModel(
      id: id,
      name: payload['name'],
      unitPrice: payload['price'],
    );
    final idx = mockServices.indexWhere((s) => s.id == id);
    if (idx != -1) mockServices[idx] = item;
    return item;
  }

  @override
  Future<void> deleteService(String id) async {
    mockServices.removeWhere((s) => s.id == id);
  }
}

class FakeRoomRepo extends RoomRepository {
  final List<RoomModel> _mockRooms = [
    RoomModel(
      id: 'r1',
      roomNumber: '101',
      floor: 1,
      status: RoomStatus.available,
      pricePerNight: 1000000,
    ),
    RoomModel(
      id: 'r2',
      roomNumber: '102',
      floor: 1,
      status: RoomStatus.occupied,
      pricePerNight: 1200000,
    ),
  ];

  @override
  List<RoomModel> get rooms => List.unmodifiable(_mockRooms);

  @override
  Future<List<RoomModel>> searchRooms({
    String? q,
    num? minPrice,
    num? maxPrice,
    List<String>? amenities,
    String? sort,
    int? floor,
    String? status,
  }) async {
    return List.from(_mockRooms);
  }

  void triggerStatusChange(String roomId, RoomStatus newStatus) {
    final idx = _mockRooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _mockRooms[idx] = _mockRooms[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }
}

void main() {
  setUpAll(() {
    if (!sl.isRegistered<BookingRepository>()) {
      sl.registerLazySingleton<BookingRepository>(() => BookingRepository());
    }
  });

  group('In-Place Update Tests (No Full-Screen Reload)', () {
    testWidgets('ServiceCatalogScreen updates in-place when deleting service without full-screen spinner', (tester) async {
      final mockRepo = MockServiceRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceCatalogScreen(serviceRepository: mockRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra có 2 dịch vụ ban đầu
      expect(find.text('Giặt ủi'), findsOneWidget);
      expect(find.text('Ăn sáng tại phòng'), findsOneWidget);

      // Tìm và nhấn nút xóa dịch vụ đầu tiên
      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Hộp thoại xác nhận xóa xuất hiện
      expect(find.text('Xác nhận xóa'), findsOneWidget);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Xác nhận item đã bị xóa khỏi danh sách mà không có CircularProgressIndicator toàn màn
      expect(find.text('Giặt ủi'), findsNothing);
      expect(find.text('Ăn sáng tại phòng'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('RoomSearchScreen updates room status in-place without triggering full screen loading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeRoomRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: RoomSearchScreen(roomRepository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra ban đầu có phòng 101 và 102
      expect(find.text('Phòng 101'), findsOneWidget);
      expect(find.text('Phòng 102'), findsOneWidget);

      // Kích hoạt biến động trạng thái phòng 101 từ AVAILABLE sang OCCUPIED
      fakeRepo.triggerStatusChange('r1', RoomStatus.occupied);
      await tester.pump(); // không pumpAndSettle để kiểm tra xem có cờ _isLoading = true hay không

      // Xác nhận không bị biến mất kết quả tìm kiếm sang CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Phòng 101'), findsOneWidget);
    });
  });
}
