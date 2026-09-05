import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/dashboard_stats.dart';

class AnalyticsRepository {
  final DioClient _dioClient;

  AnalyticsRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// Thống kê tổng quan: GET /analytics/dashboard
  Future<DashboardStats> dashboard() async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.analyticsDashboard);
      final data = ApiResult.unwrapMap(res);
      return DashboardStats.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Doanh thu theo ngày: GET /analytics/revenue/daily?range=
  /// range thuộc enum 1 | 7 | 14 | 30.
  ///
  /// Trả về nguyên báo cáo `{range, from, to, series, total, average, peak,
  /// previousTotal, changePercent, invoiceCount, ranges}` — API không còn trả
  /// về một mảng phẳng, dữ liệu biểu đồ nằm ở khóa `series`.
  Future<Map<String, dynamic>> revenueDaily({int range = 7}) async {
    try {
      final res = await _dioClient.dio.get(
        ApiEndpoints.analyticsRevenueDaily,
        queryParameters: {'range': range},
      );
      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy nhanh chuỗi dữ liệu biểu đồ doanh thu theo ngày (`data.series`).
  /// Mỗi phần tử gồm `{date, label, dateLabel, revenue, amount, invoiceCount}`.
  Future<List<Map<String, dynamic>>> revenueDailySeries({int range = 7}) async {
    final report = await revenueDaily(range: range);
    final series = report['series'];
    if (series is! List) return <Map<String, dynamic>>[];
    return series
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Báo cáo doanh thu theo năm (12 tháng): GET /analytics/revenue?year=
  Future<Map<String, dynamic>> revenueYearly({int? year}) async {
    try {
      final queryParams = <String, dynamic>{
        'year': ?year,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.analyticsRevenue,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy danh sách các năm có dữ liệu doanh thu: GET /analytics/revenue/years
  /// Nếu BE chưa hỗ trợ endpoint này (trả về 404), phương thức trả về [] để UI fallback an toàn.
  Future<List<int>> revenueAvailableYears() async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.analyticsRevenueYears);
      final body = res.data;
      dynamic raw = body is Map ? (body['data'] ?? body) : body;
      if (raw is Map && raw['years'] is List) {
        raw = raw['years'];
      }
      if (raw is List) {
        return raw
            .map((e) => e is Map ? int.tryParse('${e['year'] ?? e['id']}') : int.tryParse('$e'))
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
      }
      return <int>[];
    } catch (_) {
      return <int>[];
    }
  }

  /// Tỷ lệ lấp đầy theo hạng phòng: GET /analytics/occupancy-by-type
  Future<List<Map<String, dynamic>>> occupancyByType() async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.analyticsOccupancyByType);
      return ApiResult.unwrapList(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Hiệu suất làm việc của nhân sự (A1): GET /analytics/staff-performance?from=...&to=...
  Future<List<Map<String, dynamic>>> staffPerformance({DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{
        if (from != null) 'from': '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}',
        if (to != null) 'to': '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}',
      };
      final res = await _dioClient.dio.get(
        ApiEndpoints.staffPerformance,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return ApiResult.unwrapList(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Xuất báo cáo doanh thu CSV (A3): GET /analytics/revenue/export?year=...
  Future<String> exportRevenueReport({int? year}) async {
    try {
      final queryParams = <String, dynamic>{
        'year': ?year,
      };
      final res = await _dioClient.dio.get(
        ApiEndpoints.revenueExport,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(responseType: ResponseType.plain),
      );
      return res.data?.toString() ?? '';
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
