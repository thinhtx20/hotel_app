import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Shell Scaffold chứa Bottom Navigation Bar phong cách Modern Luxury cho khách hàng.
class CustomerTabScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerTabScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.sheet),
            topRight: Radius.circular(AppRadius.sheet),
          ),
          border: palette.isDark
              ? Border(top: BorderSide(color: palette.border, width: 1))
              : null,
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'Khám phá',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  isSelected: navigationShell.currentIndex == 0,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'Dịch vụ',
                  icon: Icons.room_service_outlined,
                  activeIcon: Icons.room_service_rounded,
                  isSelected: navigationShell.currentIndex == 1,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'Chuyến đi',
                  icon: Icons.luggage_outlined,
                  activeIcon: Icons.luggage_rounded,
                  isSelected: navigationShell.currentIndex == 2,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  label: 'Tài khoản',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isSelected: navigationShell.currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    String? badgeCount,
  }) {
    final palette = context.palette;

    return Expanded(
      child: PressableScale(
        onTap: () => _onTap(index),
        scale: 0.95,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? palette.accent : palette.inkMuted,
                      size: 24,
                    ),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: palette.surface,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? palette.accent : palette.inkMuted,
                ),
              ),
              const SizedBox(height: 3),
              // Gạch nhỏ chỉ báo mục đang chọn
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 16 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
