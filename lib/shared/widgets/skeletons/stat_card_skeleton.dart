import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/app_card.dart';
import 'skeleton_primitives.dart';

/// Skeleton mô phỏng thẻ chỉ số trên Admin Dashboard
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.button),
              SkeletonBox(width: 45, height: 20, borderRadius: AppRadius.pill),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonText(width: 80, height: 13),
          const SizedBox(height: 6),
          const SkeletonText(width: 120, height: 24),
        ],
      ),
    );
  }
}
