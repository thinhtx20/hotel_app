import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/checkout_preview_model.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/booking_repository.dart';

/// Kết quả của một lượt trả phòng: đơn đã cập nhật + hóa đơn vừa xuất.
typedef CheckOutResult = (BookingModel booking, InvoiceModel invoice);

/// Sheet thủ tục Trả phòng & Xuất hóa đơn (POST /bookings/:id/check-out).
///
/// Mở sheet là gọi `GET /bookings/:id/checkout-preview` để thu ngân thấy ngay
/// số còn phải thu cùng bảng kê đầy đủ — endpoint chỉ đọc nên không đụng vào
/// trạng thái đơn hay phòng. Số tiền nhập ở ô "Thu tại quầy" đi thẳng vào
/// `amountCollected`; bỏ trống nghĩa là không thu thêm, khách vẫn trả phòng
/// được và hóa đơn còn nợ sẽ tự hiện trong app của khách.
///
/// Dùng chung cho màn "Trả phòng hôm nay" và thao tác nhanh trên sơ đồ buồng
/// phòng, nên phần gọi API và hộp thoại hóa đơn nằm luôn trong widget này —
/// màn hình gọi chỉ cần `await CheckOutSheet.show(...)` rồi làm mới dữ liệu.
class CheckOutSheet extends StatefulWidget {
  final BookingModel booking;
  final BookingRepository bookingRepository;

  const CheckOutSheet({
    super.key,
    required this.booking,
    required this.bookingRepository,
  });

  /// Mở sheet và chạy trọn thủ tục trả phòng.
  ///
  /// Trả về `(booking, invoice)` khi thành công (hộp thoại hóa đơn đã hiện
  /// xong), `null` khi lễ tân đóng sheet giữa chừng.
  static Future<CheckOutResult?> show({
    required BuildContext context,
    required BookingModel booking,
    required BookingRepository bookingRepository,
  }) async {
    final palette = context.palette;

    final result = await showModalBottomSheet<CheckOutResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) =>
          CheckOutSheet(booking: booking, bookingRepository: bookingRepository),
    );

    if (result == null || !context.mounted) return result;
    await showInvoiceSuccessDialog(context, result.$2);
    return result;
  }

  /// Hộp thoại tóm tắt hóa đơn vừa xuất sau khi trả phòng.
  static Future<void> showInvoiceSuccessDialog(
    BuildContext context,
    InvoiceModel invoice,
  ) {
    final palette = context.palette;
    final remaining = invoice.remainingAmount;

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: palette.success, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Hóa đơn đã xuất thành công',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã hóa đơn: ${invoice.displayCode}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tiền phòng: ${Formatters.formatCurrency(invoice.roomAmount)}',
            ),
            if (invoice.servicesAmount > 0)
              Text(
                'Tiền dịch vụ: ${Formatters.formatCurrency(invoice.servicesAmount)}',
              ),
            if (invoice.discount > 0)
              Text(
                'Chiết khấu: -${Formatters.formatCurrency(invoice.discount)}',
              ),
            Text('Thuế: ${Formatters.formatCurrency(invoice.tax)}'),
            const Divider(),
            Text(
              'Tổng cộng: ${Formatters.formatCurrency(invoice.finalAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.accent,
                fontSize: 16,
              ),
            ),
            Text('Đã thu: ${Formatters.formatCurrency(invoice.paidAmount)}'),
            if (remaining > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Còn nợ: ${Formatters.formatCurrency(remaining)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hóa đơn đã đẩy về app của khách — khách tự bấm thanh toán, '
                'lễ tân đối chiếu sao kê rồi xác nhận.',
                style: TextStyle(fontSize: 12, color: palette.inkMuted),
              ),
            ],
            Text('Trạng thái: ${invoice.paymentStatus}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  State<CheckOutSheet> createState() => _CheckOutSheetState();
}

class _CheckOutSheetState extends State<CheckOutSheet> {
  static const Color _checkOutBlue = Color(0xFF3B82F6);

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(
    text: '10',
  );
  final TextEditingController _amountCollectedController =
      TextEditingController();

  String _paymentMethod = 'CASH';
  bool _isSubmitting = false;
  String? _errorMessage;

  CheckoutPreviewModel? _preview;
  bool _isLoadingPreview = true;
  String? _previewError;

