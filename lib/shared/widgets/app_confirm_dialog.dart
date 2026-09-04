import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'app_bottom_sheet.dart';

/// Hộp thoại xác nhận chung cho toàn bộ ứng dụng (Đăng xuất, Huỷ đơn, Từ chối phòng, Thanh toán).
/// Xem `design/UI-REVAMP-PLAN.md` mục 4.4.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    this.icon = Icons.help_outline_rounded,
    this.isDanger = false,
    required this.onConfirm,
    this.onCancel,
  });

  /// Hiển thị hộp thoại xác nhận dạng Bottom Sheet chuẩn Modern Luxury
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    IconData icon = Icons.help_outline_rounded,
    bool isDanger = false,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDanger: isDanger,
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm();
        },
        onCancel: () {
          Navigator.of(ctx).pop(false);
          onCancel?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final primaryActionColor = isDanger ? palette.error : palette.accent;

    return AppBottomSheet(
      showDragHandle: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon nổi bật
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryActionColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryActionColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: primaryActionColor,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tiêu đề
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Nội dung giải thích
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Hàng nút tương tác
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: palette.border, width: 1.2),
                    backgroundColor: palette.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonR,
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.buttonR,
                    ),
                  ),
                  icon: Icon(icon, size: 18),
                  label: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
