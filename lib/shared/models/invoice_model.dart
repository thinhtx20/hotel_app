class InvoiceItemModel {
  final String title;
  final int quantity;
  final num unitPrice;
  final num totalAmount;
  final String? category; // 'ROOM', 'MINIBAR', 'LAUNDRY', 'DINING', 'SURCHARGE'

  InvoiceItemModel({
    required this.title,
    this.quantity = 1,
    required this.unitPrice,
    num? totalAmount,
    this.category,
  }) : totalAmount = totalAmount ?? (quantity * unitPrice);

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      title: json['title'] ?? json['name'] ?? 'Khoản mục',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 1,
      unitPrice: json['unitPrice'] ?? json['price'] ?? 0,
      totalAmount: json['totalAmount'] ?? json['amount'],
      category: json['category']?.toString(),
    );
  }
}

/// Loại bút toán trong sổ thu tiền (`payments[]`).
///
/// Backend không cộng/trừ `paidAmount` thủ công nữa mà luôn tính lại bằng
/// `Σ(PAYMENT + DEPOSIT đã xác nhận) − Σ(REFUND)`. Tiền cọc, tiền khách trả
/// qua app, tiền thu tại quầy và tiền hoàn nằm chung một sổ.
abstract final class PaymentEntryType {
  static const String payment = 'PAYMENT';
  static const String deposit = 'DEPOSIT';
  static const String refund = 'REFUND';
}

/// Trạng thái một dòng trong sổ thu tiền.
abstract final class PaymentEntryStatus {
  /// Khách đã gửi yêu cầu qua app, tiền chưa vào két — chưa tính vào
  /// `paidAmount` cho tới khi lễ tân đối chiếu sao kê và xác nhận.
  static const String pending = 'PENDING';
  static const String confirmed = 'CONFIRMED';
  static const String rejected = 'REJECTED';
  static const String cancelled = 'CANCELLED';
}

/// Một dòng của sổ thu tiền — đây là lịch sử thật, không phải một dòng dựng
/// lại từ số tổng.
class PaymentTransactionModel {
  final String id;
  final num amount;
  final String paymentMethod; // 'CASH', 'BANK_TRANSFER', 'CREDIT_CARD'

  /// `PAYMENT` | `DEPOSIT` | `REFUND`.
  final String type;

  /// `PENDING` | `CONFIRMED` | `REJECTED` | `CANCELLED`.
  ///
  /// Dữ liệu cũ và các dòng thu tại quầy không kèm trường này — coi như đã
  /// xác nhận, đúng như cách backend quy đổi dữ liệu cũ lúc khởi động.
  final String status;

  final DateTime timestamp;
  final DateTime? confirmedAt;
  final String? cashierName;
  final String? notes;

  PaymentTransactionModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    this.type = PaymentEntryType.payment,
    this.status = PaymentEntryStatus.confirmed,
    this.confirmedAt,
    this.cashierName,
    this.notes,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['timestamp'] ?? json['createdAt'] ?? json['paidAt'];
    final confirmedStr = json['confirmedAt'];
    final rawAmount = (json['amount'] as num?) ?? 0;

    // Sổ cũ ghi tiền hoàn bằng số âm và không có `type`.
    final rawType = json['type']?.toString().toUpperCase();
    final type = rawType != null && rawType.isNotEmpty
        ? rawType
        : (rawAmount < 0 ? PaymentEntryType.refund : PaymentEntryType.payment);

    final rawStatus = json['status']?.toString().toUpperCase();

