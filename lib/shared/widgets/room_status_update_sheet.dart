import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/role_enum.dart';
import '../../core/constants/role_permissions.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../di/injection_container.dart';
import '../../features/admin/widgets/edit_room_modal.dart';
import '../models/room_model.dart';
import '../repositories/room_repository.dart';
import 'app_bottom_sheet.dart';
import 'app_error_display.dart';
import 'status_badge.dart';

/// Bottom sheet chuẩn hóa dùng chung trên toàn bộ ứng dụng để:
/// 1. Cập nhật trạng thái phòng nhanh (1 chạm).
/// 2. Sửa thông tin phòng (mở EditRoomModal cho Admin).
/// 3. Xóa phòng an toàn với hộp thoại xác nhận (cho Admin).
/// 4. Xem chi tiết phòng & album ảnh.
class RoomStatusUpdateSheet extends StatefulWidget {
  final RoomModel room;
  final RoomRepository? roomRepository;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onRoomDeleted;
  final VoidCallback? onRoomUpdated;

  const RoomStatusUpdateSheet({
    super.key,
    required this.room,
    this.roomRepository,
    this.onStatusChanged,
    this.onRoomDeleted,
    this.onRoomUpdated,
  });

  /// Phương thức tĩnh mở nhanh sheet cập nhật trạng thái phòng
  static Future<bool?> show({
    required BuildContext context,
    required RoomModel room,
    RoomRepository? roomRepository,
    VoidCallback? onStatusChanged,
    VoidCallback? onRoomDeleted,
    VoidCallback? onRoomUpdated,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (ctx) => RoomStatusUpdateSheet(
        room: room,
        roomRepository: roomRepository,
        onStatusChanged: onStatusChanged,
        onRoomDeleted: onRoomDeleted,
        onRoomUpdated: onRoomUpdated,
      ),
    );
  }

  @override
  State<RoomStatusUpdateSheet> createState() => _RoomStatusUpdateSheetState();
}

