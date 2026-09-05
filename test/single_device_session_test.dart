import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_error.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/storage/token_storage.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_event.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Single Device Session & 401 Handling Tests', () {
    test('SESSION_REVOKED: Xóa token, kích hoạt onSessionExpired, không gọi refresh-token', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.saveTokens(
        accessToken: 'old_access_token',
        refreshToken: 'old_refresh_token',
      );

      String? expiredReason;
      DioClient.onSessionExpired = (msg) {
        expiredReason = msg;
      };

      int refreshTokenCallCount = 0;
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockSessionAdapter(
        onRefreshTokenCalled: () => refreshTokenCallCount++,
        returnSessionRevoked: true,
      );

      try {
        await dioClient.dio.get('/rooms');
        fail('Phải ném DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ApiError>());
        final apiError = e.error as ApiError;
        expect(apiError.errorType, 'SESSION_REVOKED');
        expect(apiError.displayMessage, contains('Tài khoản vừa đăng nhập ở thiết bị khác'));
      }

      // Đảm bảo không gọi refresh-token
      expect(refreshTokenCallCount, 0);

      // Đảm bảo token đã bị xóa
      final savedAccess = await tokenStorage.getAccessToken();
      expect(savedAccess, isNull);

      // Đảm bảo onSessionExpired đã được kích hoạt
      expect(expiredReason, contains('Tài khoản vừa đăng nhập ở thiết bị khác'));
    });

    test('SESSION_DEVICE_LIMIT: Báo khách đăng xuất máy kia trước, không gọi refresh-token', () async {
      int refreshTokenCallCount = 0;

      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = _MockSessionAdapter(
        onRefreshTokenCalled: () => refreshTokenCallCount++,
        returnSessionDeviceLimit: true,
      );

      try {
        await dioClient.dio.post('/auth/login', data: {
          'email': 'customer@hotel.com',
          'password': 'Password@123',
        });
        fail('Phải ném DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ApiError>());
        final apiError = e.error as ApiError;
        expect(apiError.errorType, 'SESSION_DEVICE_LIMIT');
        expect(apiError.displayMessage, contains('đăng xuất'));
      }

      expect(refreshTokenCallCount, 0);
    });

    test('AuthBloc phản hồi sự kiện AuthSessionRevoked bằng AuthFailure và dọn dẹp cache', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.saveTokens(accessToken: 'token', refreshToken: 'refresh');

      bool cacheCleared = false;
      final authBloc = AuthBloc(
        tokenStorage: tokenStorage,
        onSessionReset: () => cacheCleared = true,
      );

      final states = <AuthState>[];
      final sub = authBloc.stream.listen(states.add);

      authBloc.add(const AuthSessionRevoked(reason: 'Tài khoản vừa đăng nhập ở thiết bị khác'));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(cacheCleared, isTrue);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(states.length, 1);
      expect(states.first, isA<AuthFailure>());
      expect((states.first as AuthFailure).message, contains('Tài khoản vừa đăng nhập ở thiết bị khác'));

      await sub.cancel();
      await authBloc.close();
    });
  });
}

class _MockSessionAdapter implements HttpClientAdapter {
  final VoidCallback onRefreshTokenCalled;
  final bool returnSessionRevoked;
  final bool returnSessionDeviceLimit;

  _MockSessionAdapter({
    required this.onRefreshTokenCalled,
    this.returnSessionRevoked = false,
    this.returnSessionDeviceLimit = false,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/refresh-token')) {
      onRefreshTokenCalled();
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'message': 'Refresh token failed'}),
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (returnSessionRevoked) {
      return ResponseBody.fromString(
        jsonEncode({
          'statusCode': 401,
          'success': false,
          'error': 'SESSION_REVOKED',
          'message': 'SESSION_REVOKED',
        }),
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (returnSessionDeviceLimit) {
      return ResponseBody.fromString(
        jsonEncode({
          'statusCode': 401,
          'success': false,
          'error': 'SESSION_DEVICE_LIMIT',
          'message': 'SESSION_DEVICE_LIMIT',
        }),
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
