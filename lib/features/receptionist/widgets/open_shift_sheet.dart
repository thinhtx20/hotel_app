import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/work_shift_model.dart';
import '../../../shared/repositories/shift_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// BottomSheet Nhận Ca Trực & Khai Báo Tiền Két Quầy dành cho Lễ tân
class OpenShiftSheet extends StatefulWidget {
  final ShiftRepository? shiftRepository;
  final ValueChanged<WorkShiftModel>? onShiftOpened;

  const OpenShiftSheet({
    super.key,
    this.shiftRepository,
    this.onShiftOpened,
  });

  static Future<WorkShiftModel?> show({
    required BuildContext context,
    ShiftRepository? shiftRepository,
    ValueChanged<WorkShiftModel>? onShiftOpened,
  }) {
    return AppBottomSheet.show<WorkShiftModel>(
      context: context,
      builder: (ctx) => OpenShiftSheet(
        shiftRepository: shiftRepository,
        onShiftOpened: onShiftOpened,
      ),
    );
  }

  @override
  State<OpenShiftSheet> createState() => _OpenShiftSheetState();
}

class _OpenShiftSheetState extends State<OpenShiftSheet> {
  late final ShiftRepository _shiftRepo =
      widget.shiftRepository ??
      (sl.isRegistered<ShiftRepository>() ? sl<ShiftRepository>() : ShiftRepository());

  late ShiftType _selectedShiftType;
  final TextEditingController _deskNameController =
      TextEditingController(text: 'Quầy Lễ Tân 1');
  final TextEditingController _initialCashController =
      TextEditingController(text: '2000000');
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedShiftType = _suggestInitialShiftType();
  }

  @override
  void dispose() {
    _deskNameController.dispose();
    _initialCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static ShiftType _suggestInitialShiftType() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return ShiftType.morning;
    if (hour >= 14 && hour < 22) return ShiftType.afternoon;
    return ShiftType.night;
  }

  double _parseCashInput(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  void _setCash(double value) {
    setState(() {
      _initialCashController.text = value.toStringAsFixed(0);
    });
  }

  Future<void> _submit() async {
    final cash = _parseCashInput(_initialCashController.text);
    if (cash < 0) {
      AppNotification.showWarning(
        context,
        'Số tiền bàn giao két không được âm!',
        title: 'Kiểm tra số tiền',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final shift = await _shiftRepo.openShift(
        shiftType: _selectedShiftType,
        initialCash: cash,
        deskName: _deskNameController.text.trim().isNotEmpty
            ? _deskNameController.text.trim()
            : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      if (!mounted) return;

      Navigator.of(context).pop(shift);
      widget.onShiftOpened?.call(shift);

      AppNotification.showSuccess(
        context,
        'Đã mở ca trực "${shift.shiftCode}" (${shift.shiftType.label}) với ${Formatters.formatCurrency(shift.initialCash)} tiền két.',
        title: 'Vào ca thành công!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotification.showError(
        context,
        e,
        title: 'Mở ca trực thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final parsedCash = _parseCashInput(_initialCashController.text);

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
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: palette.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhận Ca Trực & Bàn Giao Két',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Khai báo loại ca và số tiền mặt trong két quầy',
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
            const SizedBox(height: AppSpacing.lg),

            // 1. Chọn loại ca trực
            Text(
              'Loại ca trực (*)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ShiftType.values.map((type) {
                final isSelected = _selectedShiftType == type;
                return PressableScale(
                  onTap: () => setState(() => _selectedShiftType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.accent.withValues(alpha: 0.15)
                          : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isSelected ? palette.accent : palette.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16,
                          color: isSelected ? palette.accent : palette.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? palette.accent : palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Vị trí quầy / Máy làm việc
            Text(
              'Tên quầy / Vị trí trực',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _deskNameController,
              style: TextStyle(color: palette.ink, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Quầy Lễ Tân 1, Quầy Sảnh...',
                prefixIcon: Icon(
                  Icons.desktop_windows_outlined,
                  size: 20,
                  color: palette.inkMuted,
                ),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Tiền mặt nhận bàn giao đầu ca
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiền mặt nhận bàn giao két (*)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(parsedCash),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _initialCashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: palette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập số tiền thực tế trong két',
                prefixIcon: Icon(
                  Icons.payments_outlined,
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

            // Chip chọn nhanh tiền két
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickCashChip(0, '0 đ (Két rỗng)'),
                  _buildQuickCashChip(1000000, '1.000.000 đ'),
                  _buildQuickCashChip(2000000, '2.000.000 đ'),
                  _buildQuickCashChip(3000000, '3.000.000 đ'),
                  _buildQuickCashChip(5000000, '5.000.000 đ'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Ghi chú nhận ca
            Text(
              'Ghi chú nhận bàn giao (Tùy chọn)',
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
                hintText: 'Ví dụ: Nhận bàn giao từ ca đêm, tiền lẻ đầy đủ...',
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Nút Xác nhận Bắt đầu ca trực
            SizedBox(
              width: double.infinity,
              height: 48,
              child: PressableScale(
                onTap: _isSubmitting ? null : _submit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.navy,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
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
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Xác Nhận Bắt Đầu Ca Trực',
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

  Widget _buildQuickCashChip(double value, String label) {
    final palette = context.palette;
    final currentCash = _parseCashInput(_initialCashController.text);
    final isSelected = (currentCash == value);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: () => _setCash(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.accent.withValues(alpha: 0.15)
                : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? palette.accent : palette.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? palette.accent : palette.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
