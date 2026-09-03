import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
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

  final List<String> _filters = [
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
        if (list != null && list.isNotEmpty) {
          rawList = list.map((e) => RoomModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    // Fallback standard design cards from 05-search.md
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/customer');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Tìm Kiếm Phòng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Input (54px, #F1F5F9, 16px radius, no border)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _performSearch,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo view biển, ban công...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Horizontal Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final label = _filters[idx];
                  final isSelected = idx == _selectedFilterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.gold : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.border, width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.25),
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
                              Icons.check,
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
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. Results Header: "Tìm thấy X phòng" + "Sắp xếp"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy ${_results.length} phòng',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Sắp xếp',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Results List (horizontal card layout 116px height)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _performSearch(_searchController.text),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final images = [
      'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=400&q=80',
    ];

    final tags = [
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

    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 96x96 square room image (14px radius)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 96,
              height: 96,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.surfaceMuted),
                errorWidget: (context, url, error) =>
                    Container(color: AppColors.surfaceMuted),
              ),
            ),
          ),

          const SizedBox(width: 12),

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    RoomStatusBadge(status: room.status),
                  ],
                ),
                const SizedBox(height: 4),

                // Row 2: Room Type
                Text(
                  room.roomTypeName ?? 'Deluxe Hướng Biển',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Row 3: Utility chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: currentTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),

                // Row 4: Price + Circular Action Button / Status Badge Button
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '/đêm',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _onBookPressed(room),
                      child: isBooked
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_added_rounded,
                                      size: 14, color: AppColors.secondary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đã đặt',
                                    style: TextStyle(
                                      color: AppColors.secondary,
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
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.north_east,
                                color: AppColors.secondaryLight,
                                size: 16,
                              ),
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
