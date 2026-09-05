import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/api_result.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/invoice_repository.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions options) handler;
  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = handler(options);
    final text = _jsonEncode(data);
    return ResponseBody.fromString(
      text,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static String _jsonEncode(dynamic data) {
    if (data is Map) {
      final entries = data.entries
          .map((e) => '"${e.key}": ${_jsonEncode(e.value)}')
          .join(',');
      return '{$entries}';
    }
    if (data is List) {
      return '[${data.map(_jsonEncode).join(',')}]';
    }
    if (data is String) {
      return '"$data"';
    }
    if (data is num || data is bool) {
      return '$data';
    }
    if (data == null) {
      return 'null';
    }
    return '"$data"';
  }
}

class _MockDioClient implements DioClient {
  @override
  late final Dio dio;

  _MockDioClient(Map<String, dynamic> Function(RequestOptions options) handler) {
    dio = Dio(BaseOptions(baseUrl: 'https://test.hotel.local/api/v1'));
    dio.httpClientAdapter = _FakeAdapter(handler);
  }

  @override
  void setBaseUrl(String newUrl) => dio.options.baseUrl = newUrl;
}

DioClient _createMockDioClient(
  Map<String, dynamic> Function(RequestOptions options) handler,
) {
  return _MockDioClient(handler);
}

