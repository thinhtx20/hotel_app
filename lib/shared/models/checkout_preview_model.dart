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
  final num taxRate;
  final num finalAmount;
  final num paidAmount;

  /// Số còn phải thu do backend tính — FE không tự trừ.
  final num amountDue;

  /// Số tiền khách sạn cần hoàn trả cho khách khi trả phòng trước hạn và đã thu dư.
  final num refundDue;

  /// Cờ nhận diện lượt trả phòng là trước hạn (Early Check-Out).
  final bool isEarlyCheckOut;

  /// Số đêm đặt ban đầu theo hợp đồng.
  final int bookedNights;

  /// Số đêm lưu trú thực tế.
  final int actualNights;

  /// Đơn giá phòng 1 đêm.
  final num basePrice;

  /// Tiền phòng ban đầu theo đơn đặt.
  final num originalRoomAmount;

  /// Tiền phòng tính lại theo số đêm thực tế.
  final num recalculatedRoomAmount;

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
    this.taxRate = 0.1,
    this.finalAmount = 0,
    this.paidAmount = 0,
    this.amountDue = 0,
    this.refundDue = 0,
    this.isEarlyCheckOut = false,
    this.bookedNights = 1,
    this.actualNights = 1,
    this.basePrice = 0,
    this.originalRoomAmount = 0,
    this.recalculatedRoomAmount = 0,
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
        (json[key] as num?) ??
        (invoice[key] as num?) ??
        (booking[key] as num?) ??
        fallback;

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
    final paidAmount = pickNum(
      'paidAmount',
      fallback: pickNum(
        'alreadyPaidAmount',
        fallback: pickNum('depositAmount'),
      ),
    );
    final taxRate = (json['taxRate'] as num?) ??
        (invoice['taxRate'] as num?) ??
        0.1;
    final amountDue = (json['amountDue'] as num?) ??
        (json['remainingAmount'] as num?) ??
        (invoice['remainingAmount'] as num?) ??
        (finalAmount - paidAmount).clamp(0, double.infinity);
    final refundDue = (json['refundDue'] as num?) ??
        (paidAmount > finalAmount ? (paidAmount - finalAmount) : 0);
    final isEarlyCheckOut = (json['isEarlyCheckOut'] as bool?) ?? false;
    final bookedNights = (json['bookedNights'] as num?)?.toInt() ?? 1;
    final actualNights = (json['actualNights'] as num?)?.toInt() ?? 1;
    final basePrice = pickNum('basePrice');
    final originalRoomAmount =
        pickNum('originalRoomAmount', fallback: pickNum('roomAmount'));
    final recalculatedRoomAmount =
        pickNum('recalculatedRoomAmount', fallback: pickNum('roomAmount'));

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
      taxRate: taxRate,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      amountDue: amountDue,
      refundDue: refundDue,
      isEarlyCheckOut: isEarlyCheckOut,
      bookedNights: bookedNights,
      actualNights: actualNights,
      basePrice: basePrice,
      originalRoomAmount: originalRoomAmount,
      recalculatedRoomAmount: recalculatedRoomAmount,
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
