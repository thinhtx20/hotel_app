import 'package:equatable/equatable.dart';
import '../../../shared/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  /// Tài khoản đang đăng nhập trước khi thao tác thất bại.
  ///
  /// Đăng nhập hỏng lúc **đang có phiên hợp lệ** (đổi tài khoản từ màn Hồ sơ)
  /// thì token cũ vẫn còn dùng được — giữ lại người dùng này để guard trong
  /// `AppRouter` không đá người dùng ra màn đăng nhập.
  final UserModel? previousUser;

  const AuthFailure(this.message, {this.previousUser});

  @override
  List<Object?> get props => [message, previousUser];
}