    return PaymentTransactionModel(
      id: json['id']?.toString() ??
          'TXN-${DateTime.now().millisecondsSinceEpoch}',
      amount: rawAmount,
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      type: type,
      status: rawStatus != null && rawStatus.isNotEmpty
          ? rawStatus
          : PaymentEntryStatus.confirmed,
      timestamp: dateStr != null
          ? DateTime.tryParse(dateStr.toString()) ?? DateTime.now()
          : DateTime.now(),
      confirmedAt: confirmedStr != null
          ? DateTime.tryParse(confirmedStr.toString())
          : null,
      cashierName: json['cashierName']?.toString() ??
          json['confirmedBy']?['fullName']?.toString() ??
          json['issuedBy']?['fullName']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  bool get isPending => status == PaymentEntryStatus.pending;
  bool get isConfirmed => status == PaymentEntryStatus.confirmed;
  bool get isRefund => type == PaymentEntryType.refund;
  bool get isDeposit => type == PaymentEntryType.deposit;

  /// Phần đóng góp của dòng này vào `paidAmount`: hoàn tiền mang dấu âm, dòng
  /// chờ đối chiếu chưa tính đồng nào.
  num get signedAmount {
    if (!isConfirmed) return 0;
    return isRefund ? -amount.abs() : amount.abs();
  }

  /// Nhãn tiếng Việt của loại bút toán.
  String get typeLabel {
    switch (type) {
      case PaymentEntryType.deposit:
        return 'Tiền cọc';
      case PaymentEntryType.refund:
        return 'Hoàn tiền';
      default:
        return 'Thanh toán';
    }
  }
}

/// Một yêu cầu thanh toán khách gửi qua app, chờ lễ tân đối chiếu sao kê
/// (`GET /invoices/payment-requests`).
///
/// Bản chất vẫn là một dòng `PENDING` của sổ thu tiền, kèm thông tin hóa đơn
/// để lễ tân đối chiếu mà không phải mở từng hóa đơn.
class PaymentRequestModel {
  final PaymentTransactionModel payment;
  final String invoiceId;
  final String? invoiceCode;
  final String? bookingId;
  final String? customerName;
  final String? roomNumber;
  final num finalAmount;
  final num paidAmount;
  final num remainingAmount;

  const PaymentRequestModel({
    required this.payment,
    required this.invoiceId,
    this.invoiceCode,
    this.bookingId,
    this.customerName,
    this.roomNumber,
    this.finalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    // Tùy endpoint, dòng thanh toán có thể nằm ở gốc hoặc trong `payment`.
    final rawPayment = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : json;
    final invoice = json['invoice'] is Map
        ? Map<String, dynamic>.from(json['invoice'] as Map)
        : const <String, dynamic>{};

    num pick(String key, {num fallback = 0}) =>
        (json[key] as num?) ?? (invoice[key] as num?) ?? fallback;

    String? pickStr(String key) =>
        json[key]?.toString() ?? invoice[key]?.toString();

    final finalAmount = pick('finalAmount');
    final paidAmount = pick('paidAmount');
    final remaining = (json['remainingAmount'] as num?) ??
        (invoice['remainingAmount'] as num?) ??
        (finalAmount - paidAmount).clamp(0, double.infinity);

    return PaymentRequestModel(
      payment: PaymentTransactionModel.fromJson(rawPayment),
      invoiceId: json['invoiceId']?.toString() ??
          invoice['id']?.toString() ??
          rawPayment['invoiceId']?.toString() ??
          '',
      invoiceCode: pickStr('invoiceCode'),
      bookingId: pickStr('bookingId') ?? invoice['booking']?['id']?.toString(),
      customerName: pickStr('customerName') ??
          invoice['customer']?['fullName']?.toString() ??
          invoice['booking']?['customer']?['fullName']?.toString(),
      roomNumber: pickStr('roomNumber') ??
          invoice['booking']?['room']?['roomNumber']?.toString(),
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      remainingAmount: remaining,
    );
  }

  String get id => payment.id;
  num get amount => payment.amount;
  DateTime get requestedAt => payment.timestamp;

  String get displayCode {
    final code = invoiceCode;
    if (code != null && code.isNotEmpty) {
      return code.startsWith('#') ? code.substring(1) : code;
    }
    if (invoiceId.startsWith('INV-')) return invoiceId;
    return invoiceId.length > 8
        ? invoiceId.substring(0, 8).toUpperCase()
        : invoiceId;
  }
}

class InvoiceModel {
  final String id;
  final String? invoiceCode;
  final String? bookingId;
  final String? roomNumber;
  final String? customerName;
  final num roomAmount;
  final num servicesAmount;
  final num discount;
  final num tax;
  final num finalAmount;
  final num paidAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? createdAt;
  final List<InvoiceItemModel> items;

  /// Sổ thu tiền của hóa đơn (`payments[]`) — gồm cả tiền cọc, tiền khách trả
  /// qua app đang chờ đối chiếu và tiền hoàn.
  final List<PaymentTransactionModel> transactions;
  final String? notes;

  /// `remainingAmount` do backend trả về. FE đọc thẳng số này thay vì tự tính;
  /// chỉ suy ra tại chỗ khi phản hồi cũ chưa có trường này.
  final num? rawRemainingAmount;

  /// `canRequestPayment` do backend trả về ở `GET /invoices/my`.
  final bool? rawCanRequestPayment;

