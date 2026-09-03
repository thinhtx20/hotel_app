import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../customer/widgets/create_room_modal.dart';

class RoomApprovalScreen extends StatefulWidget {
  const RoomApprovalScreen({super.key});

  @override
  State<RoomApprovalScreen> createState() => _RoomApprovalScreenState();
}

class _RoomApprovalScreenState extends State<RoomApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RoomRepository _roomRepository = sl<RoomRepository>();
  final Set<String> _processingRoomIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roomRepository.fetchRooms(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateRoomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateRoomModal(
        onSuccess: () {
          _tabController.animateTo(0);
        },
      ),
    );
  }

  Future<void> _approveRoom(RoomModel room) async {
    setState(() => _processingRoomIds.add(room.id));
    final success = await _roomRepository.approveRoom(room.id);
    if (mounted) {
      setState(() => _processingRoomIds.remove(room.id));
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Đã phê duyệt phòng ${room.roomNumber} thành công! Phòng đã sẵn sàng đón khách.'),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _rejectRoom(RoomModel room) async {
    setState(() => _processingRoomIds.add(room.id));
    final success = await _roomRepository.rejectRoom(room.id);
    if (mounted) {
      setState(() => _processingRoomIds.remove(room.id));
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Đã từ chối phòng ${room.roomNumber}.'),
                ),
              ],
            ),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _roomRepository,
        builder: (context, _) {
          final pending = _roomRepository.pendingRooms;
          final approved = _roomRepository.approvedRooms;
          final rejected = _roomRepository.rejectedRooms;
          final all = _roomRepository.rooms;

          return Column(
            children: [
              // Top Bar Navy Header
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (Navigator.of(context).canPop()) ...[
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duyệt & Quản lý',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Duyệt Phòng Mới',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Badge chờ duyệt
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.pending_actions_rounded,
                                    color: AppColors.secondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${pending.length} chờ duyệt',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Quick Add Button
                            IconButton(
                              tooltip: 'Tạo phòng mới',
                              onPressed: _openCreateRoomModal,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tabs Bar
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: AppColors.secondary,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              children: [
                                const Text('Chờ duyệt'),
                                if (pending.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${pending.length}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Tab(text: 'Đã duyệt (${approved.length})'),
                          Tab(text: 'Từ chối (${rejected.length})'),
                          Tab(text: 'Tất cả (${all.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomList(pending, isPendingTab: true),
                    _buildRoomList(approved),
                    _buildRoomList(rejected),
                    _buildRoomList(all),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomList(List<RoomModel> roomList, {bool isPendingTab = false}) {
    if (_roomRepository.isLoading && _roomRepository.rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.secondary),
            SizedBox(height: 16),
            Text(
              'Đang tải danh sách phòng từ máy chủ...',
              style: TextStyle(color: AppColors.slate600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_roomRepository.errorMessage != null && _roomRepository.rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.rose,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _roomRepository.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _roomRepository.fetchRooms(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (roomList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _roomRepository.fetchRooms(forceRefresh: true),
        color: AppColors.secondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có phòng nào trong danh mục này',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kéo xuống để làm mới hoặc bấm nút + trên góc để tạo phòng',
                    style: TextStyle(fontSize: 12, color: AppColors.slate400),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _roomRepository.fetchRooms(forceRefresh: true),
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: roomList.length,
        itemBuilder: (context, index) {
          final room = roomList[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final imageUrl = room.images.isNotEmpty
        ? room.images.first
        : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=800&q=80';
    final isProcessing = _processingRoomIds.contains(room.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.slate100,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.slate100,
                        child: const Icon(
                          Icons.hotel_rounded,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Phòng ${room.roomNumber} • Tầng ${room.floor}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          RoomStatusBadge(status: room.status),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Text(
                        room.roomTypeName ?? 'Phòng Tiêu Chuẩn',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '${Formatters.formatCurrency(room.pricePerNight)} / đêm',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),

                      if (room.amenities.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Tiện nghi: ${room.amenities.join(", ")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider & Action buttons
          const Divider(height: 1, color: AppColors.slate100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isProcessing) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                        ),
                        SizedBox(width: 8),
                        Text('Đang xử lý...', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ] else if (room.status == RoomStatus.pendingApproval) ...[
                  // Outlined Reject Button
                  OutlinedButton.icon(
                    onPressed: () => _rejectRoom(room),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.rose),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filled Approve Button
                  ElevatedButton.icon(
                    onPressed: () => _approveRoom(room),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Duyệt ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ] else ...[
                  // Quick Status Toggle Options
                  TextButton.icon(
                    onPressed: room.status == RoomStatus.available ? null : () => _approveRoom(room),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Đặt là Đã duyệt'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: room.status == RoomStatus.rejected ? null : () => _rejectRoom(room),
                    icon: const Icon(Icons.block_outlined, size: 16),
                    label: const Text('Từ chối'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
