import '../../../core/utils/vietnamese_search_helper.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/role_enum.dart';
import '../../../shared/models/user_model.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  final UserStatus status;
  final List<UserModel> users;
  final bool isRealtimeConnected;

  /// Bộ lọc vai trò gốc của màn hình đang mở: `null` với Admin (xem tất cả),
  /// [UserRole.customer] với Lễ tân. Mọi thao tác đặt lại đưa
  /// [selectedRoleFilter] về đúng giá trị này.
  final UserRole? defaultRoleFilter;
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
    this.defaultRoleFilter,
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

  /// Màn đang lệch khỏi trạng thái gốc (có tìm kiếm, lọc trạng thái, hoặc đổi
  /// bộ lọc vai trò) — dùng để đặt nhãn nút đặt lại.
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      selectedStatusFilter != null ||
      selectedRoleFilter != defaultRoleFilter;

  List<UserModel> get filteredUsers {
    var list = users;
    if (selectedStatusFilter != null) {
      list = list.where((u) => u.isActive == selectedStatusFilter).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      list = list.where((u) {
        return VietnameseSearchHelper.matchesAny(
          [u.fullName, u.email, u.phone],
          searchQuery,
        );
      }).toList();
    }
    return list;
  }

  UserState copyWith({
    UserStatus? status,
    List<UserModel>? users,
    bool? isRealtimeConnected,
    UserRole? defaultRoleFilter,
    bool clearDefaultRoleFilter = false,
    UserRole? selectedRoleFilter,
    bool? selectedStatusFilter,
    bool clearRoleFilter = false,
    bool clearStatusFilter = false,
    String? searchQuery,
    Set<String>? processingIds,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      defaultRoleFilter: clearDefaultRoleFilter
          ? null
          : (defaultRoleFilter ?? this.defaultRoleFilter),
      selectedRoleFilter:
          clearRoleFilter ? null : (selectedRoleFilter ?? this.selectedRoleFilter),
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      processingIds: processingIds ?? this.processingIds,
      // `errorMessage: null` không xóa được thông báo cũ (toán tử `??` rơi về
      // giá trị cũ), nên phải có cờ xóa riêng — nếu không, snackbar lỗi của
      // thao tác trước sẽ bật lại ở mọi lần state thay đổi sau đó.
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        isRealtimeConnected,
        defaultRoleFilter,
        selectedRoleFilter,
        selectedStatusFilter,
        searchQuery,
        processingIds,
        errorMessage,
        actionMessage,
      ];
}
