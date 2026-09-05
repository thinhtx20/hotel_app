import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final DioClient _dioClient;
  List<ServiceModel> _cachedServices = [];

  ServiceRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<ServiceModel> get cachedServices => List.unmodifiable(_cachedServices);

  /// Xóa cache dịch vụ của tài khoản trước.
  void clearSession() {
    _cachedServices = [];
  }

  /// Lấy danh mục dịch vụ gia tăng (GET /services), có lưu cache bộ nhớ
  Future<List<ServiceModel>> fetchServices({bool forceRefresh = false}) async {
    if (_cachedServices.isNotEmpty && !forceRefresh) {
      return _cachedServices;
    }

    try {
      final res = await _dioClient.dio.get(ApiEndpoints.services);
      final list = ApiResult.unwrapList(res);
      _cachedServices = list.map((e) => ServiceModel.fromJson(e)).toList();
      return _cachedServices;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tạo dịch vụ mới (A2 - Chỉ Admin): POST /services
  Future<ServiceModel> createService(Map<String, dynamic> payload) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.hotelServices,
        data: payload,
      );
      final data = ApiResult.unwrapMap(res);
      final item = ServiceModel.fromJson(data);
      _cachedServices.add(item);
      return item;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Cập nhật dịch vụ (A2 - Chỉ Admin): PATCH /services/:id
  Future<ServiceModel> updateService(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.serviceDetail(id),
        data: payload,
      );
      final data = ApiResult.unwrapMap(res);
      final item = ServiceModel.fromJson(data);
      final idx = _cachedServices.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _cachedServices[idx] = item;
      }
      return item;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Xóa dịch vụ (A2 - Chỉ Admin): DELETE /services/:id
  Future<void> deleteService(String id) async {
    try {
      await _dioClient.dio.delete(ApiEndpoints.serviceDetail(id));
      _cachedServices.removeWhere((s) => s.id == id);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
