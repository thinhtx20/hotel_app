import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/storage/token_storage.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_event.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/widgets/logout_confirmation_dialog.dart';

class FakeTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;
  UserModel? _user;

  FakeTokenStorage({String? accessToken, String? refreshToken, UserModel? user})
      : _access = accessToken,
        _refresh = refreshToken {
    _user = user;
  }

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> saveUser(UserModel user) async {
    _user = user;
  }

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<void> clearAll() async {
    _access = null;
    _refresh = null;
    _user = null;
  }
}

class MockDioClient implements DioClient {
  final List<String> requestedPaths = [];
  dynamic lastData;
  bool shouldThrow = false;
  @override
  late final Dio dio;

  MockDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            lastData = options.data;
            if (shouldThrow) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: 'Network connection lost',
                ),
              );
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'message': 'Đăng xuất thành công'},
              ),
            );
          },
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Logout & API Integration Tests', () {
    test('AuthBloc logout calls POST /auth/logout and clears tokens', () async {
      final mockDioClient = MockDioClient();
      final tokenStorage = FakeTokenStorage(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
      );

      final authBloc = AuthBloc(
        dioClient: mockDioClient,
        tokenStorage: tokenStorage,
      );

      expect(authBloc.state, isA<AuthInitial>());

      final streamExpectation = expectLater(
        authBloc.stream,
        emits(isA<AuthUnauthenticated>()),
      );

      authBloc.add(AuthLogoutRequested());
      await streamExpectation;

      expect(mockDioClient.requestedPaths, contains(ApiEndpoints.logout));
      expect(mockDioClient.lastData, {'refreshToken': 'test-refresh-token'});

      final storedAccess = await tokenStorage.getAccessToken();
      final storedRefresh = await tokenStorage.getRefreshToken();
      expect(storedAccess, isNull);
      expect(storedRefresh, isNull);
    });

    test('AuthBloc logout still cleans local storage even when network fails', () async {
      final mockDioClient = MockDioClient()..shouldThrow = true;
      final tokenStorage = FakeTokenStorage(
        accessToken: 'test-access-2',
        refreshToken: 'test-refresh-2',
      );

      final authBloc = AuthBloc(
        dioClient: mockDioClient,
        tokenStorage: tokenStorage,
      );

      final streamExpectation = expectLater(
        authBloc.stream,
        emits(isA<AuthUnauthenticated>()),
      );

      authBloc.add(AuthLogoutRequested());
      await streamExpectation;

      final storedAccess = await tokenStorage.getAccessToken();
      final storedRefresh = await tokenStorage.getRefreshToken();
      expect(storedAccess, isNull);
      expect(storedRefresh, isNull);
    });

    testWidgets('LogoutConfirmationDialog displays luxury modal and dismisses on Cancel', (tester) async {
      final mockDioClient = MockDioClient();
      final tokenStorage = FakeTokenStorage();
      final authBloc = AuthBloc(dioClient: mockDioClient, tokenStorage: tokenStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => LogoutConfirmationDialog.show(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Xác Nhận Đăng Xuất'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Đăng Xuất'), findsOneWidget);

      // Nhấn 'Hủy' để đóng dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.text('Xác Nhận Đăng Xuất'), findsNothing);
      expect(authBloc.state, isA<AuthInitial>());
    });

    testWidgets('LogoutConfirmationDialog confirms and triggers logout', (tester) async {
      final mockDioClient = MockDioClient();
      final tokenStorage = FakeTokenStorage(
        accessToken: 'valid-access',
        refreshToken: 'valid-refresh',
      );
      final authBloc = AuthBloc(dioClient: mockDioClient, tokenStorage: tokenStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => LogoutConfirmationDialog.show(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Nhấn 'Đăng Xuất' trong modal
      await tester.tap(find.text('Đăng Xuất'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      // Modal đóng và state chuyển về AuthUnauthenticated
      expect(find.text('Xác Nhận Đăng Xuất'), findsNothing);
      expect(authBloc.state, isA<AuthUnauthenticated>());
      expect(await tokenStorage.getAccessToken(), isNull);
    });
  });
}
