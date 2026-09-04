import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/room_card_skeleton.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/create_booking_modal.dart';

class RoomSearchScreen extends StatefulWidget {
  const RoomSearchScreen({super.key});

  @override
  State<RoomSearchScreen> createState() => _RoomSearchScreenState();
}

class _RoomSearchScreenState extends State<RoomSearchScreen> {
  final _searchController = TextEditingController(text: 'view biển');
  int _selectedFilterIndex = 0; // "Còn trống"
  List<RoomModel> _results = [];
  bool _isLoading = false;
  final RoomRepository _roomRepository = sl<RoomRepository>();

  final List<String> _filters = const [
    'Còn trống',
    'Giá thấp nhất',
    'Tầng cao',
    'Có ban công',
    'Bể bơi riêng',
  ];

  @override
  void initState() {
    super.initState();
    _roomRepository.addListener(_onRepositoryUpdated);
    _performSearch(_searchController.text);
  }

  @override
  void dispose() {
    _roomRepository.removeListener(_onRepositoryUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) {
      _performSearch(_searchController.text);
    }
  }

  void _onBookPressed(RoomModel room) {
    if (room.status == RoomStatus.reserved || room.status == RoomStatus.occupied) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateBookingModal(
        room: room,
        onSuccess: () {
          _performSearch(_searchController.text);
          context.go('/my-bookings');
        },
      ),
    );
  }

  List<RoomModel> _syncWithRepository(List<RoomModel> items) {
    final repoRooms = _roomRepository.rooms;
    return items.map((r) {
      final match = repoRooms.firstWhere(
        (repoR) => repoR.id == r.id || repoR.roomNumber == r.roomNumber,
        orElse: () => r,
      );
      return match;
    }).toList();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    List<RoomModel> rawList = [];

    try {
      final res = await DioClient().dio.get(
        ApiEndpoints.roomsSearch,
        queryParameters: query.isNotEmpty ? {'q': query} : null,
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List?;
        if (list != null) {
          rawList = list.map((e) => RoomModel.fromJson(e)).toList();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _results = _syncWithRepository(rawList);
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback standard design cards from 05-search.md if offline or network error
    if (rawList.isEmpty) {
      rawList = [
        RoomModel(
          id: '101',
          roomNumber: '101',
          floor: 1,
          status: RoomStatus.available,
          pricePerNight: 1450000,
          roomTypeName: 'Standard Queen Double',
        ),
        RoomModel(
          id: '102',
          roomNumber: '102',
          floor: 1,
          status: RoomStatus.available,
          pricePerNight: 1650000,
          roomTypeName: 'Standard Queen Double',
        ),
        RoomModel(
          id: '205',
          roomNumber: '205',
          floor: 2,
          status: RoomStatus.available,
          pricePerNight: 4200000,
          roomTypeName: 'Suite Tổng Thống',
        ),
        RoomModel(
          id: '308',
          roomNumber: '308',
          floor: 3,
          status: RoomStatus.reserved,
          pricePerNight: 2100000,
          roomTypeName: 'Phòng Gia Đình',
        ),
      ];
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _results = _syncWithRepository(rawList);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  PressableScale(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/customer');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: palette.ink,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Tìm Kiếm Phòng',
                      style: textTheme.titleLarge?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Filter Button with Gold Dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: palette.ink,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Tìm theo view biển, ban công...',
                onSubmitted: _performSearch,
                onClear: () => _performSearch(''),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Horizontal Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final label = _filters[idx];
                  final isSelected = idx == _selectedFilterIndex;
                  return PressableScale(
                    onTap: () => setState(() => _selectedFilterIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.gold : null,
                        color: isSelected ? null : palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected
                            ? null
                            : Border.all(color: palette.border, width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? Colors.white : palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Results Header: "Tìm thấy X phòng" + "Sắp xếp"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy ${_results.length} phòng',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Sắp xếp',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 18,
                        color: palette.inkMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Results List
            Expanded(
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: Column(
                        children: const [
                          RoomCardSkeleton(),
                          SizedBox(height: AppSpacing.md),
                          RoomCardSkeleton(),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Không tìm thấy phòng',
                          description:
                              'Không có phòng nào phù hợp với từ khóa "${_searchController.text}". Hãy thử từ khóa khác!',
                          actionText: 'Xem tất cả phòng',
                          onAction: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : RefreshIndicator(
                          color: palette.accent,
                          backgroundColor: palette.surface,
                          onRefresh: () =>
                              _performSearch(_searchController.text),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screen,
                              vertical: AppSpacing.xs,
                            ),
                            itemCount: _results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final room = _results[index];
                              return _buildHorizontalRoomCard(room, index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalRoomCard(RoomModel room, int index) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final images = const [
      'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=400&q=80',
    ];

    final tags = const [
      ['Ban công', 'Wifi'],
      ['Bể bơi riêng', 'Bồn tắm'],
      ['2 giường', 'Bếp nhỏ'],
    ];

    final currentTags = tags[index % tags.length];
    final imageUrl = room.images.isNotEmpty
        ? room.images.first
        : images[index % images.length];

    final isBooked = (room.status == RoomStatus.reserved ||
        room.status == RoomStatus.occupied);

    final priceStr = room.pricePerNight > 0
        ? Formatters.formatCurrency(room.pricePerNight)
        : (index == 0
            ? '1.650.000 ₫'
            : (index == 1 ? '4.200.000 ₫' : '2.100.000 ₫'));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => _onBookPressed(room),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 96x96 square room image with Hero transition
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Hero(
                tag: 'room-image-${room.id}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) =>
                      Container(color: palette.surfaceMuted),
                  errorWidget: (context, url, error) =>
                      Container(color: palette.surfaceMuted),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row 1: Room Name + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Phòng ${room.roomNumber}',
                        style: textTheme.titleMedium?.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    RoomStatusBadge(status: room.status),
                  ],
                ),
                const SizedBox(height: 2),

                // Row 2: Room Type
                Text(
                  room.roomTypeName ?? 'Deluxe Hướng Biển',
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Row 3: Utility chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: currentTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        tag,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: palette.inkMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Row 4: Price + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '/đêm',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    isBooked
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: palette.accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_added_rounded,
                                  size: 14,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Đã đặt',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppGradients.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.north_east_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