  InvoiceModel({
    required this.id,
    this.invoiceCode,
    this.bookingId,
    this.roomNumber,
    this.customerName,
    required this.roomAmount,
    required this.servicesAmount,
    required this.discount,
    required this.tax,
    required this.finalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.createdAt,
    List<InvoiceItemModel>? items,
    List<PaymentTransactionModel>? transactions,
    this.notes,
    this.rawRemainingAmount,
    this.rawCanRequestPayment,
  })  : items = items ?? const [],
        transactions = transactions ?? const [];

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final parsedItems = (json['items'] as List?)
        ?.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawPayments = json['payments'] as List? ?? json['transactions'] as List?;
    final parsedTxns = rawPayments
        ?.map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceCode: json['invoiceCode']?.toString(),
      bookingId: json['bookingId']?.toString() ?? json['booking']?['id']?.toString(),
      roomNumber: json['roomNumber']?.toString() ?? json['booking']?['room']?['roomNumber']?.toString(),
      customerName: json['customerName']?.toString() ?? json['booking']?['customer']?['fullName']?.toString(),
      roomAmount: json['roomAmount'] ?? 0,
      servicesAmount: json['servicesAmount'] ?? 0,
      discount: json['discount'] ?? 0,
      tax: json['tax'] ?? 0,
      finalAmount: json['finalAmount'] ?? 0,
      paidAmount: json['paidAmount'] ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null),
      items: parsedItems,
      transactions: parsedTxns,
      notes: json['notes']?.toString(),
      rawRemainingAmount: json['remainingAmount'] as num?,
      rawCanRequestPayment: json['canRequestPayment'] as bool?,
    );
  }

  String get displayCode {
    if (invoiceCode != null && invoiceCode!.isNotEmpty) {
      return invoiceCode!.startsWith('#') ? invoiceCode!.substring(1) : invoiceCode!;
    }
    if (id.startsWith('INV-')) return id;
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
  }

  /// Số còn phải thu — ưu tiên số backend trả về.
  num get remainingAmount =>
      rawRemainingAmount ?? (finalAmount - paidAmount).clamp(0, double.infinity);

  /// Các dòng đã vào két (đã cộng vào `paidAmount`).
  List<PaymentTransactionModel> get confirmedPayments =>
      transactions.where((t) => t.isConfirmed).toList();

  /// Yêu cầu khách gửi qua app đang chờ lễ tân đối chiếu. Mỗi hóa đơn chỉ treo
  /// được một yêu cầu nên chỉ lấy dòng đầu tiên.
  PaymentTransactionModel? get pendingPaymentRequest {
    for (final txn in transactions) {
      if (txn.isPending) return txn;
    }
    return null;
  }

  bool get hasPendingPaymentRequest => pendingPaymentRequest != null;

  num get pendingRequestedAmount => pendingPaymentRequest?.amount ?? 0;

  /// Tổng tiền cọc đã xác nhận — nay là bút toán `DEPOSIT` trong sổ, không còn
  /// cộng thẳng vào `paidAmount` ở bước duyệt đơn.
  num get depositAmount => transactions
      .where((t) => t.isDeposit && t.isConfirmed)
      .fold<num>(0, (sum, t) => sum + t.amount.abs());

  /// Tổng tiền đã hoàn.
  num get refundedAmount => transactions
      .where((t) => t.isRefund && t.isConfirmed)
      .fold<num>(0, (sum, t) => sum + t.amount.abs());

  /// Khách có được bấm "Thanh toán" trên app hay không — ưu tiên cờ backend.
  bool get canRequestPayment =>
      rawCanRequestPayment ?? (remainingAmount > 0 && !hasPendingPaymentRequest);

  InvoiceModel copyWith({
    String? id,
    String? invoiceCode,
    String? bookingId,
    String? roomNumber,
    String? customerName,
    num? roomAmount,
    num? servicesAmount,
    num? discount,
    num? tax,
    num? finalAmount,
    num? paidAmount,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? createdAt,
    List<InvoiceItemModel>? items,
    List<PaymentTransactionModel>? transactions,
    String? notes,
    num? rawRemainingAmount,
    bool? rawCanRequestPayment,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceCode: invoiceCode ?? this.invoiceCode,
      bookingId: bookingId ?? this.bookingId,
      roomNumber: roomNumber ?? this.roomNumber,
      customerName: customerName ?? this.customerName,
      roomAmount: roomAmount ?? this.roomAmount,
      servicesAmount: servicesAmount ?? this.servicesAmount,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      finalAmount: finalAmount ?? this.finalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      transactions: transactions ?? this.transactions,
      notes: notes ?? this.notes,
      rawRemainingAmount: rawRemainingAmount ?? this.rawRemainingAmount,
      rawCanRequestPayment: rawCanRequestPayment ?? this.rawCanRequestPayment,
    );
  }
}
