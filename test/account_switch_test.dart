import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/constants/role_permissions.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/core/session/session_scope.dart';
import 'package:hotel_app/core/storage/token_storage.dart';
import 'package:hotel_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:hotel_app/features/customer/screens/home_screen.dart';
import 'package:hotel_app/features/receptionist/screens/room_matrix_screen.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_event.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/repositories/service_repository.dart';

/// AuthBloc cho phép đẩy thẳng trạng thái để mô phỏng việc đổi tài khoản.
class SwitchableAuthBloc extends AuthBloc {
  SwitchableAuthBloc(AuthState initial) : super() {
    emit(initial);
  }

  void push(AuthState state) => emit(state);
}

/// Đếm số lần `initState` chạy — đại diện cho "màn hình được dựng lại".
class _Counter extends StatefulWidget {
  final List<String> log;
  const _Counter(this.log);

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    widget.log.add('build');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

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

/// DioClient trả về sẵn một tài khoản khi POST /auth/login.
class _LoginDioClient implements DioClient {
  final UserRole role;

  @override
  late final Dio dio;

  _LoginDioClient(this.role) {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'user': {
                    'id': '${role.value}-1',
                    'email': '${role.value.toLowerCase()}@hotel.com',
                    'fullName': role.label,
                    'role': role.value,
                  },
                  'accessToken': 'access-${role.value}',
                  'refreshToken': 'refresh-${role.value}',
                },
              },
            ),
          ),
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

/// DioClient trả về 401 cho mọi request — mô phỏng đổi tài khoản thất bại.
class _FailingDioClient implements DioClient {
  @override
  late final Dio dio;

  _FailingDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'message': 'Sai email hoặc mật khẩu'},
              ),
            ),
          ),
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

