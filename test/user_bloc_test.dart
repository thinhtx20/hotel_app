import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/features/admin/bloc/user_bloc.dart';
import 'package:hotel_app/features/admin/bloc/user_event.dart';
import 'package:hotel_app/features/admin/bloc/user_state.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';

class _MockUserRepository extends UserRepository {
  List<UserModel> users;
  String? lastFetchedRole;

  _MockUserRepository(this.users);

  @override
  Future<List<UserModel>> fetchAll({
    String? role,
    String? search,
    int? page,
    int? limit,
  }) async {
    lastFetchedRole = role;
    if (role != null && role.isNotEmpty) {
      return users.where((u) => u.role.value == role).toList();
    }
    return users;
  }

  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final idx = users.indexWhere((u) => u.id == id);
    if (idx == -1) throw Exception('Not found');
    var current = users[idx];
    if (data.containsKey('role')) {
      current = current.copyWith(role: UserRole.fromString(data['role']));
    }
    if (data.containsKey('isActive')) {
      current = current.copyWith(isActive: data['isActive'] as bool);
    }
    users[idx] = current;
    return current;
  }

  @override
  Future<UserModel> setActiveStatus(String id, bool isActive) async {
    return updateUser(id, {'isActive': isActive});
  }

  @override
  Future<void> deactivate(String id) async {
    final idx = users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      users[idx] = users[idx].copyWith(isActive: false);
    }
  }

  @override
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? avatar,
    bool isActive = true,
  }) async {
    final newUser = UserModel(
      id: 'u-${users.length + 1}',
      email: email,
      fullName: fullName,
      role: UserRole.fromString(role),
      phone: phone,
      isActive: isActive,
    );
    users.insert(0, newUser);
    return newUser;
  }
}

void main() {
  group('UserBloc Tests', () {
    late _MockUserRepository mockRepo;
    late UserBloc userBloc;

    final sampleUsers = [
      UserModel(
        id: 'u-1',
        email: 'admin@hotel.com',
        fullName: 'Nguyễn Văn Bình',
        phone: '0912345678',
        role: UserRole.admin,
        isActive: true,
      ),
      UserModel(
        id: 'u-2',
        email: 'reception@hotel.com',
        fullName: 'Receptionist B',
        role: UserRole.receptionist,
        isActive: true,
      ),
      UserModel(
        id: 'u-3',
        email: 'customer@gmail.com',
        fullName: 'Customer C',
        role: UserRole.customer,
        isActive: false,
      ),
    ];

    setUp(() {
      mockRepo = _MockUserRepository(List.from(sampleUsers));
      userBloc = UserBloc(userRepository: mockRepo);
    });

    tearDown(() {
      userBloc.close();
    });

    test('initial state has default values', () {
      expect(userBloc.state.status, UserStatus.initial);
      expect(userBloc.state.users, isEmpty);
      expect(userBloc.state.isRealtimeConnected, isFalse);
    });

    test('UserFetchRequested emits loading then success', () async {
      userBloc.add(const UserFetchRequested());

      await expectLater(
        userBloc.stream,
        emitsInOrder([
          predicate<UserState>((s) => s.status == UserStatus.loading),
          predicate<UserState>((s) =>
              s.status == UserStatus.success && s.users.length == 3),
        ]),
      );
    });

    test('UserSearchChanged filters users properly', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      userBloc.add(const UserSearchChanged('Receptionist'));
      await expectLater(
        userBloc.stream,
        emits(predicate<UserState>((s) =>
            s.searchQuery == 'Receptionist' &&
            s.filteredUsers.length == 1 &&
            s.filteredUsers.first.id == 'u-2')),
      );
    });

    test('UserSearchChanged filters without accent or case sensitivity', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      // Tìm không dấu chữ thường
      userBloc.add(const UserSearchChanged('nguyen'));
      var state = await userBloc.stream.firstWhere((s) => s.searchQuery == 'nguyen');
      expect(state.filteredUsers.length, 1);
      expect(state.filteredUsers.first.fullName, 'Nguyễn Văn Bình');

      // Tìm có dấu chữ hoa
      userBloc.add(const UserSearchChanged('NGUYỄN'));
      state = await userBloc.stream.firstWhere((s) => s.searchQuery == 'NGUYỄN');
      expect(state.filteredUsers.length, 1);
      expect(state.filteredUsers.first.fullName, 'Nguyễn Văn Bình');

      // Tìm theo cụm từ không dấu đảo thứ tự
      userBloc.add(const UserSearchChanged('binh nguyen'));
      state = await userBloc.stream.firstWhere((s) => s.searchQuery == 'binh nguyen');
      expect(state.filteredUsers.length, 1);
      expect(state.filteredUsers.first.fullName, 'Nguyễn Văn Bình');

      // Tìm theo SĐT
      userBloc.add(const UserSearchChanged('0912'));
      state = await userBloc.stream.firstWhere((s) => s.searchQuery == '0912');
      expect(state.filteredUsers.length, 1);
      expect(state.filteredUsers.first.fullName, 'Nguyễn Văn Bình');
    });

    test('UserStatusFilterChanged filters active or inactive users', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      userBloc.add(const UserStatusFilterChanged(false));
      await expectLater(
        userBloc.stream,
        emits(predicate<UserState>((s) =>
            s.selectedStatusFilter == false &&
            s.filteredUsers.length == 1 &&
            s.filteredUsers.first.id == 'u-3')),
      );
    });

    test('UserRoleUpdateRequested updates role in state', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      userBloc.add(const UserRoleUpdateRequested(
        userId: 'u-3',
        role: UserRole.receptionist,
      ));

      final state = await userBloc.stream.firstWhere((s) => s.actionMessage == 'Đã cập nhật vai trò');
      expect(state.users.firstWhere((u) => u.id == 'u-3').role, UserRole.receptionist);
    });

    test('UserStatusToggleRequested toggles user active state', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      userBloc.add(const UserStatusToggleRequested(
        userId: 'u-3',
        isActive: true,
      ));

      final state = await userBloc.stream.firstWhere((s) => s.actionMessage == 'Đã mở khóa tài khoản');
      expect(state.users.firstWhere((u) => u.id == 'u-3').isActive, isTrue);
    });

    test('UserCreateRequested adds user to the top of the list', () async {
      userBloc.add(const UserFetchRequested());
      await userBloc.stream.firstWhere((s) => s.status == UserStatus.success);

      userBloc.add(const UserCreateRequested(
        email: 'new@test.com',
        password: 'password123',
        fullName: 'New User',
        role: 'CUSTOMER',
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(userBloc.state.users.first.fullName, 'New User');
      expect(userBloc.state.users.length, 4);
    });
  });
}
