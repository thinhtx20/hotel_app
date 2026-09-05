import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/role_enum.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/sse_client.dart';
import '../../core/storage/token_storage.dart';
import '../../di/injection_container.dart';
import '../models/room_model.dart';

class RoomRepository extends ChangeNotifier {
  final DioClient _dioClient;
  final TokenStorage _tokenStorage;
  List<RoomModel> _rooms = [];
  List<RoomTypeModel> _roomTypes = [];
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;

  SseClient? _roomSseClient;
  StreamSubscription? _sseSubscription;

  RoomRepository({DioClient? dioClient, TokenStorage? tokenStorage})
      : _dioClient = dioClient ?? DioClient(),
        _tokenStorage = tokenStorage ??
            (sl.isRegistered<TokenStorage>() ? sl<TokenStorage>() : TokenStorage());

  List<RoomModel> get rooms => List.unmodifiable(_rooms);
  List<RoomTypeModel> get roomTypes => List.unmodifiable(_roomTypes);
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  String? get errorMessage => _errorMessage;

  /// Trạng thái kết nối Realtime SSE
  bool get isRealtimeActive => _roomSseClient?.isConnected ?? false;
  Stream<SseConnectionState>? get realtimeConnectionState =>
      _roomSseClient?.connectionState;

  List<RoomModel> get pendingRooms =>
      _rooms.where((r) => r.status == RoomStatus.pendingApproval).toList();

  List<RoomModel> get approvedRooms =>
      _rooms.where((r) => r.status == RoomStatus.available).toList();

  List<RoomModel> get rejectedRooms =>
      _rooms.where((r) => r.status == RoomStatus.rejected).toList();

  /// Khởi chạy kết nối Realtime SSE để nhận biến động trạng thái phòng
  void startRealtimeStream({String? token}) {
    if (_roomSseClient != null) return;

    _roomSseClient = SseClient(
      path: ApiEndpoints.roomsStream,
      dioClient: _dioClient,
      tokenProvider: () async {
        if (token != null && token.isNotEmpty) return token;
        try {
          return await _tokenStorage.getAccessToken();
        } catch (_) {
          return null;
        }
      },
    );

    _sseSubscription = _roomSseClient!.events.listen(
      (event) {
        _handleRoomEvent(event);
      },
      onError: (_) {},
    );

    _roomSseClient!.connect();
  }

