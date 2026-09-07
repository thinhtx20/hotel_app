import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../admin/widgets/edit_room_modal.dart';
import '../widgets/add_service_sheet.dart';
import '../widgets/change_room_sheet.dart';
import '../widgets/check_in_confirm_dialog.dart';
import '../widgets/check_out_sheet.dart';
import '../widgets/room_stay_actions.dart';
import '../widgets/walk_in_check_in_modal.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/shift_kpi_strip.dart';
import '../../../shared/widgets/skeletons/room_matrix_skeleton.dart';

class RoomMatrixScreen extends StatefulWidget {
  final DioClient? dioClient;
  final RoomRepository? roomRepository;
  final BookingRepository? bookingRepository;
  const RoomMatrixScreen({
    super.key,
    this.dioClient,
    this.roomRepository,
    this.bookingRepository,
  });

  @override
  State<RoomMatrixScreen> createState() => _RoomMatrixScreenState();
}

class _RoomMatrixScreenState extends State<RoomMatrixScreen> {
  late final RoomRepository _roomRepo =
      widget.roomRepository ??
      (widget.dioClient != null
          ? RoomRepository(dioClient: widget.dioClient)
          : (sl.isRegistered<RoomRepository>()
                ? sl<RoomRepository>()
                : RoomRepository(dioClient: widget.dioClient ?? DioClient())));

  late final BookingRepository _bookingRepo =
      widget.bookingRepository ??
      (widget.dioClient != null
          ? BookingRepository(dioClient: widget.dioClient)
          : (sl.isRegistered<BookingRepository>()
                ? sl<BookingRepository>()
                : BookingRepository(
                    dioClient: widget.dioClient ?? DioClient(),
                  )));

  List<RoomModel> _rooms = [];
  int _todayCheckIns = 0;
  bool _isLoading = true;
  String _lastUpdatedTime = '09:42';
  final Set<String> _updatingRoomIds = {};

  /// Chip KPI ca trực đang được chọn để lọc sơ đồ phòng (null = xem tất cả).
  ShiftKpiFilter? _activeFilter;

