import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Màn hình chốt ca trực cá nhân Lễ tân – Thu ngân (FE-ROLE-MATRIX §5.2)
class ShiftCloseScreen extends StatefulWidget {
  final InvoiceRepository? invoiceRepository;
  const ShiftCloseScreen({super.key, this.invoiceRepository});

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  late final InvoiceRepository _invoiceRepo = widget.invoiceRepository ?? sl<InvoiceRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _summaryData = {};

  @override
  void initState() {
    super.initState();
    _fetchShiftSummary();
  }

  Future<void> _fetchShiftSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final data = await _invoiceRepo.getShiftSummary(date: dateStr, staffId: 'me');
      if (mounted) {
        setState(() {
          _summaryData = data;
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

  void _printShiftReport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Biên Bản Chốt Ca'),
        content: const Text('Đã gửi lệnh in biên bản chốt ca sang máy in nhiệt POS của quầy lễ tân.'),
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
    final authState = context.read<AuthBloc>().state;
    final staffName = authState is AuthAuthenticated ? authState.user.fullName : 'Nhân viên trực ca';

    final amountCollected = (_summaryData['amountCollected'] as num?) ?? (_summaryData['totalRevenue'] as num?) ?? 0;
    final byMethod = (_summaryData['byMethod'] as Map<String, dynamic>?) ?? {};
    final cashAmount = (byMethod['CASH'] as num?) ?? 0;
    final posAmount = (byMethod['CREDIT_CARD'] as num?) ?? 0;
    final transferAmount = (byMethod['BANK_TRANSFER'] as num?) ?? 0;
    final invoicesIssued = (_summaryData['invoicesIssued'] as num?) ?? (_summaryData['invoiceCount'] as num?) ?? 0;
    final unpaidLeftBehind = (_summaryData['unpaidLeftBehind'] as num?) ?? (_summaryData['unpaidCount'] as num?) ?? 0;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Biên Bản Chốt Ca Trực'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: AppErrorView(
                    error: _errorMessage!,
                    onRetry: _fetchShiftSummary,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card Thông tin ca trực
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: palette.accent.withValues(alpha: 0.15),
                                  child: Icon(Icons.person, color: palette.accent),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staffName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: palette.ink,
                                        ),
                                      ),
                                      Text(
                                        'Ngày: ${Formatters.formatDate(DateTime.now())} • Quầy Lễ tân – Thu ngân',
                                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: palette.statusAvailable.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    'ĐANG CHỐT',
                                    style: TextStyle(
                                      color: palette.statusAvailableInk,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Tổng tiền thu
                            Text(
                              'TỔNG TIỀN THỰC THU TRONG CA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.inkMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(amountCollected),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: palette.accent,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Phân rã theo phương thức thanh toán
                      Text(
                        'Phân Rã Theo Phương Thức',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _buildPaymentRow(
                              icon: Icons.money,
                              color: Colors.teal,
                              title: 'Tiền mặt (CASH)',
                              amount: cashAmount,
                              palette: palette,
                            ),
                            const Divider(height: 16),
                            _buildPaymentRow(
                              icon: Icons.credit_card,
                              color: Colors.blue,
                              title: 'Thẻ POS ngân hàng',
                              amount: posAmount,
                              palette: palette,
                            ),
                            const Divider(height: 16),
                            _buildPaymentRow(
                              icon: Icons.qr_code_2_rounded,
                              color: Colors.purple,
                              title: 'VietQR / Chuyển khoản',
                              amount: transferAmount,
                              palette: palette,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Số lượng hóa đơn
                      Text(
                        'Thống Kê Chứng Từ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hóa đơn đã xuất', style: TextStyle(fontSize: 12, color: palette.inkMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$invoicesIssued',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: palette.statusAvailableInk),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hóa đơn chưa thu', style: TextStyle(fontSize: 12, color: palette.inkMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$unpaidLeftBehind',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: palette.statusOccupiedInk),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Nút In biên bản chốt ca
                      PressableScale(
                        onTap: _printShiftReport,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppGradients.gold,
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            boxShadow: AppShadows.goldGlow,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.print_outlined, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'In Biên Bản Chốt Ca',
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
                    ],
                  ),
                ),
    );
  }

  Widget _buildPaymentRow({
    required IconData icon,
    required Color color,
    required String title,
    required num amount,
    required AppPalette palette,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
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
}
