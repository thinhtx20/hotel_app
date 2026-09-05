import 'invoice_model.dart';

/// Bảng kê trước khi trả phòng: `GET /bookings/:id/checkout-preview`.
///
/// Chỉ đọc — gọi bao nhiêu lần cũng không đổi trạng thái đơn hay phòng. Thu
/// ngân dựa vào [amountDue] để biết còn phải thu bao nhiêu, và dựa vào
/// [pendingPaymentRequests] để không thu trùng phần khách đã chuyển qua app
/// nhưng chưa ai đối chiếu sao kê.
class CheckoutPreviewModel {
  final String? bookingId;
  final String? bookingCode;
  final String? invoiceId;
  final String? roomNumber;
  final String? customerName;

  final num roomAmount;
  final num servicesAmount;
  final num discount;
  final num tax;
  final num finalAmount;
  final num paidAmount;

  /// Số còn phải thu do backend tính — FE không tự trừ.
  final num amountDue;

  final String? paymentStatus;
  final List<InvoiceItemModel> items;

  /// Sổ thu tiền đã ghi nhận (tiền cọc, tiền đã thu, tiền hoàn).
  final List<PaymentTransactionModel> payments;

  /// Yêu cầu khách gửi qua app còn treo, chưa đối chiếu.
  final List<PaymentTransactionModel> pendingPaymentRequests;

  const CheckoutPreviewModel({
    this.bookingId,
    this.bookingCode,
    this.invoiceId,
    this.roomNumber,
    this.customerName,
    this.roomAmount = 0,
    this.servicesAmount = 0,
    this.discount = 0,
    this.tax = 0,
    this.finalAmount = 0,
    this.paidAmount = 0,
    this.amountDue = 0,
    this.paymentStatus,
    this.items = const [],
    this.payments = const [],
    this.pendingPaymentRequests = const [],
  });

  factory CheckoutPreviewModel.fromJson(Map<String, dynamic> json) {
    // Backend có thể lồng bảng kê trong `invoice` hoặc trả phẳng ở gốc.
    final invoice = json['invoice'] is Map
        ? Map<String, dynamic>.from(json['invoice'] as Map)
        : const <String, dynamic>{};
    final booking = json['booking'] is Map
        ? Map<String, dynamic>.from(json['booking'] as Map)
        : const <String, dynamic>{};

    num pickNum(String key, {num fallback = 0}) =>
        (json[key] as num?) ?? (invoice[key] as num?) ?? fallback;

    String? pickStr(String key) =>
        json[key]?.toString() ?? invoice[key]?.toString() ?? booking[key]?.toString();

    List<PaymentTransactionModel> parsePayments(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) =>
              PaymentTransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawItems = json['items'] as List? ?? invoice['items'] as List?;
    final allPayments = parsePayments(
      json['payments'] ?? invoice['payments'],
    );

    // Danh sách yêu cầu chờ đối chiếu: dùng mảng riêng nếu backend gửi kèm,
    // nếu không thì lọc từ chính sổ thu tiền.
    final explicitPending = parsePayments(
      json['pendingPaymentRequests'] ??
          json['pendingPayments'] ??
          json['paymentRequests'],
    );

    final finalAmount = pickNum('finalAmount');
    final paidAmount = pickNum('paidAmount');
    final amountDue = (json['amountDue'] as num?) ??
        (json['remainingAmount'] as num?) ??
        (invoice['remainingAmount'] as num?) ??
        (finalAmount - paidAmount).clamp(0, double.infinity);

    return CheckoutPreviewModel(
      bookingId: json['bookingId']?.toString() ?? booking['id']?.toString(),
      bookingCode:
          json['bookingCode']?.toString() ?? booking['bookingCode']?.toString(),
      invoiceId: json['invoiceId']?.toString() ?? invoice['id']?.toString(),
      roomNumber: pickStr('roomNumber') ??
          booking['room']?['roomNumber']?.toString(),
      customerName: pickStr('customerName') ??
          booking['customer']?['fullName']?.toString(),
      roomAmount: pickNum('roomAmount'),
      servicesAmount: pickNum('servicesAmount'),
      discount: pickNum('discount'),
      tax: pickNum('tax'),
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      amountDue: amountDue,
      paymentStatus: pickStr('paymentStatus'),
      items: rawItems
              ?.whereType<Map>()
              .map((e) => InvoiceItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      payments: allPayments,
      pendingPaymentRequests: explicitPending.isNotEmpty
          ? explicitPending
          : allPayments.where((p) => p.isPending).toList(),
    );
  }

  /// Tổng tiền khách đã bấm trả qua app nhưng chưa ai đối chiếu.
  num get pendingRequestedAmount => pendingPaymentRequests.fold<num>(
        0,
        (sum, p) => sum + p.amount.abs(),
      );

  bool get hasPendingPaymentRequests => pendingPaymentRequests.isNotEmpty;
}
