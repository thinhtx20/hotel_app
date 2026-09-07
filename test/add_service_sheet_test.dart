import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/receptionist/widgets/add_service_sheet.dart';
import 'package:hotel_app/shared/models/service_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/service_repository.dart';

class FakeServiceRepository extends ServiceRepository {
  final List<ServiceModel> mockServices;

  FakeServiceRepository({required this.mockServices}) : super();

  @override
  Future<List<ServiceModel>> fetchServices({bool forceRefresh = false}) async {
    return mockServices;
  }
}

class FakeBookingRepository extends BookingRepository {
  final List<({String serviceName, num unitPrice, int quantity})> submittedItems = [];
  String? lastBookingId;

  FakeBookingRepository() : super();

  @override
  Future<void> addMultipleServices(
    String id,
    List<({String serviceName, num unitPrice, int quantity})> items, {
    void Function(int current, int total, String serviceName)? onProgress,
  }) async {
    lastBookingId = id;
    submittedItems.addAll(items);
    for (var i = 0; i < items.length; i++) {
      onProgress?.call(i + 1, items.length, items[i].serviceName);
    }
  }
}

void main() {
  late FakeServiceRepository fakeServiceRepo;
  late FakeBookingRepository fakeBookingRepo;

  final sampleServices = [
    const ServiceModel(
      id: 'srv_laundry',
      code: 'LAUNDRY',
      name: 'Giặt là cao cấp',
      category: 'CONVENIENCE',
      unitPrice: 50000,
      unit: 'món',
      icon: 'local_laundry_service',
    ),
    const ServiceModel(
      id: 'srv_minibar',
      code: 'MINIBAR',
      name: 'Minibar trọn gói',
      category: 'FOOD_BEVERAGE',
      unitPrice: 150000,
      unit: 'combo',
      icon: 'kitchen',
    ),
    const ServiceModel(
      id: 'srv_breakfast',
      code: 'BREAKFAST',
      name: 'Ăn sáng buffet',
      category: 'FOOD_BEVERAGE',
      unitPrice: 200000,
      unit: 'suất',
      icon: 'restaurant',
    ),
  ];

  setUp(() {
    fakeServiceRepo = FakeServiceRepository(mockServices: sampleServices);
    fakeBookingRepo = FakeBookingRepository();
  });

  Widget buildTestSheet({VoidCallback? onServiceAdded}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              AddServiceSheet.show(
                context: ctx,
                bookingId: 'bk_123',
                roomNumber: '12107',
                onServiceAdded: onServiceAdded,
                serviceRepository: fakeServiceRepo,
                bookingRepository: fakeBookingRepo,
              );
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AddServiceSheet Multi-Service Selection Tests', () {
    testWidgets('Renders header, catalog chips, and empty state initially', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Thêm Dịch Vụ Phát Sinh'), findsOneWidget);
      expect(find.textContaining('Phòng 12107'), findsOneWidget);

      // Chips from catalog
      expect(find.text('Giặt là cao cấp'), findsOneWidget);
      expect(find.text('Minibar trọn gói'), findsOneWidget);

      // Initial empty state
      expect(find.text('Chưa có dịch vụ nào được chọn'), findsOneWidget);
      expect(find.text('Vui lòng chọn dịch vụ'), findsOneWidget);
    });

    testWidgets('Selecting multiple services updates chips, cart list, and total amount', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Chạm chọn "Giặt là cao cấp" (50.000đ)
      await tester.tap(find.text('Giặt là cao cấp'));
      await tester.pumpAndSettle();

      // Chạm chọn "Minibar trọn gói" (150.000đ)
      await tester.tap(find.text('Minibar trọn gói').first);
      await tester.pumpAndSettle();

      // Danh sách đã chọn hiển thị 2 dịch vụ
      expect(find.text('Dịch vụ đã chọn (2):'), findsOneWidget);
      expect(find.textContaining('2 dịch vụ • 2 sản phẩm'), findsOneWidget);

      // Tổng tiền: 50.000 + 150.000 = 200.000 đ
      expect(find.textContaining('200.000'), findsWidgets);

      // Tăng số lượng "Giặt là cao cấp" lên 2 qua nút [+]
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Tổng tiền mới: 50.000 * 2 + 150.000 = 250.000 đ
      expect(find.textContaining('250.000'), findsWidgets);
      expect(find.textContaining('2 dịch vụ • 3 sản phẩm'), findsOneWidget);

      // Nút bấm hiển thị tổng tiền và số dịch vụ
      expect(find.textContaining('Ghi Nhận 2 Dịch Vụ'), findsOneWidget);
    });

    testWidgets('Deselecting via chip or removing via close icon updates list', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Chọn 2 dịch vụ
      await tester.tap(find.text('Giặt là cao cấp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minibar trọn gói').first);
      await tester.pumpAndSettle();

      expect(find.text('Dịch vụ đã chọn (2):'), findsOneWidget);

      // Chạm lại chip "Minibar trọn gói" ở danh mục chip phía trên để bỏ chọn
      await tester.tap(find.text('Minibar trọn gói').first);
      await tester.pumpAndSettle();

      // Chỉ còn 1 dịch vụ (Giặt là cao cấp)
      expect(find.text('Dịch vụ đã chọn (1):'), findsOneWidget);
      expect(find.textContaining('50.000'), findsWidgets);

      // Xóa item còn lại bằng nút đóng
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Quay về trạng thái trống
      expect(find.text('Chưa có dịch vụ nào được chọn'), findsOneWidget);
    });

    testWidgets('Adding custom service outside catalog works properly', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Mở form nhập tùy chỉnh
      await tester.tap(find.text('Thêm dịch vụ ngoài danh mục / tùy chỉnh'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dịch vụ ngoài danh mục'), findsOneWidget);

      // Nhập tên và đơn giá
      await tester.enterText(
        find.widgetWithText(TextField, 'VD: Nước ngọt, Đền bù vỡ ly, Phụ thu check-in sớm...'),
        'Đền ly vỡ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Đơn giá (VND)'),
        '30000',
      );
      await tester.pumpAndSettle();

      // Bấm + Thêm
      await tester.tap(find.text('+ Thêm'));
      await tester.pumpAndSettle();

      // Kiểm tra món đã vào danh sách với tag "Ngoài danh mục"
      expect(find.text('Đền ly vỡ'), findsOneWidget);
      expect(find.text('Ngoài danh mục'), findsOneWidget);
      expect(find.textContaining('30.000'), findsWidgets);
    });

    testWidgets('Submitting submits all items to repository and invokes callback', (tester) async {
      configureViewport(tester);
      bool callbackCalled = false;
      await tester.pumpWidget(buildTestSheet(onServiceAdded: () {
        callbackCalled = true;
      }));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Chọn 2 dịch vụ có sẵn
      await tester.tap(find.text('Giặt là cao cấp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minibar trọn gói').first);
      await tester.pumpAndSettle();

      // Bấm Ghi nhận dịch vụ
      await tester.tap(find.textContaining('Ghi Nhận 2 Dịch Vụ'));
      await tester.pumpAndSettle();

      // Xác minh repository nhận đúng dữ liệu
      expect(fakeBookingRepo.lastBookingId, 'bk_123');
      expect(fakeBookingRepo.submittedItems.length, 2);
      expect(fakeBookingRepo.submittedItems[0].serviceName, 'Giặt là cao cấp');
      expect(fakeBookingRepo.submittedItems[0].unitPrice, 50000);
      expect(fakeBookingRepo.submittedItems[0].quantity, 1);
      expect(fakeBookingRepo.submittedItems[1].serviceName, 'Minibar trọn gói');
      expect(fakeBookingRepo.submittedItems[1].unitPrice, 150000);
      expect(fakeBookingRepo.submittedItems[1].quantity, 1);

      // Callback được gọi
      expect(callbackCalled, isTrue);

      // Sheet đã đóng
      expect(find.text('Thêm Dịch Vụ Phát Sinh'), findsNothing);
    });

    testWidgets('Auto-adds custom item if user typed name and price before hitting submit', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestSheet());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Mở form nhập tùy chỉnh
      await tester.tap(find.text('Thêm dịch vụ ngoài danh mục / tùy chỉnh'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'VD: Nước ngọt, Đền bù vỡ ly, Phụ thu check-in sớm...'),
        'Nước suối Aquafina',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Đơn giá (VND)'),
        '15000',
      );
      await tester.pumpAndSettle();

      // Bấm + Thêm
      await tester.tap(find.byType(ElevatedButton).last); // Nút + Thêm
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Ghi Nhận 1 Dịch Vụ'));
      await tester.pumpAndSettle();

      expect(fakeBookingRepo.submittedItems.length, 1);
      expect(fakeBookingRepo.submittedItems[0].serviceName, 'Nước suối Aquafina');
      expect(fakeBookingRepo.submittedItems[0].unitPrice, 15000);
    });
  });
}
