import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/work_shift_model.dart';
import '../../../shared/repositories/shift_repository.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// BottomSheet Chốt Ca Trực & Bàn Giao Quỹ Két dành cho Lễ tân
class CloseShiftSheet extends StatefulWidget {
  final WorkShiftModel currentShift;
  final ShiftRepository? shiftRepository;
  final UserRepository? userRepository;
  final ValueChanged<WorkShiftModel>? onShiftClosed;

  const CloseShiftSheet({
    super.key,
    required this.currentShift,
    this.shiftRepository,
    this.userRepository,
    this.onShiftClosed,
  });

  static Future<WorkShiftModel?> show({
    required BuildContext context,
    required WorkShiftModel currentShift,
    ShiftRepository? shiftRepository,
    UserRepository? userRepository,
    ValueChanged<WorkShiftModel>? onShiftClosed,
  }) {
    return AppBottomSheet.show<WorkShiftModel>(
      context: context,
      builder: (ctx) => CloseShiftSheet(
        currentShift: currentShift,
        shiftRepository: shiftRepository,
        userRepository: userRepository,
        onShiftClosed: onShiftClosed,
      ),
    );
  }

  @override
  State<CloseShiftSheet> createState() => _CloseShiftSheetState();
}

class _CloseShiftSheetState extends State<CloseShiftSheet> {
  late final ShiftRepository _shiftRepo =
      widget.shiftRepository ??
      (sl.isRegistered<ShiftRepository>() ? sl<ShiftRepository>() : ShiftRepository());

  late final UserRepository _userRepo =
      widget.userRepository ??
      (sl.isRegistered<UserRepository>() ? sl<UserRepository>() : UserRepository());

  late final TextEditingController _actualCashController;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<UserModel> _staffList = [];
  String? _selectedHandoverStaffId;
  bool _isLoadingStaff = true;
  bool _isSubmitting = false;

  double get _expectedCash =>
      widget.currentShift.stats?.expectedCash ??
      widget.currentShift.expectedCash ??
      widget.currentShift.initialCash;

  @override
  void initState() {
    super.initState();
    _actualCashController = TextEditingController(
      text: _expectedCash.toStringAsFixed(0),
    );
    _loadStaffList();
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffList() async {
    try {
      final res = await _userRepo.fetchUsersPage(limit: 50);
      if (!mounted) return;
      setState(() {
        _staffList = res.items
            .where((u) => u.isActive && u.id != widget.currentShift.staffId)
            .toList();
        _isLoadingStaff = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  double _parseCashInput(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  Future<void> _submit() async {
    final actualCash = _parseCashInput(_actualCashController.text);
    final difference = actualCash - _expectedCash;
    final isDifference = difference.abs() > 0.01;

    if (isDifference && _reasonController.text.trim().isEmpty) {
      AppNotification.showWarning(
        context,
        'Số tiền thực tế kiểm đếm lệch so với sổ sách! Bạn bắt buộc phải ghi rõ lý do giải trình.',
        title: 'Bắt buộc giải trình chênh lệch',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final closedShift = await _shiftRepo.closeShift(
        actualCash: actualCash,
        differenceReason: isDifference ? _reasonController.text.trim() : null,
        closeNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        handoverStaffId: _selectedHandoverStaffId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(closedShift);
      widget.onShiftClosed?.call(closedShift);

      AppNotification.showSuccess(
        context,
        'Đã chốt ca "${closedShift.shiftCode}" thành công. Tiền thực tế: ${Formatters.formatCurrency(actualCash)}.',
        title: 'Chốt ca hoàn tất!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotification.showError(
        context,
        e,
        title: 'Chốt ca thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shift = widget.currentShift;
    final actualCash = _parseCashInput(_actualCashController.text);
    final difference = actualCash - _expectedCash;
    final hasDiff = difference.abs() > 0.01;

    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Chốt Ca & Bàn Giao Két',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              shift.shiftType.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã ca: ${shift.shiftCode} • ${shift.deskName.isNotEmpty ? shift.deskName : "Quầy Lễ Tân"}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Card Bảng Kê Đối Soát Két Realtime
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiền mặt đầu ca:',
                        style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                      ),
                      Text(
                        Formatters.formatCurrency(shift.initialCash),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiền mặt đã thu trong ca:',
                        style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                      ),
                      Text(
                        '+ ${Formatters.formatCurrency(shift.stats?.cashCollected ?? 0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  if ((shift.stats?.cashRefunded ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiền mặt đã hoàn trả:',
                          style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                        ),
                        Text(
                          '- ${Formatters.formatCurrency(shift.stats?.cashRefunded ?? 0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 16, color: palette.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiền két lý thuyết (Sổ sách):',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(_expectedCash),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nhập Tiền Thực Tế Kiểm Đếm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiền mặt thực tế kiểm đếm (*)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                PressableScale(
                  onTap: () {
                    setState(() {
                      _actualCashController.text = _expectedCash.toStringAsFixed(0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Khớp với sổ sách',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _actualCashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: palette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập số tiền mặt thực tế trong két',
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: palette.accent,
                ),
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(
                  color: palette.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Hộp cảnh báo chênh lệch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: hasDiff
                    ? (difference > 0
                        ? Colors.amber.shade50
                        : Colors.red.shade50)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: hasDiff
                      ? (difference > 0
                          ? Colors.amber.shade300
                          : Colors.red.shade300)
                      : const Color(0xFF6EE7B7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasDiff
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                    color: hasDiff
                        ? (difference > 0
                            ? Colors.amber.shade900
                            : Colors.red.shade900)
                        : const Color(0xFF059669),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasDiff
                          ? (difference > 0
                              ? 'Thừa quỹ: +${Formatters.formatCurrency(difference)} so với sổ sách.'
                              : 'Thiếu quỹ: ${Formatters.formatCurrency(difference)} so với sổ sách.')
                          : 'Số tiền thực tế khớp 100% với sổ sách két!',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: hasDiff
                            ? (difference > 0
                                ? Colors.amber.shade900
                                : Colors.red.shade900)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nếu lệch tiền -> Bắt buộc nhập giải trình
            if (hasDiff) ...[
              Text(
                'Lý do giải trình chênh lệch (*)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: TextStyle(color: palette.ink, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Khách trả thừa tiền tip, hoàn cọc chưa ghi sổ...',
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.error),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Người nhận bàn giao ca tiếp theo
            Text(
              'Nhân sự nhận bàn giao ca kế tiếp (Tùy chọn)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _isLoadingStaff
                ? const LinearProgressIndicator(minHeight: 2)
                : DropdownButtonFormField<String>(
                    initialValue: _selectedHandoverStaffId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        borderSide: BorderSide(color: palette.border),
                      ),
                    ),
                    hint: Text(
                      'Chọn nhân viên nhận ca sau',
                      style: TextStyle(color: palette.inkMuted, fontSize: 13),
                    ),
                    items: _staffList.map((u) {
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Text(
                          '${u.fullName} (${u.role.label})',
                          style: TextStyle(fontSize: 13, color: palette.ink),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedHandoverStaffId = val);
                    },
                  ),
            const SizedBox(height: AppSpacing.lg),

            // Ghi chú chốt ca
            Text(
              'Ghi chú chốt ca (Tùy chọn)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(color: palette.ink, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Đã bàn giao chìa khóa két và toàn bộ biên lai POS...',
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Nút Xác nhận Chốt Ca & Bàn Giao
            SizedBox(
              width: double.infinity,
              height: 48,
              child: PressableScale(
                onTap: _isSubmitting ? null : _submit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Xác Nhận Chốt Ca & Bàn Giao',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
