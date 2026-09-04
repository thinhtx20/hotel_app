import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../di/injection_container.dart';
import '../repositories/booking_repository.dart';
import '../repositories/room_repository.dart';
import 'motion/pressable_scale.dart';

/// Một mục trên thanh điều hướng của nhân viên.
class StaffTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Gắn huy hiệu số phòng đang chờ duyệt (tab "Duyệt phòng").
  final bool showsPendingRoomsBadge;

  /// Gắn huy hiệu số đơn đặt phòng đang chờ duyệt (tab "Duyệt đơn").
  final bool showsPendingBookingsBadge;

  const StaffTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.showsPendingRoomsBadge = false,
    this.showsPendingBookingsBadge = false,
  });
}

/// Shell Scaffold chứa Bottom Navigation Bar phong cách Modern Luxury dùng
/// chung cho ADMIN, RECEPTIONIST và CASHIER.
///
/// Mỗi vai trò truyền vào bộ tab của riêng mình — xem `design/FE-ROLE-MATRIX.md`
/// Phần 4. Tab nào cũng đã được lọc theo quyền ở [AppRouter], nên widget này
/// không tự kiểm tra role.
class StaffTabScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<StaffTab> tabs;

  const StaffTabScaffold({
    super.key,
    required this.navigationShell,
    required this.tabs,
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
                for (var i = 0; i < tabs.length; i++)
                  tabs[i].showsPendingRoomsBadge
                      ? _buildBadgedNavItem(context, i, tabs[i])
                      : tabs[i].showsPendingBookingsBadge
                          ? _buildBadgedBookingNavItem(context, i, tabs[i])
                          : _buildNavItem(
                              context: context,
                              index: i,
                              tab: tabs[i],
                            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Huy hiệu số phòng chờ duyệt bám theo [RoomRepository] để cập nhật realtime.
  Widget _buildBadgedNavItem(BuildContext context, int index, StaffTab tab) {
    final hasRepo = sl.isRegistered<RoomRepository>();
    if (!hasRepo) {
      return _buildNavItem(context: context, index: index, tab: tab);
    }
    return AnimatedBuilder(
      animation: sl<RoomRepository>(),
      builder: (context, _) {
        final pendingCount = sl<RoomRepository>().pendingRooms.length;
        return _buildNavItem(
          context: context,
          index: index,
          tab: tab,
          badgeCount: pendingCount > 0 ? '$pendingCount' : null,
        );
      },
    );
  }

  /// Huy hiệu số đơn đặt phòng chờ duyệt bám theo [BookingRepository].
  Widget _buildBadgedBookingNavItem(BuildContext context, int index, StaffTab tab) {
    final hasRepo = sl.isRegistered<BookingRepository>();
    if (!hasRepo) {
      return _buildNavItem(context: context, index: index, tab: tab);
    }
    return AnimatedBuilder(
      animation: sl<BookingRepository>(),
      builder: (context, _) {
        final pendingCount = sl<BookingRepository>().pendingCount;
        return _buildNavItem(
          context: context,
          index: index,
          tab: tab,
          badgeCount: pendingCount > 0 ? '$pendingCount' : null,
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required StaffTab tab,
    String? badgeCount,
  }) {
    final palette = context.palette;
    final isSelected = navigationShell.currentIndex == index;

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
                      isSelected ? tab.activeIcon : tab.icon,
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
                          border: Border.all(color: palette.surface, width: 1.5),
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
                tab.label,
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
