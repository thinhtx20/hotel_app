import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/app_card.dart';
import 'skeleton_primitives.dart';

/// Skeleton mô phỏng lưới sơ đồ buồng phòng
class RoomMatrixSkeleton extends StatelessWidget {
  const RoomMatrixSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int floor = 1; floor <= 3; floor++) ...[
            Row(
              children: [
                SkeletonBox(width: 80, height: 20, borderRadius: AppRadius.pill),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                return const AppCard(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  borderRadius: AppRadius.cardSmall,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonText(width: 40, height: 16),
                      SizedBox(height: 6),
                      SkeletonBox(width: 50, height: 16, borderRadius: AppRadius.pill),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}
