import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/motion/staggered_list.dart';
import '../../../shared/widgets/skeletons/room_card_skeleton.dart';
import '../../../shared/widgets/status_badge.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../widgets/create_booking_modal.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

/// Một chip lọc theo loại phòng. [typeName] null nghĩa là "Tất cả".
class _RoomCategory {
  final String title;
  final IconData icon;
  final String? typeName;
  final int count;

  const _RoomCategory({
    required this.title,
    required this.icon,
    required this.typeName,
    required this.count,
  });
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  /// Loại phòng đang lọc; null = hiển thị tất cả.
  String? _selectedRoomType;
  final Set<String> _favoriteRoomIds = {};
  final RoomRepository _roomRepository = sl<RoomRepository>();

  /// Danh mục được dựng từ chính dữ liệu phòng đã tải, nên mỗi chip luôn
  /// có phòng để hiển thị.
  List<_RoomCategory> _buildCategories(List<RoomModel> rooms) {
    final counts = <String, int>{};
    for (final room in rooms) {
      final name = (room.roomTypeName ?? '').trim();
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }

    final names = counts.keys.toList()..sort();
    return [
      _RoomCategory(
        title: 'Tất cả',
        icon: Icons.apps_rounded,
        typeName: null,
        count: rooms.length,
      ),
      ...names.map(
        (name) => _RoomCategory(
          title: name,
          icon: _iconForRoomType(name),
          typeName: name,
          count: counts[name]!,
        ),
      ),
    ];
  }

  static IconData _iconForRoomType(String name) {
    final n = name.toLowerCase();
    if (n.contains('suite') ||
        n.contains('penthouse') ||
        n.contains('president')) {
      return Icons.king_bed_outlined;
    }
    if (n.contains('biển') ||
        n.contains('ocean') ||
        n.contains('sea') ||
        n.contains('view')) {
      return Icons.waves_rounded;
    }
    if (n.contains('gia đình') || n.contains('family')) {
      return Icons.family_restroom_rounded;
    }
    if (n.contains('vip') ||
        n.contains('deluxe') ||
        n.contains('premium') ||
        n.contains('superior') ||
        n.contains('cao cấp')) {
      return Icons.star_border_rounded;
    }
    return Icons.single_bed_outlined;
  }

  @override
  void initState() {
    super.initState();
    _roomRepository.addListener(_onRepositoryUpdated);
    _roomRepository.fetchRooms();
  }