  /// Khi lễ tân đã tự gõ số thu thì không tự điền đè nữa.
  bool _amountEdited = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _amountCollectedController.dispose();
    super.dispose();
  }

  /// Số còn phải thu theo bảng kê của máy chủ (`amountDue`).
  num get _amountDue => _preview?.amountDue ?? 0;

  Future<void> _loadPreview() async {
    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });

    try {
      final preview = await widget.bookingRepository.fetchCheckOutPreview(
        widget.booking.id,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isLoadingPreview = false;
        // Mặc định thu trọn số còn lại — thao tác phổ biến nhất ở quầy.
        if (!_amountEdited && preview.amountDue > 0) {
          _amountCollectedController.text = Formatters.formatNumber(
            preview.amountDue,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPreview = false;
        _previewError = ApiError.fromDynamic(e).displayMessage;
      });
    }
  }

  Future<void> _submit() async {
    final discount = num.tryParse(_discountController.text.trim()) ?? 0;
    final taxPercent = num.tryParse(_taxController.text.trim()) ?? 10;
    final collected =
        Formatters.parseCurrency(_amountCollectedController.text) ?? 0;

    // Máy chủ cũng chặn thu vượt, báo sớm ở đây để đỡ một vòng gọi API.
    if (_preview != null && _amountDue > 0 && collected > _amountDue) {
      setState(() {
        _errorMessage =
            'Không thu vượt số còn lại (${Formatters.formatCurrency(_amountDue)}).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.bookingRepository.checkOut(
        widget.booking.id,
        paymentMethod: _paymentMethod,
        discount: discount > 0 ? discount : null,
        taxRate: taxPercent / 100.0,
        // Bỏ trống = không thu thêm; khách vẫn được trả phòng.
        amountCollected: collected > 0 ? collected : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      // Lỗi hiện ngay trong sheet: SnackBar sẽ bị chính sheet che mất.
      setState(() {
        _isSubmitting = false;
        _errorMessage = ApiError.fromDynamic(e).displayMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final booking = widget.booking;

    return ConstrainedBox(
      // Sheet có bảng kê nên dài; giới hạn chiều cao để nút xác nhận luôn nằm
      // trong tầm ngón tay thay vì trôi xuống dưới đáy màn hình.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _checkOutBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: _checkOutBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Thủ tục Trả phòng & Xuất Hóa đơn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Phòng ${booking.roomNumber ?? '---'} • ${booking.customerName ?? 'Khách hàng'} • ${booking.bookingCode ?? booking.id}',
              style: TextStyle(fontSize: 13, color: palette.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bảng kê & số còn phải thu
                    // (GET /bookings/:id/checkout-preview)
                    _buildPreviewSection(palette),
                    const SizedBox(height: AppSpacing.md),

                    // Chọn phương thức thanh toán
                    Text(
                      'Phương thức thanh toán:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'CASH',
                          child: Text('Tiền mặt (CASH)'),
                        ),
                        DropdownMenuItem(
                          value: 'BANK_TRANSFER',
                          child: Text('Chuyển khoản (BANK_TRANSFER)'),
                        ),
                        DropdownMenuItem(
                          value: 'CREDIT_CARD',
                          child: Text('Thẻ tín dụng (CREDIT_CARD)'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _paymentMethod = val);
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Số tiền thu ngân thực nhận -> amountCollected
                    _buildAmountCollectedField(palette),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giảm giá (VNĐ):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _discountController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thuế VAT (%):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _taxController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '10',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: palette.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: palette.errorInk,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.errorInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _checkOutBlue,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Xác nhận Trả phòng & Xuất Hóa đơn',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bảng kê chỉ đọc lấy từ `GET /bookings/:id/checkout-preview`.
  Widget _buildPreviewSection(AppPalette palette) {
    if (_isLoadingPreview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Đang lấy bảng kê & số còn phải thu...',
              style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
            ),
          ],
        ),
      );
    }

    if (_previewError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.warningSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: palette.warningInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Không lấy được bảng kê: $_previewError\n'
                    'Vẫn trả phòng được, nhưng hãy tự kiểm tra số tiền thu.',
                    style: TextStyle(fontSize: 12.5, color: palette.warningInk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSubmitting ? null : _loadPreview,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      );
    }

    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              _buildPreviewRow(palette, 'Tiền phòng', preview.roomAmount),
              if (preview.servicesAmount > 0)
                _buildPreviewRow(
                  palette,
                  'Dịch vụ phát sinh',
                  preview.servicesAmount,
                ),
              if (preview.discount > 0)
                _buildPreviewRow(palette, 'Giảm giá', -preview.discount),
              if (preview.tax > 0)
                _buildPreviewRow(palette, 'Thuế VAT', preview.tax),
              Divider(height: 18, color: palette.border),
              _buildPreviewRow(
                palette,
                'Tổng hóa đơn',
                preview.finalAmount,
                isBold: true,
              ),
              _buildPreviewRow(
                palette,
                'Đã thu (gồm tiền cọc)',
                preview.paidAmount,
                color: palette.statusAvailableInk,
              ),
              Divider(height: 18, color: palette.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CÒN PHẢI THU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        Formatters.formatCurrency(preview.amountDue),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: preview.amountDue > 0
                              ? palette.error
                              : palette.statusAvailableInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (preview.hasPendingPaymentRequests) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.warningSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: palette.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  size: 18,
                  color: palette.warningInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Khách đã gửi ${preview.pendingPaymentRequests.length} yêu cầu '
                    'thanh toán qua app '
                    '(${Formatters.formatCurrency(preview.pendingRequestedAmount)}) '
                    'nhưng chưa ai đối chiếu sao kê. Đối chiếu trước khi thu để '
                    'khỏi thu trùng.',
                    style: TextStyle(fontSize: 12, color: palette.warningInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewRow(
    AppPalette palette,
    String label,
    num value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? palette.ink : palette.inkMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.formatCurrency(value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                  color: color ?? palette.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCollectedField(AppPalette palette) {
    final due = _amountDue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thu tại quầy lần này (VNĐ):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _amountCollectedController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (_) => setState(() => _amountEdited = true),
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
          decoration: InputDecoration(
            hintText: 'Bỏ trống = không thu thêm',
            suffixText: '₫',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (due > 0)
              ActionChip(
                label: Text('Thu đủ ${Formatters.formatNumber(due)}'),
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _amountEdited = true;
                        _amountCollectedController.text =
                            Formatters.formatNumber(due);
                      }),
              ),
            ActionChip(
              label: const Text('Không thu thêm'),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                      _amountEdited = true;
                      _amountCollectedController.clear();
                    }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bỏ trống thì khách vẫn trả phòng được — hóa đơn còn nợ sẽ hiện trong '
          'app của khách để trả sau.',
          style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
        ),
      ],
    );
  }
}
