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
}
