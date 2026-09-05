import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  /// Bỏ trống với vai trò không được `POST /invoices/:id/pay` (khách hàng) —
  /// nút "Ghi nhận Thu tiền" sẽ không hiện.
  final VoidCallback? onCollectPayment;
  final VoidCallback? onViewReceipt;

  /// Nút "Thanh toán toàn bộ" của khách — `POST /invoices/:id/payment-requests`.
  /// Chỉ truyền ở app khách; nhân viên dùng [onCollectPayment].
  final VoidCallback? onRequestPayment;

  /// Đang gửi yêu cầu thanh toán cho chính hóa đơn này.
  final bool isRequestingPayment;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    this.onCollectPayment,
    this.onViewReceipt,
    this.onRequestPayment,
    this.isRequestingPayment = false,
  });

  Widget _buildStatusBadge(BuildContext context, InvoiceModel inv) {
    final palette = context.palette;
    final statusUpper = inv.paymentStatus.toUpperCase();
    final isPaid = statusUpper == 'PAID' || inv.remainingAmount <= 0;
    final isPartial = statusUpper == 'PARTIAL' || (inv.paidAmount > 0 && inv.remainingAmount > 0);

    Color bg;
    Color fg;
    String label;

    if (isPaid) {
      bg = palette.statusAvailable.withValues(alpha: 0.15);
      fg = palette.statusAvailableInk;
      label = 'ĐÃ HOÀN TẤT';
    } else if (isPartial) {
      bg = palette.statusReserved.withValues(alpha: 0.15);
      fg = palette.statusReservedInk;
      label = 'THANH TOÁN 1 PHẦN';
    } else {
      bg = palette.statusOccupied.withValues(alpha: 0.15);
      fg = palette.statusOccupiedInk;
      label = 'CHƯA THANH TOÁN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isPaid = invoice.paymentStatus.toUpperCase() == 'PAID' || invoice.remainingAmount <= 0;
    final ratio = invoice.finalAmount > 0
        ? (invoice.paidAmount / invoice.finalAmount).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon box + Code + Guest + Status Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: palette.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${invoice.displayCode}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoice.customerName ?? "Khách lẻ"} • Phòng ${invoice.roomNumber ?? "402"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStatusBadge(context, invoice),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã thu',
                style: TextStyle(fontSize: 11, color: palette.inkFaint),
              ),
              Text(
                'Tổng',
                style: TextStyle(fontSize: 11, color: palette.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Payment Progress Bar (8px rounded track, gold gradient fill)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Container(
              height: 8,
              width: double.infinity,
              color: palette.surfaceMuted,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isPaid ? null : AppGradients.gold,
                    color: isPaid ? palette.statusAvailable : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.formatCurrency(invoice.paidAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.statusAvailableInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Formatters.formatCurrency(invoice.finalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Warning Box: Còn thiếu (if any)
          if (invoice.remainingAmount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.warningSurface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Còn thiếu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.warningInk,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        Formatters.formatCurrency(invoice.remainingAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: palette.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Khách đã bấm trả qua app, tiền chưa vào két: chờ lễ tân đối chiếu
            // sao kê. Không cho gửi thêm — mỗi hóa đơn chỉ treo một yêu cầu.
            if (invoice.hasPendingPaymentRequest) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: palette.warningInk),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đã gửi yêu cầu ${Formatters.formatCurrency(invoice.pendingRequestedAmount)} — chờ lễ tân đối chiếu',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: palette.warningInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Button: Ghi nhận Thu tiền — chỉ vai trò được `pay` mới thấy
            if (onCollectPayment != null) ...[
              const SizedBox(height: AppSpacing.md),
              PressableScale(
                onTap: onCollectPayment!,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Ghi nhận Thu tiền',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // Nút của khách: gửi yêu cầu trả toàn bộ số còn lại. `amount` bỏ
            // trống nên máy chủ tự lấy đúng `remainingAmount`.
            else if (onRequestPayment != null && invoice.canRequestPayment) ...[
              const SizedBox(height: AppSpacing.md),
              PressableScale(
                onTap: isRequestingPayment ? null : onRequestPayment,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: Center(
                    child: isRequestingPayment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Thanh toán toàn bộ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Đã hoàn tất: Action status box
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.successSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: palette.statusAvailable),
                  const SizedBox(width: 6),
                  Text(
                    'Đã hoàn tất thanh toán đủ 100%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.statusAvailableInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
