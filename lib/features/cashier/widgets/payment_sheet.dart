import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

class PaymentSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final Future<void> Function({
    required num amount,
    required String paymentMethod,
    required String notes,
  }) onConfirmPayment;

  const PaymentSheet({
    super.key,
    required this.invoice,
    required this.onConfirmPayment,
  });

  static Future<void> show({
    required BuildContext context,
    required InvoiceModel invoice,
    required Future<void> Function({
      required num amount,
      required String paymentMethod,
      required String notes,
    }) onConfirmPayment,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => PaymentSheet(
        invoice: invoice,
        onConfirmPayment: onConfirmPayment,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _customerGivenController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedMethod = 'BANK_TRANSFER'; // BANK_TRANSFER, CASH, CREDIT_CARD
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: Formatters.formatNumber(widget.invoice.remainingAmount),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerGivenController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, AppPalette palette) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? palette.accent.withValues(alpha: 0.15) : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: isSelected ? palette.accent : palette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? palette.accent : palette.inkMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? palette.accent : palette.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? palette.accent : palette.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final remaining = widget.invoice.remainingAmount;
    final currentInputAmount = Formatters.parseCurrency(_amountController.text) ?? 0;
    final customerGiven = Formatters.parseCurrency(_customerGivenController.text) ?? 0;
    final changeAmount = (customerGiven - currentInputAmount).clamp(0, double.infinity);

    final qrUrl =
        'https://img.vietqr.io/image/970423-03609837701-compact2.png?amount=${currentInputAmount.toInt()}&addInfo=LUXE%20${widget.invoice.displayCode}&accountName=LUXE%20GRAND%20HOTEL';

    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi nhận Thu tiền #${widget.invoice.displayCode}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      '${widget.invoice.customerName ?? "Khách lẻ"} • Phòng ${widget.invoice.roomNumber ?? "N/A"}',
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

            // Card số tiền còn thiếu
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.warningSurface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SỐ TIỀN CÒN THIẾU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.warningInk,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cần thanh toán để hoàn tất',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.warningInk.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(remaining),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: palette.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nhập số tiền thu
            Text(
              'Số tiền thu đợt này (VND):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                hintStyle: TextStyle(color: palette.inkFaint),
                prefixIcon: Icon(Icons.payments_outlined, color: palette.accent),
                suffixText: '₫',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Phím chọn số tiền nhanh (Quick presets)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildQuickChip('Toàn bộ (${Formatters.formatNumber(remaining)})', () {
                  _amountController.text = Formatters.formatNumber(remaining);
                  setState(() {});
                }, palette),
                if (remaining > 1000000)
                  _buildQuickChip('50% (${Formatters.formatNumber(remaining / 2)})', () {
                    _amountController.text = Formatters.formatNumber((remaining / 2).round());
                    setState(() {});
                  }, palette),
                _buildQuickChip('1.000.000', () {
                  _amountController.text = Formatters.formatNumber(1000000);
                  setState(() {});
                }, palette),
                _buildQuickChip('2.000.000', () {
                  _amountController.text = Formatters.formatNumber(2000000);
                  setState(() {});
                }, palette),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Chọn Phương Thức Thanh Toán
            Text(
              'Hình thức thanh toán:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                _buildMethodCard(
                  title: 'VietQR',
                  subtitle: 'Chuyển khoản',
                  icon: Icons.qr_code_scanner_rounded,
                  isSelected: _selectedMethod == 'BANK_TRANSFER',
                  onTap: () => setState(() => _selectedMethod = 'BANK_TRANSFER'),
                  palette: palette,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildMethodCard(
                  title: 'Tiền mặt',
                  subtitle: 'CASH',
                  icon: Icons.attach_money_rounded,
                  isSelected: _selectedMethod == 'CASH',
                  onTap: () => setState(() => _selectedMethod = 'CASH'),
                  palette: palette,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildMethodCard(
                  title: 'Thẻ POS',
                  subtitle: 'Visa / Napas',
                  icon: Icons.credit_card_rounded,
                  isSelected: _selectedMethod == 'CREDIT_CARD',
                  onTap: () => setState(() => _selectedMethod = 'CREDIT_CARD'),
                  palette: palette,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Hiển thị giao diện theo phương thức được chọn
            if (_selectedMethod == 'BANK_TRANSFER') ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.successSurface,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: palette.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, color: palette.statusAvailable, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Mã VietQR động tạo theo số tiền:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: palette.statusAvailableInk,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(currentInputAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: palette.statusAvailableInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Image QR
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: palette.isDark ? null : AppShadows.soft,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          qrUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_rounded, size: 60, color: AppColors.primary),
                              SizedBox(height: 6),
                              Text('TPBank - 03609837701', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ngân hàng TMCP Tiên Phong (TPBank)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.ink),
                    ),
                    Text(
                      'STK: 03609837701 - LUXE GRAND HOTEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nội dung CK: ',
                            style: TextStyle(fontSize: 11, color: palette.inkMuted),
                          ),
                          Text(
                            'LUXE ${widget.invoice.displayCode}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: 'LUXE ${widget.invoice.displayCode}'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản!')),
                              );
                            },
                            child: Icon(Icons.copy, size: 14, color: palette.accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMethod == 'CASH') ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiền khách đưa (VND):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _customerGivenController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: palette.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nhập số tiền khách đưa',
                        hintStyle: TextStyle(color: palette.inkFaint),
                        prefixIcon: Icon(Icons.money, color: palette.accent),
                        filled: true,
                        fillColor: palette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.border),
                        ),
                      ),
                    ),
                    if (customerGiven > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiền thối lại khách:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(changeAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: changeAmount >= 0
                                  ? palette.statusAvailableInk
                                  : palette.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.point_of_sale_rounded, color: palette.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Quẹt thẻ qua máy POS ngân hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hỗ trợ thẻ Visa, Mastercard, JCB, Chip Napas. Vui lòng quẹt thẻ trên thiết bị POS cạnh quầy thu ngân.',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Ghi chú
            TextField(
              controller: _notesController,
              style: TextStyle(color: palette.ink, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Ghi chú thanh toán (Tùy chọn)',
                labelStyle: TextStyle(color: palette.inkMuted),
                hintText: 'VD: Khách trả trước đợt 2, thu cọc...',
                hintStyle: TextStyle(color: palette.inkFaint),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nút Xác nhận Thu tiền
            PressableScale(
              onTap: _isProcessing
                  ? null
                  : () async {
                      final amt = Formatters.parseCurrency(_amountController.text) ?? 0;
                      if (amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                        );
                        return;
                      }

                      setState(() => _isProcessing = true);
                      Navigator.pop(context);

                      await widget.onConfirmPayment(
                        amount: amt,
                        paymentMethod: _selectedMethod,
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : 'Thu tiền hóa đơn #${widget.invoice.displayCode}',
                      );
                    },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: AppShadows.goldGlow,
                ),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Xác nhận Thu tiền & Xuất biên lai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
