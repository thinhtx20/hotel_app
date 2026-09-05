import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';

/// DioClient giả lập trả về nhiều trang cho GET /bookings và đo được số request
/// chạy đồng thời, phục vụ việc kiểm tra [BookingRepository.fetchAllBookings]
/// gọi các trang song song thay vì nối tiếp.
class _PagingStubDioClient implements DioClient {
  final int totalPages;
  final int itemsPerPage;

  /// Độ trễ giả lập mỗi request, đủ để các trang chồng thời gian với nhau khi
  /// repository gọi song song.
  static const Duration latency = Duration(milliseconds: 40);

  final List<int> requestedPages = [];
  final List<Map<String, dynamic>> queries = [];
  int _inFlight = 0;
  int maxConcurrent = 0;

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) => dio.options.baseUrl = newUrl;

  _PagingStubDioClient({
    this.totalPages = 3,
    this.itemsPerPage = 2,
  }) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final page = int.tryParse('${options.queryParameters['page']}') ?? 1;
            requestedPages.add(page);
            queries.add(Map<String, dynamic>.from(options.queryParameters));

            _inFlight++;
            if (_inFlight > maxConcurrent) maxConcurrent = _inFlight;
            await Future<void>.delayed(latency);
            _inFlight--;

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'data': [
                      for (var i = 0; i < itemsPerPage; i++)
                        _bookingJson(id: 'bk-p$page-i$i'),
                    ],
                    'meta': {
                      'total': totalPages * itemsPerPage,
                      'page': page,
                      'limit': itemsPerPage,
                      'totalPages': totalPages,
                    },
                  },
                },
              ),
            );
          },
        ),
      );
  }
}

Map<String, dynamic> _bookingJson({
  required String id,
  String status = 'PENDING',
}) => {
  'id': id,
  'bookingCode': 'BK-$id',
  'customerId': 'cus-1',
  'roomId': 'room-1',
  'checkInDate': '2026-09-05T14:00:00.000Z',
  'checkOutDate': '2026-09-08T12:00:00.000Z',
  'guestCount': 2,
  'totalAmount': 3600000,
  'depositAmount': 0,
  'status': status,
};

/// Stub chọn payload theo mảnh đường dẫn của request; [fallback] dùng cho các
/// đường dẫn không khớp key nào.
class _RoutingStubDioClient implements DioClient {
  final Map<String, dynamic> byPath;
  final dynamic fallback;

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) => dio.options.baseUrl = newUrl;

  _RoutingStubDioClient(this.byPath, {this.fallback}) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final key = byPath.keys.firstWhere(
              (k) => options.path.contains(k),
              orElse: () => '',
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: key.isEmpty ? fallback : byPath[key],
              ),
            );
          },
        ),
      );
  }
}

void main() {
  group('fetchAllBookings — gom trang song song', () {
    test('gom đủ mọi trang theo meta.totalPages', () async {
      final stub = _PagingStubDioClient(totalPages: 3, itemsPerPage: 2);
      final list = await BookingRepository(dioClient: stub).fetchAllBookings();

      expect(list, hasLength(6));
      expect(stub.requestedPages..sort(), [1, 2, 3]);
      expect(stub.queries.first['limit'], 100);
    });

    test('các trang sau trang đầu chạy đồng thời, không xếp hàng nối tiếp',
        () async {
      final stub = _PagingStubDioClient(totalPages: 4, itemsPerPage: 2);
      await BookingRepository(dioClient: stub).fetchAllBookings();

      expect(stub.requestedPages, hasLength(4));
      // Trang 1 chạy riêng để đọc meta, 3 trang còn lại phải chồng lên nhau.
      expect(stub.maxConcurrent, greaterThan(1));
    });

    test('chỉ gọi một request khi backend báo đúng một trang', () async {
      final stub = _PagingStubDioClient(totalPages: 1, itemsPerPage: 5);
      final list = await BookingRepository(dioClient: stub).fetchAllBookings();

      expect(list, hasLength(5));
      expect(stub.requestedPages, [1]);
    });

    test('maxPages chặn số trang tải về', () async {
      final stub = _PagingStubDioClient(totalPages: 20, itemsPerPage: 2);
      final list =
          await BookingRepository(dioClient: stub).fetchAllBookings(maxPages: 3);

      expect(stub.requestedPages, hasLength(3));
      expect(list, hasLength(6));
    });
  });

  group('Cache danh sách đơn trong phiên', () {
    test('lần gọi không kèm bộ lọc được cache lại cho màn Duyệt đơn', () async {
      final repo = BookingRepository(
        dioClient: _PagingStubDioClient(totalPages: 1, itemsPerPage: 3),
      );

      expect(repo.cachedBookings, isEmpty);
      expect(repo.cachedBookingsAt, isNull);

      await repo.fetchAllBookings();

      expect(repo.cachedBookings, hasLength(3));
      expect(repo.cachedBookingsAt, isNotNull);
    });

    test('lần gọi kèm bộ lọc không ghi đè cache "lấy tất cả"', () async {
      final repo = BookingRepository(
        dioClient: _PagingStubDioClient(totalPages: 1, itemsPerPage: 3),
      );

      await repo.fetchAllBookings();
      await repo.fetchAllBookings(status: 'PENDING');
      await repo.fetchAllBookings(search: 'Nguyễn');

      expect(repo.cachedBookings, hasLength(3));
    });

    test('duyệt đơn cập nhật luôn bản ghi trong cache', () async {
      const id = 'bk-p1-i0';
      final repo = BookingRepository(
        dioClient: _RoutingStubDioClient(
          {
            '/approve': {
              'success': true,
              'data': {'booking': _bookingJson(id: id, status: 'CONFIRMED')},
            },
          },
          fallback: {
            'success': true,
            'data': {
              'data': [_bookingJson(id: id)],
              'meta': {'total': 1, 'page': 1, 'limit': 100, 'totalPages': 1},
            },
          },
        ),
      );

      await repo.fetchAllBookings();
      expect(repo.cachedBookings.single.status, 'PENDING');

      await repo.approveBooking(id, depositAmount: 500000);

      expect(repo.cachedBookings.single.status, 'CONFIRMED');
    });

    test('clearSession xóa cache khi đổi tài khoản', () async {
      final repo = BookingRepository(
        dioClient: _PagingStubDioClient(totalPages: 1, itemsPerPage: 2),
      );
      await repo.fetchAllBookings();
      expect(repo.cachedBookings, hasLength(2));

      repo.clearSession();

      expect(repo.cachedBookings, isEmpty);
      expect(repo.cachedBookingsAt, isNull);
      expect(repo.pendingCount, 0);
    });
  });
}
