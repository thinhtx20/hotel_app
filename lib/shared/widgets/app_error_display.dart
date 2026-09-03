import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_error.dart';

/// Bộ hiển thị thông báo & lỗi chuyên biệt theo phong cách Modern Luxury.
/// Tự động trích xuất và hiển thị trọn vẹn thông điệp do Backend NestJS trả về.
class AppNotification {
  /// Global Key cho ScaffoldMessenger để có thể hiển thị thông báo từ bất kỳ đâu.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Hiển thị thông báo LỖI (Error) nổi trên màn hình.
  ///
  /// [error] có thể là [ApiError], [DioException], [String] hoặc [Exception].
  /// Toàn bộ thông điệp trả về từ BE sẽ được ưu tiên hiển thị chính xác.
  static void showError(
    BuildContext? context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final apiError = ApiError.fromDynamic(error);
    final messenger = _getMessenger(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột chỉ báo màu đỏ sang trọng
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Icon cảnh báo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Nội dung lỗi do BE trả về
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title ?? (apiError.isNetworkError ? 'Lỗi kết nối' : 'Thông báo lỗi'),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.occupiedInk,
                          ),
                        ),
                        if (apiError.statusCode != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${apiError.statusCode}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.errorInk,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      apiError.displayMessage,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    // Hiển thị danh sách chi tiết nếu BE trả về nhiều lỗi validation
                    if (apiError.errors.length > 1) ...[
                      const SizedBox(height: 6),
                      ...apiError.errors.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: AppColors.occupiedInk,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Nút Retry hoặc nút Đóng
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onRetry();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => messenger.hideCurrentSnackBar(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4, top: 2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị thông báo THÀNH CÔNG (Success)
  static void showSuccess(
    BuildContext? context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = _getMessenger(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.available.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.available,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.availableInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Thành công',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.availableInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị thông báo CẢNH BÁO (Warning)
  static void showWarning(
    BuildContext? context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = _getMessenger(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warningInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Lưu ý',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ScaffoldMessengerState? _getMessenger(BuildContext? context) {
    if (context != null) {
      try {
        return ScaffoldMessenger.of(context);
      } catch (_) {}
    }
    return messengerKey.currentState;
  }
}

/// Hộp thoại thông báo lỗi Modal phong cách Modern Luxury.
class AppErrorDialog {
  static Future<void> show(
    BuildContext context, {
    required dynamic error,
    String? title,
    VoidCallback? onRetry,
  }) async {
    final apiError = ApiError.fromDynamic(error);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        elevation: 8,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon lỗi
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorInk,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                title ?? (apiError.isNetworkError ? 'Lỗi kết nối' : 'Đã xảy ra lỗi'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Thông điệp từ BE
              Text(
                apiError.displayMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              // Danh sách sub-errors nếu có
              if (apiError.errors.length > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: apiError.errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: AppColors.errorInk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Các nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onRetry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Thử lại',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị lỗi trạng thái toàn màn hình hoặc một khu vực nội dung
/// khi gọi API thất bại.
class AppErrorView extends StatelessWidget {
  final dynamic error;
  final String? title;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  const AppErrorView({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final apiError = ApiError.fromDynamic(error);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                apiError.isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: AppColors.errorInk,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title ?? (apiError.isNetworkError ? 'Mất kết nối' : 'Không thể tải dữ liệu'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                apiError.displayMessage,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
