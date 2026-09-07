import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/work_shift_model.dart';
import '../../../shared/repositories/shift_repository.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import 'close_shift_sheet.dart';
import 'open_shift_sheet.dart';

/// Thanh trạng thái Ca trực thông minh ghim trên màn hình của Lễ tân.
/// Tự động hiển thị lời nhắc Mở ca (nếu chưa vào ca) hoặc Đối soát két Realtime (nếu đang trực).
class ReceptionistShiftBanner extends StatefulWidget {
  final ShiftRepository? shiftRepository;
  final VoidCallback? onShiftChanged;

  const ReceptionistShiftBanner({
    super.key,
    this.shiftRepository,
    this.onShiftChanged,
  });

  @override
  State<ReceptionistShiftBanner> createState() => ReceptionistShiftBannerState();
}

class ReceptionistShiftBannerState extends State<ReceptionistShiftBanner> {
  late final ShiftRepository _shiftRepo =
      widget.shiftRepository ??
      (sl.isRegistered<ShiftRepository>() ? sl<ShiftRepository>() : ShiftRepository());

  WorkShiftModel? _currentShift;
  bool _isLoading = true;

  WorkShiftModel? get currentShift => _currentShift;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Nạp lại dữ liệu ca trực từ máy chủ (Hỗ trợ gọi từ bên ngoài)
  Future<void> reload({bool isSilent = false}) async {
    if (!isSilent && _currentShift == null) {
      setState(() => _isLoading = true);
    }

    try {
      final shift = await _shiftRepo.getCurrentShift();
      if (!mounted) return;
      setState(() {
        _currentShift = shift;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openOpenShiftSheet() {
    OpenShiftSheet.show(
      context: context,
      shiftRepository: _shiftRepo,
      onShiftOpened: (shift) {
        setState(() => _currentShift = shift);
        widget.onShiftChanged?.call();
      },
    );
  }

  void _openCloseShiftSheet() {
    if (_currentShift == null) return;
    CloseShiftSheet.show(
      context: context,
      currentShift: _currentShift!,
      shiftRepository: _shiftRepo,
      onShiftClosed: (_) {
        setState(() => _currentShift = null);
        widget.onShiftChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_isLoading) {
      return Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: palette.border),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'Đang kiểm tra ca trực quầy...',
              style: TextStyle(fontSize: 12, color: palette.inkMuted),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP 1: Lễ tân CHƯA MỞ CA
    if (_currentShift == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.isDark
              ? Colors.amber.shade900.withValues(alpha: 0.15)
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(
            color: palette.isDark
                ? Colors.amber.shade800.withValues(alpha: 0.4)
                : const Color(0xFFFDE68A),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.amber.shade500.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock_rounded,
                color: palette.isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn chưa vào ca trực quầy hôm nay',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mở ca để ghi nhận tiền két & đối soát hóa đơn',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.isDark ? Colors.amber.shade400 : Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PressableScale(
              onTap: _openOpenShiftSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.navy,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Nhận Ca',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP 2: Lễ tân ĐANG TRONG CA TRỰC (ACTIVE)
    final shift = _currentShift!;
    final expectedCash = shift.stats?.expectedCash ?? shift.initialCash;
    final totalRevenue = shift.stats?.totalRevenue ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dòng 1: Realtime status & Nút Chốt ca
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'ĐANG TRỰC: ${shift.shiftType.label.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        shift.deskName.isNotEmpty ? shift.deskName : 'Quầy 1',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PressableScale(
                onTap: _openCloseShiftSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chốt ca & Giao két',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 18, color: palette.divider),

          // Dòng 2: 3 chỉ số nhanh đối soát két
          Row(
            children: [
              // Mã ca & giờ vào
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã ca trực',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.shiftCode,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: palette.divider),
              // Tiền két lý thuyết
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Két tiền hiện tại',
                        style: TextStyle(fontSize: 11, color: palette.inkMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(expectedCash),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: palette.divider),
              // Doanh thu ca
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh thu ca',
                        style: TextStyle(fontSize: 11, color: palette.inkMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(totalRevenue),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
