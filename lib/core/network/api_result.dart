import 'package:dio/dio.dart';
import 'api_error.dart';

/// Thông tin phân trang trả về ở `data.meta` (áp dụng cho GET /bookings).
class PageMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final Map<String, dynamic>? timeFilter;

  const PageMeta({
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
    this.timeFilter,
  });

  factory PageMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PageMeta();
    int parseInt(dynamic val, int fallback) {
      if (val is int) return val;
      return int.tryParse('$val') ?? fallback;
    }

    return PageMeta(
      total: parseInt(json['total'], 0),
      page: parseInt(json['page'], 1),
      limit: parseInt(json['limit'], 20),
      totalPages: parseInt(json['totalPages'], 1),
      timeFilter: json['timeFilter'] as Map<String, dynamic>?,
    );
  }

  String? get timeFilterLabel => timeFilter?['label'] as String?;
  String? get timeFilterType => timeFilter?['type'] as String?;
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;
}

/// Một trang dữ liệu kèm thông tin phân trang thô (dạng Map).
class PagedData {
  final List<Map<String, dynamic>> items;
  final PageMeta meta;

  const PagedData(this.items, this.meta);
}

/// Kết quả phân trang chuẩn hóa cho toàn bộ hệ thống client.
class PaginatedResult<T> {
  final List<T> items;
  final PageMeta meta;

  const PaginatedResult({
    required this.items,
    required this.meta,
  });

  bool get hasNextPage => meta.hasNextPage;
  bool get hasPrevPage => meta.hasPrevPage;
  int get total => meta.total;
  int get page => meta.page;
  int get limit => meta.limit;
  int get totalPages => meta.totalPages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
}

/// Helper bóc envelope NestJS `{statusCode, success, message, data, timestamp}`.
/// Ném [ApiError] khi `success != true` hoặc khi kiểu dữ liệu không khớp.
class ApiResult {
  ApiResult._();

  /// Các key thường gặp bao ngoài một mảng dữ liệu trong `data`.
  /// `data` đứng đầu vì backend đã chuyển GET /bookings sang dạng phân trang
  /// `{ "data": { "data": [...], "meta": {...} } }`.
  static const List<String> _listKeys = [
    'data',
    'items',
    'records',
    'results',
    'series',
    'bookings',
    'rooms',
    'roomTypes',
    'users',
    'invoices',
    'services',
    'changes',
  ];

  /// Kiểm tra envelope và trả về phần `data` thô.
  static dynamic _rawData(Response res) {
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      throw ApiError(
        statusCode: res.statusCode,
        message: 'Dữ liệu phản hồi máy chủ không đúng định dạng Map.',
      );
    }

    if (body['success'] != true) {
      throw ApiError.fromDynamic(body);
    }

    return body['data'];
  }

  static List<Map<String, dynamic>> _castList(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Bóc mảng đối tượng từ `Response.data['data']`.
  /// Hỗ trợ cả trường hợp payload dạng:
  /// - `{ "success": true, "data": [ ... ] }`
  /// - `{ "success": true, "data": { "data": [ ... ], "meta": {...} } }` (phân trang)
  /// - `{ "success": true, "data": { "series": [ ... ] } }` (doanh thu theo ngày)
  /// - `{ "success": true, "data": { "items"|"bookings"|"rooms"|... : [ ... ] } }`
  static List<Map<String, dynamic>> unwrapList(
    Response res, {
    String? nestedKey,
  }) {
    var rawData = _rawData(res);

    if (rawData is Map<String, dynamic>) {
      if (nestedKey != null) {
        rawData = rawData[nestedKey];
      } else {
        for (final key in _listKeys) {
          if (rawData is Map<String, dynamic> && rawData[key] is List) {
            rawData = rawData[key];
            break;
          }
        }
      }
    }

    return _castList(rawData);
  }

  /// Bóc danh sách kèm `meta` phân trang (GET /bookings).
  /// Khi backend trả về mảng phẳng, [PageMeta] được suy ra từ độ dài danh sách.
  static PagedData unwrapPage(Response res, {String? nestedKey}) {
    final rawData = _rawData(res);

    if (rawData is Map<String, dynamic>) {
      final key = nestedKey ??
          _listKeys.firstWhere(
            (k) => rawData[k] is List,
            orElse: () => 'data',
          );
      final items = _castList(rawData[key]);
      final rawMeta = rawData['meta'];
      final meta = rawMeta is Map
          ? PageMeta.fromJson(Map<String, dynamic>.from(rawMeta))
          : PageMeta(
              total: items.length,
              limit: items.isEmpty ? 20 : items.length,
            );
      return PagedData(items, meta);
    }

    final items = _castList(rawData);
    return PagedData(
      items,
      PageMeta(total: items.length, limit: items.isEmpty ? 20 : items.length),
    );
  }

  /// Bóc danh sách kèm thông tin phân trang đã được ánh xạ sang model [T].
  static PaginatedResult<T> unwrapPaginatedList<T>(
    Response res,
    T Function(Map<String, dynamic> json) fromJson, {
    String? nestedKey,
  }) {
    final paged = unwrapPage(res, nestedKey: nestedKey);
    return PaginatedResult<T>(
      items: paged.items.map(fromJson).toList(),
      meta: paged.meta,
    );
  }

  /// Bóc Map từ `Response.data['data']`.
  static Map<String, dynamic> unwrapMap(Response res) {
    final rawData = _rawData(res);
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    // Nếu data là null nhưng success = true, trả về nguyên body để không mất
    // thông tin `message` của máy chủ.
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Bóc Map con nằm trong `data`, ví dụ `data.booking` của API
  /// approve / confirm / check-out. Nếu không có key con, trả về chính `data`.
  static Map<String, dynamic> unwrapNestedMap(Response res, String key) {
    final data = unwrapMap(res);
    final nested = data[key];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return data;
  }
}
