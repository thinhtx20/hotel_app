class ServiceModel {
  final String id;
  final String? code;
  final String name;
  final String? category;
  final String? description;
  final num unitPrice;
  final String? unit;
  final String? icon;
  final bool isAvailable;

  const ServiceModel({
    required this.id,
    this.code,
    required this.name,
    this.category,
    this.description,
    required this.unitPrice,
    this.unit,
    this.icon,
    this.isAvailable = true,
  });

  num get price => unitPrice;
  String? get imageUrl => icon;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    num parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      return num.tryParse(val.toString()) ?? 0;
    }

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? 'Dịch vụ',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      unitPrice: parsePrice(json['unitPrice'] ?? json['price']),
      unit: json['unit']?.toString(),
      icon: json['icon']?.toString(),
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : (json['isActive'] is bool ? json['isActive'] as bool : true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (code != null) 'code': code,
      'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      'unitPrice': unitPrice,
      if (unit != null) 'unit': unit,
      if (icon != null) 'icon': icon,
      'isAvailable': isAvailable,
    };
  }
}
