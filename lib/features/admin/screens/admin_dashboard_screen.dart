import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
import 'occupancy_detail_screen.dart';
import 'today_check_ins_screen.dart';
import 'today_check_outs_screen.dart';
import 'pending_bookings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  /// Các mốc lọc của biểu đồ doanh thu (số ngày gần nhất)
  static const List<int> _revenueRangeOptions = [1, 7, 14, 30];

  Map<String, dynamic>? _dashboardData;
  bool _isStatsLoading = true;
  late final AnimationController _refreshIconController;

  int _revenueDays = 7;
  List<_RevenuePoint> _revenueSeries = [];
  bool _isRevenueLoading = true;
  bool _revenueLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fetchDashboardData();
    _fetchRevenueSeries(_revenueDays);
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchDashboardData(),
      _fetchRevenueSeries(_revenueDays),
    ]);
  }

  /// Lấy chuỗi doanh thu theo số ngày gần nhất: GET /analytics/revenue/daily?days=N
  Future<void> _fetchRevenueSeries(int days) async {
    setState(() {
      _isRevenueLoading = true;
      _revenueLoadFailed = false;
    });

    try {
      final res = await DioClient().dio.get(
        ApiEndpoints.analyticsRevenueDaily,
        queryParameters: {'days': days},
      );
      final body = res.data;
      final data = body is Map && body['data'] != null ? body['data'] : body;
      final rawSeries = data is Map ? data['series'] : null;

      if (res.statusCode == 200 && rawSeries is List) {
        final series = rawSeries
            .whereType<Map>()
            .map((e) => _RevenuePoint.fromJson(e))
            .toList();
        // Bỏ qua phản hồi cũ nếu người dùng đã đổi sang mốc lọc khác
        if (mounted && days == _revenueDays) {
          setState(() {
            _revenueSeries = series;
            _isRevenueLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted && days == _revenueDays) {
      setState(() {
        _revenueSeries = [];
        _isRevenueLoading = false;
        _revenueLoadFailed = true;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) {
      setState(() => _isStatsLoading = true);
      _refreshIconController.repeat();
    }
    try {
      final res = await DioClient().dio.get(ApiEndpoints.analyticsDashboard);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _dashboardData = res.data['data'];
            _isStatsLoading = false;
          });
          _refreshIconController.stop();
          _refreshIconController.reset();
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isStatsLoading = false);
      _refreshIconController.stop();
      _refreshIconController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawRevenue = _dashboardData?['todayRevenue'] ?? _dashboardData?['totalRevenueToday'];
    final revenueToday = rawRevenue != null
        ? Formatters.formatCurrency(num.tryParse('$rawRevenue') ?? 0)
        : '0 ₫';
    final num? revenueChangePercent = _dashboardData?['revenueChangePercent'] as num?;

    final num? rawRate = _dashboardData?['occupancyRate'] as num?;
    final int occupiedRooms = (_dashboardData?['occupiedRooms'] as num?)?.toInt() ??
        (_dashboardData?['rooms']?['occupied'] as num?)?.toInt() ??
        0;
    final int totalRooms = (_dashboardData?['totalRooms'] as num?)?.toInt() ??
        (_dashboardData?['rooms']?['total'] as num?)?.toInt() ??
        0;

    final String occupancyStr;
    if (rawRate != null) {
      occupancyStr = rawRate % 1 == 0
          ? '${rawRate.toInt()}%'
          : '${rawRate.toStringAsFixed(1)}%';
    } else if (totalRooms > 0) {
      final calculated = (occupiedRooms / totalRooms * 100);
      occupancyStr = calculated % 1 == 0
          ? '${calculated.toInt()}%'
          : '${calculated.toStringAsFixed(1)}%';
    } else {
      occupancyStr = '0%';
    }

    final double occupancyFraction = totalRooms > 0
        ? (occupiedRooms / totalRooms).clamp(0.0, 1.0)
        : (rawRate != null ? (rawRate / 100.0).clamp(0.0, 1.0) : 0.0);

    final int checkIns = (_dashboardData?['checkInsToday'] as num?)?.toInt() ??
        (_dashboardData?['todayCheckIns'] as num?)?.toInt() ??
        (_dashboardData?['todayActivity']?['expectedCheckIns'] as num?)?.toInt() ??
        0;
    final int checkOuts = (_dashboardData?['checkOutsToday'] as num?)?.toInt() ??
        (_dashboardData?['todayCheckOuts'] as num?)?.toInt() ??
        (_dashboardData?['todayActivity']?['expectedCheckOuts'] as num?)?.toInt() ??
        0;
    final int pendingBookings = (_dashboardData?['pendingBookings'] as num?)?.toInt() ?? 0;

    final breakdown = _dashboardData?['roomStatusBreakdown'] as Map?;
    final int occupiedCount = (breakdown?['OCCUPIED'] as num?)?.toInt() ?? occupiedRooms;
    final int availableCount = (breakdown?['AVAILABLE'] as num?)?.toInt() ??
        (_dashboardData?['availableRooms'] as num?)?.toInt() ??
        0;
    final int cleaningCount = (breakdown?['CLEANING'] as num?)?.toInt() ??
        (_dashboardData?['cleaningRooms'] as num?)?.toInt() ??
        0;
    final int reservedCount = (breakdown?['RESERVED'] as num?)?.toInt() ??
        (_dashboardData?['reservedRooms'] as num?)?.toInt() ??
        0;
    final int maintenanceCount = (breakdown?['MAINTENANCE'] as num?)?.toInt() ??
        (_dashboardData?['maintenanceRooms'] as num?)?.toInt() ??
        0;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dải Navy đầu màn + Thống kê doanh thu hôm nay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 230 + topPadding,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.navy,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // Top Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng quan',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.50),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Báo Cáo Quản Trị',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildGlassCircleBtn(
                                      icon: Icons.refresh,
                                      onTap: () {
                                        _fetchDashboardData();
                                        _fetchRevenueSeries(_revenueDays);
                                      },
                                      customIcon: RotationTransition(
                                        turns: _refreshIconController,
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildGlassCircleBtn(
                                      icon: Icons.logout,
                                      onTap: () => LogoutConfirmationDialog.show(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Doanh thu hôm nay
                            Text(
                              'DOANH THU HÔM NAY',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _isStatsLoading
                                    ? _buildShimmerBox(
                                        width: 170,
                                        height: 30,
                                        borderRadius: 8,
                                        baseColor: Colors.white.withValues(alpha: 0.15),
                                        highlightColor: Colors.white.withValues(alpha: 0.35),
                                      )
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          revenueToday,
                                          style: const TextStyle(
                                            color: AppColors.secondaryLight,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                if (_isStatsLoading)
                                  _buildShimmerBox(
                                    width: 60,
                                    height: 22,
                                    borderRadius: 999,
                                    baseColor: Colors.white.withValues(alpha: 0.15),
                                    highlightColor: Colors.white.withValues(alpha: 0.35),
                                  )
                                else if (revenueChangePercent != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (revenueChangePercent >= 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          revenueChangePercent >= 0
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          size: 12,
                                          color: revenueChangePercent >= 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${revenueChangePercent >= 0 ? '+' : ''}${revenueChangePercent.toStringAsFixed(1).replaceAll('.', ',')}%',
                                          style: TextStyle(
                                            color: revenueChangePercent >= 0
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'so với hôm qua',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Thẻ tỷ lệ lấp đầy (đè lên dải navy 28px)
                  Positioned(
                    bottom: -40,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OccupancyDetailScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 112,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Tỷ lệ lấp đầy',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _isStatsLoading
                                    ? _buildShimmerBox(width: 80, height: 28, borderRadius: 6)
                                    : Text(
                                        occupancyStr,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                const SizedBox(height: 2),
                                _isStatsLoading
                                    ? _buildShimmerBox(width: 150, height: 14, borderRadius: 4)
                                    : Text(
                                        '$occupiedRooms / $totalRooms phòng đang có khách',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              ],
                            ),
                            // Gauge Arc Ring (76px diameter)
                            SizedBox(
                              width: 76,
                              height: 76,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: _isStatsLoading ? 0.0 : occupancyFraction,
                                ),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                builder: (context, val, _) => CustomPaint(
                                  painter: _GaugeArcPainter(percent: val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 3. Nhãn mục "HÔM NAY"
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'HÔM NAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. 3 Ô Thống kê nhỏ (96px height)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: '$checkIns',
                        label: 'Lượt nhận phòng',
                        icon: Icons.vpn_key_outlined,
                        color: AppColors.secondary,
                        isLoading: _isStatsLoading,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TodayCheckInsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: '$checkOuts',
                        label: 'Lượt trả phòng',
                        icon: Icons.logout_outlined,
                        color: const Color(0xFF3B82F6),
                        isLoading: _isStatsLoading,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TodayCheckOutsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: '$pendingBookings',
                        label: 'Đơn chờ duyệt',
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFFEF4444),
                        isLoading: _isStatsLoading,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PendingBookingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Thẻ Biểu đồ Doanh thu (lọc 1 / 7 / 14 / 30 ngày)
              _buildRevenueChartCard(),
              const SizedBox(height: 20),

              // 6. Thẻ Cơ cấu Buồng phòng (Stacked Bar + Legend)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cơ cấu buồng phòng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Single Horizontal Stacked Bar (14px height, 2px white gap)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: SizedBox(
                          height: 14,
                          child: _buildRoomBreakdownBar(
                            occupied: occupiedCount,
                            available: availableCount,
                            cleaning: cleaningCount,
                            reserved: reservedCount,
                            maintenance: maintenanceCount,
                            isLoading: _isStatsLoading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Legend Wrap
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem('Đang có khách', '$occupiedCount', AppColors.occupied, isLoading: _isStatsLoading),
                          _buildLegendItem('Phòng trống', '$availableCount', AppColors.available, isLoading: _isStatsLoading),
                          _buildLegendItem('Đang dọn dẹp', '$cleaningCount', AppColors.cleaning, isLoading: _isStatsLoading),
                          _buildLegendItem('Đã đặt cọc', '$reservedCount', AppColors.reserved, isLoading: _isStatsLoading),
                          _buildLegendItem('Bảo trì', '$maintenanceCount', AppColors.maintenance, isLoading: _isStatsLoading),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Biểu đồ doanh thu (có bộ lọc) ====================

  /// Làm tròn lên thành số "đẹp" để chia lưới trục Y: 96.2tr -> 100tr
  double _niceCeil(double value) {
    if (value <= 0) return 1;
    final exponent = (math.log(value) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final fraction = value / magnitude;
    double nice;
    if (fraction <= 1) {
      nice = 1;
    } else if (fraction <= 2) {
      nice = 2;
    } else if (fraction <= 2.5) {
      nice = 2.5;
    } else if (fraction <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  /// Rút gọn số tiền cho trục Y: 96200000 -> "96tr", 1250000000 -> "1,3 tỷ"
  String _compactMoney(double value) {
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')} tỷ';
    }
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll('.', ',')}tr';
    }
    if (value >= 1000) return '${(value / 1000).round()}k';
    return value.round().toString();
  }

  /// Nhãn trục X: <= 7 ngày dùng thứ trong tuần, dài hơn thì dùng ngày/tháng
  String _axisLabel(_RevenuePoint point) {
    if (_revenueDays <= 7 && point.label.isNotEmpty) return point.label;
    final date = point.date;
    if (date != null) return '${date.day}/${date.month}';
    return point.label;
  }

  String _tooltipLabel(_RevenuePoint point) {
    final date = point.date;
    if (date == null) return point.label;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final prefix = point.label.isNotEmpty ? '${point.label} ' : '';
    return '$prefix$day/$month';
  }

  Widget _axisText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard() {
    final series = _revenueSeries;
    final title = _revenueDays == 1
        ? 'Doanh thu hôm nay'
        : 'Doanh thu $_revenueDays ngày';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 250,
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
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Chart Header + Bộ lọc khoảng thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildRevenueRangeFilter(),
              ],
            ),
            const SizedBox(height: 14),

            // Chart Area
            Expanded(
              child: _isRevenueLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : series.isEmpty
                      ? Center(
                          child: Text(
                            _revenueLoadFailed
                                ? 'Không tải được dữ liệu doanh thu'
                                : 'Chưa có dữ liệu doanh thu',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : _buildRevenueLineChart(series),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueRangeFilter() {
    return PopupMenuButton<int>(
      initialValue: _revenueDays,
      tooltip: 'Chọn khoảng thời gian',
      offset: const Offset(0, 34),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (days) {
        if (days == _revenueDays) return;
        setState(() => _revenueDays = days);
        _fetchRevenueSeries(days);
      },
      itemBuilder: (context) => _revenueRangeOptions.map((days) {
        final selected = days == _revenueDays;
        return PopupMenuItem<int>(
          value: days,
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$days ngày',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.secondary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_revenueDays ngày',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart(List<_RevenuePoint> series) {
    final maxRevenue =
        series.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final axisMax = _niceCeil(maxRevenue > 0 ? maxRevenue : 1000000);
    final interval = axisMax / 4;

    // Chỉ có 1 điểm (lọc 1 ngày) -> vẽ đường phẳng để trục X không bị suy biến
    final isSinglePoint = series.length == 1;
    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].revenue),
    ];
    if (isSinglePoint) spots.add(FlSpot(1, series.first.revenue));

    final maxX = (spots.length - 1).toDouble();

    // Với 14/30 ngày chỉ hiện bớt nhãn để trục X không bị chồng chữ
    final labelStep = series.length <= 7
        ? 1
        : series.length <= 14
            ? 2
            : 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (val) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value > axisMax + interval * 0.1) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _compactMoney(value),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: isSinglePoint ? 0.5 : 1,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                if (isSinglePoint) {
                  // Căn giữa nhãn duy nhất dưới đường phẳng
                  if ((value - 0.5).abs() > 0.01) return const SizedBox.shrink();
                  return _axisText(_axisLabel(series.first));
                }

                final idx = value.round();
                if ((value - idx).abs() > 0.01) return const SizedBox.shrink();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                // Đếm ngược từ ngày mới nhất để nhãn cuối luôn hiển thị
                if ((series.length - 1 - idx) % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return _axisText(_axisLabel(series[idx]));
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.92),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final idx = spot.x.round().clamp(0, series.length - 1);
              final point = series[idx];
              return LineTooltipItem(
                '${_tooltipLabel(point)}\n${Formatters.formatCurrency(point.revenue)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: axisMax * 1.06,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: AppColors.secondary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              // Chỉ tô điểm cuối cùng (ngày mới nhất)
              checkToShowDot: (spot, barData) => spot.x == maxX,
              getDotPainter: (spot, percent, barData, i) =>
                  FlDotCirclePainter(
                radius: 4.5,
                color: AppColors.secondary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.22),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 6,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE2E8F0),
      highlightColor: highlightColor ?? const Color(0xFFF8FAFC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildRoomBreakdownBar({
    required int occupied,
    required int available,
    required int cleaning,
    required int reserved,
    required int maintenance,
    required bool isLoading,
  }) {
    if (isLoading) {
      return _buildShimmerBox(
        width: double.infinity,
        height: 14,
        borderRadius: 7,
      );
    }

    final total = occupied + available + cleaning + reserved + maintenance;
    if (total == 0) {
      return const ColoredBox(color: Color(0xFFE2E8F0));
    }

    final slices = <Widget>[];
    void addSlice(int count, Color color) {
      if (count > 0) {
        if (slices.isNotEmpty) {
          slices.add(const SizedBox(width: 2));
        }
        slices.add(
          Expanded(
            flex: count,
            child: ColoredBox(color: color),
          ),
        );
      }
    }

    addSlice(occupied, AppColors.occupied);
    addSlice(available, AppColors.available);
    addSlice(cleaning, AppColors.cleaning);
    addSlice(reserved, AppColors.reserved);
    addSlice(maintenance, AppColors.maintenance);

    return Row(children: slices);
  }

  Widget _buildSmallKpiCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isLoading
                ? _buildShimmerBox(width: 36, height: 22, borderRadius: 4)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    String count,
    Color color, {
    bool isLoading = false,
  }) {
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
          '$label ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        isLoading
            ? _buildShimmerBox(width: 18, height: 14, borderRadius: 3)
            : Text(
                count,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
      ],
    );
  }

  Widget _buildGlassCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Widget? customIcon,
  }) {
    return GestureDetector(
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
        child: customIcon ?? Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Vẽ vòng cung đo (gauge arc) cho tỷ lệ lấp đầy
class _GaugeArcPainter extends CustomPainter {
  final double percent;

  _GaugeArcPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Track nền
    final trackPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Vòng cung giá trị gradient
    final valuePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.secondary, AppColors.secondaryLight],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 1.25;
    const sweepAngle = math.pi * 1.5;

    // Vẽ track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Vẽ giá trị
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

/// Một điểm trên biểu đồ doanh thu theo ngày
class _RevenuePoint {
  final DateTime? date;
  final String label;
  final double revenue;

  const _RevenuePoint({
    required this.date,
    required this.label,
    required this.revenue,
  });

  factory _RevenuePoint.fromJson(Map json) {
    final rawRevenue = json['revenue'] ?? json['amount'] ?? 0;
    return _RevenuePoint(
      date: DateTime.tryParse('${json['date']}'),
      label: '${json['label'] ?? ''}',
      revenue: (num.tryParse('$rawRevenue') ?? 0).toDouble(),
    );
  }
}
