import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/booking_model.dart';
import '../models/checkout_preview_model.dart';
import '../models/invoice_model.dart';

class BookingRepository extends ChangeNotifier {
  final DioClient _dioClient;
  int _pendingCount = 0;
  PageMeta _lastMeta = const PageMeta();
  List<BookingModel> _cachedAll = [];
  DateTime? _cachedAllAt;

  int get pendingCount => _pendingCount;

  /// Thông tin phân trang của lần gọi [fetchBookings] gần nhất.
  PageMeta get lastMeta => _lastMeta;

  /// Danh sách của lần [fetchAllBookings] không kèm bộ lọc gần nhất.
  ///
  /// Màn "Duyệt đơn" vẽ ngay dữ liệu này rồi mới gọi API làm mới ngầm, nhờ vậy
  /// mở lại tab không phải nhìn khung skeleton thêm lần nữa.
  List<BookingModel> get cachedBookings => List.unmodifiable(_cachedAll);

  /// Thời điểm nạp [cachedBookings]; `null` khi phiên này chưa tải lần nào.
  DateTime? get cachedBookingsAt => _cachedAllAt;

  BookingRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// Xóa số liệu còn lại của tài khoản trước (huy hiệu "Duyệt đơn" trên thanh
  /// điều hướng đọc [pendingCount] nên nó phải về 0 khi đổi tài khoản).
  void clearSession() {
    _pendingCount = 0;
    _lastMeta = const PageMeta();
    _cachedAll = [];
    _cachedAllAt = null;
    notifyListeners();
  }

  /// Ghi đè một đơn trong cache sau khi duyệt / từ chối / nhận phòng để lần mở
  /// màn kế tiếp không vẽ lại trạng thái cũ.
  void _syncCache(BookingModel booking) {
    final idx = _cachedAll.indexWhere((b) => b.id == booking.id);
    if (idx != -1) {
      _cachedAll[idx] = booking;
      _cachedAllAt = DateTime.now();
    }
  }

