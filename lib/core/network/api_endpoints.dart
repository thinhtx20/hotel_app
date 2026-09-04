class ApiEndpoints {
  // --- Auth (§3.1) -----------------------------------------------------------
  /// POST — Public
  static const String login = '/auth/login';
  /// POST — Public
  static const String register = '/auth/register';
  /// POST — Public
  static const String refreshToken = '/auth/refresh-token';
  /// POST — Public
  static const String forgotPassword = '/auth/forgot-password';
  /// POST — Public
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  /// POST — Public
  static const String resetPassword = '/auth/reset-password';
  /// GET — Tất cả role đã đăng nhập
  static const String me = '/auth/me';
  /// POST — Public (cho phép thu hồi khi hết hạn access token)
  static const String logout = '/auth/logout';
  /// POST — Tất cả role đã đăng nhập
  static const String changePassword = '/auth/change-password';

  // --- Rooms & Room Types (§3.3 & §3.4) --------------------------------------
  /// GET — Public (nhân viên có Bearer token nhận thêm phòng chờ duyệt)
  /// POST — ADMIN, RECEPTIONIST (lễ tân bị ép PENDING_APPROVAL)
  static const String rooms = '/rooms';
  /// GET — Public (Elasticsearch full-text search)
  static const String roomsSearch = '/rooms/search';
  /// GET — Public (phòng trống theo khoảng checkIn/checkOut)
  static const String roomsAvailable = '/rooms/available';
  /// GET — Public
  static String roomDetail(String id) => '/rooms/$id';
  /// PATCH / DELETE — ADMIN
  static String updateRoom(String id) => '/rooms/$id';
  /// DELETE — ADMIN
  static String deleteRoom(String id) => '/rooms/$id';
  /// PATCH — ADMIN, RECEPTIONIST
  static String updateRoomStatus(String id) => '/rooms/$id/status';
  /// PATCH — ADMIN, RECEPTIONIST (duyệt phòng PENDING_APPROVAL -> AVAILABLE)
  static String approveRoom(String id) => '/rooms/$id/approve';
  /// PATCH — ADMIN, RECEPTIONIST (từ chối phòng -> REJECTED)
  static String rejectRoom(String id) => '/rooms/$id/reject';
  /// POST — ADMIN, RECEPTIONIST (rà soát & đồng bộ trạng thái phòng theo lịch đặt)
  static const String roomsSyncStatus = '/rooms/sync-status';
  /// GET — Public
  /// POST — ADMIN
  static const String roomTypes = '/room-types';
  /// GET — Public
  /// PATCH / DELETE — ADMIN
  static String roomTypeDetail(String id) => '/room-types/$id';

  // --- Bookings (§3.5) -------------------------------------------------------
  /// GET — Tất cả role (CUSTOMER tự động bị ép theo customerId)
  /// POST — Tất cả role
  static const String bookings = '/bookings';
  /// GET — Tất cả role (CUSTOMER bị kiểm tra chủ sở hữu)
  static String bookingDetail(String id) => '/bookings/$id';
  /// POST — ADMIN, RECEPTIONIST
  static String checkIn(String id) => '/bookings/$id/check-in';
  /// POST — ADMIN, RECEPTIONIST, CASHIER
  static String checkOut(String id) => '/bookings/$id/check-out';
  /// POST — ADMIN, RECEPTIONIST
  static String addServices(String id) => '/bookings/$id/services';
  /// POST / PATCH — Tất cả role (CUSTOMER chỉ được hủy đơn của mình)
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  /// PATCH / POST — ADMIN, RECEPTIONIST (duyệt đơn đặt phòng & xác nhận cọc)
  static String approveBooking(String id) => '/bookings/$id/approve';
  /// PATCH / POST — ADMIN, RECEPTIONIST
  /// Xác nhận đơn khách tự đặt (PENDING -> CONFIRMED), cho phép xếp lại phòng
  static String confirmBooking(String id) => '/bookings/$id/confirm';
  /// PATCH / POST — ADMIN, RECEPTIONIST (từ chối đơn đặt phòng)
  static String rejectBooking(String id) => '/bookings/$id/reject';

  // --- Invoices (§3.6) -------------------------------------------------------
  /// GET — ADMIN, RECEPTIONIST, CASHIER
  /// POST — ADMIN, CASHIER (lễ tân bị 403, hóa đơn lễ tân sinh từ check-out)
  static const String invoices = '/invoices';
  /// GET — Tất cả role (hóa đơn thuộc đơn của tài khoản đang đăng nhập)
  static const String invoicesMy = '/invoices/my';
  /// GET — ADMIN, RECEPTIONIST, CASHIER
  static const String invoiceSummary = '/invoices/summary';
  /// GET — ADMIN, RECEPTIONIST, CASHIER (CUSTOMER xem được nếu thuộc đơn của mình)
  static String invoiceDetail(String id) => '/invoices/$id';
  /// POST — ADMIN, RECEPTIONIST, CASHIER
  static String payInvoice(String id) => '/invoices/$id/pay';

  // --- Analytics (§3.7) -----------------------------------------------------
  /// GET — ADMIN, RECEPTIONIST, CASHIER
  static const String analyticsDashboard = '/analytics/dashboard';
  /// GET — ADMIN (doanh thu theo năm)
  static const String analyticsRevenue = '/analytics/revenue';
  /// GET — ADMIN, RECEPTIONIST, CASHIER (range = 1|7|14|30)
  static const String analyticsRevenueDaily = '/analytics/revenue/daily';
  /// GET — ADMIN, RECEPTIONIST
  static const String analyticsOccupancyByType = '/analytics/occupancy-by-type';

  // --- Users (§3.2) ----------------------------------------------------------
  /// GET — ADMIN, RECEPTIONIST (lễ tân xem read-only)
  /// POST — ADMIN (tạo tài khoản nhân viên Lễ tân / Thu ngân / Admin)
  static const String users = '/users';
  /// PATCH — Tất cả role (sửa hồ sơ của chính mình)
  static const String usersMe = '/users/me';
  /// GET — ADMIN, RECEPTIONIST
  static String userDetail(String id) => '/users/$id';
  /// PATCH — ADMIN (sửa thông tin và đổi role)
  static String updateUser(String id) => '/users/$id';
  /// DELETE — ADMIN (vô hiệu hóa tài khoản isActive=false)
  static String deleteUser(String id) => '/users/$id';

  // --- Services (§3.8) -------------------------------------------------------
  /// GET — Public
  static const String services = '/services';

  // --- Upload (§3.9) ---------------------------------------------------------
  /// POST — Tất cả role (tự cập nhật hồ sơ khi updateProfile=true)
  static const String uploadAvatar = '/upload/avatar';
  /// POST — ADMIN, RECEPTIONIST (1 ảnh gắn vào roomId hoặc roomTypeId)
  static const String uploadRoom = '/upload/room';
  /// POST — ADMIN, RECEPTIONIST (album ảnh gắn vào roomId)
  static const String uploadRooms = '/upload/rooms';
  /// POST — Tất cả role (1 ảnh đa năng)
  static const String uploadImage = '/upload/image';
  /// POST — Tất cả role (nhiều ảnh đa năng, tối đa 10)
  static const String uploadImages = '/upload/images';
  /// DELETE — Tất cả role (xóa ảnh theo query param `path`)
  static const String uploadDelete = '/upload';
}
