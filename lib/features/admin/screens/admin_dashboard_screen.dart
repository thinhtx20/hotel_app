import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/analytics_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/motion/animated_counter.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/skeleton_primitives.dart';
import 'occupancy_detail_screen.dart';
import 'today_check_ins_screen.dart';
import 'today_check_outs_screen.dart';
import '../../receptionist/screens/booking_approval_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  /// Các mốc lọc của biểu đồ doanh thu (số ngày gần nhất + năm nay 365)
  static const List<int> _revenueRangeOptions = [1, 7, 14, 30, 365];

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

  /// Lấy chuỗi doanh thu theo số ngày gần nhất hoặc năm nay
  Future<void> _fetchRevenueSeries(int days) async {
    setState(() {
      _isRevenueLoading = true;
      _revenueLoadFailed = false;
    });

    try {
      if (days == 365) {
        final currentYear = DateTime.now().year;
        final data = await sl<AnalyticsRepository>().revenueYearly(
          year: currentYear,
        );
        List<_RevenuePoint> points = [];

        // API trả về `{year, summary, monthly: [{month, totalRevenue, ...}]}`
        final rawList = data['monthly'] ?? data['months'] ?? data['series'];
        if (rawList is List) {
          points = rawList.whereType<Map>().map((m) {
            final monthNum = m['month'] ?? m['m'] ?? '';
            final rev =
                num.tryParse(
                  '${m['totalRevenue'] ?? m['revenue'] ?? m['total'] ?? 0}',
                )?.toDouble() ??
                0.0;
            return _RevenuePoint(label: 'T$monthNum', revenue: rev);
          }).toList();
        } else {
          for (int m = 1; m <= 12; m++) {
            final rev =
                num.tryParse('${data['$m'] ?? data['m$m'] ?? 0}')?.toDouble() ??
                0.0;
            points.add(_RevenuePoint(label: 'T$m', revenue: rev));
          }
        }

        if (mounted && days == _revenueDays) {
          setState(() {
            _revenueSeries = points;
            _isRevenueLoading = false;
          });
        }
        return;
      }

      // API dùng tham số `range` (enum 1 | 7 | 14 | 30) và trả dữ liệu biểu đồ
      // ở khóa `series`.
      final series = await sl<AnalyticsRepository>().revenueDailySeries(
        range: days,
      );

      if (series.isNotEmpty) {
        final points = series.map((e) => _RevenuePoint.fromJson(e)).toList();
        if (mounted && days == _revenueDays) {
          setState(() {
            _revenueSeries = points;
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
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final rawRevenue =
        _dashboardData?['todayRevenue'] ?? _dashboardData?['totalRevenueToday'];
    final double revenueNum = num.tryParse('$rawRevenue')?.toDouble() ?? 0.0;
    final num? revenueChangePercent =
        _dashboardData?['revenueChangePercent'] as num?;

    // Màn tổng quan dùng chung cho cả ba vai trò nhân viên (§3.7); hai màn
    // đào sâu bên dưới thì không — lọc lối vào theo quyền.
    final role = context.currentRole;
    final canViewOccupancy = role.canViewOccupancy;
    final canApproveBooking = role.canApproveBooking;
    if (!role.canViewYearlyRevenue && _revenueDays == 365) {
      _revenueDays = 7;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchRevenueSeries(7);
      });
    }

    final num? rawRate = _dashboardData?['occupancyRate'] as num?;
    final int occupiedRooms =
        (_dashboardData?['occupiedRooms'] as num?)?.toInt() ??
        (_dashboardData?['rooms']?['occupied'] as num?)?.toInt() ??
        0;
    final int totalRooms =
        (_dashboardData?['totalRooms'] as num?)?.toInt() ??
        (_dashboardData?['rooms']?['total'] as num?)?.toInt() ??
        0;

    final double occupancyPercent = rawRate != null
        ? rawRate.toDouble()
        : (totalRooms > 0 ? (occupiedRooms / totalRooms * 100) : 0.0);

    final double occupancyFraction = (occupancyPercent / 100.0).clamp(0.0, 1.0);

    final int checkIns =
        (_dashboardData?['checkInsToday'] as num?)?.toInt() ??
        (_dashboardData?['todayCheckIns'] as num?)?.toInt() ??
        (_dashboardData?['todayActivity']?['expectedCheckIns'] as num?)
            ?.toInt() ??
        0;
    final int checkOuts =
        (_dashboardData?['checkOutsToday'] as num?)?.toInt() ??
        (_dashboardData?['todayCheckOuts'] as num?)?.toInt() ??
        (_dashboardData?['todayActivity']?['expectedCheckOuts'] as num?)
            ?.toInt() ??
        0;
    final int pendingBookings =
        (_dashboardData?['pendingBookings'] as num?)?.toInt() ?? 0;

    final breakdown = _dashboardData?['roomStatusBreakdown'] as Map?;
    final int occupiedCount =
        (breakdown?['OCCUPIED'] as num?)?.toInt() ?? occupiedRooms;
    final int availableCount =
        (breakdown?['AVAILABLE'] as num?)?.toInt() ??
        (_dashboardData?['availableRooms'] as num?)?.toInt() ??
        0;
    final int cleaningCount =
        (breakdown?['CLEANING'] as num?)?.toInt() ??
        (_dashboardData?['cleaningRooms'] as num?)?.toInt() ??
        0;
    final int reservedCount =
        (breakdown?['RESERVED'] as num?)?.toInt() ??
        (_dashboardData?['reservedRooms'] as num?)?.toInt() ??
        0;
    final int maintenanceCount =
        (breakdown?['MAINTENANCE'] as num?)?.toInt() ??
        (_dashboardData?['maintenanceRooms'] as num?)?.toInt() ??
        0;

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.surface,
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
                    decoration: BoxDecoration(
                      gradient: AppGradients.navy,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppRadius.sheet),
                        bottomRight: Radius.circular(AppRadius.sheet),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            // Top Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.white30,
                                            ),
                                          ),
                                          child: Text(
                                            context.currentRole ==
                                                    UserRole.admin
                                                ? 'QUẢN TRỊ VIÊN'
                                                : context.currentRole ==
                                                      UserRole.receptionist
                                                ? 'LỄ TÂN – THU NGÂN'
                                                : 'TỔNG QUAN',
                                            style: const TextStyle(
                                              color: AppColors.secondaryLight,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      context.currentRole == UserRole.admin
                                          ? 'Báo Cáo Quản Trị'
                                          : context.currentRole ==
                                                UserRole.receptionist
                                          ? 'Bàn Trực Lễ Tân – Thu Ngân'
                                          : 'Báo Cáo Tổng Quan',
                                      style: const TextStyle(
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
                                    if (context.currentRole ==
                                        UserRole.receptionist) ...[
                                      _buildGlassCircleBtn(
                                        icon: Icons.people_outline_rounded,
                                        onTap: () =>
                                            context.push('/staff/users'),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Doanh thu hôm nay
                            Text(
                              'DOANH THU HÔM NAY',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
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
                                    ? const SkeletonBox(
                                        width: 170,
                                        height: 32,
                                        borderRadius: AppRadius.sm,
                                      )
                                    : AnimatedCounter(
                                        targetValue: revenueNum,
                                        formatter: (v) =>
                                            Formatters.formatCurrency(v),
                                        style: const TextStyle(
                                          color: AppColors.secondaryLight,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                if (!_isStatsLoading &&
                                    revenueChangePercent != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (revenueChangePercent >= 0
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444))
                                              .withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.50,
                                      ),
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

                  // 2. Thẻ tỷ lệ lấp đầy (đè lên dải navy 40px)
                  Positioned(
                    bottom: -40,
                    left: AppSpacing.screen,
                    right: AppSpacing.screen,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                        vertical: AppSpacing.md,
                      ),
                      // `GET /analytics/occupancy/detail` không mở cho thu
                      // ngân — với vai trò đó thẻ này chỉ hiển thị, không bấm.
                      onTap: canViewOccupancy
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OccupancyDetailScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tỷ lệ lấp đầy',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: palette.inkMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (canViewOccupancy) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: palette.inkMuted,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              _isStatsLoading
                                  ? const SkeletonBox(
                                      width: 80,
                                      height: 28,
                                      borderRadius: AppRadius.xs,
                                    )
                                  : AnimatedCounter.percent(
                                      percent: occupancyPercent,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: palette.ink,
                                      ),
                                    ),
                              const SizedBox(height: 2),
                              _isStatsLoading
                                  ? const SkeletonBox(
                                      width: 150,
                                      height: 14,
                                      borderRadius: AppRadius.xs,
                                    )
                                  : Text(
                                      '$occupiedRooms / $totalRooms phòng đang có khách',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: palette.inkMuted,
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
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, val, _) => CustomPaint(
                                painter: _GaugeArcPainter(
                                  percent: val,
                                  accentColor: palette.accent,
                                  backgroundColor: palette.surfaceMuted,
                                ),
                              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Text(
                  'HÔM NAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.inkMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. 3 Ô Thống kê nhỏ (96px height)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: checkIns,
                        label: 'Lượt nhận phòng',
                        icon: Icons.vpn_key_outlined,
                        color: palette.accent,
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: checkOuts,
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildSmallKpiCard(
                        value: pendingBookings,
                        label: 'Đơn chờ duyệt',
                        icon: Icons.schedule_outlined,
                        color: palette.isDark
                            ? const Color(0xFFEF4444)
                            : AppColors.error,
                        isLoading: _isStatsLoading,
                        // Duyệt đơn không mở cho thu ngân.
                        onTap: canApproveBooking
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BookingApprovalScreen(),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. Thẻ Biểu đồ Doanh thu (lọc 1 / 7 / 14 / 30 ngày)
              _buildRevenueChartCard(palette, textTheme),
              const SizedBox(height: AppSpacing.xl),

              // 6. Thẻ Cơ cấu Buồng phòng (Stacked Bar + Legend)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cơ cấu buồng phòng',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Single Horizontal Stacked Bar (14px height)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
                      const SizedBox(height: AppSpacing.md),

                      // Legend Wrap
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem(
                            'Đang có khách',
                            '$occupiedCount',
                            AppColors.occupied,
                            isLoading: _isStatsLoading,
                          ),
                          _buildLegendItem(
                            'Phòng trống',
                            '$availableCount',
                            AppColors.available,
                            isLoading: _isStatsLoading,
                          ),
                          _buildLegendItem(
                            'Đang dọn dẹp',
                            '$cleaningCount',
                            AppColors.cleaning,
                            isLoading: _isStatsLoading,
                          ),
                          _buildLegendItem(
                            'Đã đặt cọc',
                            '$reservedCount',
                            AppColors.reserved,
                            isLoading: _isStatsLoading,
                          ),
                          _buildLegendItem(
                            'Bảo trì',
                            '$maintenanceCount',
                            AppColors.maintenance,
                            isLoading: _isStatsLoading,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Biểu đồ doanh thu (có bộ lọc) ====================

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

  Widget _axisText(String text, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          color: palette.inkMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard(AppPalette palette, TextTheme textTheme) {
    final series = _revenueSeries;
    final title = _revenueDays == 365
        ? 'Doanh thu năm ${DateTime.now().year}'
        : (_revenueDays == 1
              ? 'Doanh thu hôm nay'
              : 'Doanh thu $_revenueDays ngày');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: 250,
          child: Column(
            children: [
              // Chart Header + Bộ lọc khoảng thời gian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  _buildRevenueRangeFilter(palette),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Chart Area
              Expanded(
                child: _isRevenueLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: palette.accent,
                          ),
                        ),
                      )
                    : series.isEmpty
                    ? Center(
                        child: Text(
                          _revenueLoadFailed
                              ? 'Không tải được dữ liệu doanh thu'
                              : 'Chưa có dữ liệu doanh thu',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.inkMuted,
                          ),
                        ),
                      )
                    : _buildRevenueLineChart(series, palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueRangeFilter(AppPalette palette) {
    return PopupMenuButton<int>(
      initialValue: _revenueDays,
      tooltip: 'Chọn khoảng thời gian',
      offset: const Offset(0, 34),
      color: palette.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      onSelected: (days) {
        if (days == _revenueDays) return;
        setState(() => _revenueDays = days);
        _fetchRevenueSeries(days);
      },
      itemBuilder: (context) {
        // Doanh thu năm (365) chỉ dành cho ADMIN (§3.7, §4.2, §4.3, §5)
        final options = context.currentRole.canViewYearlyRevenue
            ? _revenueRangeOptions
            : _revenueRangeOptions.where((days) => days != 365).toList();
        return options.map((days) {
          final selected = days == _revenueDays;
          final labelText = days == 365 ? 'Năm nay (12 tháng)' : '$days ngày';
          return PopupMenuItem<int>(
            value: days,
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? palette.accent : palette.ink,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 16, color: palette.accent),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _revenueDays == 365 ? 'Năm nay' : '$_revenueDays ngày',
              style: TextStyle(
                fontSize: 11,
                color: palette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: palette.inkMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart(
    List<_RevenuePoint> series,
    AppPalette palette,
  ) {
    final maxRevenue = series
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);
    final axisMax = _niceCeil(maxRevenue > 0 ? maxRevenue : 1000000);
    final interval = axisMax / 4;

    final isSinglePoint = series.length == 1;
    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].revenue),
    ];
    if (isSinglePoint) spots.add(FlSpot(1, series.first.revenue));

    final maxX = (spots.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: axisMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: palette.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _compactMoney(value),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: palette.inkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                if (series.length > 7 && idx % 2 != 0) {
                  return const SizedBox.shrink();
                }
                return _axisText(_axisLabel(series[idx]), palette);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.surface,
            tooltipBorder: BorderSide(color: palette.border),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt().clamp(0, series.length - 1);
                final point = series[idx];
                final label = _tooltipLabel(point);
                return LineTooltipItem(
                  '$label\n${Formatters.formatCurrency(spot.y)}',
                  TextStyle(
                    color: palette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: palette.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  palette.accent.withValues(alpha: 0.28),
                  palette.accent.withValues(alpha: 0.0),
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

  // ==================== Widget phụ trợ ====================

  Widget _buildGlassCircleBtn({
    IconData? icon,
    VoidCallback? onTap,
    Widget? customIcon,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: customIcon ?? Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildSmallKpiCard({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      onTap: onTap,
      child: SizedBox(
        height: 96,
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: palette.inkMuted,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isLoading
                    ? const SkeletonBox(
                        width: 40,
                        height: 20,
                        borderRadius: AppRadius.xs,
                      )
                    : AnimatedCounter.integer(
                        value: value,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: palette.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
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
      return const SkeletonBox(
        width: double.infinity,
        height: 14,
        borderRadius: AppRadius.pill,
      );
    }

    final total = occupied + available + cleaning + reserved + maintenance;
    if (total == 0) {
      return Container(color: context.palette.surfaceMuted);
    }

    final segments = [
      _Segment(occupied, AppColors.occupied),
      _Segment(available, AppColors.available),
      _Segment(cleaning, AppColors.cleaning),
      _Segment(reserved, AppColors.reserved),
      _Segment(maintenance, AppColors.maintenance),
    ];

    return Row(
      children: segments
          .where((s) => s.count > 0)
          .map(
            (s) => Expanded(
              flex: (s.count * 1000 / total).round().clamp(1, 1000),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                color: s.color,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLegendItem(
    String label,
    String count,
    Color color, {
    required bool isLoading,
  }) {
    final palette = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: palette.inkMuted)),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
      ],
    );
  }
}

class _Segment {
  final int count;
  final Color color;
  _Segment(this.count, this.color);
}

class _RevenuePoint {
  final String label;
  final double revenue;
  final DateTime? date;

  _RevenuePoint({required this.label, required this.revenue, this.date});

  factory _RevenuePoint.fromJson(Map json) {
    DateTime? parsedDate;
    final rawDate = json['date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return _RevenuePoint(
      label: json['label']?.toString() ?? json['dateLabel']?.toString() ?? '',
      revenue:
          num.tryParse(
            '${json['revenue'] ?? json['amount'] ?? 0}',
          )?.toDouble() ??
          0.0,
      date: parsedDate,
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double percent;
  final Color accentColor;
  final Color backgroundColor;

  _GaugeArcPainter({
    required this.percent,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * percent.clamp(0.0, 1.0),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