  @override
  void dispose() {
    _roomRepository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  /// Thông báo nền tối duy nhất cho mọi trạng thái — chữ trắng trên navy luôn
  /// đạt tương phản, màu chỉ nằm ở biểu tượng.
  void _showStatusSnack(String message, IconData icon, Color tint) {
    final palette = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: palette.isDark
              ? palette.surfaceMuted
              : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _onBookPressed(RoomModel room) {
    if (room.status == RoomStatus.reserved ||
        room.status == RoomStatus.occupied) {
      _showStatusSnack(
        'Phòng ${room.roomNumber} đã có người đặt, vui lòng chọn phòng khác.',
        Icons.info_outline,
        context.palette.warningInk,
      );
      return;
    }

    if (room.status == RoomStatus.pendingApproval) {
      _showStatusSnack(
        'Phòng ${room.roomNumber} đang chờ Admin duyệt trước khi có thể đặt.',
        Icons.hourglass_top_rounded,
        context.palette.infoInk,
      );
      return;
    }

    if (room.status == RoomStatus.rejected) {
      _showStatusSnack(
        'Phòng ${room.roomNumber} đã bị từ chối đăng bài.',
        Icons.cancel_outlined,
        context.palette.errorInk,
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
          context.go('/my-bookings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.26).clamp(200.0, 260.0);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final allRooms = _roomRepository.rooms;

    final categories = _buildCategories(allRooms);
    final selectedType = categories.any((c) => c.typeName == _selectedRoomType)
        ? _selectedRoomType
        : null;
    final visibleRooms = selectedType == null
        ? allRooms
        : allRooms
              .where((r) => (r.roomTypeName ?? '').trim() == selectedType)
              .toList();
    final availableCount = visibleRooms
        .where((r) => r.status == RoomStatus.available)
        .length;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.surface,
        // Header dính chiếm phần trên, kéo vòng quay xuống dưới nó cho dễ thấy.
        edgeOffset: MediaQuery.paddingOf(context).top + 64,
        onRefresh: () => _roomRepository.fetchRooms(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hero + lời chào — thu lại thành thanh dính khi cuộn lên.
            _buildHeroSliver(user?.fullName, heroHeight.toDouble()),

            // 2. Ô tìm kiếm + hàng danh mục — dính ngay dưới thanh chào.
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyDiscoveryHeader(
                categories: categories,
                selectedType: selectedType,
                onSelect: (type) =>
                    setState(() => _selectedRoomType = type),
                onSearchTap: () => context.push('/search'),
              ),
            ),

            // 3. Tiêu đề mục
            SliverToBoxAdapter(
              child: AppSectionHeader(
                title: selectedType == null
                    ? 'Danh sách phòng'
                    : 'Phòng $selectedType',
                subtitle: _roomRepository.isLoading || visibleRooms.isEmpty
                    ? null
                    : '${visibleRooms.length} phòng • $availableCount còn trống',
                actionTitle: 'Xem tất cả',
                onAction: () => context.push('/search'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // 4. Danh sách phòng (Skeleton -> Content -> Empty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              sliver: _buildRoomSliver(visibleRooms, allRooms, selectedType),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSliver(
    List<RoomModel> visibleRooms,
    List<RoomModel> allRooms,
    String? selectedType,
  ) {
    if (_roomRepository.isLoading) {
      return const SliverToBoxAdapter(
        child: Column(
          children: [
            RoomCardSkeleton(),
            SizedBox(height: AppSpacing.lg),
            RoomCardSkeleton(),
            SizedBox(height: AppSpacing.lg),
            RoomCardSkeleton(),
          ],
        ),
      );
    }

    if (allRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.hotel_outlined,
          title: 'Chưa có phòng nào',
          description:
              'Hiện tại khách sạn chưa có phòng nào sẵn sàng. Vui lòng tải lại hoặc tạo phòng mới!',
          actionText: 'Tải lại danh sách',
          onAction: () => _roomRepository.fetchRooms(forceRefresh: true),
        ),
      );
    }

    if (visibleRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'Không có phòng "$selectedType"',
          description:
              'Chưa có phòng nào thuộc loại này. Thử chọn loại phòng khác nhé!',
          actionText: 'Xem tất cả phòng',
          onAction: () => setState(() => _selectedRoomType = null),
        ),
      );
    }

    // Khóa gắn theo bộ lọc: đổi danh mục thì thẻ được dựng lại nên hoạt ảnh
    // xuất hiện so le chạy lại, tạo cảm giác danh sách "thay mới".
    final filterKey = selectedType ?? '__all__';
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final room = visibleRooms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: StaggeredListItem(
            key: ValueKey('$filterKey-${room.id}'),
            index: index,
            child: _buildFeaturedRoomCard(room),
          ),
        );
      }, childCount: visibleRooms.length),
    );
  }

