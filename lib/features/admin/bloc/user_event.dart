import 'package:equatable/equatable.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/sse_client.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserFetchRequested extends UserEvent {
  final String? role;
  final bool isSilent;

  const UserFetchRequested({this.role, this.isSilent = false});

  @override
  List<Object?> get props => [role, isSilent];
}

class UserRefreshRequested extends UserEvent {
  const UserRefreshRequested();
}

class UserRoleFilterChanged extends UserEvent {
  final UserRole? role;

  const UserRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

class UserStatusFilterChanged extends UserEvent {
  final bool? status;

  const UserStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class UserSearchChanged extends UserEvent {
  final String query;

  const UserSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class UserRealtimeConnectionChanged extends UserEvent {
  final bool isConnected;

  const UserRealtimeConnectionChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

class UserRealtimeEventReceived extends UserEvent {
  final SseEvent event;

  const UserRealtimeEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}

class UserDeactivateRequested extends UserEvent {
  final String userId;

  const UserDeactivateRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserRoleUpdateRequested extends UserEvent {
  final String userId;
  final UserRole role;

  const UserRoleUpdateRequested({required this.userId, required this.role});

  @override
  List<Object?> get props => [userId, role];
}

class UserStatusToggleRequested extends UserEvent {
  final String userId;
  final bool isActive;

  const UserStatusToggleRequested({required this.userId, required this.isActive});

  @override
  List<Object?> get props => [userId, isActive];
}

class UserCreateRequested extends UserEvent {
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String? phone;

  const UserCreateRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, fullName, role, phone];
}
