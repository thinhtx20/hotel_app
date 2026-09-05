import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/shared/models/checkout_preview_model.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/invoice_repository.dart';

/// DioClient giả lập ghi lại đường dẫn + payload để kiểm tra hợp đồng API của
/// sổ thu tiền (`payments[]`), yêu cầu thanh toán và check-out.
class _LedgerStubDioClient implements DioClient {
  final List<String> paths = [];
  final List<dynamic> bodies = [];
  final Map<String, dynamic> Function(RequestOptions options) responder;

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) => dio.options.baseUrl = newUrl;

  _LedgerStubDioClient(this.responder) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            bodies.add(options.data);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': responder(options)},
              ),
            );
          },
        ),
      );
  }
}

/// Một hóa đơn còn nợ, sổ thu tiền có đủ 4 loại bút toán.
Map<String, dynamic> _invoiceWithLedger() => {
      'id': 'inv-77',
      'invoiceCode': 'INV-2026-0077',
      'bookingId': 'bk-77',
      'roomNumber': '305',
      'customerName': 'Pham Thi Mai',
      'roomAmount': 4000000,
      'servicesAmount': 500000,
      'discount': 0,
      'tax': 450000,
      'finalAmount': 4950000,
      // Σ(PAYMENT + DEPOSIT đã xác nhận) − Σ(REFUND) = 1000000 + 2000000 - 200000
      'paidAmount': 2800000,
      'remainingAmount': 2150000,
      'paymentStatus': 'PARTIAL',
      'canRequestPayment': true,
      'payments': [
        {
          'id': 'pay-dep',
          'amount': 1000000,
          'type': 'DEPOSIT',
          'status': 'CONFIRMED',
          'paymentMethod': 'BANK_TRANSFER',
          'createdAt': '2026-09-01T09:00:00.000Z',
          'notes': 'Tiền cọc khi duyệt đơn',
        },
        {
          'id': 'pay-counter',
          'amount': 2000000,
          'type': 'PAYMENT',
          'status': 'CONFIRMED',
          'paymentMethod': 'CASH',
          'createdAt': '2026-09-03T10:00:00.000Z',
          'confirmedBy': {'fullName': 'Le Thu Ngan'},
        },
        {
          'id': 'pay-refund',
          'amount': 200000,
          'type': 'REFUND',
          'status': 'CONFIRMED',
          'paymentMethod': 'CASH',
          'createdAt': '2026-09-04T10:00:00.000Z',
        },
        {
          'id': 'pay-pending',
          'amount': 2150000,
          'type': 'PAYMENT',
          'status': 'PENDING',
          'paymentMethod': 'BANK_TRANSFER',
          'createdAt': '2026-09-05T08:00:00.000Z',
          'notes': 'Khách bấm thanh toán trên app',
        },
      ],
    };

