import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/analytics_repository.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Màn hình Chi tiết Tỷ lệ Lấp đầy (Occupancy Detail Screen)
/// Phục vụ khi người dùng nhấn vào thẻ "Tỷ lệ lấp đầy" từ Admin Dashboard
class OccupancyDetailScreen extends StatefulWidget {
  final DioClient? dioClient;
  const OccupancyDetailScreen({super.key, this.dioClient});

  @override
  State<OccupancyDetailScreen> createState() => _OccupancyDetailScreenState();
}

class _OccupancyDetailScreenState extends State<OccupancyDetailScreen> {
  late final AnalyticsRepository _analyticsRepository;
  late final RoomRepository _roomRepository;

  int _selectedFloor = -1; // -1: Tất cả
  RoomStatus? _selectedStatus; // null: Tất cả
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  // Dữ liệu thống kê
  int _totalRooms = 0;
  int _occupiedRooms = 0;
  int _availableRooms = 0;
  int _cleaningRooms = 0;
  int _reservedRooms = 0;
  int _maintenanceRooms = 0;

  List<_RoomTypeOccupancy> _roomTypeStats = [];
  List<RoomModel> _rooms = [];

  @override
  void initState() {
    super.initState();
    _analyticsRepository = widget.dioClient != null
        ? AnalyticsRepository(dioClient: widget.dioClient)
        : sl<AnalyticsRepository>();
    _roomRepository = widget.dioClient != null
        ? RoomRepository(dioClient: widget.dioClient)
        : sl<RoomRepository>();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _fetchOccupancyDetail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOccupancyDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _analyticsRepository.occupancyByType(),
        _roomRepository.fetchRooms(forceRefresh: true),
      ]);

      final byTypeRaw = results[0] as List<Map<String, dynamic>>;
      final roomsList = _roomRepository.rooms;

      _rooms = roomsList;
      _totalRooms = roomsList.length;
      _occupiedRooms = roomsList.where((r) => r.status == RoomStatus.occupied).length;
      _availableRooms = roomsList.where((r) => r.status == RoomStatus.available).length;
      _cleaningRooms = roomsList.where((r) => r.status == RoomStatus.cleaning).length;
      _reservedRooms = roomsList.where((r) => r.status == RoomStatus.reserved).length;
      _maintenanceRooms = roomsList.where((r) => r.status == RoomStatus.maintenance).length;

      if (byTypeRaw.isNotEmpty) {
        _roomTypeStats = byTypeRaw.map((e) => _RoomTypeOccupancy.fromJson(e)).toList();
      } else {
        _buildTypeStatsFromRooms(roomsList);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_roomRepository.rooms.isNotEmpty) {
        final roomsList = _roomRepository.rooms;
        _rooms = roomsList;
        _totalRooms = roomsList.length;
        _occupiedRooms = roomsList.where((r) => r.status == RoomStatus.occupied).length;
        _availableRooms = roomsList.where((r) => r.status == RoomStatus.available).length;
        _cleaningRooms = roomsList.where((r) => r.status == RoomStatus.cleaning).length;
        _reservedRooms = roomsList.where((r) => r.status == RoomStatus.reserved).length;
        _maintenanceRooms = roomsList.where((r) => r.status == RoomStatus.maintenance).length;
        _buildTypeStatsFromRooms(roomsList);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final apiErr = ApiError.fromDynamic(e);
      setState(() {
        _errorMessage = apiErr.displayMessage;
        _isLoading = false;
      });
    }
  }

  void _buildTypeStatsFromRooms(List<RoomModel> roomList) {
    final Map<String, List<RoomModel>> map = {};
    for (final r in roomList) {
      final key = r.roomTypeName ?? 'Phòng Tiêu chuẩn';
      map.putIfAbsent(key, () => []).add(r);
    }

    _roomTypeStats = map.entries.map((entry) {
      final occ =
          entry.value.where((r) => r.status == RoomStatus.occupied).length;
      final total = entry.value.length;
      final rate = total > 0 ? (occ / total * 100) : 0.0;
      final price = entry.value.first.pricePerNight;
      return _RoomTypeOccupancy(
        roomTypeName: entry.key,
        totalRooms: total,
        occupiedRooms: occ,
        occupancyRate: rate,
        basePrice: price,
      );
    }).toList();
  }

  List<RoomModel> get _filteredRooms {
    return _rooms.where((room) {
      if (_selectedFloor != -1 && room.floor != _selectedFloor) {
        return false;
      }
      if (_selectedStatus != null && room.status != _selectedStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchNum = room.roomNumber.toLowerCase().contains(query);
        final matchType =
            (room.roomTypeName ?? '').toLowerCase().contains(query);
        if (!matchNum && !matchType) return false;
      }
      return true;
    }).toList();
  }

  Set<int> get _availableFloors {
    final floors = _rooms.map((r) => r.floor).toSet().toList()..sort();
    return floors.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final double occupancyRate = _totalRooms > 0
        ? (_occupiedRooms / _totalRooms * 100)
        : 0.0;
    final String rateStr = occupancyRate % 1 == 0
        ? '${occupancyRate.toInt()}%'
        : '${occupancyRate.toStringAsFixed(1)}%';

    return Scaffold(
      backgroundColor: palette.canvas,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Navy App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetchOccupancyDetail,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết Tỷ lệ Lấp đầy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Theo dõi công suất phòng theo thời gian thực',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.navy,
                ),
              ),
            ),
          ),

          // 2. Nội dung chính
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && _rooms.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không thể tải dữ liệu',
                  description: _errorMessage ?? 'Đã xảy ra lỗi kết nối.',
                  actionText: 'Tải lại',
                  onAction: _fetchOccupancyDetail,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Thẻ Hero Tỷ lệ lấp đầy
                  _buildHeroCard(palette, textTheme, rateStr, occupancyRate / 100.0),
                  const SizedBox(height: AppSpacing.xl),

                  // Cơ cấu buồng phòng theo 5 trạng thái
                  _buildStatusBreakdownPills(palette),
                  const SizedBox(height: AppSpacing.xl),

                  // Tỷ lệ lấp đầy theo từng loại phòng
                  Text(
                    'TỶ LỆ LẤP ĐẦY THEO LOẠI PHÒNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.inkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRoomTypeBreakdownCards(palette, textTheme),
                  const SizedBox(height: AppSpacing.xl),

                  // Tiêu đề danh sách phòng & bộ lọc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DANH SÁCH BUỒNG PHÒNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${_filteredRooms.length} phòng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Thanh tìm kiếm
                  _buildSearchBar(palette),
                  const SizedBox(height: AppSpacing.md),

                  // Filter Chips (Tầng & Trạng thái)
                  _buildFilterChips(palette),
                  const SizedBox(height: AppSpacing.lg),

                  // Danh sách phòng dạng Grid
                  _buildRoomGrid(palette, textTheme),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ Hero hiển thị tổng quan tỷ lệ lấp đầy
  Widget _buildHeroCard(
      AppPalette palette, TextTheme textTheme, String rateStr, double fraction) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công suất phòng hiện tại',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rateStr,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_occupiedRooms / $_totalRooms phòng đang đón khách',
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Vòng cung đo kích thước 88px
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _DetailGaugeArcPainter(
                percent: fraction.clamp(0.0, 1.0),
                accentColor: palette.accent,
                trackColor: palette.surfaceMuted,
              ),
              child: Center(
                child: Icon(
                  Icons.hotel_rounded,
                  color: palette.accent.withValues(alpha: 0.85),
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5 Pills thống kê trạng thái phòng
  Widget _buildStatusBreakdownPills(AppPalette palette) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildMiniStatusPill(palette, 'Có khách', _occupiedRooms, AppColors.occupied),
        _buildMiniStatusPill(palette, 'Trống', _availableRooms, AppColors.available),
        _buildMiniStatusPill(palette, 'Dọn dẹp', _cleaningRooms, AppColors.cleaning),
        _buildMiniStatusPill(palette, 'Đặt cọc', _reservedRooms, AppColors.reserved),
        _buildMiniStatusPill(
            palette, 'Bảo trì', _maintenanceRooms, AppColors.maintenance),
      ],
    );
  }

  Widget _buildMiniStatusPill(
      AppPalette palette, String label, int count, Color color) {
    final isSelected = _selectedStatus != null &&
        ((label == 'Có khách' && _selectedStatus == RoomStatus.occupied) ||
            (label == 'Trống' && _selectedStatus == RoomStatus.available) ||
            (label == 'Dọn dẹp' && _selectedStatus == RoomStatus.cleaning) ||
            (label == 'Đặt cọc' && _selectedStatus == RoomStatus.reserved) ||
            (label == 'Bảo trì' &&
                _selectedStatus == RoomStatus.maintenance));

    return PressableScale(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedStatus = null;
          } else {
            if (label == 'Có khách') _selectedStatus = RoomStatus.occupied;
            if (label == 'Trống') _selectedStatus = RoomStatus.available;
            if (label == 'Dọn dẹp') _selectedStatus = RoomStatus.cleaning;
            if (label == 'Đặt cọc') _selectedStatus = RoomStatus.reserved;
            if (label == 'Bảo trì') _selectedStatus = RoomStatus.maintenance;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? color : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, color: palette.inkMuted),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Danh sách tỷ lệ lấp đầy theo loại phòng
  Widget _buildRoomTypeBreakdownCards(AppPalette palette, TextTheme textTheme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: _roomTypeStats.map((stat) {
          final isLast = stat == _roomTypeStats.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stat.roomTypeName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${stat.occupiedRooms}/${stat.totalRooms} phòng (${stat.occupancyRate.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stat.totalRooms > 0
                            ? (stat.occupiedRooms / stat.totalRooms)
                                .clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: palette.surfaceMuted,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(palette.accent),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: palette.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(AppPalette palette) {
    return TextField(
      controller: _searchController,
      style: TextStyle(fontSize: 14, color: palette.ink),
      decoration: InputDecoration(
        hintText: 'Tìm theo số phòng hoặc loại phòng...',
        hintStyle: TextStyle(fontSize: 13, color: palette.inkFaint),
        prefixIcon: Icon(Icons.search, size: 20, color: palette.inkMuted),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18, color: palette.inkMuted),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Lọc theo tầng
          ChoiceChip(
            label: const Text('Tất cả tầng'),
            selected: _selectedFloor == -1,
            onSelected: (val) => setState(() => _selectedFloor = -1),
            selectedColor: palette.accent,
            backgroundColor: palette.surface,
            labelStyle: TextStyle(
              fontSize: 12,
              color: _selectedFloor == -1 ? Colors.white : palette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ..._availableFloors.map((floor) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text('Tầng $floor'),
                selected: _selectedFloor == floor,
                onSelected: (val) => setState(() => _selectedFloor = floor),
                selectedColor: palette.accent,
                backgroundColor: palette.surface,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _selectedFloor == floor ? Colors.white : palette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomGrid(AppPalette palette, TextTheme textTheme) {
    final rooms = _filteredRooms;
    if (rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: palette.inkFaint),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy phòng phù hợp',
              style: textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomGridItem(palette, textTheme, room);
      },
    );
  }

  Widget _buildRoomGridItem(
      AppPalette palette, TextTheme textTheme, RoomModel room) {
    Color statusBgColor;
    Color statusTextColor;
    switch (room.status) {
      case RoomStatus.occupied:
        statusBgColor = AppColors.occupied.withValues(alpha: 0.15);
        statusTextColor = AppColors.occupied;
        break;
      case RoomStatus.available:
        statusBgColor = AppColors.available.withValues(alpha: 0.15);
        statusTextColor = AppColors.available;
        break;
      case RoomStatus.cleaning:
        statusBgColor = AppColors.cleaning.withValues(alpha: 0.15);
        statusTextColor = AppColors.cleaning;
        break;
      case RoomStatus.reserved:
        statusBgColor = AppColors.reserved.withValues(alpha: 0.15);
        statusTextColor = AppColors.reserved;
        break;
      case RoomStatus.maintenance:
        statusBgColor = AppColors.maintenance.withValues(alpha: 0.15);
        statusTextColor = AppColors.maintenance;
        break;
      default:
        statusBgColor = palette.accent.withValues(alpha: 0.15);
        statusTextColor = palette.accent;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'P.${room.roomNumber}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  room.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          Text(
            room.roomTypeName ?? 'Phòng Tiêu chuẩn',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: palette.inkMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tầng ${room.floor}',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: palette.inkFaint,
                ),
              ),
              Text(
                Formatters.formatCurrency(room.pricePerNight),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomTypeOccupancy {
  final String roomTypeName;
  final int totalRooms;
  final int occupiedRooms;
  final double occupancyRate;
  final num basePrice;

  _RoomTypeOccupancy({
    required this.roomTypeName,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.occupancyRate,
    required this.basePrice,
  });

  factory _RoomTypeOccupancy.fromJson(Map json) {
    return _RoomTypeOccupancy(
      roomTypeName: '${json['roomTypeName'] ?? json['name'] ?? ''}',
      totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
      occupiedRooms: (json['occupiedRooms'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      basePrice: (json['basePrice'] as num?) ?? 0,
    );
  }
}

class _DetailGaugeArcPainter extends CustomPainter {
  final double percent;
  final Color accentColor;
  final Color trackColor;

  _DetailGaugeArcPainter({
    required this.percent,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 1.25;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DetailGaugeArcPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.trackColor != trackColor;
}
