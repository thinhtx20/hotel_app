import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/work_shift_model.dart';

class ShiftRepository {
  final DioClient _dioClient;

  ShiftRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// Lấy danh sách các ca trực đang mở tại quầy (GET /shifts/active)
  Future<List<WorkShiftModel>> getActiveShifts() async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.shiftsActive);
      final list = ApiResult.unwrapList(res);
      return list.map((item) => WorkShiftModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy thông tin ca trực hiện tại của nhân viên đang đăng nhập (GET /shifts/current)
  Future<WorkShiftModel?> getCurrentShift() async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.shiftsCurrent);
      final data = ApiResult.unwrapMap(res);
      if (data.isEmpty || data['id'] == null) return null;
      return WorkShiftModel.fromJson(data);
    } on DioException catch (e) {
      // 404 nghĩa là nhân viên chưa mở ca
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Mở ca trực tại quầy (POST /shifts/open)
  Future<WorkShiftModel> openShift({
    required ShiftType shiftType,
    required double initialCash,
    String? deskName,
    String? note,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.shiftsOpen,
        data: {
          'shiftType': shiftType.value,
          'initialCash': initialCash,
          if (deskName != null && deskName.trim().isNotEmpty)
            'deskName': deskName.trim(),
          if (note != null && note.trim().isNotEmpty)
            'note': note.trim(),
        },
      );
      final data = ApiResult.unwrapMap(res);
      return WorkShiftModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Chốt ca trực cá nhân (POST /shifts/close)
  Future<WorkShiftModel> closeShift({
    required double actualCash,
    String? closeNote,
    String? differenceReason,
    String? handoverStaffId,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.shiftsClose,
        data: {
          'actualCash': actualCash,
          if (closeNote != null && closeNote.trim().isNotEmpty)
            'closeNote': closeNote.trim(),
          if (differenceReason != null && differenceReason.trim().isNotEmpty)
            'differenceReason': differenceReason.trim(),
          if (handoverStaffId != null && handoverStaffId.trim().isNotEmpty)
            'handoverStaffId': handoverStaffId.trim(),
        },
      );
      final data = ApiResult.unwrapMap(res);
      return WorkShiftModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Quản trị viên chốt ca hộ cho nhân viên (POST /shifts/:id/close)
  Future<WorkShiftModel> adminCloseShift(
    String shiftId, {
    required double actualCash,
    String? closeNote,
    String? differenceReason,
    String? handoverStaffId,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.adminCloseShift(shiftId),
        data: {
          'actualCash': actualCash,
          if (closeNote != null && closeNote.trim().isNotEmpty)
            'closeNote': closeNote.trim(),
          if (differenceReason != null && differenceReason.trim().isNotEmpty)
            'differenceReason': differenceReason.trim(),
          if (handoverStaffId != null && handoverStaffId.trim().isNotEmpty)
            'handoverStaffId': handoverStaffId.trim(),
        },
      );
      final data = ApiResult.unwrapMap(res);
      return WorkShiftModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tra cứu lịch sử ca trực và sổ giao ca (GET /shifts)
  Future<Map<String, dynamic>> getShifts({
    String? staffId,
    ShiftStatus? status,
    ShiftType? shiftType,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        if (status != null) 'status': status.value,
        if (shiftType != null) 'shiftType': shiftType.value,
        if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.shifts,
        queryParameters: query,
      );

      final data = ApiResult.unwrapMap(res);
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map((json) => WorkShiftModel.fromJson(json))
          .toList();

      return {
        'items': items,
        'total': (data['total'] as num?)?.toInt() ?? items.length,
        'page': (data['page'] as num?)?.toInt() ?? page,
        'limit': (data['limit'] as num?)?.toInt() ?? limit,
        'totalPages': (data['totalPages'] as num?)?.toInt() ?? 1,
      };
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Chi tiết ca trực kèm danh sách giao dịch (GET /shifts/:id)
  Future<WorkShiftModel> getShiftDetail(String shiftId) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.shiftDetail(shiftId));
      final data = ApiResult.unwrapMap(res);
      return WorkShiftModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
