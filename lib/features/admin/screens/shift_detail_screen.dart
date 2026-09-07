import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/work_shift_model.dart';
import '../../../shared/repositories/shift_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';

class ShiftDetailScreen extends StatefulWidget {
  final String shiftId;
  final WorkShiftModel? initialShift;

  const ShiftDetailScreen({
    super.key,
    required this.shiftId,
    this.initialShift,
  });

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  late final ShiftRepository _shiftRepo = sl<ShiftRepository>();

  WorkShiftModel? _shift;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shift = widget.initialShift;
    if (_shift == null) {
      _fetchDetail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = _shift == null;
      _errorMessage = null;
    });

    try {
      final data = await _shiftRepo.getShiftDetail(widget.shiftId);
      if (mounted) {
        setState(() {
          _shift = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Row(
          children: [
            const Icon(Icons.print_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('In Biên Bản Giao Ca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Đã gửi lệnh in biên bản bàn giao ca "${_shift?.shiftCode}" sang máy in nhiệt POS tại quầy tiếp tân.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: Text(_shift?.shiftCode.isNotEmpty == true ? _shift!.shiftCode : 'Chi Tiết Ca Trực'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'In biên bản bàn giao',
            onPressed: _shift != null ? _showPrintDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _fetchDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _shift == null
              ? Center(
                  child: AppErrorView(
                    error: _errorMessage!,
                    onRetry: _fetchDetail,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStaffHeaderCard(palette, textTheme),
                        const SizedBox(height: AppSpacing.lg),
                        _buildCashBalanceCard(palette, textTheme),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRevenueBreakdownCard(palette, textTheme),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTransactionsSection(palette, textTheme),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStaffHeaderCard(AppPalette palette, TextTheme textTheme) {
    final shift = _shift!;
    final type = shift.shiftType;
    final isOpen = shift.isOpen;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: palette.accent.withValues(alpha: 0.15),
                backgroundImage: shift.staffAvatar != null && shift.staffAvatar!.isNotEmpty
                    ? NetworkImage(shift.staffAvatar!)
                    : null,
                child: shift.staffAvatar == null || shift.staffAvatar!.isEmpty
                    ? Icon(Icons.person, color: palette.accent, size: 28)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.staffName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shift.deskName} • ${type.label}',
                      style: textTheme.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                    if (shift.staffPhone != null && shift.staffPhone!.isNotEmpty)
                      Text(
                        'SĐT: ${shift.staffPhone}',
                        style: textTheme.bodySmall?.copyWith(color: palette.inkMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isOpen ? palette.statusAvailable : palette.statusMaintenance)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: (isOpen ? palette.statusAvailable : palette.statusMaintenance)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOpen ? palette.statusAvailable : palette.inkMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOpen ? 'ĐANG TRỰC' : 'ĐÃ CHỐT CA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isOpen ? palette.statusAvailableInk : palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BẮT ĐẦU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.inkMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatDateTime(shift.startTime),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'THỜI LƯỢNG ĐÃ TRỰC' : 'KẾT THÚC',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.inkMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOpen
                          ? '${shift.duration.inHours}h ${shift.duration.inMinutes % 60}m'
                          : Formatters.formatDateTime(shift.endTime!),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (shift.handoverStaffName != null && shift.handoverStaffName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.handshake_outlined, size: 18, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Bàn giao ca cho: ',
                    style: TextStyle(fontSize: 12, color: palette.inkMuted),
                  ),
                  Text(
                    shift.handoverStaffName!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.ink),
                  ),
                ],
              ),
            ),
          ],
          if (shift.openNote != null && shift.openNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú mở ca: "${shift.openNote}"',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: palette.inkMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashBalanceCard(AppPalette palette, TextTheme textTheme) {
    final shift = _shift!;
    final stats = shift.stats;
    final initial = shift.initialCash;
    final collected = stats?.cashCollected ?? 0;
    final refunded = stats?.cashRefunded ?? 0;
    final expected = shift.expectedCash ?? stats?.expectedCash ?? (initial + collected - refunded);
    final actual = shift.actualCash;
    final diff = shift.cashDifference;
    final isClosed = shift.isClosed;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đối Soát Tiền Mặt Trong Két',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, color: palette.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _buildCashRow('Tiền mặt nhận đầu ca', Formatters.formatCurrency(initial), palette, isBold: false),
          _buildCashRow('(+) Thu tiền mặt trong ca', '+${Formatters.formatCurrency(collected)}', palette, textColor: Colors.green.shade700),
          if (refunded > 0)
            _buildCashRow('(-) Hoàn tiền mặt', '-${Formatters.formatCurrency(refunded)}', palette, textColor: Colors.red.shade700),

          const Divider(height: 20),
          _buildCashRow(
            '(=) Tiền sổ sách phải có trong két',
            Formatters.formatCurrency(expected),
            palette,
            isBold: true,
            fontSize: 15,
            textColor: palette.ink,
          ),

          if (isClosed && actual != null) ...[
            const SizedBox(height: 8),
            _buildCashRow(
              'Tiền mặt thực kiểm đếm lúc chốt',
              Formatters.formatCurrency(actual),
              palette,
              isBold: true,
              fontSize: 16,
              textColor: palette.accent,
            ),
            const SizedBox(height: 12),

            // Banner chênh lệch
            if (diff != null && diff.abs() > 0.01) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (diff > 0 ? Colors.amber.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: (diff > 0 ? Colors.amber.shade400 : Colors.red.shade400),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          diff > 0 ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                          size: 20,
                          color: diff > 0 ? Colors.amber.shade800 : Colors.red.shade800,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          diff > 0
                              ? 'THỪA TIỀN KÉT: +${Formatters.formatCurrency(diff)}'
                              : 'THIẾU TIỀN KÉT: ${Formatters.formatCurrency(diff)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: diff > 0 ? Colors.amber.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    if (shift.differenceReason != null && shift.differenceReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Giải trình: ${shift.differenceReason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: diff > 0 ? Colors.amber.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Khớp tiền chính xác 100% (Không có sai lệch)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: palette.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ca đang mở trực. Tiền mặt thực tế sẽ được nhân viên/quản trị viên kiểm đếm khi chốt ca.',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (shift.closeNote != null && shift.closeNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Ghi chú kết ca: "${shift.closeNote}"',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: palette.inkMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashRow(
    String title,
    String value,
    AppPalette palette, {
    bool isBold = false,
    double fontSize = 13,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: palette.inkMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor ?? palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard(AppPalette palette, TextTheme textTheme) {
    final shift = _shift!;
    final stats = shift.stats;
    final total = shift.effectiveRevenue;
    final cardAmount = stats?.creditCardAmount ?? shift.creditCardAmount;
    final transferAmount = stats?.bankTransferAmount ?? shift.bankTransferAmount;
    final netCash = stats?.netCashChange ?? (stats != null ? stats.cashCollected - stats.cashRefunded : 0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cơ Cấu Doanh Thu Trong Ca',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              Text(
                Formatters.formatCurrency(total),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMethodTile(
            icon: Icons.money_rounded,
            color: Colors.teal,
            title: 'Tiền mặt (CASH)',
            amount: netCash.toDouble(),
            palette: palette,
          ),
          const Divider(height: 16),
          _buildMethodTile(
            icon: Icons.credit_card_rounded,
            color: Colors.blue,
            title: 'Thẻ POS ngân hàng',
            amount: cardAmount,
            palette: palette,
          ),
          const Divider(height: 16),
          _buildMethodTile(
            icon: Icons.qr_code_2_rounded,
            color: Colors.purple,
            title: 'Chuyển khoản / VietQR',
            amount: transferAmount,
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required IconData icon,
    required Color color,
    required String title,
    required double amount,
    required AppPalette palette,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.ink),
          ),
        ),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(AppPalette palette, TextTheme textTheme) {
    final shift = _shift!;
    final payments = shift.payments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bảng Kê Giao Dịch (${payments.length})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            if (shift.stats?.refundCount != null && shift.stats!.refundCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${shift.stats!.refundCount} hoàn tiền',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (payments.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: palette.inkMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa phát sinh giao dịch thanh toán trong ca này',
                    style: TextStyle(fontSize: 13, color: palette.inkMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = payments[index];
              final isRefund = p.type == 'REFUND';
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isRefund ? Colors.red : Colors.green).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRefund ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        color: isRefund ? Colors.red : Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.invoiceCode ?? 'Hóa đơn',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              if (p.roomNumber != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: palette.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'P.${p.roomNumber}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: palette.accent),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.customerName ?? "Khách lẻ"} • ${p.method} • ${p.confirmedAt != null ? Formatters.formatDateTime(p.confirmedAt!) : ""}',
                            style: TextStyle(fontSize: 11, color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isRefund ? "-" : "+"}${Formatters.formatCurrency(p.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isRefund ? Colors.red : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
