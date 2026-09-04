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
  /// Ba vai trò nhân viên, đối lập với [UserRole.customer].
  bool get isStaff => this != UserRole.customer;

  bool get _isAdmin => this == UserRole.admin;
  bool get _isReceptionist => this == UserRole.receptionist;
  bool get _isCashier => this == UserRole.cashier;

  /// Màn hình mặc định sau khi đăng nhập — Phần 4 của ma trận.
  String get homeRoute {
    switch (this) {
      case UserRole.admin:
        return '/admin';
      case UserRole.receptionist:
        return '/receptionist';
      case UserRole.cashier:
        return '/cashier';
      case UserRole.customer:
        return '/customer';
    }
  }

  // --- Rooms (§3.4) -------------------------------------------------------

  /// `POST /rooms` — lễ tân tạo được nhưng phòng bị ép `PENDING_APPROVAL`.
  bool get canCreateRoom => _isAdmin || _isReceptionist;

  /// `PATCH /rooms/:id/approve|reject`
  bool get canApproveRoom => _isAdmin || _isReceptionist;

  /// `PATCH /rooms/:id/status`
  bool get canChangeRoomStatus => _isAdmin || _isReceptionist;

  /// `PATCH|DELETE /rooms/:id` — chỉ ADMIN sửa được thông tin phòng.
  bool get canEditRoom => _isAdmin;

  /// `POST|PATCH|DELETE /room-types`
  bool get canManageRoomTypes => _isAdmin;

  /// `POST /upload/room`, `POST /upload/rooms` (§3.9)
  bool get canUploadRoomImages => _isAdmin || _isReceptionist;

  // --- Bookings (§3.5) ----------------------------------------------------

  /// `GET /bookings` không bị ép `customerId` — khách chỉ thấy đơn của mình.
  bool get canViewAllBookings => isStaff;

  /// `POST /bookings/:id/check-in`
  bool get canCheckIn => _isAdmin || _isReceptionist;

  /// `POST /bookings/:id/check-out` — thu ngân kiêm quầy cũng trả phòng được.
  bool get canCheckOut => isStaff;

  /// `POST /bookings/:id/services` — dịch vụ do lễ tân ghi.
  bool get canAddBookingServices => _isAdmin || _isReceptionist;

  /// `PUT /bookings/:id/approve|reject` — duyệt đơn đặt phòng chờ.
  bool get canApproveBooking => _isAdmin || _isReceptionist;

  // --- Invoices (§3.6) ----------------------------------------------------

  /// `GET /invoices` — danh sách hóa đơn toàn khách sạn.
  bool get canViewAllInvoices => isStaff;

  /// `POST /invoices` — lễ tân bị `403`, hóa đơn của lễ tân sinh khi check-out.
  bool get canCreateInvoice => _isAdmin || _isCashier;

  /// `POST /invoices/:id/pay` — lễ tân **được** ghi nhận thanh toán.
  bool get canPayInvoice => isStaff;

  /// `GET /invoices/summary?date=`
  bool get canViewInvoiceSummary => isStaff;

  // --- Analytics (§3.7) ---------------------------------------------------

  /// `GET /analytics/dashboard` — dùng chung cho cả ba vai trò nhân viên.
  bool get canViewDashboard => isStaff;

  /// `GET /analytics/revenue/daily?range=`
  bool get canViewDailyRevenue => isStaff;

  /// `GET /analytics/occupancy-by-type` và `/analytics/occupancy/detail`.
  bool get canViewOccupancy => _isAdmin || _isReceptionist;

  /// `GET /analytics/revenue?year=` — báo cáo doanh thu năm, chỉ ADMIN.
  bool get canViewYearlyRevenue => _isAdmin;

  // --- Users (§3.2) -------------------------------------------------------

  /// `GET /users`, `GET /users/:id` — lễ tân xem được, không sửa được.
  bool get canViewUsers => _isAdmin || _isReceptionist;

  /// `PATCH|DELETE /users/:id` — đổi role, vô hiệu hóa tài khoản.
  bool get canManageUsers => _isAdmin;
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
