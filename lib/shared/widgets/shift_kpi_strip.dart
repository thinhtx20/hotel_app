import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Dải 4 chip KPI ca trực hiển thị trên đầu Sơ đồ phòng của Lễ tân – Thu ngân (FE-ROLE-MATRIX §5.1)
class ShiftKpiStrip extends StatelessWidget {
  final int available;
  final int occupied;
  final int cleaning;
  final int checkIns;

  const ShiftKpiStrip({
    super.key,
    required this.available,
    required this.occupied,
    required this.cleaning,
    required this.checkIns,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(context, 'Trống', available, const Color(0xFF0D9488), Icons.meeting_room_outlined),
          _buildDivider(palette),
          _buildItem(context, 'Đang ở', occupied, const Color(0xFF2563EB), Icons.person_outline),
          _buildDivider(palette),
          _buildItem(context, 'Chờ dọn', cleaning, const Color(0xFFD97706), Icons.cleaning_services_outlined),
          _buildDivider(palette),
          _buildItem(context, 'Khách đến', checkIns, const Color(0xFF7C3AED), Icons.login_rounded),
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

  Widget _buildItem(
    BuildContext context,
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
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
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: palette.inkMuted,
          ),
        ),
      ],
    );
  }
}
