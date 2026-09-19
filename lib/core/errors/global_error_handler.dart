import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/app_global_error_widget.dart';

/// Bộ điều phối & hứng lỗi toàn cục (Global Error Handling Shield).
///
/// Thiết lập hệ thống phòng vệ 3 lớp cấp runtime của Flutter:
/// 1. [FlutterError.onError]: Bắt lỗi đồng bộ / framework (render, build, layout phase).
/// 2. [PlatformDispatcher.instance.onError]: Bắt lỗi bất đồng bộ chưa được xử lý (root isolate, microtask, async future).
/// 3. [ErrorWidget.builder]: Thay thế màn hình đỏ/xám mặc định bằng UI Luxury Fallback.
class GlobalErrorHandler {
  static bool _initialized = false;

  /// Khởi tạo toàn bộ các chốt chặn hứng lỗi toàn cục.
  /// Được gọi ngay trong hàm `main()`.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Chốt chặn Framework & Widget Render Errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      } else {
        debugPrint('⚠️ [FlutterError] ${details.exceptionAsString()}');
      }
    };

    // 2. Chốt chặn Async Uncaught Exceptions (Root Isolate & Microtasks)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('🚨 [PlatformDispatcher] Unhandled Async Error: $error');
      if (kDebugMode) {
        debugPrint('StackTrace: $stack');
      }

      // Trả về true để thông báo cho Flutter runtime rằng ngoại lệ đã được hứng an toàn,
      // ngăn ngừa văng app (crash root isolate).
      return true;
    };

    // 3. Chốt chặn Render Crash: Thay thế Red/Grey Screen of Death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return AppGlobalErrorFallbackWidget(details: details);
    };
  }

  /// Ghi nhận thủ công một lỗi đã được bắt (để log hoặc tích hợp telemetry sau này).
  static void reportError(Object error, StackTrace? stack, {String? reason}) {
    debugPrint('📌 [HandledError] ${reason != null ? "[$reason] " : ""}$error');
    if (kDebugMode && stack != null) {
      debugPrint('$stack');
    }
  }
}
