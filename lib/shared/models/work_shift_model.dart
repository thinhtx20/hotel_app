import 'package:flutter/material.dart';

/// Loại ca trực tại quầy
enum ShiftType {
  morning('MORNING', 'Ca Sáng (06:00 - 14:00)', Icons.wb_sunny_rounded, Color(0xFFF59E0B)),
  afternoon('AFTERNOON', 'Ca Chiều (14:00 - 22:00)', Icons.wb_twilight_rounded, Color(0xFF3B82F6)),
  night('NIGHT', 'Ca Đêm (22:00 - 06:00)', Icons.nights_stay_rounded, Color(0xFF6366F1)),
  custom('CUSTOM', 'Ca Linh Hoạt', Icons.access_time_filled_rounded, Color(0xFF10B981));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ShiftType(this.value, this.label, this.icon, this.color);

  static ShiftType fromString(String? val) {
    if (val == null) return ShiftType.morning;
    final upper = val.toUpperCase();
    for (final t in ShiftType.values) {
      if (t.value == upper) return t;
    }
    return ShiftType.morning;
  }
}

/// Trạng thái ca trực
enum ShiftStatus {
  open('OPEN', 'Đang trực', Color(0xFF10B981)),
  closed('CLOSED', 'Đã chốt ca', Color(0xFF6B7280));

  final String value;
  final String label;
  final Color color;

  const ShiftStatus(this.value, this.label, this.color);

  static ShiftStatus fromString(String? val) {
    if (val == null) return ShiftStatus.open;
    final upper = val.toUpperCase();
    for (final s in ShiftStatus.values) {
      if (s.value == upper) return s;
    }
    return ShiftStatus.open;
  }
}

/// Thống kê doanh thu & két tiền realtime của ca
class ShiftStatsModel {
  final double initialCash;
  final double cashCollected;
  final double cashRefunded;
  final double netCashChange;
  final double expectedCash;
  final double creditCardAmount;
  final double bankTransferAmount;
  final double totalRevenue;
  final int paymentCount;
  final int refundCount;

  const ShiftStatsModel({
    this.initialCash = 0,
    this.cashCollected = 0,
    this.cashRefunded = 0,
    this.netCashChange = 0,
    this.expectedCash = 0,
    this.creditCardAmount = 0,
    this.bankTransferAmount = 0,
    this.totalRevenue = 0,
    this.paymentCount = 0,
    this.refundCount = 0,
  });

