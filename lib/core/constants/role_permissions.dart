import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import 'role_enum.dart';

/// Quyền của từng vai trò — chép đúng ma trận trong `design/FE-ROLE-MATRIX.md`.
///
/// Mỗi getter tương ứng với một dòng của Phần 3 (ma trận endpoint × role). Màn
/// hình nào định gọi endpoint bị chặn thì phải ẩn nút bằng getter tương ứng —
/// backend trả `403` và FE **không được retry** (Phần 2 của ma trận).
extension RolePermissions on UserRole {
  bool get _isAdmin => this == UserRole.admin;
  bool get _isReceptionist => this == UserRole.receptionist;
  bool get isStaff => _isAdmin || _isReceptionist;
  bool get isCustomer => this == UserRole.customer;

  // --- 1. Quyền hiện có (Đã cập nhật sau gộp) ---
  bool get canCreateInvoice => isStaff;          // Trước: Admin || Cashier -> Nay: mở cho Lễ tân-Thu ngân
  bool get canCheckIn => isStaff;                // Nhân viên lễ tân quầy
  bool get canCheckOut => isStaff;               // Check-out & xuất hóa đơn
  bool get canAddBookingServices => isStaff;      // Ghi nhận dịch vụ phát sinh
  bool get canChangeRoomStatus => isStaff;       // Đổi trạng thái buồng phòng
  bool get canViewOccupancy => isStaff;          // Xem tỷ lệ lấp đầy phòng

  // --- 2. Quyền cho các tính năng mới P1 ---
  bool get canRefundInvoice => isStaff;          // S4: Hoàn tiền hóa đơn
  bool get canChangeRoom => isStaff;             // S2: Đổi phòng cho khách đang lưu trú
  bool get canCloseShift => isStaff;             // S1: Xem sổ quỹ cá nhân / chốt ca trực
  bool get canManageAllShifts => _isAdmin;       // Quản lý toàn diện ca trực & két tiền quầy (Admin)
  bool get canViewActiveShifts => isStaff;       // Xem danh sách quầy đang mở ca
  bool get canManageServiceCatalog => _isAdmin;  // A2: Quản trị danh mục dịch vụ (Chỉ Admin)
  bool get canViewStaffPerformance => _isAdmin;  // A1: Xem báo cáo hiệu suất nhân sự (Chỉ Admin)
  bool get canRequestService => isCustomer;      // C1: Khách hàng gọi dịch vụ tại phòng

  // --- Rooms (§3.4) ---
  bool get canCreateRoom => isStaff;
  bool get canApproveRoom => isStaff;
  bool get canEditRoom => _isAdmin;
  bool get canManageRoomTypes => _isAdmin;
  bool get canUploadRoomImages => isStaff;

  // --- Bookings (§3.5) ---
  bool get canViewAllBookings => isStaff;
  bool get canApproveBooking => isStaff;

  // --- Invoices (§3.6) ---
  bool get canViewAllInvoices => isStaff;
  bool get canPayInvoice => isStaff;
  bool get canViewInvoiceSummary => isStaff;
  /// Đối chiếu sao kê & xác nhận tiền khách trả qua app:
  /// `GET /invoices/payment-requests` + `POST /invoices/payments/:id/confirm`.
  bool get canConfirmPaymentRequest => isStaff;
  /// Khách tự xin trả số còn lại: `POST /invoices/:id/payment-requests`.
  bool get canRequestInvoicePayment => isCustomer;

  // --- Analytics (§3.7) ---
  bool get canViewDashboard => isStaff;
  bool get canViewDailyRevenue => isStaff;
  bool get canViewYearlyRevenue => _isAdmin;

  // --- Users (§3.2) ---
  bool get canViewUsers => isStaff;
  bool get canManageUsers => _isAdmin;

  // Đường dẫn mặc định khi đăng nhập
  String get homeRoute {
    switch (this) {
      case UserRole.admin:
        return '/admin';
      case UserRole.receptionist:
        return '/receptionist';
      case UserRole.customer:
        return '/customer';
    }
  }
}

/// Vai trò tương ứng với [state], `null` nếu chưa xác định được.
///
/// [AuthFailure] mang theo tài khoản cũ khi đổi tài khoản thất bại — lúc đó
/// phiên cũ vẫn còn hiệu lực nên quyền vẫn là quyền của tài khoản đó.
UserRole? _roleOf(AuthState state) {
  if (state is AuthAuthenticated) return state.user.role;
  if (state is AuthFailure) return state.previousUser?.role;
  return null;
}

extension RoleContext on BuildContext {
  /// Vai trò của người đang đăng nhập.
  ///
  /// Trả về [fallback] khi cây widget chưa gắn `AuthBloc` — trường hợp duy
  /// nhất là widget test dựng thẳng một màn hình, ở đó ta muốn thấy đủ nút.
  /// Dùng trong `build()` — màn hình vẽ lại khi đổi tài khoản.
  UserRole get currentRole {
    try {
      final role = _roleOf(watch<AuthBloc>().state);
      if (role != null) return role;
    } catch (_) {
      // Không có AuthBloc phía trên: giữ nguyên fallback.
    }
    return UserRole.admin;
  }

  /// Dùng trong callback (onTap, showModalBottomSheet…) — nơi không được
  /// `watch`. Cùng giá trị với [currentRole], chỉ khác là không đăng ký lắng
  /// nghe.
  UserRole get readRole {
    try {
      final role = _roleOf(read<AuthBloc>().state);
      if (role != null) return role;
    } catch (_) {
      // Không có AuthBloc phía trên: giữ nguyên fallback.
    }
    return UserRole.admin;
  }

  /// Trả về true nếu người dùng hiện tại là nhân viên (ADMIN, RECEPTIONIST, CASHIER)
  bool get isStaff => currentRole.isStaff;
}
