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

  // Rooms & Room Types
  static const String rooms = '/rooms';
  static const String roomsSearch = '/rooms/search';
  static const String roomsAvailable = '/rooms/available';
  static String roomDetail(String id) => '/rooms/$id';
  static String updateRoomStatus(String id) => '/rooms/$id/status';
  static String approveRoom(String id) => '/rooms/$id/approve';
  static String rejectRoom(String id) => '/rooms/$id/reject';
  static const String roomTypes = '/room-types';

  // Bookings
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';
  static String checkIn(String id) => '/bookings/$id/check-in';
  static String checkOut(String id) => '/bookings/$id/check-out';
  static String addServices(String id) => '/bookings/$id/services';
  static String cancelBooking(String id) => '/bookings/$id/cancel';

  // Invoices
  static const String invoices = '/invoices';
  static String invoiceDetail(String id) => '/invoices/$id';
  static String payInvoice(String id) => '/invoices/$id/pay';

  // Analytics
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsRevenue = '/analytics/revenue';
  static const String analyticsRevenueDaily = '/analytics/revenue/daily';
  static const String analyticsOccupancyByType = '/analytics/occupancy-by-type';

  // Users
  static const String users = '/users';
}