  @override
  void initState() {
    super.initState();
    _roomRepo.addListener(_onRoomRepoChanged);
    _roomRepo.startRealtimeStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchRooms();
    });
  }

  @override
  void dispose() {
    _roomRepo.removeListener(_onRoomRepoChanged);
    super.dispose();
  }

  void _onRoomRepoChanged() {
    if (!mounted) return;
    setState(() {
      _rooms = List.from(_roomRepo.rooms);
    });
  }

  Future<void> _fetchRooms({bool isSilent = false}) async {
    if (!isSilent && _rooms.isEmpty) {
      setState(() => _isLoading = true);
    }
    final now = DateTime.now();
    _lastUpdatedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      await _roomRepo.fetchRooms(forceRefresh: true);
      int todayIns = 0;
      try {
        final bList = await _bookingRepo.fetchBookings(
          checkInFrom: DateTime(now.year, now.month, now.day),
          checkInTo: DateTime(now.year, now.month, now.day),
        );
        todayIns = bList.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _rooms = List.from(_roomRepo.rooms);
          _todayCheckIns = todayIns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (isSilent) {
          AppNotification.showError(
            context,
            e,
            title: 'Làm mới sơ đồ buồng phòng thất bại',
          );
        }
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

    try {
      await _roomRepo.updateRoomStatus(roomId, newStatus);
      if (!mounted) return;
      setState(() {
        _updatingRoomIds.remove(roomId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Đã cập nhật phòng ${room.roomNumber} sang ${newStatus.label}',
                ),
              ),
            ],
          ),
          backgroundColor: palette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Khi gặp lỗi kết nối hoặc API thất bại: rollback về trạng thái ban đầu
      if (mounted) {
        setState(() {
          _updatingRoomIds.remove(roomId);
          final idx = _rooms.indexWhere((r) => r.id == roomId);
          if (idx != -1) {
            _rooms[idx] = _rooms[idx].copyWith(status: oldStatus);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Không thể cập nhật phòng ${room.roomNumber}. Đã khôi phục trạng thái cũ.',
                  ),
                ),
              ],
            ),
            backgroundColor: palette.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
          ),
        );
      }
    }
  }

  /// Trạng thái phòng tương ứng với một chip KPI (chip "Khách đến" không lọc).
  RoomStatus? _statusOfFilter(ShiftKpiFilter filter) {
    switch (filter) {
      case ShiftKpiFilter.available:
        return RoomStatus.available;
      case ShiftKpiFilter.occupied:
        return RoomStatus.occupied;
      case ShiftKpiFilter.cleaning:
        return RoomStatus.cleaning;
      case ShiftKpiFilter.checkIns:
        return null;
    }
  }

  /// Danh sách phòng sau khi áp bộ lọc từ dải KPI ca trực.
  List<RoomModel> get _visibleRooms {
    final filter = _activeFilter;
    if (filter == null) return _rooms;
    final status = _statusOfFilter(filter);
    if (status == null) return _rooms;
    return _rooms.where((r) => r.status == status).toList();
  }

  /// Chạm chip KPI: 3 chip trạng thái bật/tắt bộ lọc sơ đồ, chip "Khách đến"
  /// mở thẳng danh sách nhận phòng hôm nay (§4.2 — tab "Hôm nay").
  void _onKpiSelected(ShiftKpiFilter filter) {
    if (!filter.filtersRoomMatrix) {
      // Route dùng chung cho cả ADMIN và RECEPTIONIST (`_sharedRouteAccess`).
      if (GoRouter.maybeOf(context) != null) {
        context.push('/staff/today-check-ins');
      }
      return;
    }
    setState(() {
      _activeFilter = _activeFilter == filter ? null : filter;
    });
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
    final role = context.readRole;
    // `PATCH /rooms/:id/status` chỉ mở cho ADMIN và RECEPTIONIST (§3.4).
    final canChangeStatus = role.canChangeRoomStatus;
    // Sửa toàn diện phòng qua PUT /rooms/:id dành riêng cho ADMIN
    final canEditRoom = role.canEditRoom;
    // Check-in / check-out cùng nhóm quyền nhân viên (§3.5).
    final canCheckIn = role.canCheckIn;
    final canCheckOut = role.canCheckOut;

    final stayActionsKey = GlobalKey<RoomStayActionsState>();
    bool isLoadingService = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AppBottomSheet(
          child: SingleChildScrollView(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
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
                // Thủ tục nhận / trả phòng ngay tại ô phòng — lễ tân không phải
                // sang tab "Hôm nay" dò lại đơn của khách.
                if (canCheckIn || canCheckOut) ...[
                  RoomStayActions(
                    key: stayActionsKey,
                    room: room,
                    bookingRepository: _bookingRepo,
                    canCheckIn: canCheckIn,
                    canCheckOut: canCheckOut,
                    onCheckIn: (booking) {
                      Navigator.pop(ctx);
                      _performCheckIn(room, booking);
                    },
                    onCheckOut: (booking) {
                      Navigator.pop(ctx);
                      _performCheckOut(room, booking);
                    },
                    onWalkInCheckIn: () {
                      Navigator.pop(ctx);
                      _openWalkInCheckIn(room);
                    },
                  ),
                  Divider(height: 28, color: palette.divider),
                ],
                if (!canChangeStatus)
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: palette.inkMuted,
                      ),
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
                  if (room.status == RoomStatus.occupied) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Divider(height: 1, color: palette.divider),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoadingService
                            ? null
                            : () async {
                                final existingStay =
                                    stayActionsKey.currentState?.currentStay;
                                if (existingStay != null) {
                                  await AddServiceSheet.show(
                                    context: ctx,
                                    bookingId: existingStay.id,
                                    roomNumber: room.roomNumber,
                                    bookingRepository: _bookingRepo,
                                    onServiceAdded: () {
                                      stayActionsKey.currentState?.reload();
                                      _fetchRooms(isSilent: true);
                                    },
                                  );
                                  return;
                                }

                                setSheetState(() => isLoadingService = true);
                                try {
                                  await _openAddServiceForRoom(
                                    room,
                                    sheetContext: ctx,
                                    onServiceAdded: () {
                                      stayActionsKey.currentState?.reload();
                                      _fetchRooms(isSilent: true);
                                    },
                                  );
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(
                                      () => isLoadingService = false,
                                    );
                                  }
                                }
                              },
                        icon: isLoadingService
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.accent,
                                ),
                              )
                            : Icon(
                                Icons.room_service_outlined,
                                size: 18,
                                color: palette.accent,
                              ),
                        label: Text(
                          isLoadingService
                              ? 'Đang mở dịch vụ...'
                              : 'Ghi nhận Dịch vụ / Minibar',
                          style: TextStyle(
                            color: palette.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.accent),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (context.readRole.canChangeRoom) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openChangeRoomForRoom(room);
                          },
                          icon: Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: palette.statusOccupiedInk,
                          ),
                          label: Text(
                            'Đổi phòng cho khách (S2)',
                            style: TextStyle(
                              color: palette.statusOccupiedInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: palette.statusOccupied),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
                if (canEditRoom) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditRoom(room);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text(
                        'Sửa Thông Tin Phòng (ADMIN)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/rooms/${room.id}');
                    },
                    icon: Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: palette.accent,
                    ),
                    label: Text(
                      'Xem Chi Tiết Phòng & Album Ảnh',
                      style: TextStyle(
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nhận phòng cho đơn đang gắn với ô phòng vừa chọn.
  Future<void> _performCheckIn(RoomModel room, BookingModel booking) async {
    final confirmed = await CheckInConfirmDialog.show(
      context: context,
      booking: booking,
    );
    if (!confirmed || !mounted) return;

    setState(() => _updatingRoomIds.add(room.id));
    try {
      await _bookingRepo.checkIn(booking.id);
      if (!mounted) return;
      setState(() => _updatingRoomIds.remove(room.id));

      // Backend đẩy phòng sang OCCUPIED — nạp lại sơ đồ để khớp trạng thái.
      await _fetchRooms(isSilent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Đã nhận phòng ${room.roomNumber} cho đơn ${booking.displayCode}',
                ),
              ),
            ],
          ),
          backgroundColor: context.palette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingRoomIds.remove(room.id));
      AppNotification.showError(context, e, title: 'Nhận phòng thất bại');
    }
  }

  /// Mở modal nhận phòng trực tiếp cho khách vãng lai (Walk-in)
  Future<void> _openWalkInCheckIn([RoomModel? room]) async {
    final result = await WalkInCheckInModal.show(
      context: context,
      preselectedRoom: room,
      onSuccess: () => _fetchRooms(isSilent: true),
    );
    if (result != null && mounted) {
      await _fetchRooms(isSilent: true);
    }
  }

  /// Trả phòng & xuất hóa đơn cho lượt khách đang ở ô phòng vừa chọn.
  Future<void> _performCheckOut(RoomModel room, BookingModel booking) async {
    final result = await CheckOutSheet.show(
      context: context,
      booking: booking,
      bookingRepository: _bookingRepo,
    );
    if (result == null || !mounted) return;

    // Phòng chuyển sang chờ dọn sau khi khách trả — nạp lại trạng thái thật.
    await _fetchRooms(isSilent: true);
  }

  Future<void> _openAddServiceForRoom(
    RoomModel room, {
    BuildContext? sheetContext,
    VoidCallback? onServiceAdded,
  }) async {
    try {
      final bookings = await _bookingRepo.fetchBookings(
        roomId: room.id,
        status: 'CHECKED_IN',
      );
      if (!mounted) return;
      if (sheetContext != null && !sheetContext.mounted) return;
      final targetCtx = sheetContext ?? context;
      if (bookings.isEmpty) {
        ScaffoldMessenger.of(targetCtx).showSnackBar(
          SnackBar(
            content: Text(
              'Không tìm thấy lượt lưu trú đang hoạt động của phòng ${room.roomNumber}',
            ),
            backgroundColor: context.palette.warning,
          ),
        );
        return;
      }
      await AddServiceSheet.show(
        context: targetCtx,
        bookingId: bookings.first.id,
        roomNumber: room.roomNumber,
        bookingRepository: _bookingRepo,
        onServiceAdded: () {
          onServiceAdded?.call();
          _fetchRooms(isSilent: true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      if (sheetContext != null && !sheetContext.mounted) return;
      final targetCtx = sheetContext ?? context;
      if (!targetCtx.mounted) return;
      ScaffoldMessenger.of(targetCtx).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải thông tin đặt phòng: ${e.toString()}'),
          backgroundColor: targetCtx.palette.error,
        ),
      );
    }
  }

  Future<void> _openChangeRoomForRoom(RoomModel room) async {
    try {
      final bookings = await _bookingRepo.fetchBookings(
        roomId: room.id,
        status: 'CHECKED_IN',
      );
      if (!mounted) return;
      if (bookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không tìm thấy lượt lưu trú đang hoạt động của phòng ${room.roomNumber}',
            ),
            backgroundColor: context.palette.warning,
          ),
        );
        return;
      }
      ChangeRoomSheet.show(
        context: context,
        bookingId: bookings.first.id,
        currentRoom: room,
        onSuccess: () => _fetchRooms(isSilent: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải thông tin đổi phòng: ${e.toString()}'),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  Future<void> _openEditRoom(RoomModel room) async {
    await EditRoomModal.show(
      context: context,
      room: room,
      roomRepository: _roomRepo,
      onSuccess: () => _fetchRooms(isSilent: true),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
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
    final availableCount = _rooms
        .where((r) => r.status == RoomStatus.available)
        .length;
    final occupiedCount = _rooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final cleaningCount = _rooms
        .where((r) => r.status == RoomStatus.cleaning)
        .length;

    // Nhóm theo tầng — chỉ những phòng khớp bộ lọc KPI đang bật
    final visibleRooms = _visibleRooms;
    final isFiltering = _activeFilter?.filtersRoomMatrix ?? false;
    final Map<int, List<RoomModel>> floors = {};
    for (var r in visibleRooms) {
      floors.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = floors.keys.toList()..sort();

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: context.readRole.canCheckIn
          ? FloatingActionButton.extended(
              onPressed: () => _openWalkInCheckIn(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Nhận phòng tại quầy',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      // Thanh chú thích 5 màu ghim cố định dưới đáy màn hình
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
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
      // Dải Navy + KPI ghim cố định; chỉ vùng lưới phòng bên dưới được cuộn.
      body: Column(
        children: [
          // 1. Dải Navy đầu màn + Thống kê nhanh
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + AppSpacing.sm,
              bottom: AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              gradient: AppGradients.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.sheet),
                bottomRight: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _roomRepo.isRealtimeActive
                                      ? const Color(0xFF10B981)
                                      : Colors.white.withValues(alpha: 0.40),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _roomRepo.isRealtimeActive
                                    ? 'Realtime trực tiếp'
                                    : 'Cập nhật lúc $_lastUpdatedTime',
                                style: TextStyle(
                                  color: _roomRepo.isRealtimeActive
                                      ? const Color(0xFF34D399)
                                      : Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildGlassCircleBtn(
                            icon: Icons.refresh,
                            onTap: () => _fetchRooms(isSilent: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Dải KPI ca trực kiêm bộ lọc nhanh FE-ROLE-MATRIX §5.1
          ShiftKpiStrip(
            available: availableCount,
            occupied: occupiedCount,
            cleaning: cleaningCount,
            checkIns: _todayCheckIns,
            selected: _activeFilter,
            onSelect: _onKpiSelected,
          ),

          if (isFiltering) _buildFilterBanner(visibleRooms.length),

          const SizedBox(height: AppSpacing.md),

          // 2. Vùng cuộn duy nhất: danh sách tầng & Lưới phòng 3 cột
          Expanded(
            child: RefreshIndicator(
              color: palette.accent,
              onRefresh: () => _fetchRooms(isSilent: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_isLoading && _rooms.isEmpty)
                      const RoomMatrixSkeleton()
                    else if (_rooms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: AppEmptyState(
                          title: 'Không có dữ liệu buồng phòng',
                          description:
                              'Hiện tại chưa có danh sách phòng nào được thiết lập.',
                          actionText: 'Tải lại',
                          onAction: () => _fetchRooms(),
                        ),
                      )
                    else if (visibleRooms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: AppEmptyState(
                          title: 'Không có phòng nào ở trạng thái này',
                          description:
                              'Hiện chưa có ${_activeFilter!.fullLabel.toLowerCase()} trong ca trực này.',
                          actionText: 'Xem tất cả phòng',
                          onAction: () => setState(() => _activeFilter = null),
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
                                      color: palette.isDark
                                          ? palette.accent
                                          : AppColors.primary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Divider(
                                      color: palette.divider,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    isFiltering
                                        ? '${floorRooms.length} phòng'
                                        : '$freeRooms/${floorRooms.length} trống',
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
                            .fadeIn(
                              duration: AppDurations.normal,
                              delay: (floorIndex * 40).ms,
                            )
                            .slideY(begin: 0.05, curve: AppMotion.enter);
                      }),
                    // Chừa chỗ cho FAB "Nhận phòng tại quầy" che góc dưới lưới
                    SizedBox(
                      height: context.readRole.canCheckIn
                          ? AppSpacing.xxxl + AppSpacing.xl
                          : AppSpacing.xl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              color: isUpdating
                  ? statusColor.withValues(alpha: 0.4)
                  : statusColor,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
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
                        : Icon(iconData, size: 14, color: statusColor),
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

  /// Thanh nhắc bộ lọc đang bật kèm nút gỡ lọc nhanh.
  Widget _buildFilterBanner(int matchCount) {
    final palette = context.palette;
    final filter = _activeFilter!;
    final color = filter.color;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 2,
      ),
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: 6,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: palette.isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt_rounded, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Đang lọc: ${filter.fullLabel} • $matchCount phòng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _activeFilter = null),
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text(
                'Bỏ lọc',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
