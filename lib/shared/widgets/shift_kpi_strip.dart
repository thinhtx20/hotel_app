import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// 4 chỉ số của dải KPI ca trực — dùng làm bộ lọc nhanh cho sơ đồ phòng.
enum ShiftKpiFilter {
  /// Phòng trống (`RoomStatus.available`).
  available,

  /// Phòng đang có khách lưu trú (`RoomStatus.occupied`).
  occupied,

  /// Phòng chờ dọn (`RoomStatus.cleaning`).
  cleaning,

  /// Lượt khách đến hôm nay — không lọc sơ đồ mà mở danh sách check-in.
  checkIns,
}

extension ShiftKpiFilterLabel on ShiftKpiFilter {
  /// Nhãn ngắn hiển thị dưới con số trên chip.
  String get label {
    switch (this) {
      case ShiftKpiFilter.available:
        return 'Trống';
      case ShiftKpiFilter.occupied:
        return 'Đang ở';
      case ShiftKpiFilter.cleaning:
        return 'Chờ dọn';
      case ShiftKpiFilter.checkIns:
        return 'Khách đến';
    }
  }

  /// Nhãn đầy đủ dùng trong thanh trạng thái "Đang lọc: ...".
  String get fullLabel {
    switch (this) {
      case ShiftKpiFilter.available:
        return 'Phòng trống';
      case ShiftKpiFilter.occupied:
        return 'Phòng đang có khách';
      case ShiftKpiFilter.cleaning:
        return 'Phòng chờ dọn';
      case ShiftKpiFilter.checkIns:
        return 'Khách đến hôm nay';
    }
  }

  IconData get icon {
    switch (this) {
      case ShiftKpiFilter.available:
        return Icons.meeting_room_outlined;
      case ShiftKpiFilter.occupied:
        return Icons.person_outline;
      case ShiftKpiFilter.cleaning:
        return Icons.cleaning_services_outlined;
      case ShiftKpiFilter.checkIns:
        return Icons.login_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ShiftKpiFilter.available:
        return const Color(0xFF0D9488);
      case ShiftKpiFilter.occupied:
        return const Color(0xFF2563EB);
      case ShiftKpiFilter.cleaning:
        return const Color(0xFFD97706);
      case ShiftKpiFilter.checkIns:
        return const Color(0xFF7C3AED);
    }
  }

  /// `checkIns` là lối tắt điều hướng, 3 chỉ số còn lại lọc được sơ đồ phòng.
  bool get filtersRoomMatrix => this != ShiftKpiFilter.checkIns;
}

/// Dải 4 chip KPI ca trực hiển thị trên đầu Sơ đồ phòng của Lễ tân – Thu ngân (FE-ROLE-MATRIX §5.1)
///
/// Truyền [onSelect] để biến 4 chip thành bộ lọc nhanh: 3 chip trạng thái lọc
/// ma trận phòng theo [selected], chip "Khách đến" mở danh sách check-in hôm nay.
/// Bỏ trống [onSelect] thì dải chỉ hiển thị số liệu như cũ.
class ShiftKpiStrip extends StatelessWidget {
  final int available;
  final int occupied;
  final int cleaning;
  final int checkIns;

  /// Chip đang được chọn — chỉ có ý nghĩa với 3 chip trạng thái phòng.
  final ShiftKpiFilter? selected;

  /// Bấm vào một chip. `null` = dải chỉ để đọc số liệu.
  final ValueChanged<ShiftKpiFilter>? onSelect;

  const ShiftKpiStrip({
    super.key,
    required this.available,
    required this.occupied,
    required this.cleaning,
    required this.checkIns,
    this.selected,
    this.onSelect,
  });

  int _valueOf(ShiftKpiFilter filter) {
    switch (filter) {
      case ShiftKpiFilter.available:
        return available;
      case ShiftKpiFilter.occupied:
        return occupied;
      case ShiftKpiFilter.cleaning:
        return cleaning;
      case ShiftKpiFilter.checkIns:
        return checkIns;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.surface.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildItem(context, ShiftKpiFilter.available)),
          _buildDivider(palette),
          Expanded(child: _buildItem(context, ShiftKpiFilter.occupied)),
          _buildDivider(palette),
          Expanded(child: _buildItem(context, ShiftKpiFilter.cleaning)),
          _buildDivider(palette),
          Expanded(child: _buildItem(context, ShiftKpiFilter.checkIns)),
        ],
      ),
    );
  }

  Widget _buildDivider(AppPalette palette) {
    return Container(
      height: 28,
      width: 1,
      color: palette.divider.withValues(alpha: 0.7),
    );
  }

  Widget _buildItem(BuildContext context, ShiftKpiFilter filter) {
    final palette = context.palette;
    final color = filter.color;
    final value = _valueOf(filter);
    final isSelected = filter.filtersRoomMatrix && selected == filter;
    final isTappable = onSelect != null;

    final content = AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.55) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.filter_alt_rounded : filter.icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
              if (filter == ShiftKpiFilter.checkIns && isTappable) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            filter.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : palette.inkMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!isTappable) return content;

    return Semantics(
      button: true,
      selected: isSelected,
      label: filter.filtersRoomMatrix
          ? '${filter.fullLabel}: $value. ${isSelected ? "Chạm để bỏ lọc" : "Chạm để lọc sơ đồ phòng"}'
          : '${filter.fullLabel}: $value. Chạm để mở danh sách nhận phòng',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect!(filter),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          child: content,
        ),
      ),
    );
  }
}
