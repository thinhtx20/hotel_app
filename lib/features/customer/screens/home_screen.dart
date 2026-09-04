import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
import '../../../shared/widgets/skeletons/room_card_skeleton.dart';
import '../../../shared/widgets/status_badge.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../widgets/create_booking_modal.dart';
import '../widgets/create_room_modal.dart';

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

  void _openCreateRoomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateRoomModal(
        onSuccess: () {
          _roomRepository.fetchRooms(forceRefresh: true);
        },
      ),
    );
  }

  void _onBookPressed(RoomModel room) {
    if (room.status == RoomStatus.reserved ||
        room.status == RoomStatus.occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Phòng ${room.roomNumber} đã có người đặt, vui lòng chọn phòng khác.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.amberDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (room.status == RoomStatus.pendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Phòng ${room.roomNumber} đang chờ Admin duyệt trước khi có thể đặt.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.amberDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (room.status == RoomStatus.rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Phòng ${room.roomNumber} đã bị từ chối đăng bài.'),
              ),
            ],
          ),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
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
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.28).clamp(220.0, 300.0);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final allRooms = _roomRepository.rooms;
    final pendingRooms = _roomRepository.pendingRooms;
    final isAdmin = user?.role == UserRole.admin;

    final categories = _buildCategories(allRooms);
    final selectedType = categories.any((c) => c.typeName == _selectedRoomType)
        ? _selectedRoomType
        : null;
    final visibleRooms = selectedType == null
        ? allRooms
        : allRooms
              .where((r) => (r.roomTypeName ?? '').trim() == selectedType)
              .toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.surface,
        onRefresh: () => _roomRepository.fetchRooms(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Image Header + Search bar overlapping
              SizedBox(
                height: heroHeight + 26,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background Luxury Suite Image
                    SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=1200&q=80',
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 250),
                            placeholder: (context, url) => Container(
                              color: palette.isDark
                                  ? palette.surfaceMuted
                                  : AppColors.primary,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: palette.isDark
                                  ? palette.surfaceMuted
                                  : AppColors.primary,
                            ),
                          ),
                          // Luxury Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  (palette.isDark
                                          ? palette.canvas
                                          : AppColors.primary)
                                      .withValues(alpha: 0.4),
                                  (palette.isDark
                                          ? palette.canvas
                                          : AppColors.primary)
                                      .withValues(alpha: 0.90),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Bar Header Content
                    Positioned(
                      top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: App Title / User Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PARADISE RESORT',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user != null
                                      ? 'Xin chào, ${user.fullName} 👋'
                                      : 'Khám Phá Nghỉ Dưỡng',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // User Avatar Profile Button
                          PressableScale(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 42,
                              height: 42,
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
                                  user != null && user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar overlapping bottom edge
                    Positioned(
                      bottom: 0,
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      child: PressableScale(
                        onTap: () => context.push('/search'),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: palette.isDark
                                ? Border.all(color: palette.border)
                                : null,
                            boxShadow: palette.isDark ? null : AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: palette.accent,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Tìm kiếm phòng sang trọng...',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: palette.inkFaint,
                                  ),
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
                                      color: palette.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Action Toolbar: chỉ Admin mới được tạo & duyệt phòng
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: Row(
                    children: [
                      // Create Room Button
                      Expanded(
                        child: PressableScale(
                          onTap: _openCreateRoomModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: palette.isDark
                                    ? palette.border
                                    : palette.border.withValues(alpha: 0.8),
                              ),
                              boxShadow: palette.isDark
                                  ? null
                                  : AppShadows.soft,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: palette.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '+ Tạo phòng mới',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Room Approval Shortcut Button
                      PressableScale(
                        onTap: () => context.push('/room-approval'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.fact_check_outlined,
                                color: AppColors.amberDark,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Text(
                                'Duyệt phòng',
                                style: TextStyle(
                                  color: AppColors.amberDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (pendingRooms.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.amberDark,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pendingRooms.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isAdmin) const SizedBox(height: AppSpacing.md),

              // Pending Rooms Banner Alert (If any) — cũng chỉ dành cho Admin
              if (isAdmin && pendingRooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Có ${pendingRooms.length} phòng mới tạo đang chờ duyệt',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vào màn Duyệt phòng để Admin phê duyệt',
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PressableScale(
                          onTap: () => context.push('/room-approval'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            child: Text(
                              'Xem ngay',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isAdmin && pendingRooms.isNotEmpty)
                const SizedBox(height: AppSpacing.lg),

              // 3. Sliding / Animated Category Chips Row
              if (categories.length > 1)
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, idx) {
                      final item = categories[idx];
                      final isSelected = item.typeName == selectedType;
                      return SizedBox(
                        width: 72,
                        child: PressableScale(
                          onTap: () =>
                              setState(() => _selectedRoomType = item.typeName),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: AppMotion.enter,
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? AppGradients.gold
                                      : null,
                                  color: isSelected
                                      ? null
                                      : palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: palette.border,
                                          width: 1,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: palette.accent.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        item.icon,
                                        color: isSelected
                                            ? Colors.white
                                            : palette.inkMuted,
                                        size: 24,
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
                                              ? Colors.white.withValues(
                                                  alpha: 0.28,
                                                )
                                              : palette.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.count}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : palette.inkMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? palette.accent
                                      : palette.inkMuted,
                                ),
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (categories.length > 1) const SizedBox(height: AppSpacing.lg),

              // 4. Section Header: "Danh sách phòng" & "Xem tất cả"
              AppSectionHeader(
                title: selectedType == null
                    ? 'Danh sách phòng'
                    : 'Phòng $selectedType',
                actionTitle: 'Xem tất cả',
                onAction: () => context.push('/search'),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 5. Dynamic Room Cards (Skeleton -> Content -> Empty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: _roomRepository.isLoading
                    ? Column(
                        children: const [
                          RoomCardSkeleton(),
                          SizedBox(height: AppSpacing.lg),
                          RoomCardSkeleton(),
                          SizedBox(height: AppSpacing.lg),
                          RoomCardSkeleton(),
                        ],
                      )
                    : allRooms.isEmpty
                    ? AppEmptyState(
                        icon: Icons.hotel_outlined,
                        title: 'Chưa có phòng nào',
                        description:
                            'Hiện tại khách sạn chưa có phòng nào sẵn sàng. Vui lòng tải lại hoặc tạo phòng mới!',
                        actionText: 'Tải lại danh sách',
                        onAction: () =>
                            _roomRepository.fetchRooms(forceRefresh: true),
                      )
                    : visibleRooms.isEmpty
                    ? AppEmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Không có phòng "$selectedType"',
                        description:
                            'Chưa có phòng nào thuộc loại này. Thử chọn loại phòng khác nhé!',
                        actionText: 'Xem tất cả phòng',
                        onAction: () =>
                            setState(() => _selectedRoomType = null),
                      )
                    : Column(
                        children: visibleRooms.map((room) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: _buildFeaturedRoomCard(room),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedRoomCard(RoomModel room) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final isFav = _favoriteRoomIds.contains(room.id);
    final imageUrl = room.images.isNotEmpty
        ? room.images.first
        : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=800&q=80';

    final roomTitle =
        'Phòng ${room.roomNumber} — ${room.roomTypeName ?? "Deluxe"}';
    final subInfo =
        'Tầng ${room.floor} • ${room.amenities.isNotEmpty ? room.amenities.take(3).join(" • ") : "Đầy đủ tiện nghi"}';
    final priceStr = Formatters.formatCurrency(room.pricePerNight);

    return AppCard(
      padding: EdgeInsets.zero,
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
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 250),
                      placeholder: (context, url) =>
                          Container(color: palette.surfaceMuted),
                      errorWidget: (context, url, error) => Container(
                        color: palette.surfaceMuted,
                        child: Icon(Icons.hotel, color: palette.inkMuted),
                      ),
                    ),
                  ),

                  // Top Left: Favorite Heart Button
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: PressableScale(
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
                        child: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.rose : Colors.white,
                          size: 20,
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
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: palette.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '4.9',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ],
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
                                  fontWeight: FontWeight.w700,
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

    if (room.status == RoomStatus.pendingApproval) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: AppColors.amberDark,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Chờ duyệt',
              style: TextStyle(
                color: AppColors.amberDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == RoomStatus.reserved ||
        room.status == RoomStatus.occupied) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_added_rounded,
              size: 16,
              color: AppColors.amberDark,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Đã được đặt',
              style: TextStyle(
                color: AppColors.amberDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == RoomStatus.rejected) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.rose),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Từ chối',
              style: TextStyle(
                color: AppColors.rose,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
              color: palette.accent.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Đặt Phòng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

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
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: palette.inkMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