  // ── Hero dính ──────────────────────────────────────────────────────────
  Widget _buildHeroSliver(String? fullName, double heroHeight) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final topPad = MediaQuery.paddingOf(context).top;
    const collapsedHeight = 64.0;
    // Màu thanh khi đã dính: navy ở chế độ sáng, nền canvas ở chế độ tối.
    final barColor = palette.isDark ? palette.canvas : AppColors.primary;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: heroHeight,
      collapsedHeight: collapsedHeight,
      toolbarHeight: collapsedHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = topPad + heroHeight;
          final minH = topPad + collapsedHeight;
          // t = 0 khi mở hết, t = 1 khi đã dính sát trên.
          final t = maxH - minH <= 0
              ? 1.0
              : ((maxH - constraints.maxHeight) / (maxH - minH)).clamp(
                  0.0,
                  1.0,
                );

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(_lerp(AppRadius.xxl, 0, t)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80',
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 250),
                      placeholder: (context, url) => Container(color: barColor),
                      errorWidget: (context, url, error) =>
                          Container(color: barColor),
                    ),
                    // Lớp phủ gradient cho chữ trắng luôn đọc được.
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            barColor.withValues(alpha: 0.45),
                            barColor.withValues(alpha: 0.92),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Càng dính thì ảnh càng chìm, thanh trở thành nền đặc.
                    Container(color: barColor.withValues(alpha: t)),
                  ],
                ),
              ),

              // Lời chào + avatar — luôn nằm sát mép trên nên không bị cuộn mất.
              Positioned(
                top: topPad + AppSpacing.sm,
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PARADISE RESORT',
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: _lerp(11, 10, t),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fullName != null
                                ? 'Xin chào, $fullName 👋'
                                : 'Khám Phá Nghỉ Dưỡng',
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: _lerp(
                                textTheme.titleLarge?.fontSize ?? 22,
                                17,
                                t,
                              ),
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    PressableScale(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: _lerp(42, 36, t),
                        height: _lerp(42, 36, t),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            fullName != null && fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _lerp(16, 14, t),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Thẻ phòng ──────────────────────────────────────────────────────────
  Widget _buildFeaturedRoomCard(RoomModel room) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final isFav = _favoriteRoomIds.contains(room.id);
    final isBookable = room.status == RoomStatus.available;
    // Fallback is requested pre-cropped to the card's ~2.6:1 box so it does not
    // decode rows that BoxFit.cover throws away.
    final imageUrl = room.images.isNotEmpty
        ? room.images.first
        : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1040&h=400&q=80';

    final roomTitle =
        'Phòng ${room.roomNumber} — ${room.roomTypeName ?? "Deluxe"}';
    final subInfo =
        'Tầng ${room.floor} • ${room.amenities.isNotEmpty ? room.amenities.take(3).join(" • ") : "Đầy đủ tiện nghi"}';
    final priceStr = Formatters.formatCurrency(room.pricePerNight);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/rooms/${room.id}'),
      // Phòng còn trống được viền accent mảnh để nổi hơn phòng đã kín.
      border: isBookable
          ? Border.all(color: palette.accent.withValues(alpha: 0.35), width: 1)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image (160px height) with Frosted Badges & Hero transition
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'room-image-${room.id}',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Decode at the card's real pixel width instead of the
                        // source resolution. The card is much wider than it is
                        // tall, so BoxFit.cover is always width-bound here and
                        // capping the width costs no sharpness.
                        final dpr = MediaQuery.devicePixelRatioOf(context);
                        final decodeWidth = constraints.maxWidth.isFinite
                            ? (constraints.maxWidth * dpr).round()
                            : null;
                        final image = CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: decodeWidth,
                          fadeInDuration: const Duration(milliseconds: 250),
                          placeholder: (context, url) =>
                              Container(color: palette.surfaceMuted),
                          errorWidget: (context, url, error) => Container(
                            color: palette.surfaceMuted,
                            child: Icon(Icons.hotel, color: palette.inkMuted),
                          ),
                        );
                        // Phòng không đặt được thì ảnh xám bớt — người dùng
                        // nhận ra ngay trước cả khi đọc nhãn trạng thái.
                        return isBookable
                            ? image
                            : ColorFiltered(
                                colorFilter: const ColorFilter.matrix(
                                  _desaturate35,
                                ),
                                child: image,
                              );
                      },
                    ),
                  ),

                  // Lớp phủ tối nhẹ ở hai mép để huy hiệu luôn đọc rõ.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: isBookable ? 0.28 : 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: isBookable ? 0.12 : 0.3),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Left: Favorite Heart Button
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: PressableScale(
                      scale: 0.85,
                      onTap: () {
                        setState(() {
                          if (isFav) {
                            _favoriteRoomIds.remove(room.id);
                          } else {
                            _favoriteRoomIds.add(room.id);
                          }
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: AppMotion.emphasis,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isFav
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            key: ValueKey(isFav),
                            color: isFav ? AppColors.rose : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Right: Dynamic Status Badge
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: RoomStatusBadge(
                      status: room.status,
                      onDarkSurface: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Under Image Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        roomTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillR,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: palette.accent,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '4.9',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Subtitle
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: palette.inkMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        subInfo,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Utility Chips
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children:
                      (room.amenities.isNotEmpty
                              ? room.amenities
                              : ['Wifi miễn phí', 'Điều hòa', 'Ăn sáng'])
                          .take(3)
                          .map((amenity) => _AmenityChip(label: amenity))
                          .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: AppSpacing.md),

                // Bottom Row: Price + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                priceStr,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '/ đêm',
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Action Button based on Status
                    _buildActionButtonForRoom(room),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonForRoom(RoomModel room) {
    final palette = context.palette;

    // Trạng thái không đặt được: cùng một khuôn, chỉ đổi màu/nhãn theo
    // bảng màu đã phân giải theo Dark/Light nên luôn đủ tương phản.
    Widget stateChip(IconData icon, String label, Color tint) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: tint.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: tint,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == RoomStatus.pendingApproval) {
      // Xanh dương = "đang xử lý", tách hẳn khỏi vàng "đã có người đặt".
      return stateChip(
        Icons.hourglass_empty_rounded,
        'Chờ duyệt',
        palette.infoInk,
      );
    }

    if (room.status == RoomStatus.reserved ||
        room.status == RoomStatus.occupied) {
      return stateChip(
        Icons.bookmark_added_rounded,
        'Đã được đặt',
        palette.warningInk,
      );
    }

    if (room.status == RoomStatus.rejected) {
      return stateChip(Icons.cancel_outlined, 'Từ chối', palette.errorInk);
    }

    if (room.status == RoomStatus.cleaning ||
        room.status == RoomStatus.maintenance) {
      return stateChip(
        room.status.icon,
        room.status.label,
        palette.statusMaintenanceInk,
      );
    }

    return PressableScale(
      onTap: () => _onBookPressed(room),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Đặt Phòng',
            style: TextStyle(
              // Chữ navy trên nền vàng: tương phản cao hơn hẳn chữ trắng.
              color: palette.onAccent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ma trận giảm bão hòa còn 35% — dùng cho ảnh phòng không đặt được.
const List<double> _desaturate35 = <double>[
  0.48845, 0.46475, 0.0468, 0, 0, //
  0.13845, 0.81475, 0.0468, 0, 0, //
  0.13845, 0.46475, 0.3968, 0, 0, //
  0, 0, 0, 1, 0,
];

/// Ô tìm kiếm + hàng danh mục, ghim lại dưới thanh chào khi cuộn.
class _StickyDiscoveryHeader extends SliverPersistentHeaderDelegate {
  final List<_RoomCategory> categories;
  final String? selectedType;
  final ValueChanged<String?> onSelect;
  final VoidCallback onSearchTap;

  const _StickyDiscoveryHeader({
    required this.categories,
    required this.selectedType,
    required this.onSelect,
    required this.onSearchTap,
  });

  static const double _topGap = 12;
  static const double _searchH = 52;
  static const double _midGap = 12;
  static const double _chipsH = 88;
  static const double _bottomGap = 10;

  /// Đường kẻ dưới lúc dính. `BoxDecoration.border` chiếm chỗ thật trong layout
  /// nên phải cộng vào chiều cao, nếu không nó ăn mất 1px của [_bottomGap].
  static const double _dividerHeight = 1;

  bool get _hasCategories => categories.length > 1;

  double get _height =>
      (_hasCategories
          ? _topGap + _searchH + _midGap + _chipsH + _bottomGap
          : _topGap + _searchH + _bottomGap) +
      _dividerHeight;

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    // Chiều cao phải khớp đúng maxExtent, nếu không sliver báo geometry sai.
    return SizedBox(
      height: _height,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppMotion.enter,
        decoration: BoxDecoration(
          color: palette.canvas,
          // Khi nội dung bắt đầu chui xuống dưới, header nhấc lên bằng một
          // đường kẻ mảnh + bóng đổ để thấy rõ nó đang dính.
          border: Border(
            bottom: BorderSide(
              color: overlapsContent ? palette.border : Colors.transparent,
              width: _dividerHeight,
            ),
          ),
          boxShadow: overlapsContent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: palette.isDark ? 0.5 : 0.07,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        // Khoảng trống thừa rơi xuống đáy — chính là _bottomGap.
        child: Column(
          children: [
            const SizedBox(height: _topGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: _buildSearchBar(context, palette, textTheme),
            ),
            if (_hasCategories) ...[
              const SizedBox(height: _midGap),
              SizedBox(
                height: _chipsH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, idx) =>
                      _buildCategoryChip(context, palette, categories[idx]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AppPalette palette,
    TextTheme textTheme,
  ) {
    return PressableScale(
      onTap: onSearchTap,
      child: Container(
        height: _searchH,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: palette.isDark
                ? palette.border
                : palette.accent.withValues(alpha: 0.18),
          ),
          boxShadow: palette.isDark ? null : AppShadows.soft,
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: palette.accent, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Tìm kiếm phòng sang trọng...',
                style: textTheme.bodyMedium?.copyWith(color: palette.inkFaint),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: palette.onAccent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    AppPalette palette,
    _RoomCategory item,
  ) {
    final isSelected = item.typeName == selectedType;

    return SizedBox(
      width: 72,
      child: PressableScale(
        onTap: () => onSelect(item.typeName),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: AppMotion.enter,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.gold : null,
                color: isSelected ? null : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: isSelected
                    ? null
                    : Border.all(color: palette.border, width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: AppMotion.enter,
                      child: Icon(
                        item.icon,
                        color: isSelected ? palette.onAccent : palette.inkMuted,
                        size: 24,
                      ),
                    ),
                  ),
                  // Số phòng thuộc loại này
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.onAccent.withValues(alpha: 0.18)
                            : palette.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: isSelected
                              ? palette.onAccent
                              : palette.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Flexible để nhãn dài / cỡ chữ hệ thống lớn không làm tràn ô.
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? palette.accent : palette.inkMuted,
                ),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDiscoveryHeader oldDelegate) {
    // Chỉ được gọi khi widget cha dựng lại, nên so sánh thô là đủ rẻ.
    return oldDelegate.selectedType != selectedType ||
        oldDelegate.categories.length != categories.length ||
        oldDelegate._height != _height;
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  static IconData _iconFor(String label) {
    final n = label.toLowerCase();
    if (n.contains('wifi') || n.contains('internet')) return Icons.wifi_rounded;
    if (n.contains('điều hòa') || n.contains('máy lạnh') || n.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (n.contains('tv') || n.contains('tivi')) return Icons.tv_rounded;
    if (n.contains('ăn sáng') || n.contains('breakfast')) {
      return Icons.free_breakfast_rounded;
    }
    if (n.contains('bể bơi') || n.contains('hồ bơi') || n.contains('pool')) {
      return Icons.pool_rounded;
    }
    if (n.contains('tắm') || n.contains('bath')) return Icons.bathtub_outlined;
    if (n.contains('đỗ xe') || n.contains('park')) {
      return Icons.local_parking_rounded;
    }
    if (n.contains('bar')) return Icons.local_bar_rounded;
    if (n.contains('ban công') || n.contains('view') || n.contains('biển')) {
      return Icons.balcony_outlined;
    }
    if (n.contains('két') || n.contains('safe')) {
      return Icons.lock_outline_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 12, color: palette.inkMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: palette.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
