import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
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

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedCategoryIndex = 1; // "Cao cấp" selected by default
  final Set<String> _favoriteRoomIds = {};
  final RoomRepository _roomRepository = sl<RoomRepository>();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Tiêu chuẩn', 'icon': Icons.single_bed_outlined},
    {'title': 'Cao cấp', 'icon': Icons.star_border_rounded},
    {'title': 'Suite', 'icon': Icons.king_bed_outlined},
    {'title': 'Hướng biển', 'icon': Icons.waves_rounded},
  ];

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
    if (room.status == RoomStatus.reserved || room.status == RoomStatus.occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
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
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Phòng ${room.roomNumber} đang chờ Admin duyệt trước khi có thể đặt.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (room.status == RoomStatus.rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phòng ${room.roomNumber} đã bị từ chối đăng bài.'),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.28;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final allRooms = _roomRepository.rooms;
    final pendingRooms = _roomRepository.pendingRooms;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _roomRepository.fetchRooms(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Image Header (28% height) + Search bar overlapping
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
                            placeholder: (context, url) => Container(
                              color: AppColors.primary,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primary,
                            ),
                          ),
                          // Gradient overlay transparent to navy 85%
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary.withValues(alpha: 0.35),
                                  AppColors.primary.withValues(alpha: 0.85),
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
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: App Title / User Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PARADISE RESORT',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user != null ? 'Xin chào, ${user.fullName} 👋' : 'Khám Phá Nghỉ Dưỡng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Action Buttons (Bell + Profile)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user != null && user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search Bar overlapping bottom edge
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tìm kiếm phòng sang trọng...',
                                  style: TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  gradient: AppGradients.navy,
                                  shape: BoxShape.circle,
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
              const SizedBox(height: 20),

              // 2. Action Toolbar: Create Room & Admin Approval Shortcut
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Create Room Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openCreateRoomModal,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: AppGradients.navy,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: AppColors.secondary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '+ Tạo phòng mới',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Room Approval Shortcut Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/room-approval'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fact_check_outlined, color: AppColors.amberDark, size: 20),
                              const SizedBox(width: 6),
                              const Text(
                                'Duyệt phòng',
                                style: TextStyle(
                                  color: AppColors.amberDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (pendingRooms.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pending Rooms Banner Alert (If any)
              if (pendingRooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Có ${pendingRooms.length} phòng mới tạo đang chờ duyệt',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Vào màn Duyệt phòng để Admin phê duyệt',
                                style: TextStyle(fontSize: 11, color: AppColors.slate600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/room-approval'),
                          child: const Text(
                            'Xem ngay',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.amberDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (pendingRooms.isNotEmpty) const SizedBox(height: 20),

              // 3. Categories Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_categories.length, (idx) {
                    final item = _categories[idx];
                    final isSelected = idx == _selectedCategoryIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = idx),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppGradients.gold : null,
                                color: isSelected ? null : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Section Header: "Danh sách phòng" & "Xem tất cả"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh sách phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/search'),
                      child: const Row(
                        children: [
                          Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 11,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Dynamic Room Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _roomRepository.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        ),
                      )
                    : Column(
                        children: allRooms.map((room) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildFeaturedRoomCard(room),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedRoomCard(RoomModel room) {
    final isFav = _favoriteRoomIds.contains(room.id);
    final imageUrl = room.images.isNotEmpty
        ? room.images.first
        : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=800&q=80';

    final roomTitle = 'Phòng ${room.roomNumber} — ${room.roomTypeName ?? "Deluxe"}';
    final subInfo = 'Tầng ${room.floor} • ${room.amenities.isNotEmpty ? room.amenities.take(3).join(" • ") : "Đầy đủ tiện nghi"}';
    final priceStr = Formatters.formatCurrency(room.pricePerNight);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image (160px height) with Frosted Badges
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.surfaceMuted),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.hotel, color: AppColors.slate400),
                    ),
                  ),

                  // Top Left: Favorite Heart Button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
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
                          isFav ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.error : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Top Right: Dynamic Status Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: RoomStatusBadge(
                      status: room.status,
                      onDarkSurface: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Under Image Content (16px padding)
          Padding(
            padding: const EdgeInsets.all(16),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '4.9',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Subtitle
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subInfo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Utility Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (room.amenities.isNotEmpty
                          ? room.amenities
                          : ['Wifi miễn phí', 'Điều hòa', 'Ăn sáng'])
                      .take(3)
                      .map((amenity) => _AmenityChip(label: amenity))
                      .toList(),
                ),
                const SizedBox(height: 14),

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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ đêm',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

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
    if (room.status == RoomStatus.pendingApproval) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.amberDark),
            SizedBox(width: 6),
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

    if (room.status == RoomStatus.reserved || room.status == RoomStatus.occupied) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.bookmark_added_rounded, size: 16, color: AppColors.amberDark),
            SizedBox(width: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.rose),
            SizedBox(width: 6),
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

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onBookPressed(room),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Center(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
