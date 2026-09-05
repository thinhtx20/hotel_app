import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import 'service_catalog_screen.dart';
import 'user_management_screen.dart';

/// Màn hình Nhân sự & Dịch vụ của ADMIN (Tab 3 - FE-ROLE-MATRIX §4.1)
class StaffAndServicesScreen extends StatefulWidget {
  final int initialSegment;
  const StaffAndServicesScreen({super.key, this.initialSegment = 0});

  @override
  State<StaffAndServicesScreen> createState() => _StaffAndServicesScreenState();
}

class _StaffAndServicesScreenState extends State<StaffAndServicesScreen> {
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
      appBar: AppBar(
        title: const Text('Nhân Sự & Dịch Vụ'),
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
                      label: 'Nhân sự',
                      icon: Icons.people_outline_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: 'Bảng giá dịch vụ',
                      icon: Icons.room_service_outlined,
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
          UserManagementScreen(),
          ServiceCatalogScreen(),
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
