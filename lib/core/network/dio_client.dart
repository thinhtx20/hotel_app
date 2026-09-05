import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_error.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();
  Completer<bool>? _refreshCompleter;

  // Mặc định sử dụng API Server trên Render
  static String get defaultBaseUrl {
    return AppConstants.productionApiUrl;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final reqOptions = error.requestOptions;
          final isRetry = reqOptions.extra['_retry'] == true;

          // Bắt theo trường error trong response 401:
          // - SESSION_REVOKED: xóa token, báo "tài khoản vừa đăng nhập ở thiết bị khác",
          //   về màn đăng nhập. Không gọi refresh-token để thử lại.
          // - SESSION_DEVICE_LIMIT: xuất hiện ở chế độ block_new, báo khách đăng xuất máy kia trước.
          if (error.response?.statusCode == 401) {
            final resData = error.response?.data;
            String? errorField;
            String? messageField;
            if (resData is Map) {
              errorField = resData['error']?.toString();
              messageField = resData['message']?.toString();
            }

            final isSessionRevoked =
                errorField == 'SESSION_REVOKED' || messageField == 'SESSION_REVOKED';
            final isDeviceLimit =
                errorField == 'SESSION_DEVICE_LIMIT' || messageField == 'SESSION_DEVICE_LIMIT';

            if (isSessionRevoked) {
              await _tokenStorage.clearAll();
              const reason = 'Tài khoản vừa đăng nhập ở thiết bị khác';
              onSessionExpired?.call(reason);
              final apiError = ApiError(
                statusCode: 401,
                message: reason,
                errorType: 'SESSION_REVOKED',
                path: reqOptions.path,
              );
              return handler.next(error.copyWith(error: apiError));
            }

            if (isDeviceLimit) {
              const reason =
                  'Tài khoản đã đăng nhập ở thiết bị khác. Vui lòng đăng xuất máy kia trước.';
              final apiError = ApiError(
                statusCode: 401,
                message: reason,
                errorType: 'SESSION_DEVICE_LIMIT',
                path: reqOptions.path,
              );
              return handler.next(error.copyWith(error: apiError));
            }
          }

          // Bắt lỗi 401 để tự động Refresh Token nếu chưa retry
          if (error.response?.statusCode == 401 &&
              !isRetry &&
              !reqOptions.path.contains(ApiEndpoints.login) &&
              !reqOptions.path.contains(ApiEndpoints.refreshToken) &&
              !reqOptions.path.contains(ApiEndpoints.logout)) {
            final refreshed = await _refreshTokenWithMutex();
            if (refreshed) {
              final retryToken = await _tokenStorage.getAccessToken();
              final clonedHeaders = Map<String, dynamic>.from(reqOptions.headers);
              if (retryToken != null && retryToken.isNotEmpty) {
                clonedHeaders['Authorization'] = 'Bearer $retryToken';
              }
              final clonedExtra = Map<String, dynamic>.from(reqOptions.extra)
                ..['_retry'] = true;

              try {
                final cloneReq = await dio.request(
                  reqOptions.path,
                  options: Options(
                    method: reqOptions.method,
                    headers: clonedHeaders,
                    extra: clonedExtra,
                  ),
                  data: reqOptions.data,
                  queryParameters: reqOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              } on DioException catch (e) {
                final retryApiError = ApiError.fromDioException(e);
                return handler.next(e.copyWith(error: retryApiError));
              }
            }
          }
          final apiError = ApiError.fromDioException(error);
          return handler.next(
            error.copyWith(error: apiError),
          );
        },
      ),
    );
  }

  void setBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }

  /// Quản lý Mutex để chỉ có 1 request thực hiện refresh token tại một thời điểm
  Future<bool> _refreshTokenWithMutex() async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final success = await _handleRefreshToken();
      completer.complete(success);
      return success;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Callback khi phiên đăng nhập hết hạn hoặc tài khoản bị khóa giữa phiên
  static void Function(String message)? onSessionExpired;

  Future<bool> _handleRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final newAccess = response.data['data']['accessToken'] as String?;
        final newRefresh = response.data['data']['refreshToken'] as String?;

        if (newAccess != null && newRefresh != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
    } catch (e) {
      // Khi refresh token bị chặn (auth.service.ts:530-532) hoặc hết hạn, xóa token
      await _tokenStorage.clearAll();
      String reason = 'Phiên đăng nhập đã hết hạn hoặc tài khoản đã bị khóa.';
      if (e is DioException) {
        final err = ApiError.fromDioException(e);
        if (err.message.isNotEmpty) {
          reason = err.displayMessage;
        }
      }
      onSessionExpired?.call(reason);
    }
    return false;
  }
}
