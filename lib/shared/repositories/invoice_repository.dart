import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final DioClient _dioClient;
  PageMeta? _lastMeta;

  InvoiceRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  PageMeta? get lastMeta => _lastMeta;

  /// Lấy một trang danh sách hóa đơn toàn khách sạn kèm thông tin phân trang:
  /// GET /invoices?status=...&search=...&page=...&limit=...
  Future<PaginatedResult<InvoiceModel>> fetchInvoicesPage({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
    String? filterType,
    int? year,
    int? fromMonth,
    int? toMonth,
    int? month,
    int? weekOffset,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'filterType': ?filterType,
        'year': ?year,
        'fromMonth': ?fromMonth,
        'toMonth': ?toMonth,
        'month': ?month,
        'weekOffset': ?weekOffset,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'page': page,
        'limit': limit,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoices,
        queryParameters: queryParams,
      );

      final paged = ApiResult.unwrapPaginatedList(res, InvoiceModel.fromJson);
      _lastMeta = paged.meta;
      return paged;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy toàn bộ hóa đơn khách sạn theo tuần hoặc theo tháng/năm: GET /invoices
  Future<List<InvoiceModel>> fetchAll({
    String? status,
    String? search,
    String? filterType,
    int? year,
    int? fromMonth,
    int? toMonth,
    int? month,
    int? weekOffset,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'filterType': ?filterType,
        'year': ?year,
        'fromMonth': ?fromMonth,
        'toMonth': ?toMonth,
        'month': ?month,
        'weekOffset': ?weekOffset,
        'startDate': ?startDate,
        'endDate': ?endDate,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoices,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final paged = ApiResult.unwrapPaginatedList(res, InvoiceModel.fromJson);
      _lastMeta = paged.meta;
      return paged.items;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải gom song song toàn bộ hóa đơn qua nhiều trang (tối đa [maxPages] trang).
  Future<List<InvoiceModel>> fetchAllInvoices({
    String? status,
    String? search,
    int maxPages = 10,
    String? filterType,
    int? year,
    int? fromMonth,
    int? toMonth,
    int? month,
    int? weekOffset,
    String? startDate,
    String? endDate,
  }) async {
    const pageSize = 100;
    final first = await fetchInvoicesPage(
      status: status,
      search: search,
      page: 1,
      limit: pageSize,
      filterType: filterType,
      year: year,
      fromMonth: fromMonth,
      toMonth: toMonth,
      month: month,
      weekOffset: weekOffset,
      startDate: startDate,
      endDate: endDate,
    );

    final all = <InvoiceModel>[...first.items];
    final lastPage =
        first.meta.totalPages < maxPages ? first.meta.totalPages : maxPages;

    if (first.items.isNotEmpty && lastPage > 1) {
      final rest = await Future.wait([
        for (var p = 2; p <= lastPage; p++)
          fetchInvoicesPage(
            status: status,
            search: search,
            page: p,
            limit: pageSize,
            filterType: filterType,
            year: year,
            fromMonth: fromMonth,
            toMonth: toMonth,
            month: month,
            weekOffset: weekOffset,
            startDate: startDate,
            endDate: endDate,
          ),
      ]);
      for (final batch in rest) {
        all.addAll(batch.items);
      }
    }

    return all;
  }

  /// Lấy một trang hóa đơn của chính tài khoản đang đăng nhập: GET /invoices/my
  Future<PaginatedResult<InvoiceModel>> fetchMyPage({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoicesMy,
        queryParameters: queryParams,
      );

      final paged = ApiResult.unwrapPaginatedList(res, InvoiceModel.fromJson);
      _lastMeta = paged.meta;
      return paged;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy hóa đơn của chính tài khoản đang đăng nhập: GET /invoices/my
  Future<List<InvoiceModel>> fetchMy({String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoicesMy,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final paged = ApiResult.unwrapPaginatedList(res, InvoiceModel.fromJson);
      _lastMeta = paged.meta;
      return paged.items;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Chi tiết hóa đơn: GET /invoices/:id
  Future<InvoiceModel> fetchDetail(String id) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.invoiceDetail(id));
      final data = ApiResult.unwrapMap(res);
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tổng kết hóa đơn theo ngày: GET /invoices/summary?date=
  Future<Map<String, dynamic>> fetchSummary({DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{
        if (date != null) 'date': date.toIso8601String().split('T').first,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoiceSummary,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tạo hóa đơn thủ công: POST /invoices (ADMIN, CASHIER)
  Future<InvoiceModel> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.invoices,
        data: payload,
      );

      final data = ApiResult.unwrapMap(res);
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Ghi nhận thanh toán: POST /invoices/:id/pay
  Future<InvoiceModel> pay(
    String id, {
    required num amount,
    required String paymentMethod,
    String? paymentStatus,
    String? notes,
  }) async {
    try {
      final payload = {
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentStatus': ?paymentStatus,
        'notes': ?notes,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.payInvoice(id),
        data: payload,
      );

      final data = ApiResult.unwrapMap(res);
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Hoàn tiền hóa đơn: POST /invoices/:id/refund (S4)
  Future<InvoiceModel> refund(
    String invoiceId, {
    required num amount,
    required String reason,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.invoiceRefund(invoiceId),
        data: {
          'amount': amount,
          'reason': reason,
        },
      );

      final data = ApiResult.unwrapMap(res);
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Khách xin thanh toán số còn lại: POST /invoices/:id/payment-requests
  ///
  /// Bỏ trống [amount] nghĩa là trả toàn bộ số còn lại — đúng nút "Thanh toán
  /// toàn bộ". Tiền chưa vào két: backend chỉ tạo một dòng `PENDING` trong sổ
  /// thu tiền, `paidAmount` chỉ tăng sau khi lễ tân xác nhận qua
  /// [confirmPayment]. Mỗi hóa đơn chỉ treo được một yêu cầu tại một thời
  /// điểm, và backend chặn mọi yêu cầu vượt số còn lại.
  Future<PaymentRequestModel> createPaymentRequest(
    String invoiceId, {
    num? amount,
    String? paymentMethod = 'BANK_TRANSFER',
    String? notes,
  }) async {
    try {
      final effectiveMethod =
          (paymentMethod != null && paymentMethod.trim().isNotEmpty)
              ? paymentMethod.trim()
              : 'BANK_TRANSFER';
      final payload = <String, dynamic>{
        'amount': ?amount,
        'paymentMethod': effectiveMethod,
        'notes': ?notes,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.invoicePaymentRequest(invoiceId),
        data: payload,
      );

      final data = ApiResult.unwrapMap(res);
      final request = PaymentRequestModel.fromJson(data);
      // Phản hồi có thể chỉ chứa dòng thanh toán, chưa kèm id hóa đơn.
      if (request.invoiceId.isEmpty) {
        return PaymentRequestModel(
          payment: request.payment,
          invoiceId: invoiceId,
          invoiceCode: request.invoiceCode,
          bookingId: request.bookingId,
          customerName: request.customerName,
          roomNumber: request.roomNumber,
          finalAmount: request.finalAmount,
          paidAmount: request.paidAmount,
          remainingAmount: request.remainingAmount,
        );
      }
      return request;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Danh sách yêu cầu khách gửi qua app, chờ lễ tân đối chiếu sao kê:
  /// GET /invoices/payment-requests
  Future<List<PaymentRequestModel>> fetchPaymentRequests({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoicePaymentRequests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final list = ApiResult.unwrapList(res);
      return list.map(PaymentRequestModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lễ tân xác nhận đã nhận tiền của một dòng `PENDING`:
  /// POST /invoices/payments/:paymentId/confirm
  ///
  /// Đây là bước duy nhất làm `paidAmount` tăng cho tiền khách trả qua app.
  Future<InvoiceModel> confirmPayment(
    String paymentId, {
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'paymentMethod': ?paymentMethod,
        'notes': ?notes,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.confirmInvoicePayment(paymentId),
        data: payload.isNotEmpty ? payload : null,
      );

      final data = ApiResult.unwrapNestedMap(res, 'invoice');
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tổng kết ca trực cá nhân: GET /invoices/summary?date=...&staffId=me (S1)
  Future<Map<String, dynamic>> getShiftSummary({
    String? date,
    String staffId = 'me',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'staffId': staffId,
        if (date != null && date.isNotEmpty) 'date': date,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoiceSummary,
        queryParameters: queryParams,
      );

      return ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
