import '../../core/constants/role_enum.dart';

class RoomPoliciesModel {
  final String checkInTime;
  final String checkOutTime;
  final String cancellation;
  final String smoking;
  final String pet;
  final String children;

  const RoomPoliciesModel({
    this.checkInTime = '14:00',
    this.checkOutTime = '12:00',
    this.cancellation = 'Miễn phí hủy phòng trước 24 giờ',
    this.smoking = 'Không hút thuốc trong phòng',
    this.pet = 'Không cho phép thú cưng',
    this.children = 'Trẻ em dưới 6 tuổi lưu trú miễn phí',
  });

  factory RoomPoliciesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RoomPoliciesModel();
    return RoomPoliciesModel(
      checkInTime: json['checkInTime']?.toString() ?? '14:00',
      checkOutTime: json['checkOutTime']?.toString() ?? '12:00',
      cancellation: json['cancellation']?.toString() ?? 'Miễn phí hủy phòng trước 24 giờ',
      smoking: json['smoking']?.toString() ?? 'Không hút thuốc trong phòng',
      pet: json['pet']?.toString() ?? 'Không cho phép thú cưng',
      children: json['children']?.toString() ?? 'Trẻ em dưới 6 tuổi lưu trú miễn phí',
    );
  }

  Map<String, dynamic> toJson() => {
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
    'cancellation': cancellation,
    'smoking': smoking,
    'pet': pet,
    'children': children,
  };
}

class RatingBreakdownModel {
  final double cleanliness;
  final double comfort;
  final double location;
  final double service;
  final double value;

  const RatingBreakdownModel({
    this.cleanliness = 5.0,
    this.comfort = 5.0,
    this.location = 5.0,
    this.service = 5.0,
    this.value = 5.0,
  });

