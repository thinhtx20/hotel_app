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
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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
              onRefresh: _fetchDashboardData,
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

              // 5. Thẻ Biểu đồ Doanh thu 7 ngày (Area chart 1 đường duy nhất)
              Padding(
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
                      // Chart Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Doanh thu 7 ngày',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '7 ngày',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Chart Area
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 50,
                              getDrawingHorizontalLine: (val) => const FlLine(
                                color: Color(0xFFF1F5F9),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 50,
                                  reservedSize: 34,
                                  getTitlesWidget: (value, meta) {
                                    String text = '';
                                    if (value == 0) text = '0';
                                    if (value == 50) text = '50tr';
                                    if (value == 100) text = '100tr';
                                    if (value == 150) text = '150tr';
                                    return Text(
                                      text,
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
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    const labels = [
                                      'T2',
                                      'T3',
                                      'T4',
                                      'T5',
                                      'T6',
                                      'T7',
                                      'CN'
                                    ];
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < labels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          labels[idx],
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
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
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 160,
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 68),
                                  FlSpot(1, 85),
                                  FlSpot(2, 74),
                                  FlSpot(3, 98),
                                  FlSpot(4, 115),
                                  FlSpot(5, 105),
                                  FlSpot(6, 128.5),
                                ],
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.secondary,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) =>
                                      spot.x == 6, // Chỉ điểm cuối cùng
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
