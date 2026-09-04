import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../widgets/app_card.dart';
import 'skeleton_primitives.dart';

/// Skeleton mô phỏng thẻ đơn đặt phòng của khách hàng
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonText(width: 110, height: 16),
              SkeletonBox(width: 80, height: 24, borderRadius: AppRadius.pill),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const SkeletonBox(width: 72, height: 72, borderRadius: AppRadius.cardSmall),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonText(width: 150, height: 16),
                    SizedBox(height: 6),
                    SkeletonText(width: 100, height: 13),
                    SizedBox(height: 6),
                    SkeletonText(width: 120, height: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonText(width: 90, height: 14),
              SkeletonText(width: 120, height: 18),
            ],
          ),
        ],
      ),
    );
  }
}
