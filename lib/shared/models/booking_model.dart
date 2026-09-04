class BookingModel {
  final String id;
  final String? bookingCode;
  final String roomId;
  final String? roomNumber;
  final String? roomTypeName;
  final String? roomImage;
  final int? floor;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final int guestCount;
  final num totalAmount;
  final num depositAmount;
  final String status;
  final String? paymentStatus;
  final bool? canCancel;
  final int? nights;
  final String? invoiceId;
  final DateTime? createdAt;
  final String? specialRequests;

  // Nhật ký duyệt / xác nhận đơn (bổ sung theo API mới)
  final DateTime? confirmedAt;
  final String? confirmedById;
  final String? confirmedByName;
  final String? confirmationNote;

  // Nhật ký hủy đơn
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledById;
  final String? cancelledByName;

  BookingModel({
    required this.id,
    this.bookingCode,
    required this.roomId,
    this.roomNumber,
    this.roomTypeName,
    this.roomImage,
    this.floor,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.checkInDate,
    required this.checkOutDate,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.guestCount,
    this.totalAmount = 0,
    this.depositAmount = 0,
    required this.status,
    this.paymentStatus,
    this.canCancel,
    this.nights,
    this.invoiceId,
    this.createdAt,
    this.specialRequests,
    this.confirmedAt,
    this.confirmedById,
    this.confirmedByName,
    this.confirmationNote,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledById,
    this.cancelledByName,
  });

  int get nightsCount {
    if (nights != null && nights! > 0) return nights!;
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Room image fallback
    String? img;
    final roomImages = json['room']?['images'] as List?;
    if (roomImages != null && roomImages.isNotEmpty) {
      img = roomImages[0].toString();
    } else {
      final typeImages = json['room']?['roomType']?['images'] as List?;
      if (typeImages != null && typeImages.isNotEmpty) {
        img = typeImages[0].toString();
      }
    }

    num parseAmount(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      return num.tryParse(val.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    // `confirmedBy` / `cancelledBy` có thể là object {id, fullName, role}
    // (Swagger) hoặc chỉ là chuỗi id kèm trường `*ById` (dữ liệu thật).
    String? actorId(String key) {
      final actor = json[key];
      if (actor is Map) return actor['id']?.toString();
      if (actor is String && actor.isNotEmpty) return actor;
      return json['${key}Id']?.toString();
    }

    String? actorName(String key) {
      final actor = json[key];
      if (actor is Map) return actor['fullName']?.toString();
      return json['${key}Name']?.toString();
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      bookingCode: json['bookingCode']?.toString() ?? json['code']?.toString(),
      roomId:
          json['roomId']?.toString() ?? json['room']?['id']?.toString() ?? '',
      roomNumber: json['room']?['roomNumber']?.toString() ??
          json['roomNumber']?.toString(),
      roomTypeName: json['room']?['roomType']?['name']?.toString() ??
          json['roomTypeName']?.toString(),
      roomImage: img,
      floor: json['room']?['floor'] is int
          ? json['room']['floor'] as int
          : (json['floor'] is int ? json['floor'] as int : null),
      customerId: json['customerId']?.toString() ??
          json['customer']?['id']?.toString(),
      customerName: json['customer']?['fullName']?.toString() ??
          json['customerName']?.toString(),
      customerPhone: json['customer']?['phone']?.toString() ??
          json['customerPhone']?.toString(),
      customerEmail: json['customer']?['email']?.toString() ??
          json['customerEmail']?.toString(),
      checkInDate: json['checkInDate'] != null
          ? DateTime.tryParse(json['checkInDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'].toString()) ??
              DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      actualCheckIn: parseDate(json['actualCheckIn']),
      actualCheckOut: parseDate(json['actualCheckOut']),
      guestCount: (json['guestCount'] is int)
          ? json['guestCount'] as int
          : int.tryParse('${json['guestCount']}') ?? 1,
      totalAmount: parseAmount(json['totalAmount']),
      depositAmount: parseAmount(json['depositAmount']),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      paymentStatus: json['paymentStatus']?.toString(),
      canCancel: json['canCancel'] is bool ? json['canCancel'] as bool : null,
      nights: json['nights'] is int
          ? json['nights'] as int
          : int.tryParse('${json['nights']}'),
      invoiceId: json['invoiceId']?.toString() ?? json['invoice']?['id']?.toString(),
      createdAt: parseDate(json['createdAt']),
      specialRequests: json['specialRequests']?.toString(),
      confirmedAt: parseDate(json['confirmedAt']),
      confirmedById: actorId('confirmedBy'),
      confirmedByName: actorName('confirmedBy'),
      confirmationNote: json['confirmationNote']?.toString() ??
          json['approvalNote']?.toString(),
      cancellationReason: json['cancellationReason']?.toString() ??
          json['cancelReason']?.toString() ??
          json['reason']?.toString() ??
          json['cancellation_reason']?.toString(),
      cancelledAt: parseDate(json['cancelledAt']),
      cancelledById: actorId('cancelledBy'),
      cancelledByName: actorName('cancelledBy'),
    );
  }

  /// Mã đơn hiển thị, an toàn khi thiếu bookingCode hoặc id ngắn/rỗng.
  String get displayCode {
    if (bookingCode != null && bookingCode!.isNotEmpty) {
      return bookingCode!.startsWith('#')
          ? bookingCode!.substring(1)
          : bookingCode!;
    }
    if (id.isEmpty) return '---';
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  BookingModel copyWith({
    String? id,
    String? bookingCode,
    String? roomId,
    String? roomNumber,
    String? roomTypeName,
    String? roomImage,
    int? floor,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    DateTime? actualCheckIn,
    DateTime? actualCheckOut,
    int? guestCount,
    num? totalAmount,
    num? depositAmount,
    String? status,
    String? paymentStatus,
    bool? canCancel,
    int? nights,
    String? invoiceId,
    DateTime? createdAt,
    String? specialRequests,
    DateTime? confirmedAt,
    String? confirmedById,
    String? confirmedByName,
    String? confirmationNote,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? cancelledById,
    String? cancelledByName,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomTypeName: roomTypeName ?? this.roomTypeName,
      roomImage: roomImage ?? this.roomImage,
      floor: floor ?? this.floor,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      actualCheckIn: actualCheckIn ?? this.actualCheckIn,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      guestCount: guestCount ?? this.guestCount,
      totalAmount: totalAmount ?? this.totalAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      canCancel: canCancel ?? this.canCancel,
      nights: nights ?? this.nights,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt ?? this.createdAt,
      specialRequests: specialRequests ?? this.specialRequests,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedById: confirmedById ?? this.confirmedById,
      confirmedByName: confirmedByName ?? this.confirmedByName,
      confirmationNote: confirmationNote ?? this.confirmationNote,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledById: cancelledById ?? this.cancelledById,
      cancelledByName: cancelledByName ?? this.cancelledByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (bookingCode != null) 'bookingCode': bookingCode,
      'roomId': roomId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (roomTypeName != null) 'roomTypeName': roomTypeName,
      if (roomImage != null) 'roomImage': roomImage,
      if (floor != null) 'floor': floor,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      if (actualCheckIn != null) 'actualCheckIn': actualCheckIn!.toIso8601String(),
      if (actualCheckOut != null) 'actualCheckOut': actualCheckOut!.toIso8601String(),
      'guestCount': guestCount,
      'totalAmount': totalAmount,
      'depositAmount': depositAmount,
      'status': status,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (canCancel != null) 'canCancel': canCancel,
      if (nights != null) 'nights': nights,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (specialRequests != null) 'specialRequests': specialRequests,
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (confirmedById != null) 'confirmedById': confirmedById,
      if (confirmedByName != null) 'confirmedByName': confirmedByName,
      if (confirmationNote != null) 'confirmationNote': confirmationNote,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
      if (cancelledById != null) 'cancelledById': cancelledById,
      if (cancelledByName != null) 'cancelledByName': cancelledByName,
    };
  }
}
