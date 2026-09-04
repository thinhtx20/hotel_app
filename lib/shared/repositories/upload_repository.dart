import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class UploadRepository {
  final DioClient _dioClient;
  final TokenStorage _tokenStorage;

  UploadRepository({DioClient? dioClient, TokenStorage? tokenStorage})
      : _dioClient = dioClient ?? DioClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  /// Tải lên ảnh đại diện: POST /upload/avatar?updateProfile=true
  ///
  /// API trả về `{url, path, type, folder, size, mimetype, originalName, user}`
  /// trong đó `user` chỉ gồm `{id, fullName, avatar}`. Vì vậy phải ghép URL ảnh
  /// mới vào hồ sơ đang lưu, tránh làm mất email/role của tài khoản.
  Future<UserModel> uploadAvatar(
    String filePath, {
    bool updateProfile = true,
  }) async {
    try {
      final fileName = filePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final res = await _dioClient.dio.post(
        ApiEndpoints.uploadAvatar,
        queryParameters: {'updateProfile': updateProfile},
        data: formData,
      );

      final data = ApiResult.unwrapMap(res);
      final uploaded = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : <String, dynamic>{};

      final avatarUrl = uploaded['avatar']?.toString() ??
          data['url']?.toString() ??
          data['imageUrl']?.toString();

      final currentUser = await _tokenStorage.getUser();
      if (currentUser != null) {
        return currentUser.copyWith(
          avatar: avatarUrl ?? currentUser.avatar,
          fullName: uploaded['fullName']?.toString() ?? currentUser.fullName,
        );
      }

      // Không có hồ sơ trong bộ nhớ: dựng tạm từ dữ liệu máy chủ trả về.
      return UserModel.fromJson({
        ...uploaded,
        'avatar': ?avatarUrl,
      });
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải lên album ảnh phòng: POST /upload/rooms?roomId=
  ///
  /// API trả về `data: {urls, images, files: [{url, ...}], room, roomType}`
  /// chứ không phải một mảng phẳng, nên phải bóc theo thứ tự `urls` → `images`
  /// → `files[].url`.
  Future<List<String>> uploadRoomImages(
    List<String> filePaths, {
    String? roomId,
    String? roomTypeId,
  }) async {
    try {
      final multipartFiles = <MultipartFile>[];
      for (final path in filePaths) {
        final fileName = path.split('/').last.split('\\').last;
        multipartFiles.add(await MultipartFile.fromFile(path, filename: fileName));
      }

      final formData = FormData.fromMap({
        'files': multipartFiles,
      });

      final queryParams = <String, dynamic>{
        'roomId': ?roomId,
        'roomTypeId': ?roomTypeId,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.uploadRooms,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: formData,
      );

      return _extractUrls(ApiResult.unwrapMap(res));
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Tải lên 1 ảnh phòng / loại phòng: POST /upload/room?roomId=&roomTypeId=
  /// Trả về URL công khai của ảnh vừa tải lên.
  Future<String?> uploadRoomImage(
    String filePath, {
    String? roomId,
    String? roomTypeId,
  }) async {
    try {
      final fileName = filePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final queryParams = <String, dynamic>{
        'roomId': ?roomId,
        'roomTypeId': ?roomTypeId,
      };

      final res = await _dioClient.dio.post(
        ApiEndpoints.uploadRoom,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: formData,
      );

      final data = ApiResult.unwrapMap(res);
      final direct = data['url']?.toString();
      if (direct != null && direct.isNotEmpty) return direct;
      final urls = _extractUrls(data);
      return urls.isEmpty ? null : urls.first;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }

  /// Gom danh sách URL ảnh từ payload upload (`urls` / `images` / `files`).
  static List<String> _extractUrls(Map<String, dynamic> data) {
    for (final key in ['urls', 'images']) {
      final raw = data[key];
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString()).toList();
      }
    }

    final files = data['files'];
    if (files is List && files.isNotEmpty) {
      return files
          .whereType<Map>()
          .map((e) => (e['url'] ?? e['path'])?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }

    final single = data['url'] ?? data['image'];
    if (single != null && single.toString().isNotEmpty) {
      return [single.toString()];
    }

    return [];
  }

  /// Xóa file tải lên: DELETE /upload?path=
  Future<void> deleteUpload(String path) async {
    try {
      final res = await _dioClient.dio.delete(
        ApiEndpoints.uploadDelete,
        queryParameters: {'path': path},
      );
      ApiResult.unwrapMap(res);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError.fromDynamic(e);
    }
  }
}
