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
  final String? cancellationReason;

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
    this.cancellationReason,
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
      checkInDate: json['checkInDate'] != null
          ? DateTime.tryParse(json['checkInDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'].toString()) ??
              DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      actualCheckIn: json['actualCheckIn'] != null
          ? DateTime.tryParse(json['actualCheckIn'].toString())
          : null,
      actualCheckOut: json['actualCheckOut'] != null
          ? DateTime.tryParse(json['actualCheckOut'].toString())
          : null,
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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      specialRequests: json['specialRequests']?.toString(),
      cancellationReason: json['cancellationReason']?.toString() ??
          json['cancelReason']?.toString() ??
          json['cancellation_reason']?.toString(),
    );
  }
}
