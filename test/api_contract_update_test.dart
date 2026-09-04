import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/api_result.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/models/dashboard_stats.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/analytics_repository.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/upload_repository.dart';

/// DioClient giả lập, trả về đúng payload mà API hiện tại đang trả về
/// (theo https://hotel-management-plsp.onrender.com/api/docs).
class _StubDioClient implements DioClient {
  final Map<String, dynamic> responses;
  final List<RequestOptions> requests = [];

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) => dio.options.baseUrl = newUrl;

  _StubDioClient(this.responses) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final key = responses.keys.firstWhere(
              (k) => options.path.contains(k),
              orElse: () => '',
            );
            if (key.isEmpty) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: 404),
                ),
              );
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: responses[key],
              ),
            );
          },
        ),
      );
  }
}

Map<String, dynamic> _bookingJson({String status = 'PENDING'}) => {
  'id': 'b1e4c7a2',
  'bookingCode': 'BK-2026-0829',
  'customerId': 'cus-1',
  'roomId': 'room-1',
  'checkInDate': '2026-09-05T14:00:00.000Z',
  'checkOutDate': '2026-09-08T12:00:00.000Z',
  'guestCount': 2,
  'totalAmount': 3600000,
  'depositAmount': 500000,
  'status': status,
  'room': {
    'roomNumber': '101',
    'floor': 1,
    'roomType': {'name': 'Phòng Deluxe Hướng Biển', 'basePrice': 1200000},
  },
  'customer': {
    'fullName': 'Nguyễn Văn Khách Hàng',
    'phone': '0912345678',
    'email': 'customer@hotel.com',
  },
};

