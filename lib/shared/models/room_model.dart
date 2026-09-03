import '../../core/constants/role_enum.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final int floor;
  final RoomStatus status;
  final num pricePerNight;
  final String? roomTypeId;
  final String? roomTypeName;
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
    this.images = const [],
    this.amenities = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      roomNumber: json['roomNumber'] ?? json['number'] ?? '',
      floor: json['floor'] is int ? json['floor'] : int.tryParse('${json['floor']}') ?? 1,
      status: RoomStatus.fromString(json['status']),
      pricePerNight: json['pricePerNight'] ?? json['basePrice'] ?? 0,
      roomTypeId: json['roomTypeId'] ?? json['roomType']?['id'],
      roomTypeName: json['roomTypeName'] ?? json['roomType']?['name'],
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      amenities: json['amenities'] is List ? List<String>.from(json['amenities']) : [],
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
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
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
    );
  }
}

