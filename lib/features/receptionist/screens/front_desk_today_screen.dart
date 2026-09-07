import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../admin/screens/today_check_ins_screen.dart';
import '../../admin/screens/today_check_outs_screen.dart';
import '../widgets/walk_in_check_in_modal.dart';

/// Tab Hôm nay (Check-in / Check-out gộp) cho Lễ tân – Thu ngân (FE-ROLE-MATRIX §4.2)
class FrontDeskTodayScreen extends StatefulWidget {
  final int initialSegment;
  const FrontDeskTodayScreen({super.key, this.initialSegment = 0});

  @override
  State<FrontDeskTodayScreen> createState() => _FrontDeskTodayScreenState();
}

class _FrontDeskTodayScreenState extends State<FrontDeskTodayScreen> {
  late int _selectedSegment;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: _selectedSegment == 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => WalkInCheckInModal.show(context: context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Nhận phòng tại quầy (Walk-in)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      appBar: AppBar(
        title: const Text('Lượt Khách Hôm Nay'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      label: 'Khách đến (Check-in)',
                      icon: Icons.login_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: 'Khách đi (Check-out)',
                      icon: Icons.logout_rounded,
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
          TodayCheckInsScreen(),
          TodayCheckOutsScreen(),
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
              size: 16,
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