void main() {
  group('GET /bookings — envelope phân trang mới', () {
    test('unwrapPage bóc được data.data kèm data.meta', () {
      final res = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.bookings),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'data': [_bookingJson()],
            'meta': {'total': 42, 'page': 1, 'limit': 20, 'totalPages': 3},
          },
        },
      );

      final paged = ApiResult.unwrapPage(res);
      expect(paged.items, hasLength(1));
      expect(paged.meta.total, 42);
      expect(paged.meta.totalPages, 3);
      expect(paged.meta.hasNextPage, isTrue);
    });

    test('unwrapList vẫn đọc được mảng phẳng lẫn envelope phân trang', () {
      RequestOptions opts() => RequestOptions(path: ApiEndpoints.bookings);

      final flat = Response(
        requestOptions: opts(),
        statusCode: 200,
        data: {'success': true, 'data': [_bookingJson()]},
      );
      final paginated = Response(
        requestOptions: opts(),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'data': [_bookingJson(), _bookingJson()],
            'meta': {'total': 2, 'page': 1, 'limit': 20, 'totalPages': 1},
          },
        },
      );

      expect(ApiResult.unwrapList(flat), hasLength(1));
      expect(ApiResult.unwrapList(paginated), hasLength(2));
    });

    test('fetchBookings gửi đúng bộ lọc status gộp và khoảng ngày', () async {
      final stub = _StubDioClient({
        ApiEndpoints.bookings: {
          'success': true,
          'data': {
            'data': [_bookingJson(status: 'CHECKED_IN')],
            'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
          },
        },
      });

      final repo = BookingRepository(dioClient: stub);
      final list = await repo.fetchBookings(
        statuses: ['CONFIRMED', 'CHECKED_IN'],
        checkOutTo: DateTime(2026, 9, 4),
      );

      expect(list, hasLength(1));
      final query = stub.requests.single.queryParameters;
      expect(query['status'], 'CONFIRMED,CHECKED_IN');
      expect(query['checkOutTo'], '2026-09-04');
    });
  });

  group('Duyệt / xác nhận / từ chối đơn — response bọc trong data.booking', () {
    test('approveBooking đọc được booking lồng trong data', () async {
      final stub = _StubDioClient({
        '/approve': {
          'success': true,
          'data': {
            'message': 'Phê duyệt đơn đặt phòng và xác nhận tiền cọc thành công',
            'depositAmount': 500000,
            'booking': _bookingJson(status: 'CONFIRMED'),
          },
        },
      });

      final booking = await BookingRepository(dioClient: stub).approveBooking(
        'b1e4c7a2',
        depositAmount: 500000,
      );

      expect(booking.id, 'b1e4c7a2');
      expect(booking.status, 'CONFIRMED');
      expect(booking.customerName, 'Nguyễn Văn Khách Hàng');
    });

    test('confirmBooking gửi assignedRoomId và đọc booking đã xác nhận', () async {
      final confirmed = _bookingJson(status: 'CONFIRMED')
        ..['confirmedAt'] = '2026-09-04T03:12:00.000Z'
        ..['confirmedBy'] = {
          'id': 'user-le-tan',
          'fullName': 'Lê Thu Hà (Lễ Tân)',
          'role': 'RECEPTIONIST',
        }
        ..['confirmationNote'] = 'Khách đã chuyển khoản cọc';

      final stub = _StubDioClient({
        '/confirm': {
          'success': true,
          'data': {
            'message': 'Xác nhận đơn đặt phòng thành công',
            'depositAmount': 500000,
            'booking': confirmed,
          },
        },
      });

      final booking = await BookingRepository(dioClient: stub).confirmBooking(
        'b1e4c7a2',
        assignedRoomId: 'room-9',
        note: 'Xếp phòng tầng cao',
      );

      expect(stub.requests.single.path, ApiEndpoints.confirmBooking('b1e4c7a2'));
      expect(stub.requests.single.method, 'PATCH');
      expect(
        (stub.requests.single.data as Map)['assignedRoomId'],
        'room-9',
      );
      expect(booking.status, 'CONFIRMED');
      expect(booking.confirmedByName, 'Lê Thu Hà (Lễ Tân)');
      expect(booking.confirmationNote, 'Khách đã chuyển khoản cọc');
    });
  });

  group('BookingModel — trường nhật ký duyệt / hủy đơn', () {
    test('đọc được cancelledBy dạng object', () {
      final booking = BookingModel.fromJson(
        _bookingJson(status: 'CANCELLED')
          ..['cancellationReason'] = 'Khách báo bận công tác'
          ..['cancelledAt'] = '2026-09-04T03:20:00.000Z'
          ..['cancelledBy'] = {
            'id': 'cus-1',
            'fullName': 'Nguyễn Văn Khách Hàng',
            'role': 'CUSTOMER',
          },
      );

      expect(booking.cancellationReason, 'Khách báo bận công tác');
      expect(booking.cancelledById, 'cus-1');
      expect(booking.cancelledByName, 'Nguyễn Văn Khách Hàng');
      expect(booking.cancelledAt, isNotNull);
      expect(booking.customerEmail, 'customer@hotel.com');
    });

    test('đọc được confirmedById dạng chuỗi id phẳng', () {
      final booking = BookingModel.fromJson(
        _bookingJson(status: 'CONFIRMED')
          ..['confirmedById'] = 'user-le-tan'
          ..['confirmedAt'] = '2026-09-04T03:12:00.000Z',
      );

      expect(booking.confirmedById, 'user-le-tan');
      expect(booking.confirmedAt, isNotNull);
    });
  });

  group('RoomModel — dữ liệu phòng mở rộng', () {
    test('đọc được currentBooking cho sơ đồ phòng', () {
      final room = RoomModel.fromJson({
        'id': 'room-1',
        'roomNumber': '101',
        'floor': 1,
        'status': 'OCCUPIED',
        'pricePerNight': 650000,
        'currentBooking': {
          'id': 'bk-1',
          'bookingCode': 'BK-63848278',
          'guestName': 'Nguyen Van A',
          'guestPhone': '0987654321',
          'checkOutDate': '2026-09-04T08:20:31.843Z',
        },
      });

      expect(room.currentBooking, isNotNull);
      expect(room.currentBooking!.guestName, 'Nguyen Van A');
      expect(room.currentBooking!.bookingCode, 'BK-63848278');
      expect(room.currentBooking!.checkOutDate, isNotNull);
    });

    test('images rơi về image/imageUrl khi mảng images rỗng', () {
      final room = RoomModel.fromJson({
        'id': 'room-1',
        'roomNumber': '101',
        'floor': 1,
        'status': 'AVAILABLE',
        'pricePerNight': 650000,
        'images': [],
        'image': 'https://cdn.test/room-101.webp',
      });

      expect(room.images, ['https://cdn.test/room-101.webp']);
    });
  });

  group('Analytics — doanh thu theo ngày trả về object, không phải mảng', () {
    test('revenueDailySeries bóc đúng khóa series', () async {
      final stub = _StubDioClient({
        ApiEndpoints.analyticsRevenueDaily: {
          'success': true,
          'data': {
            'range': 7,
            'from': '2026-08-28',
            'to': '2026-09-03',
            'total': 756000000,
            'series': [
              {
                'date': '2026-08-28',
                'label': 'T6',
                'dateLabel': '28/08',
                'revenue': 96200000,
                'amount': 96200000,
                'invoiceCount': 4,
              },
              {
                'date': '2026-08-29',
                'label': 'T7',
                'dateLabel': '29/08',
                'revenue': 112400000,
                'amount': 112400000,
                'invoiceCount': 6,
              },
            ],
          },
        },
      });

      final series =
          await AnalyticsRepository(dioClient: stub).revenueDailySeries(range: 7);

      expect(series, hasLength(2));
      expect(series.first['revenue'], 96200000);
      expect(stub.requests.single.queryParameters['range'], 7);
    });

    test('DashboardStats đọc được cả số lẫn chuỗi phần trăm', () {
      final stats = DashboardStats.fromJson({
        'todayRevenue': 15400000,
        'yesterdayRevenue': 13700000,
        'revenueChangePercent': 12.4,
        'todayCheckIns': 4,
        'todayCheckOuts': 2,
        'activeBookings': 12,
        'pendingBookings': 4,
        'unpaidInvoices': 3,
        'totalRevenue': 145000000,
        'rooms': {
          'total': 20,
          'available': 6,
          'occupied': 10,
          'reserved': 2,
          'cleaning': 1,
          'maintenance': 1,
          'occupancyRate': '50.0%',
        },
      });

      expect(stats.totalRooms, 20);
      expect(stats.availableRooms, 6);
      expect(stats.maintenanceRooms, 1);
      expect(stats.occupancyRate, 50.0);
      expect(stats.activeBookings, 12);
      expect(stats.unpaidInvoices, 3);
      expect(stats.yesterdayRevenue, 13700000);
    });
  });

  group('Upload — album ảnh phòng trả về object chứa urls', () {
    test('uploadRoomImages bóc danh sách urls', () async {
      final stub = _StubDioClient({
        ApiEndpoints.uploadRooms: {
          'success': true,
          'data': {
            'type': 'room',
            'folder': 'rooms',
            'image': 'https://cdn.test/1.webp',
            'images': ['https://cdn.test/1.webp', 'https://cdn.test/2.webp'],
            'urls': ['https://cdn.test/1.webp', 'https://cdn.test/2.webp'],
            'files': [
              {'url': 'https://cdn.test/1.webp', 'path': 'rooms/1'},
            ],
          },
        },
      });

      // Không có tệp thật nên gọi thẳng lớp bóc dữ liệu qua repository rỗng.
      final repo = UploadRepository(dioClient: stub);
      final urls = await repo.uploadRoomImages([], roomId: 'room-1');

      expect(urls, [
        'https://cdn.test/1.webp',
        'https://cdn.test/2.webp',
      ]);
    });
  });

  group('ApiEndpoints — tuyến mới của API', () {
    test('có đủ confirm booking và đồng bộ trạng thái phòng', () {
      expect(ApiEndpoints.confirmBooking('123'), '/bookings/123/confirm');
      expect(ApiEndpoints.roomsSyncStatus, '/rooms/sync-status');
      expect(ApiEndpoints.users, '/users');
    });
  });
}