  factory RatingBreakdownModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RatingBreakdownModel();
    return RatingBreakdownModel(
      cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 5.0,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 5.0,
      location: (json['location'] as num?)?.toDouble() ?? 5.0,
      service: (json['service'] as num?)?.toDouble() ?? 5.0,
      value: (json['value'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'cleanliness': cleanliness,
    'comfort': comfort,
    'location': location,
    'service': service,
    'value': value,
  };
}

class RoomReviewModel {
  final String id;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String date;
  final String comment;
  final String? stayDuration;

  const RoomReviewModel({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.date,
    required this.comment,
    this.stayDuration,
  });

  factory RoomReviewModel.fromJson(Map<String, dynamic> json) {
    return RoomReviewModel(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Khách nghỉ dưỡng',
      authorAvatar: json['authorAvatar']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      date: json['date']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      stayDuration: json['stayDuration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'rating': rating,
    'date': date,
    'comment': comment,
    if (stayDuration != null) 'stayDuration': stayDuration,
  };
}

class AmenityGroupModel {
  final String groupName;
  final String icon;
  final List<String> items;

  const AmenityGroupModel({
    required this.groupName,
    this.icon = 'star',
    this.items = const [],
  });

  factory AmenityGroupModel.fromJson(Map<String, dynamic> json) {
    return AmenityGroupModel(
      groupName: json['groupName']?.toString() ?? 'Tiện nghi',
      icon: json['icon']?.toString() ?? 'star',
      items: json['items'] is List ? List<String>.from(json['items']) : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'icon': icon,
    'items': items,
  };
}

/// Lượt lưu trú đang gắn với phòng — backend trả kèm ở `currentBooking`
/// trong GET /rooms và GET /rooms/:id, dùng cho sơ đồ phòng của lễ tân.
class RoomCurrentBookingModel {
  final String id;
  final String? bookingCode;
  final String? guestName;
  final String? guestPhone;
  final DateTime? checkOutDate;

  const RoomCurrentBookingModel({
    required this.id,
    this.bookingCode,
    this.guestName,
    this.guestPhone,
    this.checkOutDate,
  });

  static RoomCurrentBookingModel? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return RoomCurrentBookingModel(
      id: json['id']?.toString() ?? '',
      bookingCode: json['bookingCode']?.toString(),
      guestName: json['guestName']?.toString() ??
          json['customer']?['fullName']?.toString(),
      guestPhone: json['guestPhone']?.toString() ??
          json['customer']?['phone']?.toString(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (bookingCode != null) 'bookingCode': bookingCode,
    if (guestName != null) 'guestName': guestName,
    if (guestPhone != null) 'guestPhone': guestPhone,
    if (checkOutDate != null) 'checkOutDate': checkOutDate!.toIso8601String(),
  };
}

class RoomModel {
  final String id;
  final String roomNumber;
  final int floor;
  final RoomStatus status;
  final num pricePerNight;
  final String? roomTypeId;
  final String? roomTypeName;
  final String? roomTypeCode;
  final String? description;
  final num? sizeSqM;
  final int? capacityAdults;
  final int? capacityChildren;
  final num? rating;
  final int? reviewCount;
  final String? notes;
  final List<String> images;
  final List<String> amenities;

  // Dữ liệu mở rộng phục vụ màn chi tiết phòng
  final String? bedType;
  final String? viewType;
  final List<String> highlights;
  final RoomPoliciesModel policies;
  final RatingBreakdownModel ratingBreakdown;
  final List<RoomReviewModel> reviews;
  final List<AmenityGroupModel> amenityGroups;

  /// Lượt lưu trú đang chiếm phòng (nếu có) — phục vụ sơ đồ phòng.
  final RoomCurrentBookingModel? currentBooking;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.status,
    required this.pricePerNight,
    this.roomTypeId,
    this.roomTypeName,
    this.roomTypeCode,
    this.description,
    this.sizeSqM,
    this.capacityAdults,
    this.capacityChildren,
    this.rating,
    this.reviewCount,
    this.notes,
    this.images = const [],
    this.amenities = const [],
    this.bedType,
    this.viewType,
    this.highlights = const [],
    this.policies = const RoomPoliciesModel(),
    this.ratingBreakdown = const RatingBreakdownModel(),
    this.reviews = const [],
    this.amenityGroups = const [],
    this.currentBooking,
  });

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    int? floor,
    RoomStatus? status,
    num? pricePerNight,
    String? roomTypeId,
    String? roomTypeName,
    String? roomTypeCode,
    String? description,
    num? sizeSqM,
    int? capacityAdults,
    int? capacityChildren,
    num? rating,
    int? reviewCount,
    String? notes,
    List<String>? images,
    List<String>? amenities,
    String? bedType,
    String? viewType,
    List<String>? highlights,
    RoomPoliciesModel? policies,
    RatingBreakdownModel? ratingBreakdown,
    List<RoomReviewModel>? reviews,
    List<AmenityGroupModel>? amenityGroups,
    RoomCurrentBookingModel? currentBooking,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomTypeName: roomTypeName ?? this.roomTypeName,
      roomTypeCode: roomTypeCode ?? this.roomTypeCode,
      description: description ?? this.description,
      sizeSqM: sizeSqM ?? this.sizeSqM,
      capacityAdults: capacityAdults ?? this.capacityAdults,
      capacityChildren: capacityChildren ?? this.capacityChildren,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      bedType: bedType ?? this.bedType,
      viewType: viewType ?? this.viewType,
      highlights: highlights ?? this.highlights,
      policies: policies ?? this.policies,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      reviews: reviews ?? this.reviews,
      amenityGroups: amenityGroups ?? this.amenityGroups,
      currentBooking: currentBooking ?? this.currentBooking,
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Images with fallback to single image/imageUrl, then roomType.images
    List<String> imgs = [];
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      imgs = List<String>.from(json['images']);
    } else if (json['roomType']?['images'] is List &&
        (json['roomType']['images'] as List).isNotEmpty) {
      imgs = List<String>.from(json['roomType']['images']);
    } else {
      final single = json['image'] ?? json['imageUrl'];
      if (single != null && single.toString().isNotEmpty) {
        imgs = [single.toString()];
      }
    }

    // Amenities with fallback to roomType.amenities
    List<String> amens = [];
    if (json['amenities'] is List && (json['amenities'] as List).isNotEmpty) {
      amens = List<String>.from(json['amenities']);
    } else if (json['roomType']?['amenities'] is List &&
        (json['roomType']['amenities'] as List).isNotEmpty) {
      amens = List<String>.from(json['roomType']['amenities']);
    }

    // Highlights
    List<String> hls = [];
    if (json['highlights'] is List) {
      hls = List<String>.from(json['highlights']);
    }

    // Reviews
    List<RoomReviewModel> revs = [];
    if (json['reviews'] is List) {
      revs = (json['reviews'] as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => RoomReviewModel.fromJson(r))
          .toList();
    }

    // Amenity Groups
    List<AmenityGroupModel> groups = [];
    if (json['amenityGroups'] is List) {
      groups = (json['amenityGroups'] as List)
          .whereType<Map<String, dynamic>>()
          .map((g) => AmenityGroupModel.fromJson(g))
          .toList();
    }

    final adults = json['capacityAdults'] is int
        ? json['capacityAdults'] as int
        : int.tryParse(
            '${json['capacityAdults'] ?? json['roomType']?['capacityAdults']}');
    final children = json['capacityChildren'] is int
        ? json['capacityChildren'] as int
        : int.tryParse(
            '${json['capacityChildren'] ?? json['roomType']?['capacityChildren']}');
    final size = json['sizeSqM'] ?? json['area'] ?? json['roomType']?['sizeSqM'];

    return RoomModel(
      id: json['id']?.toString() ?? '',
      roomNumber:
          json['roomNumber']?.toString() ?? json['number']?.toString() ?? '',
      floor: json['floor'] is int
          ? json['floor']
          : int.tryParse('${json['floor']}') ?? 1,
      status: RoomStatus.fromString(json['status']?.toString()),
      pricePerNight: json['pricePerNight'] ??
          json['basePrice'] ??
          json['roomType']?['basePrice'] ??
          0,
      roomTypeId: json['roomTypeId']?.toString() ??
          json['roomType']?['id']?.toString(),
      roomTypeName: json['roomTypeName']?.toString() ??
          json['roomType']?['name']?.toString(),
      roomTypeCode: json['roomTypeCode']?.toString() ??
          json['roomType']?['code']?.toString(),
      description: json['description']?.toString() ??
          json['roomType']?['description']?.toString(),
      sizeSqM: size is num ? size : num.tryParse('$size'),
      capacityAdults: adults,
      capacityChildren: children,
      rating: json['rating'] is num
          ? json['rating']
          : num.tryParse('${json['rating']}'),
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount']
          : int.tryParse('${json['reviewCount']}'),
      notes: json['notes']?.toString(),
      images: imgs,
      amenities: amens,
      bedType: json['bedType']?.toString(),
      viewType: json['viewType']?.toString(),
      highlights: hls,
      policies: RoomPoliciesModel.fromJson(json['policies'] as Map<String, dynamic>?),
      ratingBreakdown: RatingBreakdownModel.fromJson(json['ratingBreakdown'] as Map<String, dynamic>?),
      reviews: revs,
      amenityGroups: groups,
      currentBooking: RoomCurrentBookingModel.fromJson(
        json['currentBooking'] is Map
            ? Map<String, dynamic>.from(json['currentBooking'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'floor': floor,
      'status': status.code,
      'pricePerNight': pricePerNight,
      'roomTypeId': roomTypeId,
      'roomTypeName': roomTypeName,
      'roomTypeCode': roomTypeCode,
      'description': description,
      'sizeSqM': sizeSqM,
      'capacityAdults': capacityAdults,
      'capacityChildren': capacityChildren,
      'notes': notes,
      'images': images,
      'amenities': amenities,
      'bedType': bedType,
      'viewType': viewType,
      'highlights': highlights,
      'policies': policies.toJson(),
      'ratingBreakdown': ratingBreakdown.toJson(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'amenityGroups': amenityGroups.map((g) => g.toJson()).toList(),
      if (currentBooking != null) 'currentBooking': currentBooking!.toJson(),
    };
  }
}

class RoomTypeModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final num basePrice;
  final int capacityAdults;
  final int capacityChildren;
  final num sizeSqM;
  final List<String> amenities;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? roomsCount;

  RoomTypeModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.basePrice,
    this.capacityAdults = 2,
    this.capacityChildren = 0,
    this.sizeSqM = 25,
    this.amenities = const [],
    this.images = const [],
    this.createdAt,
    this.updatedAt,
    this.roomsCount,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      basePrice: json['basePrice'] ?? 0,
      capacityAdults: json['capacityAdults'] is int
          ? json['capacityAdults']
          : int.tryParse('${json['capacityAdults']}') ?? 2,
      capacityChildren: json['capacityChildren'] is int
          ? json['capacityChildren']
          : int.tryParse('${json['capacityChildren']}') ?? 0,
      sizeSqM: json['sizeSqM'] ?? json['area'] ?? 25,
      amenities: json['amenities'] is List
          ? List<String>.from(json['amenities'])
          : [],
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse('${json['createdAt']}')
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse('${json['updatedAt']}')
          : null,
      roomsCount: json['_count']?['rooms'] is int
          ? json['_count']['rooms'] as int
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      'basePrice': basePrice,
      'capacityAdults': capacityAdults,
      'capacityChildren': capacityChildren,
      'sizeSqM': sizeSqM,
      'amenities': amenities,
      'images': images,
    };
  }
}