void main() {
  group('Sổ thu tiền của hóa đơn', () {
    test('đọc thẳng remainingAmount và canRequestPayment của máy chủ', () {
      final invoice = InvoiceModel.fromJson(_invoiceWithLedger());

      expect(invoice.remainingAmount, 2150000);
      expect(invoice.canRequestPayment, isTrue);
    });

    test('remainingAmount của máy chủ thắng số FE tự trừ', () {
      // Máy chủ có thể trừ thêm khoản FE không biết; FE không được tự tính lại.
      final invoice = InvoiceModel.fromJson({
        ..._invoiceWithLedger(),
        'remainingAmount': 0,
        'paymentStatus': 'PAID',
      });

      expect(invoice.finalAmount - invoice.paidAmount, 2150000);
      expect(invoice.remainingAmount, 0);
    });

    test('vẫn tự suy ra khi phản hồi cũ chưa có remainingAmount', () {
      final json = _invoiceWithLedger()..remove('remainingAmount');
      final invoice = InvoiceModel.fromJson(json);

      expect(invoice.remainingAmount, 2150000);
    });

    test('tách được tiền cọc, tiền hoàn và dòng chờ đối chiếu', () {
      final invoice = InvoiceModel.fromJson(_invoiceWithLedger());

      expect(invoice.transactions.length, 4);
      expect(invoice.depositAmount, 1000000);
      expect(invoice.refundedAmount, 200000);
      expect(invoice.confirmedPayments.length, 3);

      final pending = invoice.pendingPaymentRequest;
      expect(pending, isNotNull);
      expect(pending!.id, 'pay-pending');
      expect(invoice.hasPendingPaymentRequest, isTrue);
      expect(invoice.pendingRequestedAmount, 2150000);
    });

    test('signedAmount khớp cách máy chủ tính lại paidAmount', () {
      final invoice = InvoiceModel.fromJson(_invoiceWithLedger());

      final recomputed = invoice.transactions.fold<num>(
        0,
        (sum, t) => sum + t.signedAmount,
      );

      // Dòng PENDING đóng góp 0, REFUND mang dấu âm.
      expect(recomputed, invoice.paidAmount);
    });

    test('dữ liệu cũ không có type/status coi như PAYMENT đã xác nhận', () {
      final txn = PaymentTransactionModel.fromJson({
        'id': 'legacy-1',
        'amount': 500000,
        'paymentMethod': 'CASH',
        'paidAt': '2026-08-30T10:00:00.000Z',
        'issuedBy': {'fullName': 'Nguyen Le Tan'},
      });

      expect(txn.type, PaymentEntryType.payment);
      expect(txn.status, PaymentEntryStatus.confirmed);
      expect(txn.isPending, isFalse);
      expect(txn.signedAmount, 500000);
      expect(txn.cashierName, 'Nguyen Le Tan');
    });

    test('sổ cũ ghi tiền hoàn bằng số âm vẫn nhận ra là REFUND', () {
      final txn = PaymentTransactionModel.fromJson({
        'id': 'legacy-refund',
        'amount': -300000,
        'paymentMethod': 'CASH',
      });

      expect(txn.isRefund, isTrue);
      expect(txn.signedAmount, -300000);
    });

    test('khách hết quyền bấm thanh toán khi đã treo một yêu cầu', () {
      final json = _invoiceWithLedger()..remove('canRequestPayment');
      final invoice = InvoiceModel.fromJson(json);

      // Mỗi hóa đơn chỉ treo được một yêu cầu tại một thời điểm.
      expect(invoice.canRequestPayment, isFalse);
    });
  });

  group('PaymentRequestModel', () {
    test('bóc được dạng lồng {payment, invoice}', () {
      final request = PaymentRequestModel.fromJson({
        'payment': {
          'id': 'pay-pending',
          'amount': 2150000,
          'type': 'PAYMENT',
          'status': 'PENDING',
          'paymentMethod': 'BANK_TRANSFER',
          'createdAt': '2026-09-05T08:00:00.000Z',
        },
        'invoice': {
          'id': 'inv-77',
          'invoiceCode': 'INV-2026-0077',
          'customerName': 'Pham Thi Mai',
          'roomNumber': '305',
          'finalAmount': 4950000,
          'paidAmount': 2800000,
          'remainingAmount': 2150000,
        },
      });

      expect(request.id, 'pay-pending');
      expect(request.invoiceId, 'inv-77');
      expect(request.displayCode, 'INV-2026-0077');
      expect(request.amount, 2150000);
      expect(request.remainingAmount, 2150000);
      expect(request.payment.isPending, isTrue);
    });

    test('bóc được dạng phẳng kèm invoiceId', () {
      final request = PaymentRequestModel.fromJson({
        'id': 'pay-9',
        'invoiceId': 'inv-9',
        'amount': 500000,
        'status': 'PENDING',
        'paymentMethod': 'CASH',
        'finalAmount': 900000,
        'paidAmount': 400000,
      });

      expect(request.invoiceId, 'inv-9');
      expect(request.remainingAmount, 500000);
    });
  });

  group('CheckoutPreviewModel', () {
    test('đọc amountDue và các yêu cầu chưa đối chiếu', () {
      final preview = CheckoutPreviewModel.fromJson({
        'bookingId': 'bk-77',
        'invoiceId': 'inv-77',
        'roomNumber': '305',
        'customerName': 'Pham Thi Mai',
        'roomAmount': 4000000,
        'servicesAmount': 500000,
        'discount': 0,
        'tax': 450000,
        'finalAmount': 4950000,
        'paidAmount': 2800000,
        'amountDue': 2150000,
        'items': [
          {'title': 'Tiền phòng 305', 'quantity': 2, 'unitPrice': 2000000},
        ],
        'payments': [
          {
            'id': 'pay-pending',
            'amount': 2150000,
            'status': 'PENDING',
            'paymentMethod': 'BANK_TRANSFER',
          },
        ],
      });

      expect(preview.amountDue, 2150000);
      expect(preview.items.length, 1);
      expect(preview.hasPendingPaymentRequests, isTrue);
      expect(preview.pendingRequestedAmount, 2150000);
    });

    test('dùng mảng pendingPaymentRequests riêng khi máy chủ gửi kèm', () {
      final preview = CheckoutPreviewModel.fromJson({
        'finalAmount': 1000000,
        'paidAmount': 200000,
        'amountDue': 800000,
        'payments': const [],
        'pendingPaymentRequests': [
          {
            'id': 'pay-x',
            'amount': 800000,
            'status': 'PENDING',
            'paymentMethod': 'BANK_TRANSFER',
          },
        ],
      });

      expect(preview.pendingPaymentRequests.length, 1);
      expect(preview.pendingRequestedAmount, 800000);
    });
  });

  group('Hợp đồng API sổ thu tiền', () {
    test('đường dẫn khớp backend', () {
      expect(
        ApiEndpoints.invoicePaymentRequest('inv-77'),
        '/invoices/inv-77/payment-requests',
      );
      expect(ApiEndpoints.invoicePaymentRequests, '/invoices/payment-requests');
      expect(
        ApiEndpoints.confirmInvoicePayment('pay-1'),
        '/invoices/payments/pay-1/confirm',
      );
      expect(
        ApiEndpoints.checkOutPreview('bk-77'),
        '/bookings/bk-77/checkout-preview',
      );
    });

    test('bỏ trống amount = trả toàn bộ số còn lại', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'payment': {
            'id': 'pay-new',
            'amount': 2150000,
            'status': 'PENDING',
            'paymentMethod': 'BANK_TRANSFER',
          },
        },
      );
      final repo = InvoiceRepository(dioClient: stub);

      final request = await repo.createPaymentRequest('inv-77');

      expect(stub.paths.single, '/invoices/inv-77/payment-requests');
      // Không gửi `amount` để máy chủ tự lấy đúng remainingAmount.
      expect((stub.bodies.single as Map).containsKey('amount'), isFalse);
      expect((stub.bodies.single as Map)['paymentMethod'], 'BANK_TRANSFER');
      expect(request.invoiceId, 'inv-77');
      expect(request.amount, 2150000);
    });

    test('gửi amount khi khách trả một phần', () async {
      final stub = _LedgerStubDioClient(
        (_) => {'id': 'pay-new', 'amount': 500000, 'status': 'PENDING'},
      );
      final repo = InvoiceRepository(dioClient: stub);

      await repo.createPaymentRequest('inv-77', amount: 500000);

      expect((stub.bodies.single as Map)['amount'], 500000);
      expect((stub.bodies.single as Map)['paymentMethod'], 'BANK_TRANSFER');
    });

    test('confirm trả về hóa đơn đã cập nhật', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'invoice': {
            ..._invoiceWithLedger(),
            'paidAmount': 4950000,
            'remainingAmount': 0,
            'paymentStatus': 'PAID',
          },
        },
      );
      final repo = InvoiceRepository(dioClient: stub);

      final invoice = await repo.confirmPayment('pay-pending');

      expect(stub.paths.single, '/invoices/payments/pay-pending/confirm');
      expect(invoice.remainingAmount, 0);
      expect(invoice.paymentStatus, 'PAID');
    });

    test('danh sách yêu cầu chờ đối chiếu bóc từ mảng data', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'data': [
            {
              'payment': {
                'id': 'pay-a',
                'amount': 100000,
                'status': 'PENDING',
                'paymentMethod': 'CASH',
              },
              'invoice': {'id': 'inv-a', 'invoiceCode': 'INV-A'},
            },
          ],
          'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
        },
      );
      final repo = InvoiceRepository(dioClient: stub);

      final requests = await repo.fetchPaymentRequests();

      expect(stub.paths.single, '/invoices/payment-requests');
      expect(requests.length, 1);
      expect(requests.single.invoiceId, 'inv-a');
    });
  });

  group('Check-out', () {
    test('bỏ trống amountCollected thì không gửi trường này', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'booking': {
            'id': 'bk-77',
            'status': 'CHECKED_OUT',
            'checkInDate': '2026-09-03T14:00:00.000Z',
            'checkOutDate': '2026-09-05T12:00:00.000Z',
          },
          'invoice': _invoiceWithLedger(),
        },
      );
      final repo = BookingRepository(dioClient: stub);

      final (_, invoice) = await repo.checkOut('bk-77');

      expect((stub.bodies.single as Map).containsKey('amountCollected'), isFalse);
      // Khách vẫn trả phòng được dù hóa đơn còn nợ.
      expect(invoice.remainingAmount, 2150000);
      expect(invoice.canRequestPayment, isTrue);
    });

    test('gửi amountCollected đúng số thu ngân thực nhận', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'booking': {
            'id': 'bk-77',
            'status': 'CHECKED_OUT',
            'checkInDate': '2026-09-03T14:00:00.000Z',
            'checkOutDate': '2026-09-05T12:00:00.000Z',
          },
          'invoice': _invoiceWithLedger(),
        },
      );
      final repo = BookingRepository(dioClient: stub);

      await repo.checkOut('bk-77', amountCollected: 1000000, discount: 50000);

      final body = stub.bodies.single as Map;
      expect(body['amountCollected'], 1000000);
      expect(body['discount'], 50000);
    });

    test('checkout-preview là GET chỉ đọc', () async {
      final stub = _LedgerStubDioClient(
        (_) => {
          'finalAmount': 4950000,
          'paidAmount': 2800000,
          'amountDue': 2150000,
        },
      );
      final repo = BookingRepository(dioClient: stub);

      final preview = await repo.fetchCheckOutPreview('bk-77');

      expect(stub.paths.single, '/bookings/bk-77/checkout-preview');
      expect(preview.amountDue, 2150000);
    });
  });
}
