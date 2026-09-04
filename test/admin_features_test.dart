import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/di/injection_container.dart' as di;
import 'package:hotel_app/features/admin/screens/room_type_management_screen.dart';
import 'package:hotel_app/features/admin/screens/user_management_screen.dart';
import 'package:hotel_app/features/auth/screens/forgot_password_screen.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';

class MockAdminFeaturesDioClient implements DioClient {
  final List<String> requestedPaths = [];
  @override
  late final Dio dio;

  MockAdminFeaturesDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);

            // GET /users
            if (options.path == ApiEndpoints.users) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': 'user_1',
                        'fullName': 'Nguyễn Văn Quản Trị',
                        'email': 'admin@hotel.com',
                        'role': 'ADMIN',
                        'isActive': true,
                        'phone': '0901234567',
                      },
                      {
                        'id': 'user_2',
                        'fullName': 'Trần Thị Lễ Tân',
                        'email': 'reception@hotel.com',
                        'role': 'RECEPTIONIST',
                        'isActive': true,
                        'phone': '0902345678',
                      },
                    ],
                  },
                ),
              );
            }

            // GET /room-types
            if (options.path == ApiEndpoints.roomTypes) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': 'type_1',
                        'name': 'Deluxe Ocean Suite',
                        'code': 'DLX_OCN',
                        'basePrice': 2500000,
                        'capacityAdults': 2,
                        'capacityChildren': 1,
                        'sizeSqM': 45,
                        'description': 'View biển trực diện tầng cao',
                        'images': [],
                        '_count': {'rooms': 8},
                      },
                    ],
                  },
                ),
              );
            }

            // POST /auth/forgot-password
            if (options.path == ApiEndpoints.forgotPassword) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'OTP sent'},
                ),
              );
            }

            // POST /auth/verify-reset-otp
            if (options.path == ApiEndpoints.verifyResetOtp) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'OTP verified'},
                ),
              );
            }

            // POST /auth/reset-password
            if (options.path == ApiEndpoints.resetPassword) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'Password reset successful'},
                ),
              );
            }

            return handler.next(options);
          },
        ),
      );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await di.initDependencies();
  });

  group('UserManagementScreen Tests', () {
    testWidgets('Tải danh sách người dùng và lọc theo từ khóa tìm kiếm', (tester) async {
      final mockDio = MockAdminFeaturesDioClient();
      final userRepo = UserRepository(dioClient: mockDio);

      await tester.pumpWidget(
        MaterialApp(
          home: UserManagementScreen(userRepository: userRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra 2 người dùng hiển thị
      expect(find.text('Nguyễn Văn Quản Trị'), findsOneWidget);
      expect(find.text('Trần Thị Lễ Tân'), findsOneWidget);
      expect(find.text('admin@hotel.com'), findsOneWidget);

      // Tìm kiếm theo tên
      await tester.enterText(find.byType(TextField).first, 'Quản Trị');
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn Quản Trị'), findsOneWidget);
      expect(find.text('Trần Thị Lễ Tân'), findsNothing);
    });
  });

  group('RoomTypeManagementScreen Tests', () {
    testWidgets('Tải danh sách hạng phòng và hiển thị thông tin chi tiết', (tester) async {
      final mockDio = MockAdminFeaturesDioClient();
      final roomRepo = RoomRepository(dioClient: mockDio);

      await tester.pumpWidget(
        MaterialApp(
          home: RoomTypeManagementScreen(roomRepository: roomRepo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Deluxe Ocean Suite'), findsOneWidget);
      expect(find.text('DLX_OCN'), findsOneWidget);
      expect(find.text('8 phòng'), findsOneWidget);
      expect(find.text('Thêm hạng phòng'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Tests', () {
    testWidgets('Luồng 3 bước: Nhập email -> Nhập OTP -> Mật khẩu mới', (tester) async {
      final mockDio = MockAdminFeaturesDioClient();

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(dioClient: mockDio),
        ),
      );

      await tester.pumpAndSettle();

      // Bước 1: Nhập email
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Gửi mã xác thực'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'user@hotel.com');
      await tester.tap(find.text('Gửi mã xác thực'));
      await tester.pumpAndSettle();

      // Bước 2: Nhập OTP
      expect(find.text('Xác thực OTP'), findsWidgets);
      expect(find.text('Xác nhận mã OTP'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('Xác nhận mã OTP'));
      await tester.pumpAndSettle();

      // Bước 3: Thiết lập mật khẩu mới
      expect(find.text('Thiết lập mật khẩu mới'), findsOneWidget);
      expect(find.text('Cập nhật mật khẩu'), findsOneWidget);
    });
  });
}
