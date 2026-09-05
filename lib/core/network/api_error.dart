import 'package:dio/dio.dart';

/// Đại diện cho lỗi được trả về từ Backend (NestJS) hoặc lỗi kết nối.
///
/// Định dạng chuẩn của Backend:
/// ```json
/// {
///   "statusCode": 400,
///   "success": false,
///   "message": "email phải đúng định dạng. mật khẩu tối thiểu 6 ký tự",
///   "error": "Bad Request",
///   "errors": [
///     "email phải đúng định dạng",
///     "mật khẩu tối thiểu 6 ký tự"
///   ],
///   "timestamp": "2026-09-03T07:02:00.418Z",
///   "path": "/api/v1/auth/login"
/// }
/// ```
class ApiError implements Exception {
  final int? statusCode;
  final String message;
  final List<String> errors;
  final String? errorType;
  final String? path;
  final bool isNetworkError;

  const ApiError({
    this.statusCode,
    required this.message,
    this.errors = const [],
    this.errorType,
    this.path,
    this.isNetworkError = false,
  });

  /// Trích xuất toàn bộ thông tin lỗi từ [DioException] do Backend trả về.
  factory ApiError.fromDioException(DioException e) {
    // 1. Kiểm tra xem Backend có trả về Response hay không
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      final statusCode = e.response?.statusCode;

      if (data is Map<String, dynamic>) {
        final rawMessage = data['message'];
        final rawErrors = data['errors'];
        final errorType = data['error']?.toString();
        final path = data['path']?.toString();

        List<String> parsedErrors = [];
        if (rawErrors is List) {
          parsedErrors = rawErrors.map((item) => item.toString()).toList();
        }

        String finalMessage = '';
        if (rawMessage is List) {
          parsedErrors = rawMessage.map((item) => item.toString()).toList();
          finalMessage = parsedErrors.join('\n');
        } else if (rawMessage != null && rawMessage.toString().trim().isNotEmpty) {
          finalMessage = rawMessage.toString();
        } else if (parsedErrors.isNotEmpty) {
          finalMessage = parsedErrors.join('\n');
        } else if (errorType != null && errorType.isNotEmpty) {
          finalMessage = errorType;
        } else {
          finalMessage = _getDefaultStatusMessage(statusCode);
        }

        // Xử lý mã lỗi đơn phiên đăng nhập (Single Device Session)
        if (errorType == 'SESSION_REVOKED' || finalMessage == 'SESSION_REVOKED') {
          finalMessage = 'Tài khoản vừa đăng nhập ở thiết bị khác.';
        } else if (errorType == 'SESSION_DEVICE_LIMIT' || finalMessage == 'SESSION_DEVICE_LIMIT') {
          finalMessage = 'Tài khoản đã đăng nhập ở thiết bị khác. Vui lòng đăng xuất máy kia trước.';
        } else if (statusCode == 403 &&
            finalMessage.contains('Quyền truy cập bị từ chối: Yêu cầu vai trò')) {
          // FE-ROLE-MATRIX.md §2: Ẩn nguyên văn danh sách role nội bộ khi gặp lỗi 403
          finalMessage = 'Bạn không có quyền thực hiện thao tác này.';
        }

        return ApiError(
          statusCode: statusCode,
          message: finalMessage,
          errors: parsedErrors,
          errorType: errorType,
          path: path,
          isNetworkError: false,
        );
      } else if (data is String && data.trim().isNotEmpty) {
        String msg = data;
        if (statusCode == 403 && msg.contains('Quyền truy cập bị từ chối: Yêu cầu vai trò')) {
          msg = 'Bạn không có quyền thực hiện thao tác này.';
        }
        return ApiError(
          statusCode: statusCode,
          message: msg,
          isNetworkError: false,
        );
      }
    }

    // 2. Không nhận được phản hồi từ Backend (Lỗi đường truyền / Timeout / Mất mạng)
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(
          message: 'Kết nối máy chủ quá thời gian. Vui lòng kiểm tra lại mạng.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return const ApiError(
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra đường truyền mạng hoặc cấu hình Base URL.',
          isNetworkError: true,
        );
      case DioExceptionType.badCertificate:
        return const ApiError(
          message: 'Chứng chỉ bảo mật máy chủ không hợp lệ.',
          isNetworkError: true,
        );
      case DioExceptionType.cancel:
        return const ApiError(
          message: 'Yêu cầu tới máy chủ đã bị hủy.',
          isNetworkError: false,
        );
      case DioExceptionType.unknown:
      default:
        return ApiError(
          message: e.message ?? 'Đã xảy ra lỗi kết nối, vui lòng thử lại.',
          isNetworkError: true,
        );
    }
  }

  /// Chuyển đổi linh hoạt từ bất kỳ đối tượng lỗi nào (DioException, String, Exception, ApiResponse...)
  factory ApiError.fromDynamic(dynamic error) {
    if (error is ApiError) {
      return error;
    }
    if (error is DioException) {
      return ApiError.fromDioException(error);
    }
    // Hỗ trợ trường hợp truyền ApiResponse lỗi
    if (error != null && error is! String && error is! Exception) {
      try {
        final dyn = error as dynamic;
        if (dyn.statusCode != null && dyn.errorMessage != null) {
          return ApiError(
            statusCode: dyn.statusCode as int?,
            message: dyn.errorMessage.toString(),
            isNetworkError: false,
          );
        }
      } catch (_) {}
    }
    if (error is String) {
      return ApiError(message: error);
    }
    if (error is Exception) {
      return ApiError(message: error.toString().replaceFirst('Exception: ', ''));
    }
    return ApiError(message: error?.toString() ?? 'Đã xảy ra lỗi, vui lòng thử lại.');
  }

  /// Chuỗi thông điệp chi tiết để hiển thị lên giao diện
  String get displayMessage {
    if (errorType == 'SESSION_REVOKED' || message == 'SESSION_REVOKED') {
      return 'Tài khoản vừa đăng nhập ở thiết bị khác.';
    }
    if (errorType == 'SESSION_DEVICE_LIMIT' || message == 'SESSION_DEVICE_LIMIT') {
      return 'Tài khoản đã đăng nhập ở thiết bị khác. Vui lòng đăng xuất máy kia trước.';
    }
    if (statusCode == 403 &&
        message.contains('Quyền truy cập bị từ chối: Yêu cầu vai trò')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    return message;
  }

  /// Kiểm tra có danh sách lỗi con hay không
  bool get hasDetailedErrors => errors.isNotEmpty;

  static String _getDefaultStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ (400).';
      case 401:
        return 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 409:
        return 'Dữ liệu đã tồn tại hoặc xảy ra xung đột.';
      case 500:
        return 'Lỗi hệ thống máy chủ. Vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi (mã $statusCode), vui lòng thử lại.';
    }
  }

  @override
  String toString() => 'ApiError(code: $statusCode, message: $message, errors: $errors)';
}
