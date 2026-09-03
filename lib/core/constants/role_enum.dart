enum UserRole {
  customer('CUSTOMER', 'Khách hàng'),
  receptionist('RECEPTIONIST', 'Lễ tân'),
  cashier('CASHIER', 'Thu ngân / Kế toán'),
  admin('ADMIN', 'Quản trị viên / Giám đốc');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'RECEPTIONIST':
        return UserRole.receptionist;
      case 'CASHIER':
        return UserRole.cashier;
      case 'CUSTOMER':
      default:
        return UserRole.customer;
    }
  }
}

/// Mỗi trạng thái mang 3 màu cho 3 mục đích khác nhau — xem
/// `design/DESIGN-SYSTEM.md`. [colorValue] chỉ dùng để TÔ (ô phòng, chấm,
/// đoạn biểu đồ); chữ trên nền sáng phải dùng [inkValue] mới đạt tương phản.
enum RoomStatus {
  available('AVAILABLE', 'Phòng trống', 0xFF10B981, 0xFF047857, 0xFF34D399),
  occupied('OCCUPIED', 'Đang có khách', 0xFFEF4444, 0xFFDC2626, 0xFFF87171),
  reserved('RESERVED', 'Đã đặt cọc', 0xFFF59E0B, 0xFFB45309, 0xFFFBBF24),
  cleaning('CLEANING', 'Đang dọn dẹp', 0xFF3B82F6, 0xFF1D4ED8, 0xFF60A5FA),
  maintenance('MAINTENANCE', 'Bảo trì', 0xFF6B7280, 0xFF4B5563, 0xFF9CA3AF),
  pendingApproval('PENDING_APPROVAL', 'Chờ duyệt', 0xFFEAB308, 0xFFA16207, 0xFFFDE047),
  rejected('REJECTED', 'Từ chối', 0xFFEF4444, 0xFF991B1B, 0xFFFCA5A5);

  final String code;
  final String label;

  /// Màu tô — đã kiểm chứng tách biệt dưới mắt mù màu.
  final int colorValue;

  /// Màu chữ trên nền sáng — đạt tương phản ≥ 3:1.
  final int inkValue;

  /// Màu trên nền navy.
  final int onDarkValue;

  const RoomStatus(
    this.code,
    this.label,
    this.colorValue,
    this.inkValue,
    this.onDarkValue,
  );

  static RoomStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING_APPROVAL':
      case 'PENDING':
        return RoomStatus.pendingApproval;
      case 'REJECTED':
        return RoomStatus.rejected;
      case 'OCCUPIED':
        return RoomStatus.occupied;
      case 'RESERVED':
        return RoomStatus.reserved;
      case 'CLEANING':
        return RoomStatus.cleaning;
      case 'MAINTENANCE':
        return RoomStatus.maintenance;
      case 'AVAILABLE':
      default:
        return RoomStatus.available;
    }
  }
}
