import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/app_card.dart';
import 'skeleton_primitives.dart';

/// Skeleton mô phỏng hàng hóa đơn màn thu ngân
class InvoiceRowSkeleton extends StatelessWidget {
  const InvoiceRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: AppRadius.cardSmall),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonText(width: 100, height: 15),
                SizedBox(height: 6),
                SkeletonText(width: 140, height: 13),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonText(width: 90, height: 15),
              SizedBox(height: 6),
              SkeletonBox(width: 70, height: 20, borderRadius: AppRadius.pill),
            ],
          ),
        ],
      ),
    );
  }
}