  /// Định dạng ngày `YYYY-MM-DD` mà API dùng cho các bộ lọc khoảng ngày.
  static String _dateOnly(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Lấy danh sách booking: GET /bookings
  ///
  /// API mới trả về dạng phân trang `data: { data: [...], meta: {...} }` và hỗ
  /// trợ lọc nhiều trạng thái cùng lúc ([statuses]), lọc theo khoảng ngày nhận
  /// / trả phòng, tìm kiếm và phân trang.
  Future<List<BookingModel>> fetchBookings({
    String? status,
    List<String>? statuses,
    String? customerId,
    String? roomId,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int? page,
    int? limit,
  }) async {
    final statusFilter = _statusFilter(status, statuses);
    final result = await _fetchPage(
      status: status,
      statuses: statuses,
      customerId: customerId,
      roomId: roomId,
      checkInFrom: checkInFrom,
      checkInTo: checkInTo,
      checkOutFrom: checkOutFrom,
      checkOutTo: checkOutTo,
      search: search,
      page: page,
      limit: limit,
    );

    _lastMeta = result.meta;
    final bookings = result.items;

    if (statusFilter.length == 1 && statusFilter.first == 'PENDING') {
      _pendingCount = result.meta.total > 0 ? result.meta.total : bookings.length;
      notifyListeners();
    } else if (statusFilter.isEmpty) {
      _pendingCount = bookings.where((b) => b.status == 'PENDING').length;
      notifyListeners();
    }

    return bookings;
  }

  /// Lấy một trang danh sách booking kèm thông tin phân trang chuẩn:
  /// GET /bookings?status=...&page=...&limit=...
  Future<PaginatedResult<BookingModel>> fetchBookingsPage({
    String? status,
    List<String>? statuses,
    String? customerId,
    String? roomId,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _fetchPage(
      status: status,
      statuses: statuses,
      customerId: customerId,
      roomId: roomId,
      checkInFrom: checkInFrom,
      checkInTo: checkInTo,
      checkOutFrom: checkOutFrom,
      checkOutTo: checkOutTo,
      search: search,
      page: page,
      limit: limit,
    );
    _lastMeta = result.meta;
    return PaginatedResult<BookingModel>(items: result.items, meta: result.meta);
  }

  /// API nhận `?status=PENDING,CONFIRMED` hoặc lặp lại tham số.
  static List<String> _statusFilter(String? status, List<String>? statuses) => [
        if (status != null && status.isNotEmpty) status,
        ...?statuses,
      ];

  /// Gọi GET /bookings cho đúng một trang và trả kèm `meta`.
  ///
  /// Không đụng vào [_lastMeta] / [_pendingCount] nên nhiều trang có thể chạy
  /// song song mà không giẫm lên state dùng chung của repository.
  Future<({List<BookingModel> items, PageMeta meta})> _fetchPage({
    String? status,
    List<String>? statuses,
    String? customerId,
    String? roomId,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final statusFilter = _statusFilter(status, statuses);

      final queryParams = <String, dynamic>{
        if (statusFilter.isNotEmpty) 'status': statusFilter.join(','),
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (checkInFrom != null) 'checkInFrom': _dateOnly(checkInFrom),
        if (checkInTo != null) 'checkInTo': _dateOnly(checkInTo),
        if (checkOutFrom != null) 'checkOutFrom': _dateOnly(checkOutFrom),
        if (checkOutTo != null) 'checkOutTo': _dateOnly(checkOutTo),
        if (search != null && search.isNotEmpty) 'search': search,
        'page': ?page,
        'limit': ?limit,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.bookings,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final paged = ApiResult.unwrapPage(res);
      return (
        items: paged.items.map((e) => BookingModel.fromJson(e)).toList(),
        meta: paged.meta,
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải toàn bộ đơn khớp bộ lọc bằng cách duyệt hết các trang.
  ///
  /// API mới mặc định chỉ trả 20 bản ghi mỗi trang, nên các màn hình tự chia
  /// tab / lọc phía client phải gom đủ dữ liệu trước khi hiển thị.
  /// Trang đầu cho biết `meta.totalPages`, các trang còn lại được gọi song song
  /// thay vì nối tiếp — trước đây 5 trang là 5 lần chờ round-trip cộng dồn.
  /// [maxPages] chặn số trang tối đa để không treo UI với dữ liệu quá lớn.
  Future<List<BookingModel>> fetchAllBookings({
    String? status,
    List<String>? statuses,
    String? customerId,
    String? roomId,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    DateTime? checkOutFrom,
    DateTime? checkOutTo,
    String? search,
    int maxPages = 10,
  }) async {
    const pageSize = 100; // Giới hạn tối đa mỗi trang theo tài liệu API

    Future<({List<BookingModel> items, PageMeta meta})> loadPage(int page) {
      return _fetchPage(
        status: status,
        statuses: statuses,
        customerId: customerId,
        roomId: roomId,
        checkInFrom: checkInFrom,
        checkInTo: checkInTo,
        checkOutFrom: checkOutFrom,
        checkOutTo: checkOutTo,
        search: search,
        page: page,
        limit: pageSize,
      );
    }

    final first = await loadPage(1);
    _lastMeta = first.meta;

    final all = <BookingModel>[...first.items];
    final lastPage =
        first.meta.totalPages < maxPages ? first.meta.totalPages : maxPages;

    if (first.items.isNotEmpty && lastPage > 1) {
      final rest = await Future.wait([
        for (var page = 2; page <= lastPage; page++) loadPage(page),
      ]);
      for (final batch in rest) {
        all.addAll(batch.items);
      }
    }

    final statusFilter = _statusFilter(status, statuses);
    if (statusFilter.isEmpty) {
      _pendingCount = all.where((b) => b.status == 'PENDING').length;
      notifyListeners();
    }

    // Chỉ cache lần gọi "lấy tất cả" thật sự, vì đây là dữ liệu màn Duyệt đơn
    // dùng lại; các lần gọi kèm bộ lọc là tập con nên không được ghi đè.
    final isUnfiltered = statusFilter.isEmpty &&
        (customerId == null || customerId.isEmpty) &&
        (roomId == null || roomId.isEmpty) &&
        checkInFrom == null &&
        checkInTo == null &&
        checkOutFrom == null &&
        checkOutTo == null &&
        (search == null || search.isEmpty);
    if (isUnfiltered) {
      _cachedAll = List.of(all);
      _cachedAllAt = DateTime.now();
    }

    return all;
  }

  /// Lấy danh sách đơn chờ xác nhận: GET /bookings?status=PENDING
  Future<List<BookingModel>> fetchPending() async {
    final list = await fetchAllBookings(status: 'PENDING');
    _pendingCount = list.length;
    notifyListeners();
    return list;
  }

  /// Lấy danh sách nhận phòng hôm nay:
  /// GET /bookings?status=CONFIRMED&checkInFrom=hôm nay&checkInTo=hôm nay
  Future<List<BookingModel>> fetchTodayCheckIns() async {
    final now = DateTime.now();
    return fetchAllBookings(
      status: 'CONFIRMED',
      checkInFrom: now,
      checkInTo: now,
    );
  }

  /// Lấy danh sách trả phòng hôm nay (gồm cả đơn quá hạn trả phòng):
  /// GET /bookings?status=CHECKED_IN&checkOutTo=hôm nay
  Future<List<BookingModel>> fetchTodayCheckOuts() async {
    final now = DateTime.now();
    return fetchAllBookings(
      status: 'CHECKED_IN',
      checkOutTo: now,
    );
  }

  /// Lấy chi tiết đơn đặt phòng: GET /bookings/:id
  Future<BookingModel> fetchDetail(String id) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.bookingDetail(id));
      final data = ApiResult.unwrapMap(res);
      return BookingModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tạo đơn đặt phòng: POST /bookings (gồm depositAmount)
  Future<BookingModel> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.bookings,
        data: payload,
      );
      final data = ApiResult.unwrapMap(res);
      return BookingModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Nhận phòng: POST /bookings/:id/check-in
  Future<BookingModel> checkIn(String id) async {
    try {
      final res = await _dioClient.dio.post(ApiEndpoints.checkIn(id));
      final data = ApiResult.unwrapMap(res);
      final booking = BookingModel.fromJson(data);
      _syncCache(booking);
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Bảng kê & số còn phải thu trước khi trả phòng:
  /// GET /bookings/:id/checkout-preview
  ///
  /// Chỉ đọc — không đổi trạng thái đơn hay phòng, nên gọi được nhiều lần khi
  /// thu ngân sửa giảm giá / VAT trên sheet.
  Future<CheckoutPreviewModel> fetchCheckOutPreview(String id) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.checkOutPreview(id));
      final data = ApiResult.unwrapMap(res);
      return CheckoutPreviewModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Trả phòng & xuất hóa đơn: POST /bookings/:id/check-out
  /// Server trả về cả Booking và Invoice.
  ///
  /// [amountCollected] là số thu ngân **thực nhận** tại quầy. Bỏ trống nghĩa là
  /// không thu thêm: khách vẫn được trả phòng (phòng sang `CLEANING`), hóa đơn
  /// ở `PARTIAL`/`UNPAID` và tự xuất hiện trong `GET /invoices/my` với
  /// `remainingAmount > 0`, `canRequestPayment: true` để khách trả sau qua app.
  Future<(BookingModel, InvoiceModel)> checkOut(
    String id, {
    String paymentMethod = 'CASH',
    num? discount,
    num? taxRate,
    num? amountCollected,
  }) async {
    try {
      final payload = {
        'paymentMethod': paymentMethod,
        'discount': ?discount,
        'taxRate': ?taxRate,
        'amountCollected': ?amountCollected,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.checkOut(id),
        data: payload,
      );

      final data = ApiResult.unwrapMap(res);
      final bookingMap = data['booking'] is Map
          ? Map<String, dynamic>.from(data['booking'] as Map)
          : data;
      final invoiceMap = data['invoice'] is Map
          ? Map<String, dynamic>.from(data['invoice'] as Map)
          : <String, dynamic>{};

      return (
        BookingModel.fromJson(bookingMap),
        InvoiceModel.fromJson(invoiceMap),
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Hủy đơn: POST /bookings/:id/cancel
  Future<BookingModel> cancel(String id, {String? reason}) async {
    try {
      final payload = {
        if (reason != null && reason.isNotEmpty) 'cancellationReason': reason,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.cancelBooking(id),
        data: payload,
      );

      final data = ApiResult.unwrapMap(res);
      final booking = BookingModel.fromJson(data);
      _syncCache(booking);
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Ghi nhận dịch vụ phát sinh: POST /bookings/:id/services
  Future<void> addService(
    String id, {
    required String serviceName,
    required num unitPrice,
    int quantity = 1,
  }) async {
    try {
      final payload = {
        'serviceName': serviceName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.addServices(id),
        data: payload,
      );
      ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Phê duyệt đơn đặt phòng & xác nhận tiền cọc: PATCH /bookings/:id/approve
  ///
  /// API mới trả về `data: { message, depositAmount, booking: {...} }` nên phải
  /// bóc thêm một lớp `booking`.
  Future<BookingModel> approveBooking(
    String id, {
    num? depositAmount,
    String paymentMethod = 'CASH',
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (depositAmount != null && depositAmount > 0) 'depositAmount': depositAmount,
        'paymentMethod': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await _dioClient.dio.patch(
        ApiEndpoints.approveBooking(id),
        data: payload,
      );
      final booking =
          BookingModel.fromJson(ApiResult.unwrapNestedMap(res, 'booking'));

      _syncCache(booking);
      _decreasePendingCount();
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Xác nhận đơn khách tự đặt (PENDING -> CONFIRMED): PATCH /bookings/:id/confirm
  ///
  /// Khác với [approveBooking], API này cho phép lễ tân xếp lại phòng cho khách
  /// qua [assignedRoomId] và ghi chú xác nhận qua [note].
  Future<BookingModel> confirmBooking(
    String id, {
    String? assignedRoomId,
    String? note,
    num? depositAmount,
    String? paymentMethod,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (assignedRoomId != null && assignedRoomId.isNotEmpty)
          'assignedRoomId': assignedRoomId,
        if (note != null && note.isNotEmpty) 'note': note,
        if (depositAmount != null && depositAmount > 0)
          'depositAmount': depositAmount,
        // paymentMethod chỉ có ý nghĩa khi thực sự thu cọc
        if (depositAmount != null &&
            depositAmount > 0 &&
            paymentMethod != null &&
            paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
      };

      final res = await _dioClient.dio.patch(
        ApiEndpoints.confirmBooking(id),
        data: payload,
      );
      final booking =
          BookingModel.fromJson(ApiResult.unwrapNestedMap(res, 'booking'));

      _syncCache(booking);
      _decreasePendingCount();
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Từ chối đơn đặt phòng: PATCH /bookings/:id/reject
  Future<BookingModel> rejectBooking(
    String id, {
    required String reason,
  }) async {
    try {
      final payload = <String, dynamic>{
        'reason': reason,
        // API chấp nhận cả hai tên trường, gửi kèm alias cho chắc chắn.
        'cancellationReason': reason,
      };

      final res = await _dioClient.dio.patch(
        ApiEndpoints.rejectBooking(id),
        data: payload,
      );
      final booking =
          BookingModel.fromJson(ApiResult.unwrapNestedMap(res, 'booking'));

      _syncCache(booking);
      _decreasePendingCount();
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  void _decreasePendingCount() {
    if (_pendingCount > 0) {
      _pendingCount--;
      notifyListeners();
    }
  }

  /// Đổi phòng cho khách đang lưu trú (S2): POST /bookings/:id/change-room
  Future<BookingModel> changeRoom(
    String bookingId, {
    required String newRoomId,
    required String reason,
    bool keepPrice = true,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.changeRoom(bookingId),
        data: {
          'newRoomId': newRoomId,
          'reason': reason,
          'keepPrice': keepPrice,
        },
      );
      final data = ApiResult.unwrapMap(res);
      // API may return { booking: {...} } or {...} directly
      final bookingData = data.containsKey('booking') ? data['booking'] : data;
      final booking = BookingModel.fromJson(bookingData);
      _syncCache(booking);
      return booking;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Khách hàng gửi yêu cầu dịch vụ phòng (C1): POST /bookings/:id/service-requests
  Future<dynamic> requestService(
    String bookingId, {
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.serviceRequests(bookingId),
        data: {
          'items': items,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Cập nhật trạng thái yêu cầu dịch vụ (CONFIRMED / REJECTED): PATCH /bookings/:id/services/:orderId
  Future<dynamic> updateServiceRequest(
    String bookingId,
    String orderId, {
    required String status,
    String? reason,
  }) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.updateServiceRequest(bookingId, orderId),
        data: {
          'status': status,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
