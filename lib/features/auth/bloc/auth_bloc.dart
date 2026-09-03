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

  AuthBloc({
    DioClient? dioClient,
    TokenStorage? tokenStorage,
  })  : _dioClient = dioClient ?? DioClient(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
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
          await _tokenStorage.saveUser(updatedUser);
          emit(AuthAuthenticated(updatedUser));
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

        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await _tokenStorage.saveUser(user);

        emit(AuthAuthenticated(user));
      } else {
        final msg = res.data['message']?.toString() ?? 'Đăng nhập thất bại';
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
          'role': 'CUSTOMER',
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
      if (refreshToken != null) {
        await _dioClient.dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors when logging out
    } finally {
      await _tokenStorage.clearAll();
      emit(AuthUnauthenticated());
    }
  }
}
