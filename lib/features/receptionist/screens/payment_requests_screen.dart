import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Đối chiếu tiền khách trả qua app: `GET /invoices/payment-requests`.
///
/// Khách bấm "Thanh toán toàn bộ" trong app chỉ tạo một dòng `PENDING` trong sổ
/// thu tiền — tiền chưa vào két. Lễ tân mở màn này, dò sao kê ngân hàng, rồi
/// bấm xác nhận (`POST /invoices/payments/:paymentId/confirm`); chỉ khi đó
/// `paidAmount` của hóa đơn mới tăng.
class PaymentRequestsScreen extends StatefulWidget {
  final InvoiceRepository? invoiceRepository;

  const PaymentRequestsScreen({super.key, this.invoiceRepository});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> {
  late final InvoiceRepository _invoiceRepo =
      widget.invoiceRepository ?? sl<InvoiceRepository>();

  List<PaymentRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Id dòng thanh toán đang gửi lệnh xác nhận.
  String? _confirmingId;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests({bool isSilent = false}) async {
    if (!isSilent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final requests = await _invoiceRepo.fetchPaymentRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  num get _totalPending => _requests.fold<num>(
        0,
        (sum, r) => sum + r.amount.abs(),
      );

  /// Xác nhận đã nhận tiền — thao tác động tới sổ quỹ nên hỏi lại một lần.
  Future<void> _confirm(PaymentRequestModel request) async {
    final palette = context.palette;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('Xác nhận đã nhận tiền?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hóa đơn #${request.displayCode} • ${request.customerName ?? "Khách hàng"}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Số tiền: ${Formatters.formatCurrency(request.amount.abs())}'),
            const SizedBox(height: 6),
            Text(
              'Chỉ xác nhận khi đã thấy tiền trong sao kê. Sau bước này, '
              'số đã thu của hóa đơn sẽ tăng tương ứng.',
              style: TextStyle(fontSize: 12, color: palette.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (agreed != true || !mounted) return;

    setState(() => _confirmingId = request.id);
    try {
      final invoice = await _invoiceRepo.confirmPayment(request.id);
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
        _confirmingId = null;
      });
      AppNotification.showSuccess(
        context,
        'Đã ghi nhận ${Formatters.formatCurrency(request.amount.abs())} cho hóa đơn '
        '#${request.displayCode}. Còn lại ${Formatters.formatCurrency(invoice.remainingAmount)}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirmingId = null);
      AppNotification.showError(
        context,
        e,
        title: 'Xác nhận thanh toán thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Đối Chiếu Thanh Toán'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: _fetchRequests,
        child: _buildBody(palette),
      ),
    );
  }

  Widget _buildBody(AppPalette palette) {
    if (_isLoading && _requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          AppErrorView(error: _errorMessage!, onRetry: _fetchRequests),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        children: [
          AppEmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Không có yêu cầu chờ đối chiếu',
            description:
                'Khi khách bấm thanh toán trong app, yêu cầu sẽ hiện ở đây để '
                'bạn dò sao kê rồi xác nhận.',
            actionText: 'Tải lại',
            onAction: _fetchRequests,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: _requests.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildSummaryHeader(palette);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildRequestCard(palette, _requests[index - 1]),
        );
      },
    );
  }

  Widget _buildSummaryHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppGradients.navy,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHỜ ĐỐI CHIẾU SAO KÊ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Formatters.formatCurrency(_totalPending),
                style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_requests.length} yêu cầu khách gửi qua app',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AppPalette palette, PaymentRequestModel request) {
    final isConfirming = _confirmingId == request.id;
    final payment = request.payment;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.warningSurface,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(Icons.schedule_rounded,
                    color: palette.warningInk, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${request.displayCode}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${request.customerName ?? "Khách hàng"} • Phòng ${request.roomNumber ?? "N/A"}',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                _buildRow(
                  palette,
                  'Khách xin trả',
                  Formatters.formatCurrency(request.amount.abs()),
                  isBold: true,
                  color: palette.accent,
                ),
                _buildRow(
                  palette,
                  'Tổng hóa đơn',
                  Formatters.formatCurrency(request.finalAmount),
                ),
                _buildRow(
                  palette,
                  'Đã thu trước đó',
                  Formatters.formatCurrency(request.paidAmount),
                ),
                _buildRow(
                  palette,
                  'Còn lại nếu chưa xác nhận',
                  Formatters.formatCurrency(request.remainingAmount),
                  color: palette.error,
                ),
                _buildRow(
                  palette,
                  'Hình thức',
                  _methodLabel(payment.paymentMethod),
                ),
                _buildRow(
                  palette,
                  'Gửi lúc',
                  Formatters.formatDateTime(request.requestedAt),
                ),
              ],
            ),
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ghi chú: ${payment.notes}',
              style: TextStyle(
                fontSize: 12,
                color: palette.inkMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PressableScale(
            onTap: isConfirming ? null : () => _confirm(request),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: BorderRadius.circular(AppRadius.button),
                boxShadow: AppShadows.goldGlow,
              ),
              child: Center(
                child: isConfirming
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
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Đã thấy tiền — Xác nhận',
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
        ],
      ),
    );
  }

  Widget _buildRow(
    AppPalette palette,
    String label,
    String value, {
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
            style: TextStyle(fontSize: 12, color: palette.inkMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isBold ? 15 : 12.5,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? palette.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'VietQR / Chuyển khoản';
      case 'CREDIT_CARD':
        return 'Thẻ POS ngân hàng';
      default:
        return method;
    }
  }
}
