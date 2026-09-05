import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

/// Bottom sheet hoàn tiền hóa đơn (FE-ROLE-MATRIX §5.4)
class RefundSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final Function(InvoiceModel updated) onRefundSuccess;

  const RefundSheet({
    super.key,
    required this.invoice,
    required this.onRefundSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required InvoiceModel invoice,
    required Function(InvoiceModel updated) onRefundSuccess,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => RefundSheet(
        invoice: invoice,
        onRefundSuccess: onRefundSuccess,
      ),
    );
  }

  @override
  State<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<RefundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Mặc định điền toàn bộ số tiền đã thanh toán
    _amountController.text = widget.invoice.paidAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = num.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Số tiền hoàn trả phải lớn hơn 0'),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }
    if (parsedAmount > widget.invoice.paidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số tiền hoàn trả không được vượt quá số tiền đã thu (${Formatters.formatCurrency(widget.invoice.paidAmount)})'),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final invoiceRepo = sl<InvoiceRepository>();
      final updated = await invoiceRepo.refund(
        widget.invoice.id,
        amount: parsedAmount,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onRefundSuccess(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hoàn trả ${Formatters.formatCurrency(parsedAmount)} cho hóa đơn ${widget.invoice.displayCode}'),
          backgroundColor: context.palette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoàn tiền thất bại: ${e.toString()}'),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppBottomSheet(
      title: 'Hoàn Tiền Hóa Đơn',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin hóa đơn & tiền đã thu
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.canvas,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mã hóa đơn:', style: TextStyle(fontSize: 13, color: palette.inkMuted)),
                      Text(widget.invoice.displayCode, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số tiền đã thu:', style: TextStyle(fontSize: 13, color: palette.inkMuted)),
                      Text(
                        Formatters.formatCurrency(widget.invoice.paidAmount),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.statusAvailableInk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Số tiền hoàn
            Text(
              'Số tiền hoàn trả (VNĐ) (*)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Nhập số tiền cần hoàn...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(fontWeight: FontWeight.w600, color: palette.inkMuted),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền hoàn';
                }
                final numVal = num.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                if (numVal == null || numVal <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                if (numVal > widget.invoice.paidAmount) {
                  return 'Không được vượt quá ${Formatters.formatCurrency(widget.invoice.paidAmount)}';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Lý do hoàn tiền
            Text(
              'Lý do hoàn tiền (*)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Khách trả phòng sớm 1 đêm / hoàn tiền dịch vụ hủy',
                hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập lý do hoàn tiền';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Nút Xác nhận Hoàn tiền
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRefund,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.statusOccupied,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                icon: const Icon(Icons.assignment_return_outlined, size: 20),
                label: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Xác Nhận Hoàn Tiền', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
