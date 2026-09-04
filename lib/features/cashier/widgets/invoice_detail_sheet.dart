import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

class InvoiceDetailSheet extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onPrintReceipt;

  /// Bỏ trống với vai trò không được `POST /invoices/:id/pay` (khách hàng) —
  /// nút "Ghi nhận Thu tiền" sẽ không hiện.
  final VoidCallback? onCollectPayment;

  const InvoiceDetailSheet({
    super.key,
    required this.invoice,
    required this.onPrintReceipt,
    this.onCollectPayment,
  });

  static Future<void> show({
    required BuildContext context,
    required InvoiceModel invoice,
    required VoidCallback onPrintReceipt,
    VoidCallback? onCollectPayment,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => InvoiceDetailSheet(
        invoice: invoice,
        onPrintReceipt: onPrintReceipt,
        onCollectPayment: onCollectPayment,
      ),
    );
  }

  String _getMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản (VietQR)';
      case 'CREDIT_CARD':
        return 'Thẻ tín dụng / POS';
      default:
        return method;
    }
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
    bool isNegative = false,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? palette.ink : palette.inkMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isNegative
                  ? palette.error
                  : (color ?? (isBold ? palette.ink : palette.ink)),
            ),
          ),
        ],
      ),
    );
  }

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

    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết hóa đơn #${invoice.displayCode}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã đặt phòng: ${invoice.bookingId ?? "BK-DIRECT"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.inkMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 20, color: palette.divider),

            // Guest & Room Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: palette.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName ?? 'Khách vãng lai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phòng: ${invoice.roomNumber ?? "Chưa chỉ định"} • Ngày lập: ${Formatters.formatDate(invoice.createdAt ?? DateTime.now())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, invoice),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Itemized Charges
            Text(
              'Bảng kê chi phí & dịch vụ:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < invoice.items.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.items[i].title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${invoice.items[i].quantity} × ${Formatters.formatCurrency(invoice.items[i].unitPrice)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(invoice.items[i].totalAmount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < invoice.items.length - 1)
                      Divider(height: 1, color: palette.divider),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cost Summary Breakdown
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, 'Tiền phòng', Formatters.formatCurrency(invoice.roomAmount)),
                  if (invoice.servicesAmount > 0)
                    _buildSummaryRow(context, 'Dịch vụ & Tiện ích', Formatters.formatCurrency(invoice.servicesAmount)),
                  if (invoice.discount > 0)
                    _buildSummaryRow(context, 'Giảm giá / Ưu đãi', '- ${Formatters.formatCurrency(invoice.discount)}', isNegative: true),
                  if (invoice.tax > 0)
                    _buildSummaryRow(context, 'Thuế VAT (8%)', '+ ${Formatters.formatCurrency(invoice.tax)}'),
                  Divider(height: 20, color: palette.border),
                  _buildSummaryRow(
                    context,
                    'TỔNG TIỀN HÓA ĐƠN',
                    Formatters.formatCurrency(invoice.finalAmount),
                    isBold: true,
                    fontSize: 15,
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    context,
                    'Đã thanh toán',
                    Formatters.formatCurrency(invoice.paidAmount),
                    color: palette.statusAvailableInk,
                    isBold: true,
                  ),
                  if (invoice.remainingAmount > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      context,
                      'Còn thiếu cần thu',
                      Formatters.formatCurrency(invoice.remainingAmount),
                      color: palette.error,
                      isBold: true,
                      fontSize: 15,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Payment Transactions Timeline
            if (invoice.transactions.isNotEmpty) ...[
              Text(
                'Lịch sử các đợt thanh toán:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final txn in invoice.transactions)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: palette.statusAvailable.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.statusAvailable,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Formatters.formatCurrency(txn.amount),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                            Text(
                              '${_getMethodLabel(txn.paymentMethod)} • ${Formatters.formatDateTime(txn.timestamp)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (txn.notes != null && txn.notes!.isNotEmpty)
                        Text(
                          txn.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.inkFaint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: onPrintReceipt,
                    child: OutlinedButton.icon(
                      onPressed: onPrintReceipt,
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('In biên lai'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.accent,
                        side: BorderSide(color: palette.accent),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                    ),
                  ),
                ),
                if (!isPaid && onCollectPayment != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PressableScale(
                      onTap: onCollectPayment!,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.gold,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          boxShadow: AppShadows.goldGlow,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            onTap: onCollectPayment,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 13),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Ghi nhận Thu tiền',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