  factory ShiftStatsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShiftStatsModel();
    return ShiftStatsModel(
      initialCash: (json['initialCash'] as num?)?.toDouble() ?? 0,
      cashCollected: (json['cashCollected'] as num?)?.toDouble() ?? 0,
      cashRefunded: (json['cashRefunded'] as num?)?.toDouble() ?? 0,
      netCashChange: (json['netCashChange'] as num?)?.toDouble() ?? 0,
      expectedCash: (json['expectedCash'] as num?)?.toDouble() ?? 0,
      creditCardAmount: (json['creditCardAmount'] as num?)?.toDouble() ?? 0,
      bankTransferAmount: (json['bankTransferAmount'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
      refundCount: (json['refundCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'initialCash': initialCash,
    'cashCollected': cashCollected,
    'cashRefunded': cashRefunded,
    'netCashChange': netCashChange,
    'expectedCash': expectedCash,
    'creditCardAmount': creditCardAmount,
    'bankTransferAmount': bankTransferAmount,
    'totalRevenue': totalRevenue,
    'paymentCount': paymentCount,
    'refundCount': refundCount,
  };
}

/// Giao dịch thanh toán phát sinh trong ca
class ShiftPaymentItemModel {
  final String id;
  final String? invoiceId;
  final double amount;
  final String method;
  final String type;
  final String status;
  final String? reference;
  final String? note;
  final DateTime? confirmedAt;
  final String? invoiceCode;
  final String? bookingCode;
  final String? roomNumber;
  final String? customerName;

  const ShiftPaymentItemModel({
    required this.id,
    this.invoiceId,
    required this.amount,
    required this.method,
    required this.type,
    required this.status,
    this.reference,
    this.note,
    this.confirmedAt,
    this.invoiceCode,
    this.bookingCode,
    this.roomNumber,
    this.customerName,
  });

  factory ShiftPaymentItemModel.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoice'] as Map<String, dynamic>?;
    final booking = invoice?['booking'] as Map<String, dynamic>?;
    final room = booking?['room'] as Map<String, dynamic>?;
    final customer = booking?['customer'] as Map<String, dynamic>?;

    return ShiftPaymentItemModel(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: json['method'] ?? 'CASH',
      type: json['type'] ?? 'PAYMENT',
      status: json['status'] ?? 'CONFIRMED',
      reference: json['reference'],
      note: json['note'],
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'].toString())
          : null,
      invoiceCode: invoice?['invoiceCode'],
      bookingCode: booking?['bookingCode'],
      roomNumber: room?['roomNumber'],
      customerName: customer?['fullName'],
    );
  }
}

/// Dữ liệu ca làm việc & bàn giao tiền két
class WorkShiftModel {
  final String id;
  final String shiftCode;
  final String staffId;
  final String staffName;
  final String? staffAvatar;
  final String? staffPhone;
  final String? staffEmail;
  final ShiftType shiftType;
  final String deskName;
  final ShiftStatus status;
  final DateTime startTime;
  final DateTime? endTime;

  final double initialCash;
  final double? actualCash;
  final double? expectedCash;
  final double? cashDifference;
  final double creditCardAmount;
  final double bankTransferAmount;
  final double totalRevenue;

  final String? openNote;
  final String? closeNote;
  final String? differenceReason;

  final String? handoverStaffId;
  final String? handoverStaffName;

  final ShiftStatsModel? stats;
  final List<ShiftPaymentItemModel> payments;

  const WorkShiftModel({
    required this.id,
    required this.shiftCode,
    required this.staffId,
    required this.staffName,
    this.staffAvatar,
    this.staffPhone,
    this.staffEmail,
    required this.shiftType,
    required this.deskName,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.initialCash,
    this.actualCash,
    this.expectedCash,
    this.cashDifference,
    this.creditCardAmount = 0,
    this.bankTransferAmount = 0,
    this.totalRevenue = 0,
    this.openNote,
    this.closeNote,
    this.differenceReason,
    this.handoverStaffId,
    this.handoverStaffName,
    this.stats,
    this.payments = const [],
  });

  bool get isOpen => status == ShiftStatus.open;
  bool get isClosed => status == ShiftStatus.closed;

  /// Có chênh lệch quỹ tiền mặt lúc chốt ca hay không
  bool get hasDifference =>
      cashDifference != null && cashDifference!.abs() > 0.01;

  /// Thừa tiền trong két
  bool get isOverCash => (cashDifference ?? 0) > 0.01;

  /// Thiếu tiền trong két
  bool get isShortCash => (cashDifference ?? 0) < -0.01;

  /// Số tiền lý thuyết hiện tại cần có trong két
  double get currentExpectedCash =>
      expectedCash ?? stats?.expectedCash ?? initialCash;

  /// Tổng doanh thu trong ca
  double get effectiveRevenue =>
      totalRevenue > 0 ? totalRevenue : (stats?.totalRevenue ?? 0);

  /// Thời gian trực
  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  factory WorkShiftModel.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] as Map<String, dynamic>?;
    final handoverStaff = json['handoverStaff'] as Map<String, dynamic>?;

    final rawPayments = json['payments'] as List<dynamic>?;
    final paymentsList = rawPayments != null
        ? rawPayments
            .whereType<Map<String, dynamic>>()
            .map((p) => ShiftPaymentItemModel.fromJson(p))
            .toList()
        : <ShiftPaymentItemModel>[];

    return WorkShiftModel(
      id: json['id'] ?? '',
      shiftCode: json['shiftCode'] ?? '',
      staffId: json['staffId'] ?? staff?['id'] ?? '',
      staffName: json['staffName'] ?? staff?['fullName'] ?? 'Nhân viên',
      staffAvatar: json['staffAvatar'] ?? staff?['avatar'],
      staffPhone: json['staffPhone'] ?? staff?['phone'],
      staffEmail: staff?['email'],
      shiftType: ShiftType.fromString(json['shiftType']),
      deskName: json['deskName'] ?? 'Quầy Lễ Tân',
      status: ShiftStatus.fromString(json['status']),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initialCash: (json['initialCash'] as num?)?.toDouble() ?? 0,
      actualCash: (json['actualCash'] as num?)?.toDouble(),
      expectedCash: (json['expectedCash'] as num?)?.toDouble() ??
          (json['currentExpectedCash'] as num?)?.toDouble(),
      cashDifference: (json['cashDifference'] as num?)?.toDouble(),
      creditCardAmount:
          (json['creditCardAmount'] as num?)?.toDouble() ?? 0,
      bankTransferAmount:
          (json['bankTransferAmount'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ??
          (json['totalRevenueSoFar'] as num?)?.toDouble() ??
          0,
      openNote: json['openNote'],
      closeNote: json['closeNote'],
      differenceReason: json['differenceReason'],
      handoverStaffId: json['handoverStaffId'] ?? handoverStaff?['id'],
      handoverStaffName:
          json['handoverStaffName'] ?? handoverStaff?['fullName'],
      stats: json['stats'] != null
          ? ShiftStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      payments: paymentsList,
    );
  }
}
