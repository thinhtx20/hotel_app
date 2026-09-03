import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/dio_client.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  /// Các mốc lọc của biểu đồ doanh thu (số ngày gần nhất)
  static const List<int> _revenueRangeOptions = [1, 7, 14, 30];

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  int _revenueDays = 7;
  List<_RevenuePoint> _revenueSeries = [];
  bool _isRevenueLoading = true;
  bool _revenueLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchRevenueSeries(_revenueDays);
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
    setState(() => _isLoading = true);
    try {
      final res = await DioClient().dio.get(ApiEndpoints.analyticsDashboard);
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _dashboardData = res.data['data'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawRevenue = _dashboardData?['totalRevenueToday'];
    final revenueToday = rawRevenue != null
        ? Formatters.formatCurrency(num.tryParse('$rawRevenue') ?? 0)
        : '128.500.000 ₫';
    final occupancy = _dashboardData?['occupancyRate'] != null
        ? '${_dashboardData!['occupancyRate']}%'
        : '78%';
    final occupiedRooms = _dashboardData?['occupiedRooms'] ?? 14;
    final totalRooms = _dashboardData?['totalRooms'] ?? 20;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : RefreshIndicator(
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
                                      onTap: _fetchDashboardData,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildGlassCircleBtn(
                                      icon: Icons.logout,
                                      onTap: () => context
                                          .read<AuthBloc>()
                                          .add(AuthLogoutRequested()),
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
                                FittedBox(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_upward_rounded,
                                          size: 12, color: Color(0xFF10B981)),
                                      SizedBox(width: 2),
                                      Text(
                                        '+12,4%',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
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
                              const Text(
                                'Tỷ lệ lấp đầy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                occupancy,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
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
                            child: CustomPaint(
                              painter: _GaugeArcPainter(percent: 0.78),
                            ),
                          ),
                        ],
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
                        value: '12',
                        label: 'Lượt nhận phòng',
                        icon: Icons.vpn_key_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: '8',
                        label: 'Lượt trả phòng',
                        icon: Icons.logout_outlined,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: '4',
                        label: 'Đơn chờ duyệt',
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFFEF4444),
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
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 55,
                                child: ColoredBox(color: AppColors.occupied),
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                flex: 25,
                                child: ColoredBox(color: AppColors.available),
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                flex: 10,
                                child: ColoredBox(color: AppColors.cleaning),
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                flex: 5,
                                child: ColoredBox(color: AppColors.reserved),
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                flex: 5,
                                child: ColoredBox(color: AppColors.maintenance),
                              ),
                            ],
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
                          _buildLegendItem('Đang có khách', '11', AppColors.occupied),
                          _buildLegendItem('Phòng trống', '5', AppColors.available),
                          _buildLegendItem('Đang dọn dẹp', '2', AppColors.cleaning),
                          _buildLegendItem('Đã đặt cọc', '1', AppColors.reserved),
                          _buildLegendItem('Bảo trì', '1', AppColors.maintenance),
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

  Widget _buildSmallKpiCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          FittedBox(
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
    );
  }



  Widget _buildLegendItem(String label, String count, Color color) {
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
        Text(
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
        child: Icon(icon, color: Colors.white, size: 18),
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
