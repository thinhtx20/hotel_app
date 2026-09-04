import 'dart:convert';
import '../../core/constants/role_enum.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatar;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatar,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'] ?? json['avatarUrl'],
      role: UserRole.fromString(json['role']),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse('${json['createdAt']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'role': role.value,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source));

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
