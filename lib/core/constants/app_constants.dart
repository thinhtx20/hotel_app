class AppConstants {
  static const String appName = 'Luxe Grand Hotel';

  // Base API URLs
  static const String productionApiUrl = 'https://hotel-management-plsp.onrender.com/api/v1';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:3000/api/v1';
  static const String defaultLocalhostUrl = 'http://localhost:3000/api/v1';
  
  // Storage Keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userKey = 'userData';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
