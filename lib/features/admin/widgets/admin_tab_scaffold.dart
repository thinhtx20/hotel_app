import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/room_repository.dart';

/// Shell Scaffold chứa Bottom Navigation Bar phong cách Modern Luxury cho Quản trị viên (Admin).
/// Gồm 4 tab chính:
/// - Tổng quan (Dashboard báo cáo kinh doanh)
/// - Duyệt phòng (Kèm huy hiệu số lượng phòng chờ duyệt thời gian thực)
/// - Sơ đồ phòng (Ma trận trạng thái buồng phòng)
/// - Thu ngân (Hóa đơn & thu tiền theo ca)
class AdminTabScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminTabScaffold({
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
                  label: 'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  isSelected: navigationShell.currentIndex == 0,
                ),
                AnimatedBuilder(
                  animation: sl.isRegistered<RoomRepository>()
                      ? sl<RoomRepository>()
                      : ChangeNotifier(),
                  builder: (context, _) {
                    final pendingCount = sl.isRegistered<RoomRepository>()
                        ? sl<RoomRepository>().pendingRooms.length
                        : 0;
                    return _buildNavItem(
                      index: 1,
                      label: 'Duyệt phòng',
                      icon: Icons.fact_check_outlined,
                      activeIcon: Icons.fact_check_rounded,
                      badgeCount: pendingCount > 0 ? '$pendingCount' : null,
                      isSelected: navigationShell.currentIndex == 1,
                    );
                  },
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Sơ đồ phòng',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  isSelected: navigationShell.currentIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Thu ngân',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
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
              // Gạch nhỏ chỉ báo mục đang chọn
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
