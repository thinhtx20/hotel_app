import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/app_card.dart';
import 'skeleton_primitives.dart';

/// Skeleton mô phỏng thẻ phòng của khách hàng
class RoomCardSkeleton extends StatelessWidget {
  const RoomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh phòng skeleton
          const SkeletonBox(
            width: double.infinity,
            height: 180,
            borderRadius: AppRadius.card,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonText(width: 140, height: 18),
                    SkeletonBox(width: 70, height: 24, borderRadius: AppRadius.pill),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const SkeletonText(width: 200, height: 13),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonText(width: 100, height: 16),
                    SkeletonBox(width: 80, height: 36, borderRadius: AppRadius.button),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
