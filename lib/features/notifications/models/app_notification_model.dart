import 'package:flutter/material.dart';

/// 5 Kiểu hiển thị thông báo trong ứng dụng theo phong cách Modern Luxury.
enum AppNotificationStyle {
  /// Banner phong cách Midnight Navy & Gold mạ vàng 24K, trượt từ đỉnh kèm thanh đếm ngược
  luxuryBanner,

  /// Viên thuốc Dynamic Island đen bóng bo tròn, thu nhỏ/mở rộng linh hoạt phong cách iOS
  dynamicIsland,

  /// Thẻ kính mờ pha lê Frosted Glassmorphism xuyên thấu với viền phát sáng
  glassCard,

  /// Thanh thông báo nổi đáy màn hình (Floating Bottom Toast) tinh gọn
  bottomToast,

  /// Hộp thoại pop-up sang trọng giữa màn hình với nền làm mờ cho tin quan trọng
  dialogAlert;

  String get displayName {
    switch (this) {
      case AppNotificationStyle.luxuryBanner:
        return 'Modern Luxury Banner';
      case AppNotificationStyle.dynamicIsland:
        return 'Dynamic Island Capsule';
      case AppNotificationStyle.glassCard:
        return 'Frosted Glass Card';
      case AppNotificationStyle.bottomToast:
        return 'Floating Bottom Toast';
      case AppNotificationStyle.dialogAlert:
        return 'Luxury Modal Dialog';
    }
  }

  String get description {
    switch (this) {
      case AppNotificationStyle.luxuryBanner:
        return 'Banner hoàng gia trượt từ đỉnh kèm vạch tiến trình vàng ánh kim';
      case AppNotificationStyle.dynamicIsland:
        return 'Viên thuốc linh hoạt phong cách iOS, chạm mở rộng mượt mà';
      case AppNotificationStyle.glassCard:
        return 'Kính mờ xuyên thấu Glassmorphism hiện đại với viền phát sáng';
      case AppNotificationStyle.bottomToast:
        return 'Thanh thông báo nổi nhẹ phía trên thanh điều hướng đáy';
      case AppNotificationStyle.dialogAlert:
        return 'Hộp thoại pop-up trung tâm cho thông báo ưu tiên & khẩn cấp';
    }
  }

  IconData get icon {
    switch (this) {
      case AppNotificationStyle.luxuryBanner:
        return Icons.view_headline_rounded;
      case AppNotificationStyle.dynamicIsland:
        return Icons.lens_blur_rounded;
      case AppNotificationStyle.glassCard:
        return Icons.auto_awesome_mosaic_rounded;
      case AppNotificationStyle.bottomToast:
        return Icons.call_to_action_rounded;
      case AppNotificationStyle.dialogAlert:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

/// 5 Phân loại nội dung thông báo cho người dùng
enum AppNotificationCategory {
  booking,
  payment,
  service,
  promotion,
  system;

  String get label {
    switch (this) {
      case AppNotificationCategory.booking:
        return 'Đặt phòng';
      case AppNotificationCategory.payment:
        return 'Thanh toán';
      case AppNotificationCategory.service:
        return 'Dịch vụ phòng';
      case AppNotificationCategory.promotion:
        return 'Ưu đãi & VIP';
      case AppNotificationCategory.system:
        return 'Hệ thống';
    }
  }

  IconData get icon {
    switch (this) {
      case AppNotificationCategory.booking:
        return Icons.meeting_room_rounded;
      case AppNotificationCategory.payment:
        return Icons.receipt_long_rounded;
      case AppNotificationCategory.service:
        return Icons.room_service_rounded;
      case AppNotificationCategory.promotion:
        return Icons.card_giftcard_rounded;
      case AppNotificationCategory.system:
        return Icons.security_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AppNotificationCategory.booking:
        return const Color(0xFFD97706); // Gold / Amber
      case AppNotificationCategory.payment:
        return const Color(0xFF059669); // Emerald
      case AppNotificationCategory.service:
        return const Color(0xFF6366F1); // Indigo
      case AppNotificationCategory.promotion:
        return const Color(0xFFEC4899); // Rose / Pink
      case AppNotificationCategory.system:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AppNotificationCategory.booking:
        return const Color(0xFFFEF3C7);
      case AppNotificationCategory.payment:
        return const Color(0xFFD1FAE5);
      case AppNotificationCategory.service:
        return const Color(0xFFE0E7FF);
      case AppNotificationCategory.promotion:
        return const Color(0xFFFCE7F3);
      case AppNotificationCategory.system:
        return const Color(0xFFDBEAFE);
    }
  }
}

/// Model lưu trữ chi tiết một thông báo người dùng
class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final AppNotificationCategory category;
  final AppNotificationStyle? style;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionLabel;
  final String? actionRoute;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.style,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.actionLabel,
    this.actionRoute,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    AppNotificationCategory? category,
    AppNotificationStyle? style,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionLabel,
    String? actionRoute,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.name,
      'style': style?.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'actionLabel': actionLabel,
      'actionRoute': actionRoute,
    };
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    AppNotificationCategory cat = AppNotificationCategory.system;
    try {
      cat = AppNotificationCategory.values.byName(json['category'] as String);
    } catch (_) {}

    AppNotificationStyle? st;
    if (json['style'] != null) {
      try {
        st = AppNotificationStyle.values.byName(json['style'] as String);
      } catch (_) {}
    }

    return AppNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: cat,
      style: st,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
      actionLabel: json['actionLabel'] as String?,
      actionRoute: json['actionRoute'] as String?,
    );
  }
}
