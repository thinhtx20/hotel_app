import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;
  UserRepository get _userRepository => userRepository;

  /// Số thứ tự của request danh sách mới nhất.
  ///
  /// Các handler tải danh sách chạy song song, nên response của lần lọc trước
  /// có thể về sau response mới và ghi đè lên đúng dữ liệu vừa tải. Mỗi lần gọi
  /// API nhận một số thứ tự; khi trả về mà số đã cũ thì bỏ qua.
  int _fetchRequestId = 0;

  UserBloc({required this.userRepository})
      : super(const UserState()) {
    on<UserFetchRequested>(_onFetchRequested);
    on<UserScopeInitialized>(_onScopeInitialized);
    on<UserResetRequested>(_onResetRequested);
    on<UserRoleFilterChanged>(_onRoleFilterChanged);
    on<UserStatusFilterChanged>(_onStatusFilterChanged);
    on<UserSearchChanged>(_onSearchChanged);
    on<UserRealtimeConnectionChanged>(_onRealtimeConnectionChanged);
    on<UserRealtimeEventReceived>(_onRealtimeEventReceived);
    on<UserDeactivateRequested>(_onDeactivateRequested);
    on<UserRoleUpdateRequested>(_onRoleUpdateRequested);
    on<UserStatusToggleRequested>(_onStatusToggleRequested);
    on<UserCreateRequested>(_onCreateRequested);
    on<UserPasswordChangeRequested>(_onPasswordChangeRequested);
  }

  /// Gọi `GET /users` cho đúng [role] và ghi kết quả vào state.
  ///
  /// Bỏ qua response của request đã cũ (xem [_fetchRequestId]) để dữ liệu trên
  /// màn luôn khớp với lần gọi gần nhất.
  Future<void> _fetchUsers(
    Emitter<UserState> emit, {
    required String? role,
    required bool isSilent,
  }) async {
    final requestId = ++_fetchRequestId;

    if (!isSilent) {
      emit(state.copyWith(
        status: UserStatus.loading,
        clearErrorMessage: true,
      ));
    }

    try {
      final list = await _userRepository.fetchAll(role: role);
      if (requestId != _fetchRequestId || emit.isDone) return;

      emit(state.copyWith(
        status: UserStatus.success,
        users: list,
        clearErrorMessage: true,
      ));
    } catch (e) {
      if (requestId != _fetchRequestId || emit.isDone) return;

      final msg = e is ApiError ? e.message : 'Không thể tải danh sách người dùng';
      emit(state.copyWith(
        status: UserStatus.failure,
        errorMessage: msg,
        clearActionMessage: true,
      ));
    }
  }

  Future<void> _onFetchRequested(
    UserFetchRequested event,
    Emitter<UserState> emit,
  ) async {
    await _fetchUsers(
      emit,
      role: event.role ?? state.selectedRoleFilter?.value,
      isSilent: event.isSilent,
    );
  }

  /// Mở màn hình (hoặc đổi tài khoản đang đăng nhập): dựng lại state từ đầu
  /// theo phạm vi của màn rồi mới tải danh sách, không giữ lại gì của phiên
  /// trước.
  Future<void> _onScopeInitialized(
    UserScopeInitialized event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      users: const [],
      defaultRoleFilter: event.defaultRole,
      clearDefaultRoleFilter: event.defaultRole == null,
      selectedRoleFilter: event.defaultRole,
      clearRoleFilter: event.defaultRole == null,
      clearStatusFilter: true,
      searchQuery: '',
      processingIds: const {},
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    await _fetchUsers(emit, role: event.defaultRole?.value, isSilent: false);
  }

  /// Đặt lại màn: bỏ mọi bộ lọc rồi gọi API danh sách gốc của màn.
  ///
  /// Cố ý dùng [UserState.defaultRoleFilter] chứ không dùng
  /// [UserState.selectedRoleFilter] — lấy bộ lọc đang chọn đồng nghĩa với gọi
  /// lại đúng request của lần lọc trước, tức là không đặt lại gì cả.
  Future<void> _onResetRequested(
    UserResetRequested event,
    Emitter<UserState> emit,
  ) async {
    final defaultRole = state.defaultRoleFilter;

    emit(state.copyWith(
      selectedRoleFilter: defaultRole,
      clearRoleFilter: defaultRole == null,
      clearStatusFilter: true,
      searchQuery: '',
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    await _fetchUsers(emit, role: defaultRole?.value, isSilent: false);
  }

  Future<void> _onRoleFilterChanged(
    UserRoleFilterChanged event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      selectedRoleFilter: event.role,
      clearRoleFilter: event.role == null,
    ));

    await _fetchUsers(emit, role: event.role?.value, isSilent: false);
  }

  void _onStatusFilterChanged(
    UserStatusFilterChanged event,
    Emitter<UserState> emit,
  ) {
    emit(state.copyWith(
      selectedStatusFilter: event.status,
      clearStatusFilter: event.status == null,
    ));
  }

  void _onSearchChanged(
    UserSearchChanged event,
    Emitter<UserState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onRealtimeConnectionChanged(
    UserRealtimeConnectionChanged event,
    Emitter<UserState> emit,
  ) {
    emit(state.copyWith(isRealtimeConnected: event.isConnected));
  }

  void _onRealtimeEventReceived(
    UserRealtimeEventReceived event,
    Emitter<UserState> emit,
  ) {
    final sse = event.event;
    switch (sse.event) {
      case 'user.created':
        final data = sse.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          try {
            final newUser = UserModel.fromJson(Map<String, dynamic>.from(userMap));
            if (!state.users.any((u) => u.id == newUser.id)) {
              final updated = [newUser, ...state.users];
              final name = newUser.fullName.isNotEmpty ? newUser.fullName : newUser.email;
              emit(state.copyWith(
                users: updated,
                actionMessage: 'Tài khoản mới: $name',
              ));
            }
          } catch (_) {}
        }
        break;

      case 'user.updated':
        final data = sse.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          try {
            final updatedUser = UserModel.fromJson(Map<String, dynamic>.from(userMap));
            final idx = state.users.indexWhere((u) => u.id == updatedUser.id);
            if (idx != -1) {
              final list = List<UserModel>.from(state.users);
              list[idx] = updatedUser;
              emit(state.copyWith(users: list));
            }
          } catch (_) {}
        }
        break;

      case 'user.deactivated':
        final data = sse.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          final deactivatedId = userMap['id']?.toString() ?? data['id']?.toString();
          if (deactivatedId != null) {
            final idx = state.users.indexWhere((u) => u.id == deactivatedId);
            if (idx != -1) {
              final list = List<UserModel>.from(state.users);
              list[idx] = list[idx].copyWith(isActive: false);
              emit(state.copyWith(users: list));
            }
          }
        }
        break;

      default:
        break;
    }
  }

  Future<void> _onDeactivateRequested(
    UserDeactivateRequested event,
    Emitter<UserState> emit,
  ) async {
    final nextProcessing = Set<String>.from(state.processingIds)..add(event.userId);
    emit(state.copyWith(
      processingIds: nextProcessing,
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    try {
      await _userRepository.deactivate(event.userId);
      final list = state.users.map((u) {
        return u.id == event.userId ? u.copyWith(isActive: false) : u;
      }).toList();
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        users: list,
        processingIds: finishedProcessing,
        actionMessage: 'Đã vô hiệu hóa tài khoản (Soft-delete)',
        clearErrorMessage: true,
      ));
    } catch (e) {
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        processingIds: finishedProcessing,
        errorMessage: e is ApiError ? e.message : 'Không thể khóa tài khoản',
        clearActionMessage: true,
      ));
    }
  }

  Future<void> _onRoleUpdateRequested(
    UserRoleUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    final nextProcessing = Set<String>.from(state.processingIds)..add(event.userId);
    emit(state.copyWith(
      processingIds: nextProcessing,
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    try {
      final updated = await _userRepository.updateUser(
        event.userId,
        {'role': event.role.value},
      );
      final list = state.users.map((u) {
        return u.id == event.userId ? updated : u;
      }).toList();
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        users: list,
        processingIds: finishedProcessing,
        actionMessage: 'Đã cập nhật vai trò',
        clearErrorMessage: true,
      ));
    } catch (e) {
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        processingIds: finishedProcessing,
        errorMessage: e is ApiError ? e.message : 'Không thể cập nhật quyền',
        clearActionMessage: true,
      ));
    }
  }

  Future<void> _onStatusToggleRequested(
    UserStatusToggleRequested event,
    Emitter<UserState> emit,
  ) async {
    final nextProcessing = Set<String>.from(state.processingIds)..add(event.userId);
    emit(state.copyWith(
      processingIds: nextProcessing,
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    try {
      UserModel updated;
      if (event.isActive) {
        updated = await _userRepository.setActiveStatus(event.userId, true);
      } else {
        await _userRepository.deactivate(event.userId);
        final current = state.users.firstWhere((u) => u.id == event.userId);
        updated = current.copyWith(isActive: false);
      }
      final list = state.users.map((u) {
        return u.id == event.userId ? updated : u;
      }).toList();
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        users: list,
        processingIds: finishedProcessing,
        actionMessage: event.isActive ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản',
        clearErrorMessage: true,
      ));
    } catch (e) {
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        processingIds: finishedProcessing,
        errorMessage: e is ApiError ? e.message : 'Thao tác trạng thái thất bại',
        clearActionMessage: true,
      ));
    }
  }

  Future<void> _onCreateRequested(
    UserCreateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(clearErrorMessage: true, clearActionMessage: true));

    try {
      final newUser = await _userRepository.createUser(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        role: event.role,
        phone: event.phone,
      );
      if (!state.users.any((u) => u.id == newUser.id)) {
        final list = [newUser, ...state.users];
        emit(state.copyWith(
          users: list,
          actionMessage: 'Đã tạo thành công tài khoản cho ${newUser.fullName}',
          clearErrorMessage: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e is ApiError ? e.message : 'Lỗi tạo tài khoản: ${e.toString()}',
        clearActionMessage: true,
      ));
    }
  }
  Future<void> _onPasswordChangeRequested(
    UserPasswordChangeRequested event,
    Emitter<UserState> emit,
  ) async {
    final nextProcessing = Set<String>.from(state.processingIds)..add(event.userId);
    emit(state.copyWith(
      processingIds: nextProcessing,
      clearErrorMessage: true,
      clearActionMessage: true,
    ));

    try {
      await _userRepository.changePassword(event.userId, event.newPassword);
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      final user = state.users.where((u) => u.id == event.userId).firstOrNull;
      final name = user != null && user.fullName.isNotEmpty ? user.fullName : (user?.email ?? 'tài khoản');
      emit(state.copyWith(
        processingIds: finishedProcessing,
        actionMessage: 'Đã đổi mật khẩu cho tài khoản $name',
        clearErrorMessage: true,
      ));
    } catch (e) {
      final finishedProcessing = Set<String>.from(state.processingIds)..remove(event.userId);
      emit(state.copyWith(
        processingIds: finishedProcessing,
        errorMessage: e is ApiError ? e.message : 'Không thể đổi mật khẩu tài khoản',
        clearActionMessage: true,
      ));
    }
  }

}
