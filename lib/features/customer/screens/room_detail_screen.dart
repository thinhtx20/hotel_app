import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../admin/widgets/edit_room_modal.dart';
import '../widgets/create_booking_modal.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final RoomModel? initialRoom;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    this.initialRoom,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final RoomRepository _roomRepository = sl<RoomRepository>();
  final PageController _pageController = PageController();

  RoomModel? _room;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _roomRepository.addListener(_onRepositoryUpdated);
    _fetchRoomDetail();
  }

  @override
  void dispose() {
    _roomRepository.removeListener(_onRepositoryUpdated);
    _pageController.dispose();
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (!mounted) return;
    try {
      final updated = _roomRepository.rooms.firstWhere(
        (r) => r.id == widget.roomId,
      );
      if (_room != null && _room!.status != updated.status) {
        setState(() {
          _room = _room!.copyWith(status: updated.status);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRoomDetail() async {
    if (_room == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final detail = await _roomRepository.fetchDetail(widget.roomId);
      if (!mounted) return;
      setState(() {
        _room = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_room == null) {
        final apiErr = ApiError.fromDynamic(e);
        setState(() {
          _isLoading = false;
          _errorMessage = apiErr.displayMessage;
        });
      }
    }
  }

  void _onBookPressed() {
    if (_room == null) return;
    final room = _room!;

    if (room.status == RoomStatus.maintenance) {
      AppNotification.showWarning(
        context,
        'Phòng ${room.roomNumber} hiện đang bảo trì kỹ thuật, tạm thời không nhận đặt.',
        title: 'Phòng đang bảo trì',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateBookingModal(
        room: room,
        onSuccess: () {
          _fetchRoomDetail();
          if (context.canPop()) {
            context.pop();
          }
          context.go('/my-bookings');
        },
      ),
    );
  }

  Future<void> _openEditModal() async {
    if (_room == null) return;
    final updated = await EditRoomModal.show(
      context: context,
      room: _room!,
      roomRepository: _roomRepository,
      onSuccess: () => _fetchRoomDetail(),
    );
    if (updated == true && mounted) {
      _fetchRoomDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading && _room == null) {
      return Scaffold(
        backgroundColor: palette.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: palette.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Đang tải thông tin phòng...',
                style: TextStyle(color: palette.inkMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _room == null) {
      return Scaffold(
        backgroundColor: palette.canvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/customer');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 54, color: palette.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Không thể tải chi tiết phòng',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: palette.inkMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _fetchRoomDetail,
                  style: ElevatedButton.styleFrom(backgroundColor: palette.accent),
                  child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final room = _room!;
    final images = room.images.isNotEmpty
        ? room.images
        : [
            'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80',
            'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80',
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
          ];

    final isStaff = context.isStaff;
    final isAvailable = room.status == RoomStatus.available;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          // Nội dung cuộn chính
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Slider Ảnh phòng Luxury dạng SliverAppBar
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                backgroundColor: palette.surface,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: _buildFrostedCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/customer');
                        }
                      },
                    ),
                  ),
                ),
                actions: [
                  if (context.currentRole.canEditRoom) ...[
                    Center(
                      child: _buildFrostedCircleButton(
                        icon: Icons.edit_note_rounded,
                        onTap: _openEditModal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Center(
                    child: _buildFrostedCircleButton(
                      icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconColor: _isFavorite ? AppColors.rose : Colors.white,
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                        AppNotification.showSuccess(
                          context,
                          _isFavorite ? 'Đã lưu vào danh sách yêu thích' : 'Đã xóa khỏi yêu thích',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: _buildFrostedCircleButton(
                        icon: Icons.share_rounded,
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                            text: 'Khách sạn Luxe Grand - Phòng ${room.roomNumber} (${room.roomTypeName}): ${Formatters.formatCurrency(room.pricePerNight)}/đêm',
                          ));
                          AppNotification.showSuccess(context, 'Đã sao chép liên kết phòng vào bộ nhớ tạm');
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemBuilder: (ctx, idx) {
                          return Hero(
                            tag: idx == 0 ? 'room-image-${room.id}' : 'room-image-${room.id}-$idx',
                            child: CachedNetworkImage(
                              imageUrl: images[idx],
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(color: palette.surfaceMuted),
                              errorWidget: (_, _, _) => Container(
                                color: palette.surfaceMuted,
                                child: const Center(
                                  child: Icon(Icons.hotel_rounded, size: 48, color: Colors.white54),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient mờ trên đỉnh để nhìn rõ nút
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Badge đếm ảnh ở góc phải dưới slider (1/5)
                      Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.screen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Nội dung chi tiết phòng
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề & Trạng thái
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: palette.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: Text(
                                        'TẦNG ${room.floor}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: palette.accent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      room.roomTypeCode ?? 'STD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: palette.inkFaint,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Phòng ${room.roomNumber}',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: palette.ink,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  room.roomTypeName ?? 'Hạng phòng cao cấp',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: palette.inkMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          RoomStatusBadge(status: room.status),
                        ],
                      ),
                      if (room.status == RoomStatus.reserved || room.status == RoomStatus.occupied) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (room.status == RoomStatus.occupied
                                    ? AppColors.occupied
                                    : AppColors.reserved)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: (room.status == RoomStatus.occupied
                                      ? AppColors.occupied
                                      : AppColors.reserved)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: room.status == RoomStatus.occupied
                                    ? AppColors.occupiedInk
                                    : AppColors.reservedInk,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  room.status == RoomStatus.occupied
                                      ? 'Phòng đang có khách hôm nay. Quý khách có thể chọn ngày sau để đặt trước.'
                                      : 'Phòng đã có lịch đặt trước hôm nay. Quý khách có thể chọn ngày khác để đặt chỗ.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: room.status == RoomStatus.occupied
                                        ? AppColors.occupiedInk
                                        : AppColors.reservedInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      Divider(color: palette.divider, height: 1),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Dải Thông Số Vàng (Golden Specs Bar)
                      _buildGoldenSpecsGrid(room, palette, textTheme),

                      const SizedBox(height: AppSpacing.xl),

                      // 4. Các điểm nổi bật (Highlights)
                      if (room.highlights.isNotEmpty) ...[
                        _buildSectionTitle('ĐIỂM NỔI BẬT ĐẮC GIÁ', palette),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: room.highlights.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondary.withValues(alpha: 0.12),
                                    AppColors.secondaryLight.withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppColors.secondaryLight.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: AppColors.secondaryDark),
                                  const SizedBox(width: 5),
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.ink,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // 5. Mô tả phòng (Description)
                      if (room.description != null && room.description!.isNotEmpty) ...[
                        _buildSectionTitle('GIỚI THIỆU KHÔNG GIAN', palette),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          room.description!,
                          maxLines: _isDescriptionExpanded ? null : 3,
                          overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: palette.ink,
                          ),
                        ),
                        if ((room.description?.length ?? 0) > 120) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                            child: Text(
                              _isDescriptionExpanded ? 'Thu gọn ▲' : 'Xem thêm toàn bộ ▼',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Ghi chú nội bộ (chỉ hiển thị cho nhân viên: Admin, Lễ tân, Thu ngân)
                      if (context.isStaff && room.notes != null && room.notes!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFF57F17),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ghi chú nội bộ (Chỉ nhân viên)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                room.notes!.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // 6. Tiện nghi theo nhóm (Amenity Groups)
                      if (room.amenityGroups.isNotEmpty) ...[
                        _buildSectionTitle('TIỆN NGHI CAO CẤP', palette),
                        const SizedBox(height: AppSpacing.md),
                        ...room.amenityGroups.map((group) => _buildAmenityGroupCard(group, palette)),
                        const SizedBox(height: AppSpacing.xl),
                      ] else if (room.amenities.isNotEmpty) ...[
                        _buildSectionTitle('TIỆN NGHI PHÒNG', palette),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.amenities.map((a) {
                            return Chip(
                              label: Text(a, style: const TextStyle(fontSize: 12)),
                              backgroundColor: palette.surfaceMuted,
                              side: BorderSide(color: palette.border),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // 7. Quy định & Chính sách phòng (Policies)
                      _buildSectionTitle('QUY ĐỊNH & CHÍNH SÁCH NGHỈ DƯỠNG', palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildPoliciesCard(room.policies, palette),

                      const SizedBox(height: AppSpacing.xl),

                      // 8. Đánh giá & Nhận xét từ khách (Reviews & Breakdown)
                      _buildSectionTitle('ĐÁNH GIÁ TỪ KHÁCH HÀNG', palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildRatingSection(room, palette),

                      // Chừa khoảng trống cho thanh tác vụ cố định đáy
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 9. Thanh Tác Vụ Cố Định Đáy (Sticky Floating Bottom Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(room, palette, isAvailable, isStaff),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppPalette palette) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: palette.inkFaint,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildGoldenSpecsGrid(RoomModel room, AppPalette palette, TextTheme textTheme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSpecItem(
                  icon: Icons.square_foot_rounded,
                  title: 'Diện tích',
                  value: '${room.sizeSqM ?? 45} m²',
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 44, color: palette.divider),
              Expanded(
                child: _buildSpecItem(
                  icon: Icons.king_bed_outlined,
                  title: 'Loại giường',
                  value: room.bedType ?? '1 Giường King đôi',
                  palette: palette,
                ),
              ),
            ],
          ),
          Divider(color: palette.divider, height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSpecItem(
                  icon: Icons.landscape_outlined,
                  title: 'Tầm nhìn',
                  value: room.viewType ?? 'Hướng biển 180°',
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 44, color: palette.divider),
              Expanded(
                child: _buildSpecItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Sức chứa',
                  value: '${room.capacityAdults ?? 2} người lớn, ${room.capacityChildren ?? 1} trẻ em',
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String title,
    required String value,
    required AppPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: palette.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: palette.inkFaint, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityGroupCard(AmenityGroupModel group, AppPalette palette) {
    IconData iconData = Icons.star_border_rounded;
    final gn = group.groupName.toLowerCase();
    if (gn.contains('ngủ') || gn.contains('bedroom')) iconData = Icons.bed_outlined;
    if (gn.contains('tắm') || gn.contains('bath')) iconData = Icons.bathtub_outlined;
    if (gn.contains('công nghệ') || gn.contains('giải trí')) iconData = Icons.tv_rounded;
    if (gn.contains('ẩm thực') || gn.contains('uống')) iconData = Icons.coffee_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: palette.accent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  group.groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: palette.accent),
                      const SizedBox(width: 5),
                      Text(
                        item,
                        style: TextStyle(fontSize: 12, color: palette.ink),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesCard(RoomPoliciesModel policies, AppPalette palette) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPolicyTimeCol('Nhận phòng', policies.checkInTime, Icons.login_rounded, palette),
              ),
              Container(width: 1, height: 40, color: palette.divider),
              Expanded(
                child: _buildPolicyTimeCol('Trả phòng', policies.checkOutTime, Icons.logout_rounded, palette),
              ),
            ],
          ),
          Divider(color: palette.divider, height: 28),
          _buildPolicyRow(Icons.cancel_presentation_rounded, 'Hủy phòng', policies.cancellation, palette),
          const SizedBox(height: AppSpacing.sm),
          _buildPolicyRow(Icons.smoke_free_rounded, 'Hút thuốc', policies.smoking, palette),
          const SizedBox(height: AppSpacing.sm),
          _buildPolicyRow(Icons.pets_rounded, 'Thú cưng', policies.pet, palette),
          const SizedBox(height: AppSpacing.sm),
          _buildPolicyRow(Icons.child_care_rounded, 'Trẻ em', policies.children, palette),
          const SizedBox(height: AppSpacing.sm),
          _buildPolicyRow(Icons.account_balance_wallet_outlined, 'Đặt cọc', 'Đơn trên 5.000.000 ₫ cọc 10% qua mã VietQR; Dưới 5.000.000 ₫ miễn cọc', palette),
        ],
      ),
    );
  }

  Widget _buildPolicyTimeCol(String label, String time, IconData icon, AppPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: palette.accent),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: palette.inkFaint)),
            Text(
              time,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyRow(IconData icon, String label, String value, AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: palette.inkMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: palette.inkMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(RoomModel room, AppPalette palette) {
    final bd = room.ratingBreakdown;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${room.rating ?? 4.95}',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryDark,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (idx) {
                      return const Icon(Icons.star_rounded, color: AppColors.secondary, size: 18);
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dựa trên ${room.reviewCount ?? 124} đánh giá khách thực tế',
                    style: TextStyle(fontSize: 12, color: palette.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: palette.divider, height: 1),
          const SizedBox(height: AppSpacing.md),

          // 5 tiêu chuẩn đánh giá
          _buildRatingProgressBar('Độ sạch sẽ & Vệ sinh', bd.cleanliness, palette),
          _buildRatingProgressBar('Tiện nghi & Thiết bị', bd.comfort, palette),
          _buildRatingProgressBar('Vị trí & Cảnh quan', bd.location, palette),
          _buildRatingProgressBar('Chất lượng dịch vụ', bd.service, palette),
          _buildRatingProgressBar('Giá trị trải nghiệm', bd.value, palette),

          // Danh sách nhận xét
          if (room.reviews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(color: palette.divider, height: 1),
            const SizedBox(height: AppSpacing.md),
            ...room.reviews.map((rev) => _buildReviewItem(rev, palette)),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingProgressBar(String title, double score, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: TextStyle(fontSize: 12, color: palette.inkMuted)),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: score / 5.0,
                minHeight: 6,
                backgroundColor: palette.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 26,
            child: Text(
              score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(RoomReviewModel review, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: palette.surfaceMuted,
                backgroundImage: review.authorAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(review.authorAvatar)
                    : null,
                child: review.authorAvatar.isEmpty
                    ? Text(
                        review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : 'K',
                        style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                    ),
                    Text(
                      '${review.date} • ${review.stayDuration ?? "Lưu trú 2 đêm"}',
                      style: TextStyle(fontSize: 11, color: palette.inkFaint),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.secondary, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${review.rating}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.ink),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13, height: 1.45, color: palette.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(RoomModel room, AppPalette palette, bool isAvailable, bool isStaff) {
    final canBook = room.status != RoomStatus.maintenance;
    final isAvailableToday = room.status == RoomStatus.available;
    final buttonText = isAvailableToday
        ? 'Đặt Phòng Ngay'
        : (canBook ? 'Chọn Ngày Đặt Trước' : 'Phòng Đang Bảo Trì');
    final buttonIcon = isAvailableToday
        ? Icons.calendar_today_rounded
        : (canBook ? Icons.event_available_rounded : Icons.lock_outline_rounded);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: palette.isDark ? Border(top: BorderSide(color: palette.border, width: 1)) : null,
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giá niêm yết',
                style: TextStyle(fontSize: 11, color: palette.inkFaint),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    Formatters.formatCurrency(room.pricePerNight),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '/đêm',
                    style: TextStyle(fontSize: 12, color: palette.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          if (context.currentRole.canEditRoom) ...[
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _openEditModal,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Sửa phòng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.accent,
                  side: BorderSide(color: palette.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: PressableScale(
              onTap: canBook ? _onBookPressed : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: canBook ? AppGradients.gold : null,
                  color: canBook ? null : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: canBook ? AppShadows.goldGlow : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      buttonIcon,
                      color: canBook ? Colors.white : palette.inkMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: canBook ? Colors.white : palette.inkMuted,
                      ),
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
}
