import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/cashier/bloc/invoice_bloc.dart';
import 'package:hotel_app/features/cashier/bloc/invoice_event.dart';
import 'package:hotel_app/features/cashier/bloc/invoice_state.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';
import 'package:hotel_app/shared/repositories/invoice_repository.dart';

class _MockInvoiceRepository extends InvoiceRepository {
  final List<InvoiceModel> mockInvoices;
  String? lastFilterType;
  int? lastYear;
  int? lastFromMonth;
  int? lastToMonth;

  _MockInvoiceRepository(this.mockInvoices);

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
    int? page,
    int? limit,
  }) async {
    lastFilterType = filterType;
    lastYear = year;
    lastFromMonth = fromMonth;
    lastToMonth = toMonth;
    return mockInvoices;
  }

  @override
  Future<Map<String, dynamic>> fetchSummary({DateTime? date}) async {
    return {'todayRevenue': 5000000};
  }
}

void main() {
  group('InvoiceBloc Tests', () {
    late _MockInvoiceRepository mockRepo;
    late InvoiceBloc invoiceBloc;

    final sampleInvoices = [
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
        roomNumber: '101',
        customerName: 'Khách A',
      ),
      InvoiceModel(
        id: 'inv-2',
        invoiceCode: 'INV-002',
        roomAmount: 2000000,
        servicesAmount: 0,
        discount: 0,
        tax: 0,
        finalAmount: 2000000,
        paidAmount: 1000000,
        paymentStatus: 'PARTIAL',
        roomNumber: '102',
        customerName: 'Khách B',
      ),
      InvoiceModel(
        id: 'inv-3',
        invoiceCode: 'INV-003',
        roomAmount: 3000000,
        servicesAmount: 0,
        discount: 0,
        tax: 0,
        finalAmount: 3000000,
        paidAmount: 3000000,
        paymentStatus: 'PAID',
        roomNumber: '103',
        customerName: 'Khách C',
      ),
    ];

    setUp(() {
      mockRepo = _MockInvoiceRepository(sampleInvoices);
      invoiceBloc = InvoiceBloc(invoiceRepository: mockRepo);
    });

    tearDown(() {
      invoiceBloc.close();
    });

    test('initial state has default values', () {
      expect(invoiceBloc.state.status, InvoiceStatus.initial);
      expect(invoiceBloc.state.invoices, isEmpty);
      expect(invoiceBloc.state.selectedTabIndex, 0);
    });

    test('InvoiceFetchRequested emits loading then success with calculated today revenue', () async {
      invoiceBloc.add(const InvoiceFetchRequested());

      await expectLater(
        invoiceBloc.stream,
        emitsInOrder([
          predicate<InvoiceState>((s) => s.status == InvoiceStatus.loading),
          predicate<InvoiceState>((s) =>
              s.status == InvoiceStatus.success &&
              s.invoices.length == 3 &&
              s.todayRevenue == 5000000),
        ]),
      );
    });

    test('InvoiceTabFilterChanged updates selectedTabIndex', () async {
      invoiceBloc.add(const InvoiceFetchRequested());
      await invoiceBloc.stream.firstWhere((s) => s.status == InvoiceStatus.success);

      invoiceBloc.add(const InvoiceTabFilterChanged(1));
      await expectLater(
        invoiceBloc.stream,
        emits(predicate<InvoiceState>((s) =>
            s.selectedTabIndex == 1 &&
            s.filteredInvoices.length == 1 &&
            s.filteredInvoices.first.id == 'inv-2')),
      );
    });

    test('InvoiceSearchChanged filters invoices by code, guest name, or room', () async {
      invoiceBloc.add(const InvoiceFetchRequested());
      await invoiceBloc.stream.firstWhere((s) => s.status == InvoiceStatus.success);

      invoiceBloc.add(const InvoiceTabFilterChanged(3)); // Tất cả
      await invoiceBloc.stream.firstWhere((s) => s.selectedTabIndex == 3);

      invoiceBloc.add(const InvoiceSearchChanged('103'));
      await expectLater(
        invoiceBloc.stream,
        emits(predicate<InvoiceState>((s) =>
            s.searchQuery == '103' &&
            s.filteredInvoices.length == 1 &&
            s.filteredInvoices.first.roomNumber == '103')),
      );
    });

    test('InvoiceCreated prepends new invoice and switches to tab 0', () async {
      invoiceBloc.add(const InvoiceFetchRequested());
      await invoiceBloc.stream.firstWhere((s) => s.status == InvoiceStatus.success);

      final newInv = InvoiceModel(
        id: 'inv-new',
        invoiceCode: 'INV-NEW',
        roomAmount: 500000,
        servicesAmount: 0,
        discount: 0,
        tax: 0,
        finalAmount: 500000,
        paidAmount: 0,
        paymentStatus: 'UNPAID',
      );

      invoiceBloc.add(InvoiceCreated(newInv));
      await expectLater(
        invoiceBloc.stream,
        emits(predicate<InvoiceState>((s) =>
            s.invoices.first.id == 'inv-new' &&
            s.selectedTabIndex == 0)),
      );
    });

    test('InvoicePaymentRecorded updates invoice and todayRevenue', () async {
      invoiceBloc.add(const InvoiceFetchRequested());
      await invoiceBloc.stream.firstWhere((s) => s.status == InvoiceStatus.success);

      final updatedInv = sampleInvoices[0].copyWith(
        paidAmount: 1000000,
        paymentStatus: 'PAID',
      );

      invoiceBloc.add(InvoicePaymentRecorded(
        invoiceId: 'inv-1',
        updatedInvoice: updatedInv,
        amount: 1000000,
      ));

      await expectLater(
        invoiceBloc.stream,
        emits(predicate<InvoiceState>((s) =>
            s.invoices.firstWhere((i) => i.id == 'inv-1').paymentStatus == 'PAID' &&
            s.todayRevenue == 6000000)),
      );
    });
  });
}
