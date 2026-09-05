import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/network/sse_client.dart';
import 'package:hotel_app/core/storage/token_storage.dart';
import 'package:hotel_app/features/admin/screens/user_management_screen.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('User Management Realtime SSE Tests', () {
    test('UserRepository tạo SseClient kết nối đúng path /users/stream', () {
      final repo = UserRepository(tokenStorage: _MockTokenStorage());
      final client = repo.createUsersSseClient(token: 'test_token');
      expect(client.path, contains('/users/stream'));
      client.dispose();
    });

    test('SseClient nhận event từ _MockUserDioClient', () async {
      final mock = _MockUserDioClient();
      final sseClient = SseClient(path: '/users/stream', dio: mock.dio);
      final events = <SseEvent>[];
      sseClient.events.listen(events.add);
      await sseClient.connect();
      expect(sseClient.isConnected, isTrue);

      mock.emitEvent('user.created', '{"user":{"id":"u1"}}');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events.length, 1);
      expect(events.first.event, 'user.created');
      sseClient.dispose();
      mock.close();
    });

    testWidgets(
      'UserManagementScreen cập nhật realtime khi nhận user.created, user.updated, user.deactivated',
      (tester) async {
        final mockDioClient = _MockUserDioClient();
        final mockTokenStorage = _MockTokenStorage();
        final repo = UserRepository(
          dioClient: mockDioClient,
          tokenStorage: mockTokenStorage,
        );

        final adminUser = UserModel(
          id: 'admin-1',
          email: 'admin@hotel.com',
          fullName: 'Admin User',
          role: UserRole.admin,
        );

        final authBloc = _FakeAuthBloc(adminUser, mockTokenStorage);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: UserManagementScreen(userRepository: repo),
            ),
          ),
        );

        // Chờ màn hình nạp dữ liệu ban đầu
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Admin User'), findsOneWidget);

        // Chờ SSE stream kết nối và hiện huy hiệu 'Live'
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.text('Live').evaluate().isNotEmpty) break;
        }
        expect(find.text('Live'), findsOneWidget);

        // 1. Bắn sự kiện user.created
        mockDioClient.emitEvent(
          'user.created',
          jsonEncode({
            'user': {
              'id': 'u-new',
              'email': 'newbie@hotel.com',
              'fullName': 'Nguyễn Văn Mới',
              'role': 'CUSTOMER',
              'isActive': true,
            },
          }),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Nguyễn Văn Mới'), findsOneWidget);

        // 2. Bắn sự kiện user.updated: Đổi tên
        mockDioClient.emitEvent(
          'user.updated',
          jsonEncode({
            'user': {
              'id': 'u-new',
              'email': 'newbie@hotel.com',
              'fullName': 'Nguyễn Văn Đã Đổi Tên',
              'role': 'CUSTOMER',
              'isActive': true,
            },
          }),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Nguyễn Văn Đã Đổi Tên'), findsOneWidget);

        // 3. Bắn sự kiện user.deactivated: Khóa tài khoản
        mockDioClient.emitEvent(
          'user.deactivated',
          jsonEncode({
            'user': {'id': 'u-new'},
          }),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Đã khóa'), findsWidgets);

        await tester.pumpWidget(const SizedBox());
        mockDioClient.close();
        authBloc.close();
      },
    );
  });
}

class _FakeAuthBloc extends AuthBloc {
  _FakeAuthBloc(UserModel user, TokenStorage storage)
    : super(tokenStorage: storage) {
    emit(AuthAuthenticated(user));
  }
}

class _MockTokenStorage implements TokenStorage {
  @override
  Future<String?> getAccessToken() async => 'test_token';

  @override
  Future<String?> getRefreshToken() async => 'test_refresh';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> saveUser(UserModel user) async {}

  @override
  Future<UserModel?> getUser() async => null;

  @override
  Future<void> clearAll() async {}
}

class _MockUserAdapter implements HttpClientAdapter {
  final StreamController<Uint8List> _streamController =
      StreamController<Uint8List>.broadcast();

  void emitEvent(String eventName, String dataJson) {
    final sse = 'event: $eventName\ndata: $dataJson\n\n';
    _streamController.add(Uint8List.fromList(utf8.encode(sse)));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/users/stream')) {
      return ResponseBody(
        _streamController.stream,
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        },
      );
    }

    final initialUsers = [
      {
        'id': 'admin-1',
        'email': 'admin@hotel.com',
        'fullName': 'Admin User',
        'role': 'ADMIN',
        'isActive': true,
      },
    ];

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': initialUsers}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {
    _streamController.close();
  }
}

class _MockUserDioClient implements DioClient {
  final _MockUserAdapter adapter = _MockUserAdapter();

  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) {}

  _MockUserDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
  }

  void emitEvent(String eventName, String dataJson) {
    adapter.emitEvent(eventName, dataJson);
  }

  void close() {
    adapter.close();
  }
}