  /// Ngắt kết nối Realtime SSE
  void stopRealtimeStream() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _roomSseClient?.dispose();
    _roomSseClient = null;
  }

  void _handleRoomEvent(SseEvent event) {
    switch (event.event) {
      case 'room.status_changed':
        final data = event.data;
        if (data is Map) {
          final roomData = data['room'] is Map ? data['room'] as Map : data;
          final roomId = roomData['id']?.toString();
          final statusStr = roomData['status']?.toString();
          if (roomId != null && statusStr != null) {
            final newStatus = RoomStatus.fromString(statusStr);
            _updateLocalStatus(roomId, newStatus);
          }
        }
        break;

      case 'room.created':
        final data = event.data;
        if (data is Map) {
          final roomData = data['room'] is Map
              ? Map<String, dynamic>.from(data['room'] as Map)
              : Map<String, dynamic>.from(data);
          try {
            final room = RoomModel.fromJson(roomData);
            if (!_rooms.any((r) => r.id == room.id)) {
              _rooms.insert(0, room);
              notifyListeners();
            }
          } catch (_) {}
        }
        break;

      case 'room.updated':
        final data = event.data;
        if (data is Map) {
          final roomData = data['room'] is Map
              ? Map<String, dynamic>.from(data['room'] as Map)
              : Map<String, dynamic>.from(data);
          try {
            final room = RoomModel.fromJson(roomData);
            final idx = _rooms.indexWhere((r) => r.id == room.id);
            if (idx != -1) {
              _rooms[idx] = room;
              notifyListeners();
            }
          } catch (_) {}
        }
        break;

      case 'room.deleted':
        final data = event.data;
        if (data is Map) {
          final roomData = data['room'] is Map ? data['room'] as Map : data;
          final roomId = roomData['id']?.toString();
          if (roomId != null) {
            _rooms.removeWhere((r) => r.id == roomId);
            notifyListeners();
          }
        }
        break;

      default:
        // ready, ping
        break;
    }
  }

  /// Xóa toàn bộ dữ liệu đã nạp của tài khoản trước.
  ///
  /// [fetchRooms] và [fetchRoomTypes] trả cache khi đã nạp một lần, nên nếu
  /// không dọn ở đây thì tài khoản mới vẫn thấy danh sách phòng của tài khoản
  /// cũ (khách hàng chỉ thấy phòng đã duyệt, nhân viên thấy cả phòng chờ duyệt).
  void clearSession() {
    stopRealtimeStream();
    _rooms = [];
    _roomTypes = [];
    _isLoading = false;
    _initialized = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Tải danh sách loại phòng từ API (có cờ forceRefresh)
  Future<List<RoomTypeModel>> fetchRoomTypes({bool forceRefresh = false}) async {
    if (!forceRefresh && _roomTypes.isNotEmpty) return _roomTypes;
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.roomTypes);
      final list = ApiResult.unwrapList(res);
      _roomTypes = list.map((e) => RoomTypeModel.fromJson(e)).toList();
      notifyListeners();
      return _roomTypes;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải danh sách phòng từ API (có cờ forceRefresh)
  /// Hỗ trợ bộ lọc phía máy chủ: [status], [floor], [roomTypeId].
  Future<void> fetchRooms({
    bool forceRefresh = false,
    RoomStatus? status,
    int? floor,
    String? roomTypeId,
  }) async {
    final hasFilter = status != null || floor != null || roomTypeId != null;
    if (_initialized && !forceRefresh && !hasFilter && _rooms.isNotEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    scheduleMicrotask(notifyListeners);

    try {
      final queryParams = <String, dynamic>{
        if (status != null) 'status': status.code,
        'floor': ?floor,
        if (roomTypeId != null && roomTypeId.isNotEmpty) 'roomTypeId': roomTypeId,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.rooms,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final list = ApiResult.unwrapList(res);
      _rooms = list.map((item) => RoomModel.fromJson(item)).toList();
    } on DioException catch (e) {
      final apiErr = ApiError.fromDioException(e);
      if (_rooms.isEmpty) {
        _errorMessage = apiErr.message;
      }
      rethrow;
    } catch (e) {
      final apiErr = ApiError.fromDynamic(e);
      if (_rooms.isEmpty) {
        _errorMessage = apiErr.message;
      }
      rethrow;
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Chi tiết phòng: GET /rooms/:id
  Future<RoomModel> fetchDetail(String id) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.roomDetail(id));
      final data = ApiResult.unwrapMap(res);
      return RoomModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tìm kiếm phòng trống theo khoảng thời gian: GET /rooms/available
  Future<List<RoomModel>> fetchAvailable({
    required DateTime checkInDate,
    required DateTime checkOutDate,
    int? guestCount,
    String? roomTypeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
        if (guestCount != null && guestCount > 0) 'guestCount': guestCount,
        if (roomTypeId != null && roomTypeId.isNotEmpty) 'roomTypeId': roomTypeId,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.roomsAvailable,
        queryParameters: queryParams,
      );

      final list = ApiResult.unwrapList(res);
      return list.map((e) => RoomModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tìm kiếm phòng: GET /rooms/search
  Future<List<RoomModel>> searchRooms({
    String? q,
    num? minPrice,
    num? maxPrice,
    List<String>? amenities,
    String? sort,
    int? floor,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (q != null && q.isNotEmpty) 'q': q,
        'minPrice': ?minPrice,
        'maxPrice': ?maxPrice,
        if (amenities != null && amenities.isNotEmpty) 'amenities': amenities.join(','),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'floor': ?floor,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.roomsSearch,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final list = ApiResult.unwrapList(res);
      return list.map((e) => RoomModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Thêm phòng mới & gửi duyệt
  Future<bool> addRoom(RoomModel room, {String? notes}) async {
    // Thêm lạc quan vào đầu danh sách
    _rooms.insert(0, room);
    notifyListeners();

    try {
      // CreateRoomDto nhận đầy đủ giá, ảnh, tiện ích và sức chứa — trước đây
      // các trường này bị bỏ rơi nên ảnh vừa tải lên không được lưu vào phòng.
      final payload = <String, dynamic>{
        'roomNumber': room.roomNumber,
        'floor': room.floor,
        if (room.roomTypeId != null && room.roomTypeId!.isNotEmpty)
          'roomTypeId': room.roomTypeId,
        'status': room.status.code,
        if (room.pricePerNight > 0) 'pricePerNight': room.pricePerNight,
        if (room.images.isNotEmpty) ...{
          'image': room.images.first,
          'images': room.images,
        },
        if (room.amenities.isNotEmpty) 'amenities': room.amenities,
        if (room.description != null && room.description!.isNotEmpty)
          'description': room.description,
        'sizeSqM': ?room.sizeSqM,
        'capacityAdults': ?room.capacityAdults,
        'capacityChildren': ?room.capacityChildren,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.rooms,
        data: payload,
      );

      final serverData = ApiResult.unwrapMap(res);
      final idx = _rooms.indexWhere((r) => r.id == room.id);
      if (idx != -1) {
        _rooms[idx] = RoomModel.fromJson(serverData);
        notifyListeners();
      }
      return true;
    } catch (e) {
      // Rollback trạng thái lạc quan khi có lỗi
      _rooms.removeWhere((r) => r.id == room.id);
      notifyListeners();
      if (e is DioException) throw ApiError.fromDioException(e);
      throw ApiError.fromDynamic(e);
    }
  }

  /// Phê duyệt phòng mới: PATCH /rooms/:id/approve
  Future<bool> approveRoom(String roomId) async {
    final oldStatus = _findRoomStatus(roomId);
    _updateLocalStatus(roomId, RoomStatus.available);

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.approveRoom(roomId),
      );
      ApiResult.unwrapMap(res);
      return true;
    } catch (e) {
      // Rollback về trạng thái cũ khi lỗi
      if (oldStatus != null) {
        _updateLocalStatus(roomId, oldStatus);
      }
      if (e is DioException) throw ApiError.fromDioException(e);
      throw ApiError.fromDynamic(e);
    }
  }

  /// Từ chối phòng: PATCH /rooms/:id/reject
  Future<bool> rejectRoom(String roomId) async {
    final oldStatus = _findRoomStatus(roomId);
    _updateLocalStatus(roomId, RoomStatus.rejected);

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.rejectRoom(roomId),
      );
      ApiResult.unwrapMap(res);
      return true;
    } catch (e) {
      // Rollback về trạng thái cũ khi lỗi
      if (oldStatus != null) {
        _updateLocalStatus(roomId, oldStatus);
      }
      if (e is DioException) throw ApiError.fromDioException(e);
      throw ApiError.fromDynamic(e);
    }
  }

  /// Cập nhật trạng thái phòng: PATCH /rooms/:id/status
  Future<bool> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    final oldStatus = _findRoomStatus(roomId);
    _updateLocalStatus(roomId, newStatus);

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.updateRoomStatus(roomId),
        data: {'status': newStatus.code},
      );
      ApiResult.unwrapMap(res);
      return true;
    } catch (e) {
      // Rollback về trạng thái cũ
      if (oldStatus != null) {
        _updateLocalStatus(roomId, oldStatus);
      }
      if (e is DioException) throw ApiError.fromDioException(e);
      throw ApiError.fromDynamic(e);
    }
  }

  /// Cập nhật thông tin phòng: PATCH /rooms/:id (ADMIN)
  Future<RoomModel> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.updateRoom(roomId),
        data: data,
      );
      final updated = RoomModel.fromJson(ApiResult.unwrapMap(res));
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx != -1) {
        _rooms[idx] = updated;
        notifyListeners();
      }
      return updated;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Xóa phòng: DELETE /rooms/:id (ADMIN)
  Future<void> deleteRoom(String roomId) async {
    try {
      final res = await _dioClient.dio.delete(ApiEndpoints.deleteRoom(roomId));
      ApiResult.unwrapMap(res);
      _rooms.removeWhere((r) => r.id == roomId);
      notifyListeners();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Rà soát & đồng bộ trạng thái toàn bộ phòng theo lịch đặt phòng thực tế:
  /// POST /rooms/sync-status (ADMIN, RECEPTIONIST).
  ///
  /// Trả về `{message, totalRooms, updatedCount, changes: [...]}` và tự động
  /// tải lại danh sách phòng khi có phòng bị đổi trạng thái.
  Future<Map<String, dynamic>> syncRoomStatus() async {
    try {
      final res = await _dioClient.dio.post(ApiEndpoints.roomsSyncStatus);
      final data = ApiResult.unwrapMap(res);

      final updatedCount = data['updatedCount'];
      final changed = updatedCount is num
          ? updatedCount > 0
          : int.tryParse('$updatedCount') != null &&
              int.parse('$updatedCount') > 0;
      if (changed) {
        await fetchRooms(forceRefresh: true);
      }

      return data;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  // --- CRUD Loại phòng (Room Types) ------------------------------------------

  /// Tạo loại phòng: POST /room-types (ADMIN)
  Future<RoomTypeModel> createRoomType(Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.roomTypes,
        data: data,
      );
      final resData = ApiResult.unwrapMap(res);
      final newType = RoomTypeModel.fromJson(resData);
      _roomTypes.insert(0, newType);
      notifyListeners();
      return newType;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Sửa loại phòng: PATCH /room-types/:id (ADMIN)
  Future<RoomTypeModel> updateRoomType(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.roomTypeDetail(id),
        data: data,
      );
      final resData = ApiResult.unwrapMap(res);
      final updatedType = RoomTypeModel.fromJson(resData);
      final idx = _roomTypes.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _roomTypes[idx] = updatedType;
        notifyListeners();
      }
      return updatedType;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Xóa loại phòng: DELETE /room-types/:id (ADMIN)
  Future<void> deleteRoomType(String id) async {
    try {
      final res = await _dioClient.dio.delete(ApiEndpoints.roomTypeDetail(id));
      ApiResult.unwrapMap(res);
      _roomTypes.removeWhere((t) => t.id == id);
      notifyListeners();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  RoomStatus? _findRoomStatus(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    return idx != -1 ? _rooms[idx].status : null;
  }

  void _updateLocalStatus(String roomId, RoomStatus newStatus) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final oldRoom = _rooms[index];
      _rooms[index] = oldRoom.copyWith(status: newStatus);
      notifyListeners();
    }
  }
}
