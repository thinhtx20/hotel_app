import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Shell Scaffold chứa Bottom Navigation Bar phong cách Modern Luxury cho khách hàng.
/// Đồng bộ theo thiết kế 04-home.md:
/// - Chiều cao 72px + SafeArea, nền trắng, bo góc trên 24px, đổ bóng hướng lên
/// - 4 mục: Khám phá (la bàn), Tìm kiếm (kính lúp), Đơn phòng (lịch + badge), Tài khoản (người)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
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
                  index: 0,
                  label: 'Khám phá',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  isSelected: navigationShell.currentIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Tìm kiếm',
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  isSelected: navigationShell.currentIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Đơn phòng',
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  badgeCount: '2',
                  isSelected: navigationShell.currentIndex == 2,
                ),
                _buildNavItem(
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
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    String? badgeCount,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(index),
          splashColor: AppColors.secondary.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
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
                      color: isSelected ? AppColors.secondary : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
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
                  color: isSelected ? AppColors.secondary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              // Gạch nhỏ chỉ báo mục đang chọn (theo 04-home.md)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 16 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
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
