import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/core/storage/token_storage.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/admin/bloc/user_bloc.dart';
import 'package:hotel_app/features/admin/bloc/user_event.dart';
import 'package:hotel_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/features/customer/screens/home_screen.dart';
import 'package:hotel_app/features/receptionist/screens/room_matrix_screen.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';

class _FakeTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;
  UserModel? _user;

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> saveUser(UserModel user) async => _user = user;

  @override
  Future<void> clearAll() async {
    _access = null;
    _refresh = null;
    _user = null;
  }
}

class _DynamicRoleDioClient implements DioClient {
  @override
  late final Dio dio;

  _DynamicRoleDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/login')) {
              final email = options.data['email'] as String? ?? '';
              UserRole role = UserRole.customer;
              if (email.contains('admin')) {
                role = UserRole.admin;
              } else if (email.contains('reception')) {
                role = UserRole.receptionist;
              }
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'user': {
                        'id': '${role.value}-id',
                        'email': email,
                        'fullName': role.label,
                        'role': role.value,
                      },
                      'accessToken': 'access-${role.value}',
                      'refreshToken': 'refresh-${role.value}',
                    },
                  },
                ),
              );
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': []},
              ),
            );
          },
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

class _SlowUserRepository extends UserRepository {
  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return UserModel(
      id: id,
      email: 'test@hotel.com',
      fullName: 'Test User',
      role: UserRole.customer,
    );
  }
}

UserModel _userFor(UserRole role) => UserModel(
      id: '${role.value}-id',
      email: '${role.value.toLowerCase()}@hotel.com',
      fullName: role.label,
      role: role,
    );

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      await initDependencies();
    }
    if (sl.isRegistered<DioClient>()) {
      sl.unregister<DioClient>();
    }
    sl.registerSingleton<DioClient>(_DynamicRoleDioClient());
  });

  group('Kiểm tra đổi role không bị crash app', () {
    testWidgets('Đổi role 1-chạm từ màn hình Profile chuyển đổi mượt mà không văng app',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dioClient = _DynamicRoleDioClient();
      final tokenStorage = _FakeTokenStorage();
      final authBloc = AuthBloc(
        dioClient: dioClient,
        tokenStorage: tokenStorage,
      );

      final admin = _userFor(UserRole.admin);
      await tokenStorage.saveUser(admin);
      await tokenStorage.saveTokens(
        accessToken: 'access-ADMIN',
        refreshToken: 'refresh-ADMIN',
      );
      authBloc.emit(AuthAuthenticated(admin));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
          child: HotelApp(router: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Đang ở Admin Profile
      router.go('/admin/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Chuyển sang Lễ tân – Thu ngân
      final receptionBtn = find.text('Lễ tân – Thu ngân');
      expect(receptionBtn, findsOneWidget);
      await tester.ensureVisible(receptionBtn);
      await tester.pump();
      await tester.tap(receptionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect((authBloc.state as AuthAuthenticated).user.role, UserRole.receptionist);
      expect(find.byType(RoomMatrixScreen), findsOneWidget);

      // Đang ở Lễ tân: vào Profile
      router.go('/receptionist/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Chuyển sang Khách hàng
      final customerBtn = find.text('Khách hàng');
      expect(customerBtn, findsOneWidget);
      await tester.ensureVisible(customerBtn);
      await tester.pump();
      await tester.tap(customerBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect((authBloc.state as AuthAuthenticated).user.role, UserRole.customer);
      expect(find.byType(CustomerHomeScreen), findsOneWidget);

      // Đang ở Khách hàng: vào Profile
      router.go('/profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Chuyển sang Quản trị viên
      final adminBtn = find.text('Quản trị viên');
      expect(adminBtn, findsOneWidget);
      await tester.ensureVisible(adminBtn);
      await tester.pump();
      await tester.tap(adminBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect((authBloc.state as AuthAuthenticated).user.role, UserRole.admin);
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    test('UserBloc đóng khi đang chạy async không ném lỗi emit after close',
        () async {
      final repo = _SlowUserRepository();
      final userBloc = UserBloc(userRepository: repo);

      userBloc.add(const UserRoleUpdateRequested(
        userId: 'test-1',
        role: UserRole.receptionist,
      ));
      // Đóng bloc ngay lập tức trong khi API đang chạy dở
      await userBloc.close();

      // Chờ API hoàn thành để đảm bảo emit không ném StateError
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}
