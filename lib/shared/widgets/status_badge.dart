import 'package:flutter/material.dart';
import '../../core/constants/role_enum.dart';

/// Biểu tượng đi kèm từng trạng thái — trạng thái không bao giờ chỉ được
/// thể hiện bằng màu.
extension RoomStatusVisuals on RoomStatus {
  IconData get icon {
    switch (this) {
      case RoomStatus.available:
        return Icons.bed_outlined;
      case RoomStatus.occupied:
        return Icons.person;
      case RoomStatus.reserved:
        return Icons.vpn_key_outlined;
      case RoomStatus.cleaning:
        return Icons.cleaning_services_outlined;
      case RoomStatus.maintenance:
        return Icons.build_outlined;
      case RoomStatus.pendingApproval:
        return Icons.pending_actions_outlined;
      case RoomStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  /// Màu tô: ô phòng, chấm chú thích, đoạn biểu đồ.
  Color get fill => Color(colorValue);

  /// Màu chữ trên nền sáng — đạt tương phản, khác với [fill].
  Color get ink => Color(inkValue);

  /// Màu trên nền navy.
  Color get onDark => Color(onDarkValue);
}

class RoomStatusBadge extends StatelessWidget {
  final RoomStatus status;

  /// Đặt `true` khi huy hiệu nằm trên nền tối (ảnh phủ scrim, dải navy).
  final bool onDarkSurface;

  const RoomStatusBadge({
    super.key,
    required this.status,
    this.onDarkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = status.fill;
    final label = onDarkSurface ? status.onDark : status.ink;
    final background = onDarkSurface
        ? Colors.white.withValues(alpha: 0.16)
        : status.fill.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
