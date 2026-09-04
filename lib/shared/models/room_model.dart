import '../../core/constants/role_enum.dart';

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
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Images with fallback to roomType.images
    List<String> imgs = [];
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      imgs = List<String>.from(json['images']);
    } else if (json['roomType']?['images'] is List &&
        (json['roomType']['images'] as List).isNotEmpty) {
      imgs = List<String>.from(json['roomType']['images']);
    }

    // Amenities with fallback to roomType.amenities
    List<String> amens = [];
    if (json['amenities'] is List && (json['amenities'] as List).isNotEmpty) {
      amens = List<String>.from(json['amenities']);
    } else if (json['roomType']?['amenities'] is List &&
        (json['roomType']['amenities'] as List).isNotEmpty) {
      amens = List<String>.from(json['roomType']['amenities']);
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
}

