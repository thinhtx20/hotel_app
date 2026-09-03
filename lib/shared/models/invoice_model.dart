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

class PaymentTransactionModel {
  final String id;
  final num amount;
  final String paymentMethod; // 'CASH', 'BANK_TRANSFER', 'CREDIT_CARD'
  final DateTime timestamp;
  final String? cashierName;
  final String? notes;

  PaymentTransactionModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
    this.cashierName,
    this.notes,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      cashierName: json['cashierName'],
      notes: json['notes'],
    );
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
  final List<PaymentTransactionModel> transactions;
  final String? notes;

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
  })  : items = items ?? _generateDefaultItems(roomAmount, servicesAmount),
        transactions = transactions ??
            _generateDefaultTransactions(paidAmount, paymentMethod, createdAt);

  static List<InvoiceItemModel> _generateDefaultItems(num room, num services) {
    final list = <InvoiceItemModel>[];
    if (room > 0) {
      list.add(InvoiceItemModel(
        title: 'Tiền phòng lưu trú',
        quantity: 1,
        unitPrice: room,
        category: 'ROOM',
      ));
    }
    if (services > 0) {
      list.add(InvoiceItemModel(
        title: 'Dịch vụ minibar & tiện ích phòng',
        quantity: 1,
        unitPrice: services,
        category: 'MINIBAR',
      ));
    }
    if (list.isEmpty) {
      list.add(InvoiceItemModel(
        title: 'Khoản thu dịch vụ',
        quantity: 1,
        unitPrice: 0,
      ));
    }
    return list;
  }

  static List<PaymentTransactionModel> _generateDefaultTransactions(
      num paid, String? method, DateTime? date) {
    if (paid <= 0) return [];
    return [
      PaymentTransactionModel(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        amount: paid,
        paymentMethod: method ?? 'BANK_TRANSFER',
        timestamp: date ?? DateTime.now(),
        cashierName: 'Thu ngân ca trực',
        notes: 'Thanh toán đợt 1 / Đặt cọc',
      ),
    ];
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final parsedItems = (json['items'] as List?)
        ?.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final parsedTxns = (json['transactions'] as List?)
        ?.map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceCode: json['invoiceCode'],
      bookingId: json['bookingId'] ?? json['booking']?['id'],
      roomNumber: json['booking']?['room']?['roomNumber'] ?? json['roomNumber'],
      customerName: json['booking']?['customer']?['fullName'] ?? json['customerName'],
      roomAmount: json['roomAmount'] ?? 0,
      servicesAmount: json['servicesAmount'] ?? 0,
      discount: json['discount'] ?? 0,
      tax: json['tax'] ?? 0,
      finalAmount: json['finalAmount'] ?? 0,
      paidAmount: json['paidAmount'] ?? 0,
      paymentStatus: json['paymentStatus'] ?? 'UNPAID',
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      items: parsedItems,
      transactions: parsedTxns,
      notes: json['notes'],
    );
  }

  String get displayCode {
    if (invoiceCode != null && invoiceCode!.isNotEmpty) {
      return invoiceCode!.startsWith('#') ? invoiceCode!.substring(1) : invoiceCode!;
    }
    if (id.startsWith('INV-')) return id;
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
  }

  num get remainingAmount => (finalAmount - paidAmount).clamp(0, double.infinity);

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
    );
  }
}


