import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/features/cashier/screens/cashier_invoices_screen.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/invoice_repository.dart';

class _FakeAuthBloc extends AuthBloc {
  _FakeAuthBloc(UserModel user) : super() {
    emit(AuthAuthenticated(user));
  }
}

void main() {
  group('InvoiceModel Tests', () {
    test('displayCode returns formatted code or shortened id', () {
      final inv1 = InvoiceModel(
        id: '27364cb1-faea-476f-a037-4a97e9123c95',
        invoiceCode: 'INV-2026-004',
        roomAmount: 1000000,
        servicesAmount: 0,
        discount: 0,
        tax: 0,
        finalAmount: 1000000,
        paidAmount: 500000,
        paymentStatus: 'PARTIAL',
      );
      expect(inv1.displayCode, 'INV-2026-004');
      expect(inv1.remainingAmount, 500000);

      final inv2 = InvoiceModel(
        id: 'abcdef1234567890',
        roomAmount: 1000000,
        servicesAmount: 0,
        discount: 0,
        tax: 0,
        finalAmount: 1000000,
        paidAmount: 1000000,
        paymentStatus: 'PAID',
      );
      expect(inv2.displayCode, 'ABCDEF12');
      expect(inv2.remainingAmount, 0);
    });

    test('InvoiceModel.fromJson parses backend response correctly', () {
      final json = {
        'id': 'inv-uuid-1',
        'invoiceCode': 'INV-2026-001',
        'roomAmount': 1350000,
        'servicesAmount': 140000,
        'discount': 50000,
        'tax': 144000,
        'finalAmount': 1584000,
        'paidAmount': 1584000,
        'paymentStatus': 'PAID',
        'booking': {
          'id': 'bk-1',
          'customer': {'fullName': 'Nguyễn Văn A'},
          'room': {'roomNumber': '101'},
        },
      };

      final model = InvoiceModel.fromJson(json);
      expect(model.id, 'inv-uuid-1');
      expect(model.invoiceCode, 'INV-2026-001');
      expect(model.customerName, 'Nguyễn Văn A');
      expect(model.roomNumber, '101');
      expect(model.finalAmount, 1584000);
      expect(model.remainingAmount, 0);
    });
  });

  group('CashierInvoicesScreen Widget Tests', () {
    testWidgets('renders Cashier screen with tabs and fallback data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );

      // Initial loading state or loaded fallback
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hóa Đơn & Thu Quỹ'), findsOneWidget);
      expect(find.text('Chưa thanh toán'), findsOneWidget);
      expect(find.text('Thanh toán 1 phần'), findsOneWidget);
      expect(find.text('Đã hoàn tất'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets); // Search text field
    });

    testWidgets('search bar filters invoice list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Enter search text '203' into the search TextField
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, '203');
      await tester.pump();

      // Invoice 203 should be found
      expect(find.textContaining('203'), findsWidgets);
    });

    testWidgets('tapping FAB opens create invoice sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final fab = find.byIcon(Icons.add);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tạo Hóa Đơn / Thêm Phụ Phí'), findsOneWidget);
    });

    testWidgets('tab switching filters invoices correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Tap tab 'Thanh toán 1 phần'
      final partialTab = find.text('Thanh toán 1 phần');
      expect(partialTab, findsOneWidget);
      await tester.tap(partialTab);
      await tester.pump();

      // Tap tab 'Đã hoàn tất'
      final paidTab = find.text('Đã hoàn tất');
      expect(paidTab, findsOneWidget);
      await tester.tap(paidTab);
      await tester.pump();
    });

    testWidgets('paginates 20 items per load and loads more on demand', (tester) async {
      final mockList = List.generate(
        45,
        (i) => InvoiceModel(
          id: 'inv-$i',
          invoiceCode: 'INV-TEST-$i',
          roomAmount: 1000000,
          servicesAmount: 0,
          discount: 0,
          tax: 0,
          finalAmount: 1000000,
          paidAmount: 0,
          paymentStatus: 'UNPAID',
        ),
      );

      if (sl.isRegistered<InvoiceRepository>()) {
        sl.unregister<InvoiceRepository>();
      }
      sl.registerLazySingleton<InvoiceRepository>(() => _StubInvoiceRepo(mockList));

      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final state = tester.state(find.byType(CashierInvoicesScreen)) as dynamic;

      // Initially only 20 items are displayed
      expect(state.displayedCount, 20);

      // Trigger load more -> increases by 20 to 40
      state.loadMoreForTesting();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.displayedCount, 40);

      // Trigger load more again -> loads remaining 5 items up to 45
      state.loadMoreForTesting();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.displayedCount, 45);

      // Switching tabs resets displayed count back to 20
      final allTab = find.text('Tất cả');
      await tester.tap(allTab);
      await tester.pump();
      expect(state.displayedCount, 20);

      // Load more again
      state.loadMoreForTesting();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.displayedCount, 40);

      // Typing in search bar resets displayed count back to 20
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'TEST');
      await tester.pump();
      expect(state.displayedCount, 20);
    });

    testWidgets('back button exists in top bar and triggers back action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CashierInvoicesScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pump();
    });

    testWidgets('Lễ tân: Hiển thị nhãn cố định Tuần này kèm khoảng ngày và không thể mở modal', (tester) async {
      final weekRange = CashierInvoicesScreen.formatCurrentWeekRange();
      final expectedLabel = 'Tuần này ($weekRange)';

      final stubRepo = _StubInvoiceRepo([]);
      if (sl.isRegistered<InvoiceRepository>()) {
        sl.unregister<InvoiceRepository>();
      }
      sl.registerLazySingleton<InvoiceRepository>(() => stubRepo);

      final recUser = UserModel(
        id: 'rec-1',
        email: 'rec@hotel.com',
        fullName: 'Lễ Tân A',
        role: UserRole.receptionist,
      );
      final authBloc = _FakeAuthBloc(recUser);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: CashierInvoicesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(expectedLabel), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsNothing);

      // Tapping label does not open bottom sheet
      await tester.tap(find.text(expectedLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bộ Lọc Thời Gian Hóa Đơn'), findsNothing);

      // Verify repo called with filterType: 'week', weekOffset: 0
      expect(stubRepo.lastFilterType, 'week');
      expect(stubRepo.lastWeekOffset, 0);
    });

    testWidgets('Admin: Hiển thị chip chọn bộ lọc thời gian, mở modal và đổi bộ lọc theo khoảng tháng', (tester) async {
      final initialList = [
        InvoiceModel(
          id: 'inv-1',
          invoiceCode: 'INV-001',
          roomAmount: 1000000,
          servicesAmount: 0,
          discount: 0,
          tax: 0,
          finalAmount: 1000000,
          paidAmount: 0,
          paymentStatus: 'UNPAID',
        ),
      ];
      final monthList = [
        InvoiceModel(
          id: 'inv-2',
          invoiceCode: 'INV-002',
          roomAmount: 2000000,
          servicesAmount: 0,
          discount: 0,
          tax: 0,
          finalAmount: 2000000,
          paidAmount: 0,
          paymentStatus: 'UNPAID',
        ),
      ];

      final stubRepo = _StubInvoiceRepo(initialList);
      if (sl.isRegistered<InvoiceRepository>()) {
        sl.unregister<InvoiceRepository>();
      }
      sl.registerLazySingleton<InvoiceRepository>(() => stubRepo);

      final adminUser = UserModel(
        id: 'admin-1',
        email: 'admin@hotel.com',
        fullName: 'Quản trị viên',
        role: UserRole.admin,
      );
      final authBloc = _FakeAuthBloc(adminUser);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: CashierInvoicesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Admin has dropdown arrow icon
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
      expect(find.text('Tuần này'), findsOneWidget);

      // Tap chip to open modal
      await tester.tap(find.text('Tuần này'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal options exist
      expect(find.text('Bộ Lọc Thời Gian Hóa Đơn'), findsOneWidget);
      expect(find.text('Tuần này (Mặc định)'), findsOneWidget);
      expect(find.text('Theo khoảng tháng'), findsOneWidget);
      expect(find.text('Theo năm'), findsOneWidget);

      // Change stub repo data for the new query
      stubRepo.stubInvoices = monthList;

      // Select "Theo khoảng tháng"
      await tester.tap(find.text('Theo khoảng tháng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Áp Dụng Bộ Lọc"
      await tester.tap(find.text('Áp Dụng Bộ Lọc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Query sent to backend
      expect(stubRepo.lastFilterType, 'month_range');
      expect(stubRepo.lastYear, DateTime.now().year);

      // Tab counts and list updated
      expect(find.textContaining('INV-002'), findsOneWidget);
      expect(find.textContaining('INV-001'), findsNothing);
    });

    testWidgets('Admin: Đổi bộ lọc theo năm và gọi API với filterType=year', (tester) async {
      final stubRepo = _StubInvoiceRepo([]);
      if (sl.isRegistered<InvoiceRepository>()) {
        sl.unregister<InvoiceRepository>();
      }
      sl.registerLazySingleton<InvoiceRepository>(() => stubRepo);

      final adminUser = UserModel(
        id: 'admin-1',
        email: 'admin@hotel.com',
        fullName: 'Quản trị viên',
        role: UserRole.admin,
      );
      final authBloc = _FakeAuthBloc(adminUser);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: CashierInvoicesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap chip to open modal
      await tester.tap(find.text('Tuần này'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select "Theo năm"
      await tester.tap(find.text('Theo năm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Áp Dụng Bộ Lọc"
      await tester.tap(find.text('Áp Dụng Bộ Lọc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(stubRepo.lastFilterType, 'year');
      expect(stubRepo.lastYear, DateTime.now().year);
      expect(find.text('Năm ${DateTime.now().year}'), findsOneWidget);
    });
  });
}

class _StubInvoiceRepo extends InvoiceRepository {
  List<InvoiceModel> stubInvoices;
  String? lastFilterType;
  int? lastYear;
  int? lastFromMonth;
  int? lastToMonth;
  int? lastWeekOffset;

  _StubInvoiceRepo(this.stubInvoices);

  @override
  Future<List<InvoiceModel>> fetchAll({
    String? status,
    String? search,
    String? filterType,
    int? year,
    int? fromMonth,
    int? toMonth,
    int? month,
    int? weekOffset,
    String? startDate,
    String? endDate,
  }) async {
    lastFilterType = filterType;
    lastYear = year;
    lastFromMonth = fromMonth;
    lastToMonth = toMonth;
    lastWeekOffset = weekOffset;
    return stubInvoices;
  }

  @override
  Future<Map<String, dynamic>> fetchSummary({DateTime? date}) async => {
    'todayRevenue': 0,
  };
}


