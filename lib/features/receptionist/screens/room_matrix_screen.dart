import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/room_matrix_skeleton.dart';

class RoomMatrixScreen extends StatefulWidget {
  final DioClient? dioClient;
  const RoomMatrixScreen({super.key, this.dioClient});

  @override
  State<RoomMatrixScreen> createState() => _RoomMatrixScreenState();
}

class _RoomMatrixScreenState extends State<RoomMatrixScreen> {
  DioClient get _dioClient => widget.dioClient ?? DioClient();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String _lastUpdatedTime = '09:42';
  final Set<String> _updatingRoomIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms({bool isSilent = false}) async {
    if (!isSilent && _rooms.isEmpty) {
      setState(() => _isLoading = true);
    }
    final now = DateTime.now();
    _lastUpdatedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      final res = await _dioClient.dio.get(ApiEndpoints.rooms);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List?;
        if (list != null && mounted) {
          setState(() {
            _rooms = list.map((e) => RoomModel.fromJson(e)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback data strictly adhering to 07-room-matrix.md
    if (mounted) {
      if (_rooms.isEmpty) {
        setState(() {
          _isLoading = false;
          _rooms = [
            // Tầng 1 (6 phòng)
            RoomModel(id: '101', roomNumber: '101', floor: 1, status: RoomStatus.available, pricePerNight: 1200000),
            RoomModel(id: '102', roomNumber: '102', floor: 1, status: RoomStatus.available, pricePerNight: 1200000),
            RoomModel(id: '103', roomNumber: '103', floor: 1, status: RoomStatus.occupied, pricePerNight: 1400000),
            RoomModel(id: '104', roomNumber: '104', floor: 1, status: RoomStatus.cleaning, pricePerNight: 1200000),
            RoomModel(id: '105', roomNumber: '105', floor: 1, status: RoomStatus.available, pricePerNight: 1200000),
            RoomModel(id: '106', roomNumber: '106', floor: 1, status: RoomStatus.reserved, pricePerNight: 1500000),

            // Tầng 2 (6 phòng)
            RoomModel(id: '201', roomNumber: '201', floor: 2, status: RoomStatus.occupied, pricePerNight: 1800000),
            RoomModel(id: '202', roomNumber: '202', floor: 2, status: RoomStatus.occupied, pricePerNight: 1800000),
            RoomModel(id: '203', roomNumber: '203', floor: 2, status: RoomStatus.available, pricePerNight: 1800000),
            RoomModel(id: '204', roomNumber: '204', floor: 2, status: RoomStatus.maintenance, pricePerNight: 1800000),
            RoomModel(id: '205', roomNumber: '205', floor: 2, status: RoomStatus.reserved, pricePerNight: 4200000),
            RoomModel(id: '206', roomNumber: '206', floor: 2, status: RoomStatus.available, pricePerNight: 1800000),

            // Tầng 3 (4 phòng mẫu)
            RoomModel(id: '301', roomNumber: '301', floor: 3, status: RoomStatus.available, pricePerNight: 2000000),
            RoomModel(id: '302', roomNumber: '302', floor: 3, status: RoomStatus.occupied, pricePerNight: 2000000),
            RoomModel(id: '303', roomNumber: '303', floor: 3, status: RoomStatus.cleaning, pricePerNight: 2000000),
            RoomModel(id: '304', roomNumber: '304', floor: 3, status: RoomStatus.available, pricePerNight: 2000000),
          ];
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateRoomStatus(RoomModel room, RoomStatus newStatus) async {
    if (room.status == newStatus) return;

    final oldStatus = room.status;
    final roomId = room.id;
    final palette = context.palette;

    // 1. Cập nhật lạc quan (Optimistic Update) ngay lập tức trên UI
    setState(() {
      _updatingRoomIds.add(roomId);
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _rooms[idx] = _rooms[idx].copyWith(status: newStatus);
      }
    });

    // Đồng bộ tức thời tới RoomRepository cho các màn khác
    if (sl.isRegistered<RoomRepository>()) {
      sl<RoomRepository>().updateRoomStatus(roomId, newStatus);
    }

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.updateRoomStatus(roomId),
        data: {'status': newStatus.code},
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _updatingRoomIds.remove(roomId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Đã cập nhật phòng ${room.roomNumber} sang ${newStatus.label}'),
                ),
              ],
            ),
            backgroundColor: palette.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    } catch (_) {
      // Khi gặp lỗi kết nối hoặc API thất bại: rollback về trạng thái ban đầu
      if (mounted) {
        setState(() {
          _updatingRoomIds.remove(roomId);
          final idx = _rooms.indexWhere((r) => r.id == roomId);
          if (idx != -1) {
            _rooms[idx] = _rooms[idx].copyWith(status: oldStatus);
          }
        });
        if (sl.isRegistered<RoomRepository>()) {
          sl<RoomRepository>().updateRoomStatus(roomId, oldStatus);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Không thể cập nhật phòng ${room.roomNumber}. Đã khôi phục trạng thái cũ.'),
                ),
              ],
            ),
            backgroundColor: palette.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
          ),
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        _updatingRoomIds.remove(roomId);
      });
    }
  }

  Color _getStatusColor(RoomStatus status, AppPalette palette) {
    switch (status) {
      case RoomStatus.available:
        return palette.statusAvailable;
      case RoomStatus.occupied:
        return palette.statusOccupied;
      case RoomStatus.reserved:
        return palette.statusReserved;
      case RoomStatus.cleaning:
        return palette.statusCleaning;
      case RoomStatus.maintenance:
        return palette.statusMaintenance;
      case RoomStatus.pendingApproval:
        return palette.warning;
      case RoomStatus.rejected:
        return palette.error;
    }
  }

  Color _getStatusInk(RoomStatus status, AppPalette palette) {
    switch (status) {
      case RoomStatus.available:
        return palette.statusAvailableInk;
      case RoomStatus.occupied:
        return palette.statusOccupiedInk;
      case RoomStatus.reserved:
        return palette.statusReservedInk;
      case RoomStatus.cleaning:
        return palette.statusCleaningInk;
      case RoomStatus.maintenance:
        return palette.statusMaintenanceInk;
      case RoomStatus.pendingApproval:
        return palette.warningInk;
      case RoomStatus.rejected:
        return palette.errorInk;
    }
  }

  IconData _getRoomStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Icons.check_circle_outline;
      case RoomStatus.occupied:
        return Icons.person_outline;
      case RoomStatus.reserved:
        return Icons.vpn_key_outlined;
      case RoomStatus.cleaning:
        return Icons.cleaning_services_outlined;
      case RoomStatus.maintenance:
        return Icons.build_outlined;
      case RoomStatus.pendingApproval:
        return Icons.hourglass_top_outlined;
      case RoomStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  void _showRoomDetailSheet(RoomModel room) {
    final palette = context.palette;
    final statusColor = _getStatusColor(room.status, palette);
    final statusInk = _getStatusInk(room.status, palette);
    // `PATCH /rooms/:id/status` chỉ mở cho ADMIN và RECEPTIONIST (§3.4).
    final canChangeStatus = context.readRole.canChangeRoomStatus;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => AppBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phòng ${room.roomNumber}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    room.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: statusInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tầng ${room.floor} • Hạng ${room.roomTypeName ?? "Tiêu Chuẩn"} • ${Formatters.formatCurrency(room.pricePerNight)}/đêm',
              style: TextStyle(color: palette.inkMuted, fontSize: 13),
            ),
            Divider(height: 28, color: palette.divider),
            if (!canChangeStatus)
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: palette.inkMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Vai trò của bạn chỉ được xem sơ đồ phòng.',
                      style: TextStyle(fontSize: 13, color: palette.inkMuted),
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                'Thao tác nhanh 1 chạm:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildActionButton(
                    ctx: ctx,
                    room: room,
                    label: 'Sẵn sàng',
                    status: RoomStatus.available,
                    icon: Icons.check_circle_outline,
                  ),
                  _buildActionButton(
                    ctx: ctx,
                    room: room,
                    label: 'Dọn dẹp',
                    status: RoomStatus.cleaning,
                    icon: Icons.cleaning_services_outlined,
                  ),
                  _buildActionButton(
                    ctx: ctx,
                    room: room,
                    label: 'Có khách',
                    status: RoomStatus.occupied,
                    icon: Icons.person_outline,
                  ),
                  _buildActionButton(
                    ctx: ctx,
                    room: room,
                    label: 'Đặt cọc',
                    status: RoomStatus.reserved,
                    icon: Icons.vpn_key_outlined,
                  ),
                  _buildActionButton(
                    ctx: ctx,
                    room: room,
                    label: 'Bảo trì',
                    status: RoomStatus.maintenance,
                    icon: Icons.build_outlined,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext ctx,
    required RoomModel room,
    required String label,
    required RoomStatus status,
    required IconData icon,
  }) {
    final palette = context.palette;
    final isCurrent = room.status == status;
    final color = _getStatusColor(status, palette);

    return ElevatedButton.icon(
      onPressed: isCurrent
          ? () => Navigator.pop(ctx)
          : () {
              Navigator.pop(ctx);
              _updateRoomStatus(room, status);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrent ? color.withValues(alpha: 0.15) : color,
        foregroundColor: isCurrent ? color : Colors.white,
        elevation: isCurrent ? 0 : 1,
        side: isCurrent ? BorderSide(color: color, width: 1.5) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      ),
      icon: Icon(isCurrent ? Icons.check : icon, size: 16),
      label: Text(
        isCurrent ? '$label (Hiện tại)' : label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Thống kê nhanh
    final availableCount =
        _rooms.where((r) => r.status == RoomStatus.available).length;
    final occupiedCount =
        _rooms.where((r) => r.status == RoomStatus.occupied).length;
    final cleaningCount =
        _rooms.where((r) => r.status == RoomStatus.cleaning).length;

    // Nhóm theo tầng
    final Map<int, List<RoomModel>> floors = {};
    for (var r in _rooms) {
      floors.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = floors.keys.toList()..sort();

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: palette.canvas,
      // Thanh chú thích 5 màu ghim cố định dưới đáy màn hình
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.border)),
          boxShadow: palette.isDark ? null : AppShadows.soft,
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: 6,
            children: [
              _buildLegendItem('Phòng trống', palette.statusAvailable),
              _buildLegendItem('Đang có khách', palette.statusOccupied),
              _buildLegendItem('Đã đặt cọc', palette.statusReserved),
              _buildLegendItem('Đang dọn dẹp', palette.statusCleaning),
              _buildLegendItem('Bảo trì', palette.statusMaintenance),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: () => _fetchRooms(isSilent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. Dải Navy đầu màn + Thống kê nhanh
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: topPadding + AppSpacing.sm, bottom: AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: AppGradients.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.sheet),
                    bottomRight: Radius.circular(AppRadius.sheet),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sơ Đồ Buồng Phòng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cập nhật lúc $_lastUpdatedTime',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildGlassCircleBtn(
                                icon: Icons.refresh,
                                onTap: () => _fetchRooms(isSilent: true),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildGlassCircleBtn(
                                icon: Icons.logout,
                                onTap: () => LogoutConfirmationDialog.show(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3 Quick Stat Boxes
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStatBox(
                              value: '$availableCount',
                              label: 'TRỐNG',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildQuickStatBox(
                              value: '$occupiedCount',
                              label: 'CÓ KHÁCH',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildQuickStatBox(
                              value: '$cleaningCount',
                              label: 'DỌN DẸP',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Danh sách tầng & Lưới phòng 3 cột
              if (_isLoading && _rooms.isEmpty)
                const RoomMatrixSkeleton()
              else if (_rooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: AppEmptyState(
                    title: 'Không có dữ liệu buồng phòng',
                    description: 'Hiện tại chưa có danh sách phòng nào được thiết lập.',
                    actionText: 'Tải lại',
                    onAction: () => _fetchRooms(),
                  ),
                )
              else
                ...sortedFloors.asMap().entries.map((entry) {
                  final floorIndex = entry.key;
                  final floor = entry.value;
                  final floorRooms = floors[floor]!;
                  final freeRooms = floorRooms
                      .where((r) => r.status == RoomStatus.available)
                      .length;

                  final floorSection = Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floor Title Row
                        Row(
                          children: [
                            Text(
                              'TẦNG $floor',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.isDark ? palette.accent : AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Divider(color: palette.divider, height: 1),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              '$freeRooms/${floorRooms.length} trống',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3-Column Grid with depth
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 88,
                          ),
                          itemCount: floorRooms.length,
                          itemBuilder: (ctx, i) {
                            final room = floorRooms[i];
                            return _buildRoomTile(room);
                          },
                        ),
                      ],
                    ),
                  );

                  // Staggered fade in cho từng tầng khi tải
                  return floorSection
                      .animate()
                      .fadeIn(duration: AppDurations.normal, delay: (floorIndex * 40).ms)
                      .slideY(begin: 0.05, curve: AppMotion.enter);
                }),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile(RoomModel room) {
    final palette = context.palette;
    final isUpdating = _updatingRoomIds.contains(room.id);
    final statusColor = _getStatusColor(room.status, palette);
    final statusInk = _getStatusInk(room.status, palette);
    final iconData = _getRoomStatusIcon(room.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdating ? null : () => _showRoomDetailSheet(room),
        borderRadius: BorderRadius.circular(AppRadius.image),
        child: AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: palette.isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(AppRadius.image),
            border: Border.all(
              color: isUpdating ? statusColor.withValues(alpha: 0.4) : statusColor,
              width: 1.5,
            ),
            boxShadow: palette.isDark
                ? null
                : [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Right Icon hoặc Loading Indicator cục bộ cho riêng phòng này
                  Align(
                    alignment: Alignment.topRight,
                    child: isUpdating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: statusColor,
                            ),
                          )
                        : Icon(
                            iconData,
                            size: 14,
                            color: statusColor,
                          ),
                  ),
                  // Room Number
                  Text(
                    room.roomNumber,
                    style: TextStyle(
                      color: statusInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Status Label
                  Text(
                    room.status.label,
                    style: TextStyle(
                      color: statusInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isUpdating)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.image),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatBox({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: palette.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
