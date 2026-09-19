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
    InvoiceModel invoice, {
    num? refundAmount,
  }) {
    final palette = context.palette;
    final remaining = invoice.remainingAmount;
    final actualRefund = refundAmount ??
        (invoice.paidAmount > invoice.finalAmount
            ? (invoice.paidAmount - invoice.finalAmount)
            : null);

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
            if (actualRefund != null && actualRefund > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.statusAvailable.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: palette.statusAvailable.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_exchange_rounded,
                      color: palette.statusAvailableInk,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Đã hoàn trả khách: ${Formatters.formatCurrency(actualRefund)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.statusAvailableInk,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            const SizedBox(height: 6),
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
  final TextEditingController _refundController = TextEditingController();

  String _paymentMethod = 'CASH';
  String _refundMethod = 'CASH';
  bool _recalculateRoomAmount = true;
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
    _discountController.addListener(_onFormNumberChanged);
    _taxController.addListener(_onFormNumberChanged);
    _loadPreview();
  }

  @override
  void dispose() {
    _discountController.removeListener(_onFormNumberChanged);
    _taxController.removeListener(_onFormNumberChanged);
    _discountController.dispose();
    _taxController.dispose();
    _amountCollectedController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  void _onFormNumberChanged() {
    setState(() {
      _syncAmounts();
    });
  }

  bool get _isEarlyCheckOut {
    if (_preview != null) return _preview!.isEarlyCheckOut;
    final inDate = widget.booking.actualCheckIn ?? widget.booking.checkInDate;
    final now = DateTime.now();
    final diff = now.difference(inDate).inDays;
    final actual = diff <= 0 ? 1 : diff;
    final bookedDiff = widget.booking.checkOutDate.difference(inDate).inDays;
    final booked = bookedDiff <= 0 ? 1 : bookedDiff;
    return now.isBefore(widget.booking.checkOutDate) && actual < booked;
  }

  int get _bookedNights {
    if (_preview != null && _preview!.bookedNights > 0) {
      return _preview!.bookedNights;
    }
    final inDate = widget.booking.actualCheckIn ?? widget.booking.checkInDate;
    final diff = widget.booking.checkOutDate.difference(inDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  int get _actualNights {
    if (_preview != null && _preview!.actualNights > 0) {
      return _preview!.actualNights;
    }
    final inDate = widget.booking.actualCheckIn ?? widget.booking.checkInDate;
    final now = DateTime.now();
    final diff = now.difference(inDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  num get _basePrice {
    if (_preview != null && _preview!.basePrice > 0) return _preview!.basePrice;
    if (_bookedNights > 0) {
      return (widget.booking.totalAmount / _bookedNights).round();
    }
    return widget.booking.totalAmount;
  }

  num get _originalRoomAmount {
    if (_preview != null && _preview!.originalRoomAmount > 0) {
      return _preview!.originalRoomAmount;
    }
    return widget.booking.totalAmount;
  }

  num get _recalculatedRoomAmount {
    if (_preview != null && _preview!.recalculatedRoomAmount > 0) {
      return _preview!.recalculatedRoomAmount;
    }
    return _actualNights * _basePrice;
  }

  bool get _hasCustomAdjustments {
    if (_preview == null) return false;
    final discountInput = num.tryParse(_discountController.text.trim()) ?? 0;
    if (discountInput != _preview!.discount) return true;

    final taxInput = num.tryParse(_taxController.text.trim());
    if (taxInput != null) {
      final inputTaxRate = taxInput / 100.0;
      if ((inputTaxRate - _preview!.taxRate).abs() > 0.001) return true;
    }

    if (_isEarlyCheckOut && _recalculateRoomAmount != _preview!.isEarlyCheckOut) {
      return true;
    }
    return false;
  }

  num get _effectiveRoomAmount {
    if (_preview != null && !_hasCustomAdjustments) {
      return _preview!.roomAmount;
    }
    if (_isEarlyCheckOut) {
      return _recalculateRoomAmount ? _recalculatedRoomAmount : _originalRoomAmount;
    }
    return _preview?.roomAmount ?? widget.booking.totalAmount;
  }

  num get _effectiveServicesAmount => _preview?.servicesAmount ?? 0;

  num get _effectiveDiscount =>
      num.tryParse(_discountController.text.trim()) ?? (_preview?.discount ?? 0);

  num get _effectiveTaxRate =>
      (num.tryParse(_taxController.text.trim()) ??
          (_preview != null ? (_preview!.taxRate * 100) : 10)) /
      100.0;

  num get _effectiveTaxable =>
      (_effectiveRoomAmount + _effectiveServicesAmount - _effectiveDiscount)
          .clamp(0, double.infinity);

  num get _effectiveTax {
    if (_preview != null && !_hasCustomAdjustments) {
      return _preview!.tax;
    }
    return (_effectiveTaxable * _effectiveTaxRate).round();
  }

  num get _effectiveFinalAmount {
    if (_preview != null && !_hasCustomAdjustments) {
      return _preview!.finalAmount;
    }
    return (_effectiveTaxable + _effectiveTax).round();
  }

  num get _effectivePaidAmount => _preview?.paidAmount ?? 0;

  num get _amountDue {
    if (_preview == null) return 0;
    if (!_hasCustomAdjustments) {
      return _preview!.amountDue;
    }
    return (_effectiveFinalAmount - _effectivePaidAmount).clamp(0, double.infinity);
  }

  num get _refundDue {
    if (_preview == null) return 0;
    if (!_hasCustomAdjustments) {
      return _preview!.refundDue;
    }
    return (_effectivePaidAmount - _effectiveFinalAmount).clamp(0, double.infinity);
  }

  void _syncAmounts() {
    if (_amountEdited) return;
    if (_refundDue > 0) {
      _refundController.text = Formatters.formatNumber(_refundDue);
      _amountCollectedController.clear();
    } else if (_amountDue > 0) {
      _amountCollectedController.text = Formatters.formatNumber(_amountDue);
      _refundController.clear();
    } else {
      _amountCollectedController.clear();
      _refundController.clear();
    }
  }

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
        _recalculateRoomAmount = preview.isEarlyCheckOut;
        if (!_amountEdited) {
          if (preview.discount > 0) {
            _discountController.text = preview.discount.toInt().toString();
          }
          final taxPct = (preview.taxRate * 100).round();
          _taxController.text = taxPct.toString();
        }
        _syncAmounts();
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
    final refund =
        Formatters.parseCurrency(_refundController.text) ?? _refundDue;

    // Máy chủ cũng chặn thu vượt, báo sớm ở đây để đỡ một vòng gọi API.
    if (_amountDue > 0 && collected > _amountDue) {
      setState(() {
        _errorMessage =
            'Không thu vượt số còn lại (${Formatters.formatCurrency(_amountDue)}).';
      });
      return;
    }

    // Kiểm tra thanh toán: Nếu còn tiền phải thu, bắt buộc phải thu đủ trước khi hoàn tất trả phòng và đổi trạng thái phòng
    if (_amountDue > 0 && collected < _amountDue) {
      setState(() {
        _errorMessage =
            'Vui lòng thu đủ số tiền còn lại (${Formatters.formatCurrency(_amountDue)}) trước khi hoàn tất trả phòng và đổi trạng thái phòng.';
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
        amountCollected: collected > 0 ? collected : null,
        recalculateRoomAmount: _isEarlyCheckOut ? _recalculateRoomAmount : null,
        refundAmount: _refundDue > 0 ? refund : null,
        refundMethod: _refundDue > 0 ? _refundMethod : null,
        refundReason: _isEarlyCheckOut
            ? 'Khách trả phòng trước hạn ($_actualNights/$_bookedNights đêm)'
            : null,
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
                    if (_isEarlyCheckOut) _buildEarlyCheckOutBanner(palette),
                    // Bảng kê & số còn phải thu
                    // (GET /bookings/:id/checkout-preview)
                    _buildPreviewSection(palette),
                    const SizedBox(height: AppSpacing.md),

                    if (_refundDue > 0)
                      _buildRefundSection(palette)
                    else ...[
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
                    ],
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
                  backgroundColor: _refundDue > 0
                      ? palette.statusAvailable
                      : _checkOutBlue,
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
                    : Text(
                        _refundDue > 0
                            ? 'Xác nhận Trả phòng & Hoàn tiền'
                            : 'Xác nhận Trả phòng & Xuất Hóa đơn',
                        style: const TextStyle(
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

    final effectiveRoom = _effectiveRoomAmount;
    final effectiveServices = _effectiveServicesAmount;
    final effectiveDisc = _effectiveDiscount;
    final effectiveTax = _effectiveTax;
    final effectiveFinal = _effectiveFinalAmount;
    final effectivePaid = _effectivePaidAmount;
    final effectiveDue = _amountDue;
    final effectiveRefund = _refundDue;

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
              _buildPreviewRow(
                palette,
                _isEarlyCheckOut
                    ? (_recalculateRoomAmount
                        ? 'Tiền phòng ($_actualNights/$_bookedNights đêm)'
                        : 'Tiền phòng (Giữ nguyên $_bookedNights đêm)')
                    : 'Tiền phòng',
                effectiveRoom,
              ),
              if (effectiveServices > 0)
                _buildPreviewRow(
                  palette,
                  'Dịch vụ phát sinh',
                  effectiveServices,
                ),
              if (effectiveDisc > 0)
                _buildPreviewRow(palette, 'Giảm giá', -effectiveDisc),
              if (effectiveTax > 0)
                _buildPreviewRow(palette, 'Thuế VAT', effectiveTax),
              Divider(height: 18, color: palette.border),
              _buildPreviewRow(
                palette,
                'Tổng hóa đơn',
                effectiveFinal,
                isBold: true,
              ),
              _buildPreviewRow(
                palette,
                'Đã thu (gồm tiền cọc)',
                effectivePaid,
                color: palette.statusAvailableInk,
              ),
              Divider(height: 18, color: palette.border),
              if (effectiveRefund > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.currency_exchange_rounded,
                          size: 16,
                          color: palette.statusAvailableInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CẦN HOÀN TRẢ KHÁCH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.statusAvailableInk,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          Formatters.formatCurrency(effectiveRefund),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: palette.statusAvailableInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
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
                          Formatters.formatCurrency(effectiveDue),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: effectiveDue > 0
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
            hintText: 'Nhập số tiền thu tại quầy',
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
                avatar: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text('Thu đủ ${Formatters.formatNumber(due)} ₫'),
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _amountEdited = true;
                        _amountCollectedController.text =
                            Formatters.formatNumber(due);
                      }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cần kiểm tra và thu đủ thanh toán để hoàn tất thủ tục trả phòng và chuyển trạng thái phòng sang Chờ dọn.',
          style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
        ),
      ],
    );
  }

  Widget _buildEarlyCheckOutBanner(AppPalette palette) {
    if (!_isEarlyCheckOut) return const SizedBox.shrink();

    final booked = _bookedNights;
    final actual = _actualNights;
    final scheduledDate = Formatters.formatDate(widget.booking.checkOutDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.warning,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'TRẢ PHÒNG TRƯỚC HẠN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Lưu trú: $actual / $booked đêm',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.warningInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Khách làm thủ tục trả phòng trước ngày dự kiến ($scheduledDate).',
            style: TextStyle(fontSize: 12, color: palette.warningInk),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: palette.border),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              dense: true,
              title: const Text(
                'Tính lại tiền phòng theo số đêm thực tế',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _recalculateRoomAmount
                    ? 'Áp dụng $actual đêm: ${Formatters.formatCurrency(_recalculatedRoomAmount)} (Đơn giá ${Formatters.formatCurrency(_basePrice)}/đêm)'
                    : 'Giữ nguyên giá ban đầu: ${Formatters.formatCurrency(_originalRoomAmount)} ($booked đêm)',
                style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
              ),
              value: _recalculateRoomAmount,
              activeThumbColor: palette.accent,
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      setState(() {
                        _recalculateRoomAmount = val;
                        _amountEdited = false;
                        _syncAmounts();
                      });
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSection(AppPalette palette) {
    final refund = _refundDue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.statusAvailable.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: palette.statusAvailable.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.currency_exchange_rounded,
                size: 20,
                color: palette.statusAvailableInk,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Khách đã thanh toán/đặt cọc vượt quá tiền phòng thực tế (${Formatters.formatCurrency(refund)}). '
                  'Vui lòng hoàn tiền cho khách tại quầy để hoàn tất trả phòng.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.statusAvailableInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hình thức hoàn tiền:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _refundMethod,
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
              child: Text('Hoàn thẻ (CREDIT_CARD)'),
            ),
          ],
          onChanged: _isSubmitting
              ? null
              : (val) {
                  if (val != null) {
                    setState(() => _refundMethod = val);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Số tiền hoàn trả khách (VNĐ):',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _refundController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: palette.statusAvailableInk,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập số tiền hoàn cho khách',
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
            if (refund > 0)
              ActionChip(
                avatar: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text('Hoàn đủ ${Formatters.formatNumber(refund)} ₫'),
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _refundController.text = Formatters.formatNumber(refund);
                      }),
              ),
          ],
        ),
      ],
    );
  }
}
