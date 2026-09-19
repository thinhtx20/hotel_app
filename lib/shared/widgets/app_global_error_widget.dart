import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';

/// Widget thay thế màn hình đỏ/xám khi xảy ra lỗi render (ErrorWidget.builder).
///
/// Thiết kế theo phong cách Modern Luxury, tự động thích ứng với cả
/// vùng hiển thị nhỏ (component level) và toàn màn hình (screen level).
class AppGlobalErrorFallbackWidget extends StatefulWidget {
  final FlutterErrorDetails details;

  const AppGlobalErrorFallbackWidget({
    super.key,
    required this.details,
  });

  @override
  State<AppGlobalErrorFallbackWidget> createState() =>
      _AppGlobalErrorFallbackWidgetState();
}

class _AppGlobalErrorFallbackWidgetState
    extends State<AppGlobalErrorFallbackWidget> {
  bool _showDebugDetails = false;

  void _handleGoHome() {
    try {
      if (AppRouter.router != null) {
        AppRouter.router!.go('/');
        return;
      }
      final nav = AppRouter.rootNavigatorKey.currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('⚠️ [ErrorWidget] Không thể điều hướng về trang chủ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo luôn có Directionality và Material dù Error xảy ra ở bất kỳ tầng nào
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Trường hợp lỗi xảy ra trong một thành phần giao diện nhỏ (card, list item)
            if (constraints.maxHeight < 180 || constraints.maxWidth < 200) {
              return _buildCompactErrorView();
            }
            // Trường hợp lỗi toàn màn hình hoặc vùng lớn
            return _buildFullScreenErrorView(context);
          },
        ),
      ),
    );
  }

  /// Giao diện lỗi tinh gọn cho component nhỏ
  Widget _buildCompactErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: AppColors.error,
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Lỗi kết xuất thành phần',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện lỗi đầy đủ chuẩn Modern Luxury
  Widget _buildFullScreenErrorView(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon chỉ báo lỗi phong cách Luxury
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.error,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),

              // Tiêu đề
              const Text(
                'Đã xảy ra sự cố hiển thị',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Thông điệp thân thiện với khách hàng
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: const Text(
                  'Ứng dụng gặp lỗi trong quá trình kết xuất giao diện. Hệ thống đã ghi nhận sự cố để đội ngũ kỹ thuật khắc phục.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // Các nút hành động phục hồi luồng
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _handleGoHome,
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text(
                      'Về trang chủ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),

              // Khu vực hiển thị thông tin kỹ thuật (chỉ trong Debug mode)
              if (kDebugMode) ...[
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showDebugDetails = !_showDebugDetails;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bug_report_outlined,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Chi tiết lỗi kỹ thuật (Debug Mode)',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                _showDebugDetails
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showDebugDetails) ...[
                        const Divider(height: 1, color: AppColors.border),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E293B),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.details.exceptionAsString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFFF87171),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
