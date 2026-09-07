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
  /// PUT / PATCH — ADMIN (Cập nhật thông tin phòng toàn diện tại /api/v1/rooms/:id)
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
  /// GET — Public (SSE stream realtime trạng thái phòng)
  static const String roomsStream = '/rooms/stream';
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
  /// Nhận `amountCollected` = số thu ngân thực nhận; bỏ trống = không thu thêm
  /// (khách vẫn trả phòng, hóa đơn ở PARTIAL/UNPAID).
  static String checkOut(String id) => '/bookings/$id/check-out';
  /// GET — ADMIN, RECEPTIONIST, CASHIER (bảng kê & `amountDue` trước khi trả
  /// phòng — chỉ đọc, không đổi trạng thái đơn/phòng)
  static String checkOutPreview(String id) => '/bookings/$id/checkout-preview';
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
  /// POST — ADMIN, RECEPTIONIST (Đổi phòng cho khách lưu trú S2)
  static String changeRoom(String bookingId) => '/bookings/$bookingId/change-room';
  /// POST — CUSTOMER (Khách đặt dịch vụ tại phòng C1)
  static String serviceRequests(String bookingId) => '/bookings/$bookingId/service-requests';
  /// PATCH — ADMIN, RECEPTIONIST (Duyệt / từ chối yêu cầu dịch vụ)
  static String updateServiceRequest(String bookingId, String orderId) =>
      '/bookings/$bookingId/services/$orderId';

  // --- Invoices (§3.6) -------------------------------------------------------
  /// GET — ADMIN, RECEPTIONIST
  /// POST — ADMIN, RECEPTIONIST (mở tạo thủ công cho Lễ tân - Thu ngân)
  static const String invoices = '/invoices';
  /// GET — Tất cả role (hóa đơn thuộc đơn của tài khoản đang đăng nhập)
  static const String invoicesMy = '/invoices/my';
  /// GET — ADMIN, RECEPTIONIST
  static const String invoiceSummary = '/invoices/summary';
  /// GET — ADMIN, RECEPTIONIST (CUSTOMER xem được nếu thuộc đơn của mình)
  static String invoiceDetail(String id) => '/invoices/$id';
  /// POST — ADMIN, RECEPTIONIST (thu tại quầy — ghi thẳng một dòng đã xác nhận)
  static String payInvoice(String id) => '/invoices/$id/pay';
  /// POST — ADMIN, RECEPTIONIST (Hoàn tiền S4)
  static String invoiceRefund(String id) => '/invoices/$id/refund';
  /// POST — CUSTOMER (khách xin trả số còn lại; bỏ trống `amount` = trả toàn bộ).
  /// Tạo một dòng PENDING trong sổ thu tiền, `paidAmount` **chưa** đổi.
  /// Mỗi hóa đơn chỉ treo được một yêu cầu tại một thời điểm.
  static String invoicePaymentRequest(String id) =>
      '/invoices/$id/payment-requests';
  /// GET — ADMIN, RECEPTIONIST (danh sách yêu cầu khách gửi qua app, chờ đối
  /// chiếu sao kê)
  static const String invoicePaymentRequests = '/invoices/payment-requests';
  /// POST — ADMIN, RECEPTIONIST (xác nhận đã nhận tiền → `paidAmount` mới tăng)
  static String confirmInvoicePayment(String paymentId) =>
      '/invoices/payments/$paymentId/confirm';

  // --- Analytics (§3.7) -----------------------------------------------------
  /// GET — ADMIN, RECEPTIONIST
  static const String analyticsDashboard = '/analytics/dashboard';
  /// GET — ADMIN (doanh thu theo năm)
  static const String analyticsRevenue = '/analytics/revenue';
  /// GET — ADMIN (danh sách các năm có doanh thu)
  static const String analyticsRevenueYears = '/analytics/revenue/years';
  /// GET — ADMIN (xuất báo cáo doanh thu CSV A3)
  static const String revenueExport = '/analytics/revenue/export';
  /// GET — ADMIN (hiệu suất nhân viên A1)
  static const String staffPerformance = '/analytics/staff-performance';
  /// GET — ADMIN, RECEPTIONIST (range = 1|7|14|30)
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
  /// PATCH — ADMIN (sửa thông tin, đổi role, mở/khóa thủ công isActive: true|false — update-user.dto.ts:26-29)
  static String updateUser(String id) => '/users/$id';
  /// DELETE — ADMIN (khóa tài khoản bằng soft-delete isActive=false — users.service.ts:146-152)
  static String deleteUser(String id) => '/users/$id';
  /// PATCH / POST — ADMIN (đổi / đặt lại mật khẩu cho tài khoản người dùng)
  static String changeUserPassword(String id) => '/users/$id/password';
  /// GET — ADMIN (SSE stream realtime danh sách người dùng)
  static const String usersStream = '/users/stream';

  // --- Services (§3.8 & A2) --------------------------------------------------
  /// GET — Public, POST — ADMIN
  static const String services = '/services';
  static const String hotelServices = '/services';
  /// PATCH / DELETE — ADMIN
  static String serviceDetail(String id) => '/services/$id';

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

  // --- Shifts (Quản lý Ca trực & Bàn giao tiền két) -------------------------
  /// POST — ADMIN, RECEPTIONIST (Mở ca trực quầy)
  static const String shiftsOpen = '/shifts/open';
  /// GET — ADMIN, RECEPTIONIST (Ca trực hiện tại của user đăng nhập)
  static const String shiftsCurrent = '/shifts/current';
  /// GET — ADMIN, RECEPTIONIST (Danh sách ca trực đang OPEN tại quầy)
  static const String shiftsActive = '/shifts/active';
  /// POST — ADMIN, RECEPTIONIST (Chốt ca trực của chính mình)
  static const String shiftsClose = '/shifts/close';
  /// POST — ADMIN (Admin cưỡng chế chốt ca hộ cho nhân viên)
  static String adminCloseShift(String id) => '/shifts/$id/close';
  /// GET — ADMIN, RECEPTIONIST (Lịch sử ca trực & sổ giao ca, hỗ trợ phân trang & lọc)
  static const String shifts = '/shifts';
  /// GET — ADMIN, RECEPTIONIST (Chi tiết ca trực & các giao dịch trong ca)
  static String shiftDetail(String id) => '/shifts/$id';
}