void main() {
  group('PageMeta & PaginatedResult Core Tests', () {
    test('PageMeta parses standard and fallback values correctly', () {
      final meta = PageMeta.fromJson({
        'total': 105,
        'page': 2,
        'limit': 20,
        'totalPages': 6,
      });

      expect(meta.total, 105);
      expect(meta.page, 2);
      expect(meta.limit, 20);
      expect(meta.totalPages, 6);
      expect(meta.hasNextPage, isTrue);
      expect(meta.hasPrevPage, isTrue);
    });

    test('PageMeta handles string types and edge boundary values', () {
      final firstPage = PageMeta.fromJson({
        'total': '15',
        'page': '1',
        'limit': '20',
        'totalPages': '1',
      });

      expect(firstPage.total, 15);
      expect(firstPage.page, 1);
      expect(firstPage.hasNextPage, isFalse);
      expect(firstPage.hasPrevPage, isFalse);

      const emptyMeta = PageMeta();
      expect(emptyMeta.total, 0);
      expect(emptyMeta.page, 1);
      expect(emptyMeta.limit, 20);
      expect(emptyMeta.totalPages, 1);
      expect(emptyMeta.hasNextPage, isFalse);
      expect(emptyMeta.hasPrevPage, isFalse);
    });

    test('PaginatedResult wraps items and delegates meta helpers correctly', () {
      const meta = PageMeta(total: 50, page: 1, limit: 20, totalPages: 3);
      final result = PaginatedResult<String>(
        items: const ['item1', 'item2'],
        meta: meta,
      );

      expect(result.items, hasLength(2));
      expect(result.length, 2);
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
      expect(result.total, 50);
      expect(result.page, 1);
      expect(result.limit, 20);
      expect(result.totalPages, 3);
      expect(result.hasNextPage, isTrue);
      expect(result.hasPrevPage, isFalse);
    });
  });

  group('ApiResult.unwrapPaginatedList Tests', () {
    test('unwraps response with data.data and data.meta', () {
      final res = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {'id': 'inv-1', 'finalAmount': 1000000, 'paymentStatus': 'PAID'},
              {'id': 'inv-2', 'finalAmount': 2000000, 'paymentStatus': 'UNPAID'},
            ],
            'meta': {
              'total': 45,
              'page': 1,
              'limit': 20,
              'totalPages': 3,
            },
          },
        },
      );

      final paged = ApiResult.unwrapPaginatedList(res, InvoiceModel.fromJson);
      expect(paged.items, hasLength(2));
      expect(paged.items[0].id, 'inv-1');
      expect(paged.items[1].id, 'inv-2');
      expect(paged.total, 45);
      expect(paged.page, 1);
      expect(paged.limit, 20);
      expect(paged.totalPages, 3);
      expect(paged.hasNextPage, isTrue);
    });

    test('gracefully handles legacy plain array response without meta', () {
      final res = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: {
          'statusCode': 200,
          'success': true,
          'data': [
            {'id': 'u-1', 'email': 'user1@test.com', 'fullName': 'User One'},
            {'id': 'u-2', 'email': 'user2@test.com', 'fullName': 'User Two'},
          ],
        },
      );

      final paged = ApiResult.unwrapPaginatedList(res, UserModel.fromJson);
      expect(paged.items, hasLength(2));
      expect(paged.items[0].email, 'user1@test.com');
      expect(paged.total, 2);
      expect(paged.page, 1);
      expect(paged.totalPages, 1);
      expect(paged.hasNextPage, isFalse);
    });
  });

  group('InvoiceRepository Pagination Tests', () {
    test('fetchInvoicesPage sends pagination & search query params', () async {
      RequestOptions? recordedOptions;
      final mock = _createMockDioClient((options) {
        recordedOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {'id': 'inv-001', 'finalAmount': 500000, 'paymentStatus': 'UNPAID'}
            ],
            'meta': {'total': 25, 'page': 2, 'limit': 10, 'totalPages': 3},
          },
        };
      });

      final repo = InvoiceRepository(dioClient: mock);
      final paged = await repo.fetchInvoicesPage(
        status: 'UNPAID',
        search: 'INV-2026',
        page: 2,
        limit: 10,
      );

      expect(recordedOptions?.queryParameters['status'], 'UNPAID');
      expect(recordedOptions?.queryParameters['search'], 'INV-2026');
      expect(recordedOptions?.queryParameters['page'], 2);
      expect(recordedOptions?.queryParameters['limit'], 10);
      expect(paged.items, hasLength(1));
      expect(paged.total, 25);
      expect(repo.lastMeta?.totalPages, 3);
    });

    test('fetchInvoicesPage and fetchAll send time filter query parameters correctly', () async {
      RequestOptions? recordedPageOptions;
      RequestOptions? recordedAllOptions;

      final mockPage = _createMockDioClient((options) {
        recordedPageOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [],
            'meta': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 0},
          },
        };
      });

      final mockAll = _createMockDioClient((options) {
        recordedAllOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [],
            'meta': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 0},
          },
        };
      });

      final pageRepo = InvoiceRepository(dioClient: mockPage);
      await pageRepo.fetchInvoicesPage(
        filterType: 'month_range',
        year: 2026,
        fromMonth: 3,
        toMonth: 8,
        weekOffset: 1,
        startDate: '2026-03-01',
        endDate: '2026-08-31',
      );

      expect(recordedPageOptions?.queryParameters['filterType'], 'month_range');
      expect(recordedPageOptions?.queryParameters['year'], 2026);
      expect(recordedPageOptions?.queryParameters['fromMonth'], 3);
      expect(recordedPageOptions?.queryParameters['toMonth'], 8);
      expect(recordedPageOptions?.queryParameters['weekOffset'], 1);
      expect(recordedPageOptions?.queryParameters['startDate'], '2026-03-01');
      expect(recordedPageOptions?.queryParameters['endDate'], '2026-08-31');

      final allRepo = InvoiceRepository(dioClient: mockAll);
      await allRepo.fetchAll(
        filterType: 'week',
        weekOffset: 0,
        month: 9,
      );

      expect(recordedAllOptions?.queryParameters['filterType'], 'week');
      expect(recordedAllOptions?.queryParameters['weekOffset'], 0);
      expect(recordedAllOptions?.queryParameters['month'], 9);
      expect(recordedAllOptions?.queryParameters.containsKey('year'), isFalse);
    });

    test('fetchAllInvoices aggregates multi-page data in parallel', () async {
      final calls = <int>[];
      final mock = _createMockDioClient((options) {
        final page = options.queryParameters['page'] as int? ?? 1;
        calls.add(page);
        if (page == 1) {
          return {
            'statusCode': 200,
            'success': true,
            'data': {
              'data': [
                {'id': 'inv-1', 'finalAmount': 100000},
                {'id': 'inv-2', 'finalAmount': 200000},
              ],
              'meta': {'total': 3, 'page': 1, 'limit': 2, 'totalPages': 2},
            },
          };
        } else {
          return {
            'statusCode': 200,
            'success': true,
            'data': {
              'data': [
                {'id': 'inv-3', 'finalAmount': 300000},
              ],
              'meta': {'total': 3, 'page': 2, 'limit': 2, 'totalPages': 2},
            },
          };
        }
      });

      final repo = InvoiceRepository(dioClient: mock);
      final all = await repo.fetchAllInvoices();

      expect(all, hasLength(3));
      expect(all.map((i) => i.id).toList(), ['inv-1', 'inv-2', 'inv-3']);
      expect(calls, containsAll([1, 2]));
    });

    test('fetchMyPage requests customer invoices with query params', () async {
      RequestOptions? recordedOptions;
      final mock = _createMockDioClient((options) {
        recordedOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {'id': 'my-inv-1', 'finalAmount': 800000, 'paymentStatus': 'PARTIAL'}
            ],
            'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
          },
        };
      });

      final repo = InvoiceRepository(dioClient: mock);
      final paged = await repo.fetchMyPage(status: 'PARTIAL', search: '101');

      expect(recordedOptions?.path, '/invoices/my');
      expect(recordedOptions?.queryParameters['status'], 'PARTIAL');
      expect(recordedOptions?.queryParameters['search'], '101');
      expect(paged.items, hasLength(1));
      expect(paged.items.first.id, 'my-inv-1');
    });
  });

  group('UserRepository Pagination Tests', () {
    test('fetchUsersPage sends role, search, page and limit', () async {
      RequestOptions? recordedOptions;
      final mock = _createMockDioClient((options) {
        recordedOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {
                'id': 'u-10',
                'email': 'staff@hotel.com',
                'fullName': 'Staff Ten',
                'role': 'RECEPTIONIST'
              }
            ],
            'meta': {'total': 12, 'page': 1, 'limit': 20, 'totalPages': 1},
          },
        };
      });

      final repo = UserRepository(dioClient: mock);
      final paged = await repo.fetchUsersPage(
        role: 'RECEPTIONIST',
        search: 'Staff',
        page: 1,
        limit: 20,
      );

      expect(recordedOptions?.path, '/users');
      expect(recordedOptions?.queryParameters['role'], 'RECEPTIONIST');
      expect(recordedOptions?.queryParameters['search'], 'Staff');
      expect(paged.items.first.fullName, 'Staff Ten');
      expect(repo.lastMeta?.total, 12);
    });
  });

  group('RoomRepository Pagination Tests', () {
    test('fetchRoomsPage sends floor, roomTypeId, status, search, and page', () async {
      RequestOptions? recordedOptions;
      final mock = _createMockDioClient((options) {
        recordedOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {
                'id': 'r-101',
                'roomNumber': '101',
                'floor': 1,
                'status': 'AVAILABLE',
                'pricePerNight': 1200000,
              }
            ],
            'meta': {'total': 30, 'page': 2, 'limit': 15, 'totalPages': 2},
          },
        };
      });

      final repo = RoomRepository(dioClient: mock);
      final paged = await repo.fetchRoomsPage(
        status: RoomStatus.available,
        floor: 1,
        search: '101',
        page: 2,
        limit: 15,
      );

      expect(recordedOptions?.path, '/rooms');
      expect(recordedOptions?.queryParameters['status'], 'AVAILABLE');
      expect(recordedOptions?.queryParameters['floor'], 1);
      expect(recordedOptions?.queryParameters['search'], '101');
      expect(recordedOptions?.queryParameters['page'], 2);
      expect(recordedOptions?.queryParameters['limit'], 15);
      expect(paged.items.first.roomNumber, '101');
      expect(repo.lastMeta?.total, 30);
    });
  });

  group('BookingRepository Pagination Tests', () {
    test('fetchBookingsPage returns PaginatedResult with PageMeta', () async {
      RequestOptions? recordedOptions;
      final mock = _createMockDioClient((options) {
        recordedOptions = options;
        return {
          'statusCode': 200,
          'success': true,
          'data': {
            'data': [
              {
                'id': 'bk-01',
                'bookingCode': 'BK-0001',
                'status': 'CONFIRMED',
                'totalAmount': 2400000,
              }
            ],
            'meta': {'total': 80, 'page': 3, 'limit': 20, 'totalPages': 4},
          },
        };
      });

      final repo = BookingRepository(dioClient: mock);
      final paged = await repo.fetchBookingsPage(
        status: 'CONFIRMED',
        search: 'BK-0001',
        page: 3,
        limit: 20,
      );

      expect(recordedOptions?.path, '/bookings');
      expect(recordedOptions?.queryParameters['status'], 'CONFIRMED');
      expect(recordedOptions?.queryParameters['search'], 'BK-0001');
      expect(recordedOptions?.queryParameters['page'], 3);
      expect(recordedOptions?.queryParameters['limit'], 20);
      expect(paged.items.first.bookingCode, 'BK-0001');
      expect(paged.total, 80);
      expect(paged.page, 3);
      expect(paged.totalPages, 4);
      expect(paged.hasNextPage, isTrue);
      expect(paged.hasPrevPage, isTrue);
    });
  });
}
