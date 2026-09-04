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
    } catch (_) {
      // Khi refresh token cũng hết hạn, xóa token để buộc user đăng nhập lại
      await _tokenStorage.clearAll();
    }
    return false;
  }
}
