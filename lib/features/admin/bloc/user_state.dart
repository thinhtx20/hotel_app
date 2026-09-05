import 'package:equatable/equatable.dart';
import '../../../core/constants/role_enum.dart';
import '../../../shared/models/user_model.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final List<UserModel> users;
  final bool isRealtimeConnected;
  final UserRole? selectedRoleFilter;
  final bool? selectedStatusFilter;
  final String searchQuery;
  final Set<String> processingIds;
  final String? errorMessage;
  final String? actionMessage;

  const UserState({
    this.status = UserStatus.initial,
    this.users = const [],
    this.isRealtimeConnected = false,
    this.selectedRoleFilter,
    this.selectedStatusFilter,
    this.searchQuery = '',
    this.processingIds = const {},
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == UserStatus.loading;
  bool get isInitial => status == UserStatus.initial;
  bool get isSuccess => status == UserStatus.success;
  bool get isFailure => status == UserStatus.failure;

  List<UserModel> get filteredUsers {
    var list = users;
    if (selectedStatusFilter != null) {
      list = list.where((u) => u.isActive == selectedStatusFilter).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((u) {
        final name = u.fullName.toLowerCase();
        final email = u.email.toLowerCase();
        final phone = (u.phone ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }
    return list;
  }

  UserState copyWith({
    UserStatus? status,
    List<UserModel>? users,
    bool? isRealtimeConnected,
    UserRole? selectedRoleFilter,
    bool? selectedStatusFilter,
    bool clearRoleFilter = false,
    bool clearStatusFilter = false,
    String? searchQuery,
    Set<String>? processingIds,
    String? errorMessage,
    String? actionMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      selectedRoleFilter:
          clearRoleFilter ? null : (selectedRoleFilter ?? this.selectedRoleFilter),
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      processingIds: processingIds ?? this.processingIds,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        isRealtimeConnected,
        selectedRoleFilter,
        selectedStatusFilter,
        searchQuery,
        processingIds,
        errorMessage,
        actionMessage,
      ];
}
