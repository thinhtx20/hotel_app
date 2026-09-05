import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final DioClient _dioClient;

  InvoiceRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// Lấy toàn bộ hóa đơn khách sạn: GET /invoices
  Future<List<InvoiceModel>> fetchAll({String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.invoices,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final list = ApiResult.unwrapList(res);
      return list.map((e) => InvoiceModel.fromJson(e)).toList();
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

      final list = ApiResult.unwrapList(res);
      return list.map((e) => InvoiceModel.fromJson(e)).toList();
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
