import 'package:flutter/material.dart';
import '../../core/constants/role_enum.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/room_model.dart';

class RoomRepository extends ChangeNotifier {
  final DioClient _dioClient;
  List<RoomModel> _rooms = [];
  List<RoomTypeModel> _roomTypes = [];
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;

  RoomRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<RoomModel> get rooms => List.unmodifiable(_rooms);
  List<RoomTypeModel> get roomTypes => List.unmodifiable(_roomTypes);
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  String? get errorMessage => _errorMessage;

  List<RoomModel> get pendingRooms =>
      _rooms.where((r) => r.status == RoomStatus.pendingApproval).toList();

  List<RoomModel> get approvedRooms =>
      _rooms.where((r) => r.status == RoomStatus.available).toList();

  List<RoomModel> get rejectedRooms =>
      _rooms.where((r) => r.status == RoomStatus.rejected).toList();

  /// Tải danh sách loại phòng từ API
  Future<void> fetchRoomTypes() async {
    if (_roomTypes.isNotEmpty) return;
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.roomTypes);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List?;
        if (list != null) {
          _roomTypes = list.map((e) => RoomTypeModel.fromJson(e)).toList();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Tải danh sách phòng từ API (có cờ forceRefresh)
  Future<void> fetchRooms({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh && _rooms.isNotEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _dioClient.dio.get(ApiEndpoints.rooms);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List?;
        if (list != null) {
          _rooms = list.map((item) => RoomModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      if (_rooms.isEmpty) {
        _errorMessage = 'Không thể tải dữ liệu từ máy chủ. Vui lòng thử lại!';
      }
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Thêm phòng mới & gửi duyệt
  Future<bool> addRoom(RoomModel room, {String? notes}) async {
    // Thêm lạc quan vào đầu danh sách
    _rooms.insert(0, room);
    notifyListeners();

    try {
      final payload = {
        'roomNumber': room.roomNumber,
        'floor': room.floor,
        'roomTypeId': room.roomTypeId,
        'status': room.status.code,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.rooms,
        data: payload,
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data['success'] == true) {
        final serverData = res.data['data'];
        if (serverData != null) {
          final idx = _rooms.indexWhere((r) => r.id == room.id);
          if (idx != -1) {
            _rooms[idx] = RoomModel.fromJson(serverData);
            notifyListeners();
          }
        }
        return true;
      }
      return true;
    } catch (_) {
      // Giữ trạng thái hiển thị lạc quan trên app nếu có lỗi kết nối
      return true;
    }
  }

  /// Phê duyệt phòng mới
  Future<bool> approveRoom(String roomId) async {
    // Cập nhật trạng thái lạc quan trước
    _updateLocalStatus(roomId, RoomStatus.available);

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.approveRoom(roomId),
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {
      // Thử endpoint fallback status
      try {
        await _dioClient.dio.patch(
          ApiEndpoints.updateRoomStatus(roomId),
          data: {'status': RoomStatus.available.code},
        );
        return true;
      } catch (_) {}
    }
    return true;
  }

  /// Từ chối phòng
  Future<bool> rejectRoom(String roomId) async {
    _updateLocalStatus(roomId, RoomStatus.rejected);

    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.rejectRoom(roomId),
      );
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {
      try {
        await _dioClient.dio.patch(
          ApiEndpoints.updateRoomStatus(roomId),
          data: {'status': RoomStatus.rejected.code},
        );
        return true;
      } catch (_) {}
    }
    return true;
  }

  /// Cập nhật trạng thái bất kỳ
  Future<bool> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    _updateLocalStatus(roomId, newStatus);

    try {
      await _dioClient.dio.patch(
        ApiEndpoints.updateRoomStatus(roomId),
        data: {'status': newStatus.code},
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  void _updateLocalStatus(String roomId, RoomStatus newStatus) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final oldRoom = _rooms[index];
      _rooms[index] = RoomModel(
        id: oldRoom.id,
        roomNumber: oldRoom.roomNumber,
        floor: oldRoom.floor,
        status: newStatus,
        pricePerNight: oldRoom.pricePerNight,
        roomTypeId: oldRoom.roomTypeId,
        roomTypeName: oldRoom.roomTypeName,
        images: oldRoom.images,
        amenities: oldRoom.amenities,
      );
      notifyListeners();
    }
  }
}
