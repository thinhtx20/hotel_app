import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_error.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();

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
          // Bắt lỗi 401 để tự động Refresh Token
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh-token')) {
            final refreshed = await _handleRefreshToken();
            if (refreshed) {
              final retryToken = await _tokenStorage.getAccessToken();
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $retryToken';

              try {
                final cloneReq = await dio.request(
                  options.path,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                  data: options.data,
                  queryParameters: options.queryParameters,
                );
                return handler.resolve(cloneReq);
              } on DioException catch (e) {
                return handler.next(e);
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
        '/auth/refresh-token',
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
