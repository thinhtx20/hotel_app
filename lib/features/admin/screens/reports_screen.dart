import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/analytics_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Màn hình Báo Cáo Doanh Thu & Hiệu Suất Nhân Viên (Tab 1 của ADMIN - FE-ROLE-MATRIX §5.6)
class ReportsScreen extends StatefulWidget {
  final AnalyticsRepository? analyticsRepository;
  const ReportsScreen({super.key, this.analyticsRepository});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final AnalyticsRepository _analyticsRepo = widget.analyticsRepository ?? sl<AnalyticsRepository>();

  int _selectedYear = DateTime.now().year;
  late List<int> _availableYears;

  /// Chỉ dùng cho lần tải đầu tiên & nút refresh toàn màn - đổi năm KHÔNG dùng cờ này.
  bool _isInitialLoading = true;
  String? _errorMessage;

  bool _isRevenueLoading = false;
  String? _revenueError;

  /// Chống race condition khi người dùng đổi năm liên tục.
  int _revenueRequestId = 0;

  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _staffPerformance = [];

  @override
  void initState() {
    super.initState();
    _availableYears = _resolveYears();
    _loadReportData();
  }

  /// Tổng hợp danh sách năm từ API (trường availableYears trong revenueYearly hoặc endpoint riêng)
  /// Có fallback động an toàn nếu Backend chưa bổ sung.
  List<int> _resolveYears({List<int>? apiYearsList, Map<String, dynamic>? revenueData}) {
    // 1. Nếu API có endpoint danh sách năm riêng và trả về dữ liệu
    if (apiYearsList != null && apiYearsList.isNotEmpty) {
      final set = apiYearsList.toSet()..add(_selectedYear);
      return set.toList()..sort();
    }

    // 2. Nếu API doanh thu trả về kèm trường availableYears / years
    if (revenueData != null) {
      final rawYears = revenueData['availableYears'] ??
          revenueData['years'] ??
          revenueData['available_years'];
      if (rawYears is List) {
        final parsed = rawYears
            .map((e) => int.tryParse('$e'))
            .whereType<int>()
            .toSet();
        if (parsed.isNotEmpty) {
          parsed.add(_selectedYear);
          return parsed.toList()..sort();
        }
      }
    }

    // 3. Fallback động khi BE chưa bổ sung:
    // Gồm năm đang chọn, năm trả về từ data, năm hiện tại và các năm lân cận (-2 đến +1)
    final currentYear = DateTime.now().year;
    final int? returnedYear = revenueData != null ? int.tryParse('${revenueData['year']}') : null;
    final fallbackSet = <int>{
      ?returnedYear,
      _selectedYear,
      currentYear - 2,
      currentYear - 1,
      currentYear,
      currentYear + 1,
    };
    return fallbackSet.toList()..sort();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _revenueError = null;
    });

    final requestId = ++_revenueRequestId;

    try {
      final revenueFuture = _analyticsRepo.revenueYearly(year: _selectedYear);
      final staffFuture = _analyticsRepo.staffPerformance();
      final yearsFuture = _analyticsRepo.revenueAvailableYears();

      final results = await Future.wait([revenueFuture, staffFuture, yearsFuture]);
      if (mounted && requestId == _revenueRequestId) {
        final revenue = results[0] as Map<String, dynamic>;
        final staff = results[1] as List<Map<String, dynamic>>;
        final apiYears = results[2] as List<int>;

        setState(() {
          _revenueData = revenue;
          _staffPerformance = staff;
          _availableYears = _resolveYears(apiYearsList: apiYears, revenueData: revenue);
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _revenueRequestId) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Chỉ tải lại dữ liệu doanh thu (biểu đồ 12 tháng) khi đổi năm.
  Future<void> _loadRevenueOnly() async {
    setState(() {
      _isRevenueLoading = true;
      _revenueError = null;
    });

    final requestId = ++_revenueRequestId;

    try {
      final revenue = await _analyticsRepo.revenueYearly(year: _selectedYear);
      if (mounted && requestId == _revenueRequestId) {
        setState(() {
          _revenueData = revenue;
          _availableYears = _resolveYears(revenueData: revenue);
          _isRevenueLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _revenueRequestId) {
        setState(() {
          _isRevenueLoading = false;
          _revenueError = e.toString();
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final csvContent = await _analyticsRepo.exportRevenueReport(year: _selectedYear);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xuất Báo Cáo Doanh Thu (CSV)'),
          content: Text(
            csvContent.isNotEmpty
                ? 'Đã tải thành công dữ liệu báo cáo doanh thu năm $_selectedYear (Dung lượng: ${csvContent.length} bytes).'
                : 'Báo cáo đã sẵn sàng để xuất.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất báo cáo: ${e.toString()}'),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  Widget _buildChartBars(AppPalette palette, List monthlySeries, num totalYearRevenue) {
    // Tìm doanh thu lớn nhất trong các tháng để vẽ tỷ lệ cột cân đối
    num maxMonthVal = 0;
    for (final item in monthlySeries) {
      if (item is Map) {
        final v = (item['totalRevenue'] ?? item['revenue'] ?? item['amount'] ?? 0) as num;
        if (v > maxMonthVal) maxMonthVal = v;
      } else if (item is num && item > maxMonthVal) {
        maxMonthVal = item;
      }
    }
    final maxMonth = maxMonthVal > 0 ? maxMonthVal : (totalYearRevenue > 0 ? totalYearRevenue / 4 : 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(12, (m) {
        num monthVal = 0;
        dynamic matchingMonth;
        for (final it in monthlySeries) {
          if (it is Map && (it['month'] == m + 1 || it['m'] == m + 1)) {
            matchingMonth = it;
            break;
          }
        }
        if (matchingMonth != null && matchingMonth is Map) {
          monthVal = (matchingMonth['totalRevenue'] ?? matchingMonth['revenue'] ?? matchingMonth['amount'] ?? 0) as num;
        } else if (m < monthlySeries.length) {
          final item = monthlySeries[m];
          monthVal = (item is Map ? item['totalRevenue'] ?? item['revenue'] ?? item['amount'] ?? 0 : item) as num;
        }
        final double barRatio = (monthVal / maxMonth).clamp(0.08, 1.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 14,
              height: 90 * barRatio,
              decoration: BoxDecoration(
                color: m == DateTime.now().month - 1 && _selectedYear == DateTime.now().year
                    ? palette.accent
                    : palette.accent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'T${m + 1}',
              style: TextStyle(fontSize: 10, color: palette.inkMuted, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChartError(AppPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không tải được doanh thu năm $_selectedYear.',
            style: TextStyle(fontSize: 12, color: palette.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _isRevenueLoading ? null : _loadRevenueOnly,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final totalYearRevenue = (_revenueData['summary'] is Map
            ? (_revenueData['summary']['totalYearRevenue'] as num?)
            : null) ??
        (_revenueData['totalRevenue'] as num?) ??
        (_revenueData['total'] as num?) ??
        0;
    final monthlySeries = (_revenueData['monthly'] as List?) ??
        (_revenueData['monthlyRevenue'] as List?) ??
        (_revenueData['series'] as List?) ??
        [];

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Báo Cáo & Hiệu Suất'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: AppErrorView(
                    error: _errorMessage!,
                    onRetry: _loadReportData,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner truy cập sổ hóa đơn
                      PressableScale(
                        onTap: () => context.push('/admin/invoices'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: AppGradients.gold,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.goldGlow,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sổ Nhật Ký Hóa Đơn Toàn Khách Sạn',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Xem tất cả giao dịch thanh toán, tra cứu chi tiết & in biên lai',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Doanh thu năm & biểu đồ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doanh Thu Năm $_selectedYear',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.ink),
                              ),
                              const SizedBox(height: 2),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _isRevenueLoading ? 0.35 : 1,
                                child: Text(
                                  Formatters.formatCurrency(totalYearRevenue),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: palette.accent,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          DropdownButton<int>(
                            value: _selectedYear,
                            underline: const SizedBox.shrink(),
                            items: _availableYears.map((y) {
                              return DropdownMenuItem<int>(
                                value: y,
                                child: Text('Năm $y', style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink)),
                              );
                            }).toList(),
                            onChanged: (y) {
                              if (y != null && y != _selectedYear) {
                                setState(() => _selectedYear = y);
                                // Chỉ tải lại biểu đồ doanh thu, giữ nguyên phần còn lại của màn hình.
                                _loadRevenueOnly();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Biểu đồ 12 tháng đơn giản
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phân bổ 12 tháng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.inkMuted)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: _revenueError != null
                                  ? _buildChartError(palette)
                                  : Stack(
                                      children: [
                                        AnimatedOpacity(
                                          duration: const Duration(milliseconds: 180),
                                          opacity: _isRevenueLoading ? 0.25 : 1,
                                          child: _buildChartBars(palette, monthlySeries, totalYearRevenue),
                                        ),
                                        if (_isRevenueLoading)
                                          const Positioned.fill(
                                            child: Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Bảng xếp hạng hiệu suất nhân sự
                      Text(
                        'Hiệu Suất Làm Việc Nhân Sự (A1)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Thống kê số lượng đơn duyệt, hóa đơn và tiền thực thu theo từng nhân viên.',
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (_staffPerformance.isEmpty)
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              'Chưa có dữ liệu hiệu suất nhân sự trong kỳ này.',
                              style: TextStyle(color: palette.inkMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingTextStyle: TextStyle(fontWeight: FontWeight.w700, color: palette.ink, fontSize: 12),
                              dataTextStyle: TextStyle(color: palette.ink, fontSize: 12),
                              columns: const [
                                DataColumn(label: Text('Nhân viên')),
                                DataColumn(label: Text('Đơn duyệt')),
                                DataColumn(label: Text('Đơn hủy')),
                                DataColumn(label: Text('HĐ xuất')),
                                DataColumn(label: Text('Thực thu')),
                              ],
                              rows: _staffPerformance.map((st) {
                                final name = st['staffName'] ?? st['name'] ?? st['fullName'] ?? 'Nhân viên';
                                final confirmed = st['confirmedBookings'] ?? st['approvedBookings'] ?? 0;
                                final cancelled = st['cancelledBookings'] ?? 0;
                                final invoices = st['invoicesIssued'] ?? st['invoiceCount'] ?? 0;
                                final collected = (st['amountCollected'] ?? st['totalRevenue'] ?? 0) as num;

                                return DataRow(cells: [
                                  DataCell(Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text('$confirmed', style: TextStyle(color: palette.statusAvailableInk, fontWeight: FontWeight.w700))),
                                  DataCell(Text('$cancelled', style: TextStyle(color: palette.statusOccupiedInk))),
                                  DataCell(Text('$invoices')),
                                  DataCell(Text(Formatters.formatCurrency(collected), style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
