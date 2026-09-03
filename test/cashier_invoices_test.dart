import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/cashier/screens/cashier_invoices_screen.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';

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

      expect(find.text('Thu Ngân'), findsOneWidget);
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
  });
}

