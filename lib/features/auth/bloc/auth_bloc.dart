import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

import '../../../core/network/api_error.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DioClient _dioClient;
  final TokenStorage _tokenStorage;

  /// Được gọi khi phiên đăng nhập kết thúc hoặc chuyển sang tài khoản khác, để
  /// tầng dữ liệu dọn cache của người dùng cũ (xem `clearUserScopedCaches`).
  final void Function()? _onSessionReset;

  AuthBloc({
    DioClient? dioClient,
    TokenStorage? tokenStorage,
    void Function()? onSessionReset,
  })  : _dioClient = dioClient ?? DioClient(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        // ignore: prefer_initializing_formals
        _onSessionReset = onSessionReset,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionRevoked>(_onSessionRevoked);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    final user = await _tokenStorage.getUser();

    if (token != null && user != null) {
      emit(AuthAuthenticated(user));
      try {
        final res = await _dioClient.dio.get(ApiEndpoints.me);
        if ((res.statusCode == 200 || res.statusCode == 201) &&
            res.data['success'] == true) {
          final rawData = res.data['data'] ?? res.data;
          final updatedUser = UserModel.fromJson(rawData);
          if (!updatedUser.isActive) {
            await _tokenStorage.clearAll();
            emit(AuthFailure('Tài khoản của bạn đã bị khóa'));
            return;
          }
          await _tokenStorage.saveUser(updatedUser);
          emit(AuthAuthenticated(updatedUser));
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await _tokenStorage.clearAll();
          final apiErr = ApiError.fromDioException(e);
          emit(AuthFailure(apiErr.displayMessage));
          return;
        }
      } catch (_) {
        // Keep existing user if network fails temporarily
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Đổi tài khoản ngay trong app: phiên hiện tại phải được giữ nguyên nếu
    // đăng nhập tài khoản mới thất bại.
    final previousState = state;
    final previousUser =
        previousState is AuthAuthenticated ? previousState.user : null;

    emit(AuthLoading());
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': event.email.trim(),
          'password': event.password,
        },
      );

      final isSuccess = (res.statusCode == 200 || res.statusCode == 201) &&
          (res.data['success'] == true || res.data['data'] != null);

      if (isSuccess) {
        final data = res.data['data'] ?? res.data;
        final userJson = data['user'] ?? data;
        final user = UserModel.fromJson(userJson);
        final accessToken = (data['accessToken'] ?? '') as String;
        final refreshToken = (data['refreshToken'] ?? '') as String;

        // Dữ liệu đã nạp thuộc về tài khoản trước đó — dọn trước khi phát
        // trạng thái mới để màn hình của tài khoản mới tải lại từ API.
        _onSessionReset?.call();

        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await _tokenStorage.saveUser(user);

        emit(AuthAuthenticated(user));
      } else {
        final msg = res.data['message']?.toString() ?? 'Đăng nhập thất bại';
        _emitLoginFailure(emit, msg, previousUser);
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      _emitLoginFailure(emit, apiError.displayMessage, previousUser);
    } catch (e) {
      final apiError = ApiError.fromDynamic(e);
      _emitLoginFailure(emit, apiError.displayMessage, previousUser);
    }
  }

  /// Báo lỗi đăng nhập, rồi trả phiên cũ về nguyên trạng nếu có.
  ///
  /// Không khôi phục thì một lần đổi tài khoản hỏng (sai mật khẩu, rớt mạng)
  /// sẽ hất người dùng ra màn đăng nhập dù token cũ vẫn còn hiệu lực.
  void _emitLoginFailure(
    Emitter<AuthState> emit,
    String message,
    UserModel? previousUser,
  ) {
    emit(AuthFailure(message, previousUser: previousUser));
    if (previousUser != null) {
      emit(AuthAuthenticated(previousUser));
    }
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: {
          'email': event.email.trim(),
          'password': event.password,
          'fullName': event.fullName.trim(),
          'phone': event.phone?.trim(),
          // Không gửi `role`: API đăng ký công khai luôn ép vai trò CUSTOMER
          // và bỏ qua trường này.
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data['success'] == true) {
        // Auto login sau khi register thành công
        add(AuthLoginSubmitted(
          email: event.email,
          password: event.password,
        ));
      } else {
        final msg = res.data['message']?.toString() ?? 'Đăng ký thất bại';
        emit(AuthFailure(msg));
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      emit(AuthFailure(apiError.displayMessage));
    } catch (e) {
      final apiError = ApiError.fromDynamic(e);
      emit(AuthFailure(apiError.displayMessage));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      await _dioClient.dio.post(
        ApiEndpoints.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
      );
    } catch (_) {
      // Ignore network errors when logging out
    } finally {
      _onSessionReset?.call();
      await _tokenStorage.clearAll();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSessionRevoked(
    AuthSessionRevoked event,
    Emitter<AuthState> emit,
  ) async {
    _onSessionReset?.call();
    await _tokenStorage.clearAll();
    emit(AuthFailure(event.reason));
  }
}