class _RoomStatusUpdateSheetState extends State<RoomStatusUpdateSheet> {
  late RoomModel _currentRoom;
  late final RoomRepository _roomRepo = widget.roomRepository ??
      (sl.isRegistered<RoomRepository>()
          ? sl<RoomRepository>()
          : RoomRepository());

  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
  }

  Future<void> _changeStatus(RoomStatus newStatus) async {
    if (_currentRoom.status == newStatus || _isUpdating) return;

    final oldStatus = _currentRoom.status;

    // Kiểm tra an toàn: nếu phòng đang có khách (OCCUPIED) mà muốn đổi sang trạng thái khác
    if (_currentRoom.status == RoomStatus.occupied &&
        newStatus != RoomStatus.occupied) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('Cảnh Báo Phòng Có Khách', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: Text(
            'Phòng ${_currentRoom.roomNumber} hiện đang có khách lưu trú. Bạn nên thực hiện thủ tục Trả phòng trước.\n\nBạn có chắc chắn muốn buộc đổi trạng thái sang "${newStatus.label}" không?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
              ),
              child: const Text('Vẫn Tiếp Tục'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    setState(() {
      _isUpdating = true;
      _currentRoom = _currentRoom.copyWith(status: newStatus);
    });

    try {
      await _roomRepo.updateRoomStatus(_currentRoom.id, newStatus);
      if (!mounted) return;

      setState(() => _isUpdating = false);
      widget.onStatusChanged?.call();

      AppNotification.showSuccess(
        context,
        'Đã cập nhật phòng ${_currentRoom.roomNumber} sang "${newStatus.label}"',
        title: 'Thành công',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _currentRoom = _currentRoom.copyWith(status: oldStatus);
      });

      AppNotification.showError(
        context,
        e,
        title: 'Cập nhật trạng thái thất bại',
      );
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.rose, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Xác Nhận Xóa Phòng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn Phòng ${_currentRoom.roomNumber} khỏi hệ thống không?\n\nLưu ý: Nếu phòng đã có lịch sử giao dịch hoặc đơn đặt phòng, hệ thống sẽ yêu cầu bạn chuyển sang trạng thái "Bảo trì" thay vì xóa.',
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: const Text('Xóa Phòng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _roomRepo.deleteRoom(_currentRoom.id);
      if (!mounted) return;

      setState(() => _isDeleting = false);
      Navigator.of(context).pop(true);
      widget.onRoomDeleted?.call();

      AppNotification.showSuccess(
        context,
        'Đã xóa phòng ${_currentRoom.roomNumber} thành công!',
        title: 'Đã xóa phòng',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppNotification.showError(
        context,
        e,
        title: 'Xóa phòng thất bại',
      );
    }
  }

  Future<void> _openEditModal() async {
    Navigator.of(context).pop();
    final res = await EditRoomModal.show(
      context: context,
      room: _currentRoom,
      roomRepository: _roomRepo,
      onSuccess: () {
        widget.onRoomUpdated?.call();
      },
    );
    if (res == true) {
      widget.onRoomUpdated?.call();
    }
  }

  Color _getStatusColor(RoomStatus status, AppPalette palette) {
    switch (status) {
      case RoomStatus.available:
        return AppColors.available;
      case RoomStatus.occupied:
        return AppColors.occupied;
      case RoomStatus.reserved:
        return AppColors.reserved;
      case RoomStatus.cleaning:
        return AppColors.cleaning;
      case RoomStatus.maintenance:
        return AppColors.maintenance;
      case RoomStatus.pendingApproval:
        return AppColors.secondary;
      case RoomStatus.rejected:
        return AppColors.rose;
    }
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Icons.check_circle_outline_rounded;
      case RoomStatus.occupied:
        return Icons.person_outline_rounded;
      case RoomStatus.reserved:
        return Icons.vpn_key_outlined;
      case RoomStatus.cleaning:
        return Icons.cleaning_services_outlined;
      case RoomStatus.maintenance:
        return Icons.build_outlined;
      case RoomStatus.pendingApproval:
        return Icons.hourglass_top_rounded;
      case RoomStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusDesc(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Sạch sẽ, sẵn sàng đón khách nhận phòng';
      case RoomStatus.occupied:
        return 'Đang có khách lưu trú tại phòng';
      case RoomStatus.reserved:
        return 'Đã được đặt cọc hoặc giữ chỗ trước';
      case RoomStatus.cleaning:
        return 'Khách vừa trả phòng, nhân viên đang dọn dẹp';
      case RoomStatus.maintenance:
        return 'Đang sửa chữa trang thiết bị, tạm ngừng đón khách';
      case RoomStatus.pendingApproval:
        return 'Phòng mới tạo, đang chờ Quản lý phê duyệt';
      case RoomStatus.rejected:
        return 'Phòng không được duyệt vào hoạt động kinh doanh';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final role = context.readRole;
    final canChangeStatus = role.canChangeRoomStatus;
    final canEditRoom = role.canEditRoom;

    final statuses = [
      RoomStatus.available,
      RoomStatus.cleaning,
      RoomStatus.occupied,
      RoomStatus.reserved,
      RoomStatus.maintenance,
      RoomStatus.pendingApproval,
      RoomStatus.rejected,
    ];

    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Số phòng, Tầng, Hạng & Trạng thái hiện tại
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Phòng ${_currentRoom.roomNumber}',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'Tầng ${_currentRoom.floor}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_currentRoom.roomTypeName ?? "Tiêu Chuẩn"} • ${Formatters.formatCurrency(_currentRoom.pricePerNight)}/đêm',
                        style: TextStyle(fontSize: 13, color: palette.inkMuted),
                      ),
                    ],
                  ),
                ),
                RoomStatusBadge(status: _currentRoom.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: palette.divider, height: 1),
            const SizedBox(height: AppSpacing.md),

            // Tiêu đề chọn trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cập nhật trạng thái phòng (1-chạm):',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                if (_isUpdating)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (!canChangeStatus)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 16, color: palette.inkMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tài khoản của bạn không có quyền cập nhật trạng thái phòng.',
                        style: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: statuses.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final st = statuses[i];
                  final isCurrent = _currentRoom.status == st;
                  final color = _getStatusColor(st, palette);
                  final icon = _getStatusIcon(st);
                  final desc = _getStatusDesc(st);

                  return InkWell(
                    onTap: isCurrent || _isUpdating ? null : () => _changeStatus(st),
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? color.withValues(alpha: 0.12)
                            : palette.surfaceMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                        border: Border.all(
                          color: isCurrent ? color : palette.border.withValues(alpha: 0.5),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      st.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                        color: isCurrent ? color : palette.ink,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                        ),
                                        child: const Text(
                                          'Hiện tại',
                                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: TextStyle(fontSize: 11, color: palette.inkMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Icon(Icons.check_circle_rounded, color: color, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.lg),
            Divider(color: palette.divider, height: 1),
            const SizedBox(height: AppSpacing.md),

            // Nhóm hành động nâng cao: Xem chi tiết, Sửa phòng, Xóa phòng
            Text(
              'Tác vụ buồng phòng:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/rooms/${_currentRoom.id}');
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 17),
                    label: const Text('Xem Chi Tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.accent,
                      side: BorderSide(color: palette.accent),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                if (canEditRoom) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openEditModal,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: const Text('Sửa Phòng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Nút Xóa Phòng dành cho ADMIN
            if (canEditRoom) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isDeleting ? null : _confirmAndDelete,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rose),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.rose),
                  label: Text(
                    _isDeleting ? 'Đang xóa phòng...' : 'Xóa phòng ${_currentRoom.roomNumber} (Admin)',
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.rose.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
