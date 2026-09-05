import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';

/// Hộp thoại xác nhận thủ tục nhận phòng (POST /bookings/:id/check-in).
///
/// Dùng chung cho màn "Nhận phòng hôm nay" và thao tác nhanh trên sơ đồ buồng
/// phòng để lễ tân luôn thấy cùng một bước xác nhận.
class CheckInConfirmDialog {
  CheckInConfirmDialog._();

  /// Trả về `true` khi lễ tân bấm "Xác nhận".
  static Future<bool> show({
    required BuildContext context,
    required BookingModel booking,
  }) async {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: palette.accent, size: 26),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Xác nhận Nhận phòng',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thực hiện thủ tục nhận phòng cho khách hàng ${booking.customerName ?? ''} vào phòng ${booking.roomNumber ?? ''}?',
              style: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mã đặt phòng:',
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                      Text(
                        booking.bookingCode ?? booking.id,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng tiền:',
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                      Text(
                        Formatters.formatCurrency(booking.totalAmount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: TextStyle(color: palette.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}