UserModel _userFor(UserRole role, {String suffix = '1'}) => UserModel(
      id: '${role.value}-$suffix',
      email: '${role.value.toLowerCase()}$suffix@hotel.com',
      fullName: role.label,
      role: role,
    );

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      await initDependencies();
    }
  });

  group('Đổi tài khoản đăng nhập thì đổi giao diện', () {
    testWidgets('đổi vai trò giữa phiên thì nhảy về màn chính của vai trò mới',
        (tester) async {
      final authBloc = SwitchableAuthBloc(
        AuthAuthenticated(_userFor(UserRole.customer)),
      );
      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
          child: HotelApp(router: router),
        ),
      );
      router.go('/customer');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      String location() =>
          router.routerDelegate.currentConfiguration.uri.path;
      expect(location(), '/customer');

      expect(find.byType(CustomerHomeScreen), findsOneWidget);

      // Màn hình thật của từng vai trò phải xuất hiện, không chỉ đổi địa chỉ.
      final screenOfRole = <UserRole, Type>{
        UserRole.admin: AdminDashboardScreen,
        UserRole.receptionist: RoomMatrixScreen,
      };

      for (final role in screenOfRole.keys) {
        authBloc.push(AuthLoading());
        await tester.pump();
        authBloc.push(AuthAuthenticated(_userFor(role)));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(location(), role.homeRoute,
            reason: 'đổi sang ${role.value} phải về ${role.homeRoute}');
        expect(find.byType(screenOfRole[role]!), findsOneWidget,
            reason: 'giao diện phải là màn chính của ${role.value}');
        expect(find.byType(CustomerHomeScreen), findsNothing);
      }

      authBloc.push(AuthUnauthenticated());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(location(), '/login');
    });

    testWidgets(
        'đang ở màn dùng chung của nhân viên, đổi tài khoản vẫn về màn chính',
        (tester) async {
      final authBloc = SwitchableAuthBloc(
        AuthAuthenticated(_userFor(UserRole.admin)),
      );
      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
          child: HotelApp(router: router),
        ),
      );

      // `/staff/today-check-outs` hợp lệ với cả ADMIN lẫn RECEPTIONIST, nên nếu
      // không có guard đổi tài khoản thì người dùng ở nguyên màn cũ.
      router.go('/staff/today-check-outs');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/staff/today-check-outs');

      authBloc.push(AuthAuthenticated(_userFor(UserRole.receptionist)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/receptionist',
      );
    });

    test('phiên cũ lưu CASHIER trong storage được hồi sinh thành RECEPTIONIST', () {
      final cachedUserJson = {
        'id': 'legacy-cashier-1',
        'email': 'cashier@hotel.com',
        'fullName': 'Thu Ngân Cũ',
        'role': 'CASHIER',
      };
      final user = UserModel.fromJson(cachedUserJson);
      expect(user.role, UserRole.receptionist);
      expect(user.role.label, 'Lễ tân – Thu ngân');
      expect(user.role.homeRoute, '/receptionist');
    });

    testWidgets('SessionScope dựng lại màn hình khi đổi tài khoản',
        (tester) async {
      final authBloc = SwitchableAuthBloc(
        AuthAuthenticated(_userFor(UserRole.customer)),
      );
      final log = <String>[];

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(home: SessionScope(child: _Counter(log))),
        ),
      );
      expect(log.length, 1);

      // Cùng một tài khoản: giữ nguyên State, không tải lại vô ích.
      authBloc.push(AuthAuthenticated(_userFor(UserRole.customer)));
      await tester.pump();
      await tester.pump();
      expect(log.length, 1);

      // Tài khoản khác (cùng vai trò): màn hình phải được dựng lại từ đầu.
      authBloc.push(AuthAuthenticated(_userFor(UserRole.customer, suffix: '2')));
      await tester.pump();
      await tester.pump();
      expect(log.length, 2);

      // Đăng xuất cũng là một phiên khác.
      authBloc.push(AuthUnauthenticated());
      await tester.pump();
      await tester.pump();
      expect(log.length, 3);
    });
  });

  group('Đổi tài khoản thất bại thì giữ nguyên phiên cũ', () {
    test('đăng nhập hỏng khi đang có phiên: quay lại đúng tài khoản cũ',
        () async {
      final authBloc = AuthBloc(
        dioClient: _FailingDioClient(),
        tokenStorage: _FakeTokenStorage(),
      );
      final admin = _userFor(UserRole.admin);
      authBloc.emit(AuthAuthenticated(admin));

      final states = <AuthState>[];
      final sub = authBloc.stream.listen(states.add);

      authBloc.add(AuthLoginSubmitted(
        email: 'cashier@hotel.com',
        password: 'sai-mat-khau',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(states.whereType<AuthFailure>().single.previousUser, admin);
      expect(states.last, isA<AuthAuthenticated>());
      expect((states.last as AuthAuthenticated).user.role, UserRole.admin);
    });

    testWidgets('đổi tài khoản hỏng thì không bị đá ra màn đăng nhập',
        (tester) async {
      final authBloc = SwitchableAuthBloc(
        AuthAuthenticated(_userFor(UserRole.admin)),
      );
      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
          child: HotelApp(router: router),
        ),
      );
      router.go('/admin/profile');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      authBloc.push(AuthFailure(
        'Sai email hoặc mật khẩu',
        previousUser: _userFor(UserRole.admin),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/admin/profile',
      );
    });
  });

  group('Cache của tài khoản cũ được dọn', () {
    test('đăng nhập tài khoản khác thì repository bị dọn cache', () async {
      var cleared = 0;
      final authBloc = AuthBloc(
        dioClient: _LoginDioClient(UserRole.admin),
        tokenStorage: _FakeTokenStorage(),
        onSessionReset: () => cleared++,
      );

      final done = expectLater(
        authBloc.stream,
        emitsThrough(isA<AuthAuthenticated>()),
      );
      authBloc.add(AuthLoginSubmitted(
        email: 'admin@hotel.com',
        password: 'Admin@123',
      ));
      await done;

      expect(cleared, 1, reason: 'đăng nhập phải dọn dữ liệu của phiên trước');
    });

    test('đăng xuất cũng dọn cache', () async {
      var cleared = 0;
      final authBloc = AuthBloc(
        dioClient: _LoginDioClient(UserRole.admin),
        tokenStorage: _FakeTokenStorage(),
        onSessionReset: () => cleared++,
      );

      final done = expectLater(
        authBloc.stream,
        emitsThrough(isA<AuthUnauthenticated>()),
      );
      authBloc.add(AuthLogoutRequested());
      await done;

      expect(cleared, 1);
    });

    test('clearUserScopedCaches xóa dữ liệu đã nạp của các repository', () {
      final rooms = sl<RoomRepository>();
      final bookings = sl<BookingRepository>();
      final services = sl<ServiceRepository>();

      clearUserScopedCaches();

      expect(rooms.rooms, isEmpty);
      expect(rooms.roomTypes, isEmpty);
      expect(rooms.isInitialized, isFalse);
      expect(bookings.pendingCount, 0);
      expect(services.cachedServices, isEmpty);
    });
  });
}
