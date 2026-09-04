class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

  // Rooms & Room Types
  static const String rooms = '/rooms';
  static const String roomsSearch = '/rooms/search';
  static const String roomsAvailable = '/rooms/available';
  static String roomDetail(String id) => '/rooms/$id';
  static String updateRoom(String id) => '/rooms/$id';
  static String deleteRoom(String id) => '/rooms/$id';
  static String updateRoomStatus(String id) => '/rooms/$id/status';
  static String approveRoom(String id) => '/rooms/$id/approve';
  static String rejectRoom(String id) => '/rooms/$id/reject';
  static const String roomTypes = '/room-types';
  static String roomTypeDetail(String id) => '/room-types/$id';

  // Bookings
  static const String bookings = '/bookings';
  static const String todayCheckIns = '/bookings/today/check-ins';
  static const String todayCheckOuts = '/bookings/today/check-outs';
  static const String pendingBookings = '/bookings/pending';
  static String bookingDetail(String id) => '/bookings/$id';
  static String checkIn(String id) => '/bookings/$id/check-in';
  static String checkOut(String id) => '/bookings/$id/check-out';
  static String approveBooking(String id) => '/bookings/$id/approve';
  static String rejectBooking(String id) => '/bookings/$id/reject';
  static String addServices(String id) => '/bookings/$id/services';
  static String cancelBooking(String id) => '/bookings/$id/cancel';

  // Invoices
  static const String invoices = '/invoices';

  /// Hóa đơn của chính tài khoản đang đăng nhập — endpoint duy nhất ở nhóm
  /// hóa đơn mà CUSTOMER gọi được (xem `design/FE-ROLE-MATRIX.md` §3.6).
  static const String invoicesMy = '/invoices/my';
  static const String invoiceSummary = '/invoices/summary';
  static String invoiceDetail(String id) => '/invoices/$id';
  static String payInvoice(String id) => '/invoices/$id/pay';

  // Analytics
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsRevenue = '/analytics/revenue';
  static const String analyticsRevenueDaily = '/analytics/revenue/daily';
  static const String analyticsOccupancyByType = '/analytics/occupancy-by-type';
  static const String analyticsOccupancyDetail = '/analytics/occupancy/detail';

  // Users
  static const String users = '/users';
  static const String usersMe = '/users/me';
  static String userDetail(String id) => '/users/$id';
  static String updateUser(String id) => '/users/$id';
  static String deleteUser(String id) => '/users/$id';

  // Services
  static const String services = '/services';
}
