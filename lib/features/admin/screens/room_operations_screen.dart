import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../receptionist/screens/room_matrix_screen.dart';
import 'room_approval_screen.dart';
import 'room_type_management_screen.dart';

/// Màn hình Vận hành phòng của ADMIN (Tab 2 - FE-ROLE-MATRIX §4.1)
class RoomOperationsScreen extends StatefulWidget {
  final int initialSegment;
  const RoomOperationsScreen({super.key, this.initialSegment = 0});

  @override
  State<RoomOperationsScreen> createState() => _RoomOperationsScreenState();
}

class _RoomOperationsScreenState extends State<RoomOperationsScreen> {
  late int _selectedSegment;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
  }

  Future<void> _syncRoomStatuses() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final repo = sl<RoomRepository>();
      final result = await repo.syncStatus();
      if (!mounted) return;
      setState(() => _isSyncing = false);
      final syncedCount = result['updatedCount'] ?? result['count'] ?? result['synced'] ?? '';
      final msg = syncedCount != '' && syncedCount != 0
          ? 'Đã rà soát & đồng bộ $syncedCount phòng theo lịch đặt hiện hành.'
          : 'Trạng thái toàn bộ phòng đã khớp chính xác với lịch đặt.';
      AppNotification.showSuccess(context, msg, title: 'Đồng bộ phòng');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      AppNotification.showError(context, e, title: 'Đồng bộ thất bại');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Vận Hành Phòng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Rà soát & đồng bộ trạng thái phòng (FR-27)',
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _isSyncing ? null : _syncRoomStatuses,
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
                    child: _buildSegmentButton(
                      index: 0,
                      label: 'Sơ đồ',
                      icon: Icons.grid_view_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: 'Hạng phòng',
                      icon: Icons.hotel_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 2,
                      label: 'Chờ duyệt',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedSegment,
        children: const [
          RoomMatrixScreen(),
          RoomTypeManagementScreen(),
          RoomApprovalScreen(),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedSegment == index;

    return PressableScale(
      onTap: () => setState(() => _selectedSegment = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
              size: 15,
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
            const SizedBox(width: 5),
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
}
