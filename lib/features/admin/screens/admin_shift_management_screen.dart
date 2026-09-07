import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/work_shift_model.dart';
import '../../../shared/repositories/shift_repository.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import 'shift_detail_screen.dart';

class AdminShiftManagementScreen extends StatefulWidget {
  final int initialTab;

  const AdminShiftManagementScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<AdminShiftManagementScreen> createState() =>
      _AdminShiftManagementScreenState();
}

class _AdminShiftManagementScreenState
    extends State<AdminShiftManagementScreen> {
  late final ShiftRepository _shiftRepo = sl<ShiftRepository>();

  late int _selectedTab;

  // Tab 0: Active Shifts
  List<WorkShiftModel> _activeShifts = [];
  bool _isActiveLoading = true;
  String? _activeError;

  // Tab 1: Shift History
  List<WorkShiftModel> _historyShifts = [];
  bool _isHistoryLoading = true;
  String? _historyError;
  int _historyPage = 1;
  int _historyTotal = 0;
  int _historyTotalPages = 1;
  String _historyFilterRange = 'ALL'; // ALL, TODAY, 7DAYS
  ShiftStatus? _historyFilterStatus;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchActiveShifts();
    _fetchHistoryShifts();
  }

  Future<void> _fetchActiveShifts() async {
    setState(() {
      _isActiveLoading = true;
      _activeError = null;
    });

    try {
      final list = await _shiftRepo.getActiveShifts();
      if (mounted) {
        setState(() {
          _activeShifts = list;
          _isActiveLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActiveLoading = false;
          _activeError = e.toString();
        });
      }
    }
  }

  Future<void> _fetchHistoryShifts({int page = 1}) async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });

    String? fromDate;
    String? toDate;
    final now = DateTime.now();

    if (_historyFilterRange == 'TODAY') {
      fromDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      toDate = fromDate;
    } else if (_historyFilterRange == '7DAYS') {
      final start = now.subtract(const Duration(days: 7));
      fromDate =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      toDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    try {
      final res = await _shiftRepo.getShifts(
        status: _historyFilterStatus,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        limit: 15,
      );

      if (mounted) {
        setState(() {
          _historyShifts = res['items'] as List<WorkShiftModel>;
          _historyPage = res['page'] as int;
          _historyTotal = res['total'] as int;
          _historyTotalPages = res['totalPages'] as int;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
          _historyError = e.toString();
        });
      }
    }
  }

  /// Mở dialog cho Admin chốt ca hộ nhân viên
  Future<void> _openAdminCloseShiftDialog(WorkShiftModel shift) async {
    final palette = context.palette;
    final actualCashController = TextEditingController(
      text: shift.currentExpectedCash.toInt().toString(),
    );
    final reasonController = TextEditingController();
    final noteController = TextEditingController();

    double actualCash = shift.currentExpectedCash;
    double difference = 0.0;
    String? selectedHandoverStaffId;
    List<UserModel> availableStaff = [];

    // Tải danh sách nhân sự để chọn người nhận bàn giao
    try {
      final staffRes = await sl<UserRepository>().fetchUsersPage(limit: 50);
      availableStaff = staffRes.items
          .where((u) => u.isActive && u.id != shift.staffId)
          .toList();
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final expected = shift.currentExpectedCash;
            final isDiff = difference.abs() > 0.01;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.inkMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.lock_clock_rounded, color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quản Trị Viên Chốt Ca Hộ',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${shift.deskName} • Nhân viên: ${shift.staffName}',
                                style: TextStyle(fontSize: 12, color: palette.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Tiền sổ sách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tiền sổ sách hiện tại:', style: TextStyle(fontSize: 13, color: palette.inkMuted)),
                        Text(
                          Formatters.formatCurrency(expected),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Tiền mặt kiểm đếm thực tế
                    const Text(
                      'Số tiền mặt thực kiểm đếm trong két (*)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: actualCashController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: 'VNĐ',
                        hintText: 'Nhập số tiền thực tế',
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                        setModalState(() {
                          actualCash = parsed;
                          difference = actualCash - expected;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cảnh báo chênh lệch
                    if (isDiff) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: difference > 0 ? Colors.amber.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: difference > 0 ? Colors.amber.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: difference > 0 ? Colors.amber.shade800 : Colors.red.shade800,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  difference > 0
                                      ? 'Thừa két: +${Formatters.formatCurrency(difference)}'
                                      : 'Thiếu két: ${Formatters.formatCurrency(difference)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: difference > 0 ? Colors.amber.shade900 : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số tiền không khớp sổ sách. Bạn bắt buộc phải ghi rõ lý do giải trình bên dưới.',
                              style: TextStyle(fontSize: 11, color: difference > 0 ? Colors.amber.shade900 : Colors.red.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Lý do chênh lệch quỹ tiền (*)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Khách gửi tiền tip chưa ghi sổ...',
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Người nhận bàn giao
                    if (availableStaff.isNotEmpty) ...[
                      const Text(
                        'Nhân sự nhận bàn giao ca tiếp theo (Tùy chọn)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedHandoverStaffId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Chọn nhân sự nhận bàn giao'),
                        items: availableStaff.map((u) {
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Text('${u.fullName} (${u.role.label})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedHandoverStaffId = val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Ghi chú chốt ca
                    const Text('Ghi chú chốt ca (Tùy chọn)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'Nhập ghi chú bàn giao hoặc kiểm két...',
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Nút xác nhận
                    PressableScale(
                      onTap: () async {
                        if (isDiff && reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập lý do giải trình chênh lệch tiền mặt!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        _performAdminCloseShift(
                          shift.id,
                          actualCash: actualCash,
                          differenceReason: reasonController.text.trim(),
                          closeNote: noteController.text.trim(),
                          handoverStaffId: selectedHandoverStaffId,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppGradients.navy,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Xác Nhận Chốt Ca & Khóa Sổ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performAdminCloseShift(
    String shiftId, {
    required double actualCash,
    String? differenceReason,
    String? closeNote,
    String? handoverStaffId,
  }) async {
    try {
      await _shiftRepo.adminCloseShift(
        shiftId,
        actualCash: actualCash,
        differenceReason: differenceReason,
        closeNote: closeNote,
        handoverStaffId: handoverStaffId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chốt ca trực và khóa sổ két thành công!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _fetchActiveShifts();
        _fetchHistoryShifts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chốt ca: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Quản Lý Ca Trực & Tiền Két'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: () {
              if (_selectedTab == 0) {
                _fetchActiveShifts();
              } else {
                _fetchHistoryShifts();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentTab(
                      index: 0,
                      label: 'Quầy Đang Trực (${_activeShifts.length})',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentTab(
                      index: 1,
                      label: 'Sổ Giao Ca & Lịch Sử',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildActiveShiftsTab(palette),
          _buildHistoryShiftsTab(palette),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;

    return PressableScale(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 0: QUẦY ĐANG TRỰC ====================

  Widget _buildActiveShiftsTab(AppPalette palette) {
    if (_isActiveLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeError != null) {
      return Center(
        child: AppErrorView(
          error: _activeError!,
          onRetry: _fetchActiveShifts,
        ),
      );
    }

    final totalActive = _activeShifts.length;
    final totalExpectedCash = _activeShifts.fold<double>(
      0.0,
      (sum, s) => sum + s.currentExpectedCash,
    );
    final totalRevenue = _activeShifts.fold<double>(
      0.0,
      (sum, s) => sum + s.effectiveRevenue,
    );

    return RefreshIndicator(
      onRefresh: _fetchActiveShifts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Strip
            Row(
              children: [
                Expanded(
                  child: _buildKpiBox(
                    title: 'Quầy đang trực',
                    value: '$totalActive quầy',
                    icon: Icons.storefront_outlined,
                    color: palette.statusAvailableInk,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildKpiBox(
                    title: 'Tiền mặt trong két',
                    value: Formatters.formatCurrency(totalExpectedCash),
                    icon: Icons.account_balance_wallet_outlined,
                    color: palette.accent,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildKpiBox(
                    title: 'Doanh thu ca',
                    value: Formatters.formatCurrency(totalRevenue),
                    icon: Icons.trending_up_rounded,
                    color: Colors.blue.shade700,
                    palette: palette,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'DANH SÁCH QUẦY ĐANG MỞ CA (${_activeShifts.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_activeShifts.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: palette.statusAvailableInk,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hiện không có quầy nào đang trực',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tất cả ca trực đã được chốt và tiền két đã bàn giao an toàn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeShifts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shift = _activeShifts[index];
                  return _buildActiveShiftCard(shift, palette);
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required AppPalette palette,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: palette.inkMuted, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftCard(WorkShiftModel shift, AppPalette palette) {
    final type = shift.shiftType;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: type.color.withValues(alpha: 0.15),
                backgroundImage: shift.staffAvatar != null && shift.staffAvatar!.isNotEmpty
                    ? NetworkImage(shift.staffAvatar!)
                    : null,
                child: shift.staffAvatar == null || shift.staffAvatar!.isEmpty
                    ? Icon(Icons.person, color: type.color)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shift.staffName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type.icon, size: 12, color: type.color),
                              const SizedBox(width: 4),
                              Text(
                                type.label.split('(').first.trim(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: type.color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shift.deskName} • Vào ca: ${Formatters.formatDateTime(shift.startTime)}',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Đối soát tiền mặt & Doanh thu
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiền đầu ca', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(shift.initialCash),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Két hiện có (Lý thuyết)', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(shift.currentExpectedCash),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.accent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Doanh thu ca', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(shift.effectiveRevenue),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShiftDetailScreen(
                          shiftId: shift.id,
                          initialShift: shift,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('Chi tiết sổ', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: palette.border),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAdminCloseShiftDialog(shift),
                  icon: const Icon(Icons.lock_clock_outlined, size: 16),
                  label: const Text('Chốt ca hộ', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: SỔ GIAO CA & LỊCH SỬ ====================

  Widget _buildHistoryShiftsTab(AppPalette palette) {
    return RefreshIndicator(
      onRefresh: () => _fetchHistoryShifts(page: 1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chip row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả thời gian', 'ALL', palette),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hôm nay', 'TODAY', palette),
                  const SizedBox(width: 8),
                  _buildFilterChip('7 ngày qua', '7DAYS', palette),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: palette.border),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: Text(
                      _historyFilterStatus == ShiftStatus.closed
                          ? 'Chỉ xem đã chốt'
                          : 'Tất cả trạng thái',
                      style: TextStyle(fontSize: 12, color: palette.ink),
                    ),
                    selected: _historyFilterStatus == ShiftStatus.closed,
                    onSelected: (val) {
                      setState(() {
                        _historyFilterStatus = val ? ShiftStatus.closed : null;
                      });
                      _fetchHistoryShifts(page: 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isHistoryLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_historyError != null)
              AppErrorView(
                error: _historyError!,
                onRetry: () => _fetchHistoryShifts(page: 1),
              )
            else if (_historyShifts.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: palette.inkMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có dữ liệu ca trực trong khoảng thời gian này',
                        style: TextStyle(fontSize: 14, color: palette.inkMuted),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'LỊCH SỬ CA TRỰC ($_historyTotal kết quả)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.inkMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historyShifts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final shift = _historyShifts[index];
                  return _buildHistoryShiftTile(shift, palette);
                },
              ),
              if (_historyTotalPages > 1) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _historyPage > 1
                          ? () => _fetchHistoryShifts(page: _historyPage - 1)
                          : null,
                    ),
                    Text(
                      'Trang $_historyPage / $_historyTotalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _historyPage < _historyTotalPages
                          ? () => _fetchHistoryShifts(page: _historyPage + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, AppPalette palette) {
    final isSelected = _historyFilterRange == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : palette.ink)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (val) {
        if (val) {
          setState(() => _historyFilterRange = value);
          _fetchHistoryShifts(page: 1);
        }
      },
    );
  }

  Widget _buildHistoryShiftTile(WorkShiftModel shift, AppPalette palette) {
    final hasDiff = shift.hasDifference;
    final isOpen = shift.isOpen;

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShiftDetailScreen(
              shiftId: shift.id,
              initialShift: shift,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shift.shiftCode,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shift.deskName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
                  ),
                ],
              ),
              // Badge chênh lệch két hoặc đang trực
              if (isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.statusAvailable.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'ĐANG TRỰC',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: palette.statusAvailableInk),
                  ),
                )
              else if (hasDiff)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: shift.isOverCash ? Colors.amber.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    shift.isOverCash ? 'THỪA TIỀN' : 'THIẾU TIỀN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: shift.isOverCash ? Colors.amber.shade900 : Colors.red.shade900,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'KHỚP TIỀN 100%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green.shade800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.staffName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${Formatters.formatDateTime(shift.startTime)} • ${shift.shiftType.label.split('(').first.trim()}',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Doanh thu: ${Formatters.formatCurrency(shift.effectiveRevenue)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.accent),
                  ),
                  if (shift.actualCash != null)
                    Text(
                      'Kiểm két: ${Formatters.formatCurrency(shift.actualCash!)}',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: palette.inkMuted),
            ],
          ),

          if (shift.handoverStaffName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bàn giao cho: ${shift.handoverStaffName}',
              style: TextStyle(fontSize: 11, color: palette.inkMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
