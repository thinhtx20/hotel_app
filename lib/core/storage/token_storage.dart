import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage({FlutterSecureStorage? storage}) {
    if (storage != null) {
      return TokenStorage._internal(storage: storage);
    }
    return _instance;
  }

  final FlutterSecureStorage _storage;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  UserModel? _cachedUser;

  TokenStorage._internal({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    try {
      await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
      await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    try {
      _cachedAccessToken = await _storage.read(key: AppConstants.accessTokenKey);
      return _cachedAccessToken;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    try {
      _cachedRefreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      return _cachedRefreshToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    try {
      await _storage.write(key: AppConstants.userKey, value: user.toJsonString());
    } catch (_) {}
  }

  Future<UserModel?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final raw = await _storage.read(key: AppConstants.userKey);
      if (raw == null) return null;
      _cachedUser = UserModel.fromJsonString(raw);
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
