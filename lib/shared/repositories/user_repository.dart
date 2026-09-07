import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/sse_client.dart';
import '../../core/storage/token_storage.dart';
import '../../di/injection_container.dart';
import '../models/user_model.dart';

class UserRepository {
  final DioClient _dioClient;
  final TokenStorage _tokenStorage;
  PageMeta? _lastMeta;

  UserRepository({DioClient? dioClient, TokenStorage? tokenStorage})
      : _dioClient = dioClient ?? DioClient(),
        _tokenStorage = tokenStorage ??
            (sl.isRegistered<TokenStorage>() ? sl<TokenStorage>() : TokenStorage());

  PageMeta? get lastMeta => _lastMeta;

  /// Tạo SseClient kết nối luồng realtime danh sách tài khoản GET /users/stream
  SseClient createUsersSseClient({String? token}) {
    return SseClient(
      path: ApiEndpoints.usersStream,
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
  }

  /// Lấy một trang danh sách người dùng kèm thông tin phân trang:
  /// GET /users?role=...&search=...&page=...&limit=...
  Future<PaginatedResult<UserModel>> fetchUsersPage({
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
      );

      final paged = ApiResult.unwrapPaginatedList(res, UserModel.fromJson);
      _lastMeta = paged.meta;
      return paged;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Lấy danh sách người dùng / nhân sự: GET /users
  /// Hỗ trợ cả tương thích ngược (không truyền page/limit) lẫn gọi kèm phân trang.
  Future<List<UserModel>> fetchAll({
    String? role,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': ?page,
        'limit': ?limit,
      };

      final res = await _dioClient.dio.get(
        ApiEndpoints.users,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final paged = ApiResult.unwrapPaginatedList(res, UserModel.fromJson);
      _lastMeta = paged.meta;
      return paged.items;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải gom song song toàn bộ người dùng qua nhiều trang (tối đa [maxPages] trang).
  Future<List<UserModel>> fetchAllUsers({
    String? role,
    String? search,
    int maxPages = 10,
  }) async {
    const pageSize = 100;
    final first = await fetchUsersPage(
      role: role,
      search: search,
      page: 1,
      limit: pageSize,
    );

    final all = <UserModel>[...first.items];
    final lastPage =
        first.meta.totalPages < maxPages ? first.meta.totalPages : maxPages;

    if (first.items.isNotEmpty && lastPage > 1) {
      final rest = await Future.wait([
        for (var p = 2; p <= lastPage; p++)
          fetchUsersPage(
            role: role,
            search: search,
            page: p,
            limit: pageSize,
          ),
      ]);
      for (final batch in rest) {
        all.addAll(batch.items);
      }
    }

    return all;
  }

  /// Admin tạo tài khoản nhân viên: POST /users
  /// [role] nhận ADMIN | RECEPTIONIST | CASHIER | CUSTOMER.
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? avatar,
    bool isActive = true,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
        'isActive': isActive,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.users,
        data: payload,
      );
      final data = ApiResult.unwrapMap(res);
      // Backend có thể bọc trong `user` khi trả kèm thông tin đăng nhập.
      if (data['user'] is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Chi tiết người dùng: GET /users/:id
  Future<UserModel> fetchDetail(String id) async {
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.userDetail(id));
      final data = ApiResult.unwrapMap(res);
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Cập nhật thông tin bản thân: PATCH /users/me
  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.usersMe,
        data: data,
      );
      final resData = ApiResult.unwrapMap(res);
      return UserModel.fromJson(resData);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Sửa thông tin & vai trò người dùng: PATCH /users/:id (ADMIN)
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.patch(
        ApiEndpoints.updateUser(id),
        data: data,
      );
      final resData = ApiResult.unwrapMap(res);
      if (resData['user'] is Map) {
        return UserModel.fromJson(
            Map<String, dynamic>.from(resData['user'] as Map));
      }
      return UserModel.fromJson(resData);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Khóa / mở khóa tài khoản thủ công: PATCH /users/:id body { isActive: false | true }
  /// Tham chiếu: update-user.dto.ts:26-29
  Future<UserModel> setActiveStatus(String id, bool isActive) async {
    return updateUser(id, {'isActive': isActive});
  }

  /// Khóa tài khoản thủ công: PATCH /users/:id { isActive: false }
  Future<UserModel> lockUser(String id) async {
    return setActiveStatus(id, false);
  }

  /// Mở khóa tài khoản thủ công: PATCH /users/:id { isActive: true }
  Future<UserModel> unlockUser(String id) async {
    return setActiveStatus(id, true);
  }

  /// Khóa tài khoản (soft-delete): DELETE /users/:id -> isActive = false
  /// Tham chiếu: users.service.ts:146-152
  Future<void> deactivate(String id) async {
    try {
      final res = await _dioClient.dio.delete(ApiEndpoints.deleteUser(id));
      if (res.data != null && res.data is Map) {
        ApiResult.unwrapMap(res);
      }
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Alias cho xóa mềm tài khoản: DELETE /users/:id
  Future<void> softDeleteUser(String id) async {
    return deactivate(id);
  }
}
