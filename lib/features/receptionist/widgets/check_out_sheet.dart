import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/booking_repository.dart';

/// Kết quả của một lượt trả phòng: đơn đã cập nhật + hóa đơn vừa xuất.
typedef CheckOutResult = (BookingModel booking, InvoiceModel invoice);

/// Sheet thủ tục Trả phòng & Xuất hóa đơn (POST /bookings/:id/check-out).
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => CheckOutSheet(
        booking: booking,
        bookingRepository: bookingRepository,
      ),
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
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
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
            Text('Mã hóa đơn: ${invoice.displayCode}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Tiền phòng: ${Formatters.formatCurrency(invoice.roomAmount)}'),
            if (invoice.servicesAmount > 0)
              Text(
                  'Tiền dịch vụ: ${Formatters.formatCurrency(invoice.servicesAmount)}'),
            if (invoice.discount > 0)
              Text(
                  'Chiết khấu: -${Formatters.formatCurrency(invoice.discount)}'),
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
            Text('Trạng thái: ${invoice.paymentStatus}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
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
  final TextEditingController _taxController =
      TextEditingController(text: '10');

  String _paymentMethod = 'CASH';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final discount = num.tryParse(_discountController.text.trim()) ?? 0;
    final taxPercent = num.tryParse(_taxController.text.trim()) ?? 10;

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

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
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
                        child: const Icon(Icons.logout_rounded,
                            color: _checkOutBlue, size: 22),
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
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Phòng ${booking.roomNumber ?? '---'} • ${booking.customerName ?? 'Khách hàng'} • ${booking.bookingCode ?? booking.id}',
              style: TextStyle(fontSize: 13, color: palette.inkMuted),
            ),
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
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt (CASH)')),
                DropdownMenuItem(
                    value: 'BANK_TRANSFER',
                    child: Text('Chuyển khoản (BANK_TRANSFER)')),
                DropdownMenuItem(
                    value: 'CREDIT_CARD',
                    child: Text('Thẻ tín dụng (CREDIT_CARD)')),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
            ),
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm)),
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm)),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: palette.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 18, color: palette.errorInk),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            TextStyle(fontSize: 12.5, color: palette.errorInk),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button)),
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
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
