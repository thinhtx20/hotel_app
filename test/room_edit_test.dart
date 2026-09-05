import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/constants/role_permissions.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/api_error.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/admin/widgets/edit_room_modal.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/widgets/custom_text_field.dart';

class MockEditDioClient implements DioClient {
  String? lastMethod;
  String? lastPath;
  dynamic lastData;
  bool shouldThrow409 = false;

  @override
  late final Dio dio;

  MockEditDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            lastMethod = options.method;
            lastPath = options.path;
            lastData = options.data;

            if (shouldThrow409) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 409,
                    data: {
                      'statusCode': 409,
                      'message': 'Số phòng 102 đã tồn tại',
                      'error': 'Conflict',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            }

            if (options.path == ApiEndpoints.roomTypes) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': 'type-deluxe',
                        'name': 'Deluxe City View',
                        'code': 'DLX',
                        'basePrice': 1500000,
                      },
                      {
                        'id': 'type-suite',
                        'name': 'Executive Suite',
                        'code': 'SUI',
                        'basePrice': 2500000,
                      },
                    ],
                  },
                ),
              );
            }

            if (options.path.startsWith('/rooms/')) {
              final id = options.path.split('/').last;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': id,
                      'roomNumber': options.data?['roomNumber'] ?? '101',
                      'floor': options.data?['floor'] ?? 1,
                      'status': options.data?['status'] ?? 'AVAILABLE',
                      'pricePerNight': options.data?['pricePerNight'] ?? 1500000,
                      'roomTypeId': options.data?['roomTypeId'] ?? 'type-deluxe',
                      'roomTypeName': 'Deluxe City View',
                      'amenities': options.data?['amenities'] ?? ['Wifi tốc độ cao'],
                      'description': options.data?['description'] ?? 'Mô tả mới',
                      'notes': options.data?['notes'] ?? 'Ghi chú mới',
                    },
                  },
                ),
              );
            }

            return handler.next(options);
          },
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

void main() {
  group('Role Permissions - canEditRoom', () {
    test('Chỉ vai trò ADMIN mới có quyền sửa phòng (canEditRoom)', () {
      expect(UserRole.admin.canEditRoom, isTrue);
      expect(UserRole.receptionist.canEditRoom, isFalse);
      expect(UserRole.customer.canEditRoom, isFalse);
    });
  });

  group('RoomRepository - updateRoom via PUT /api/v1/rooms/:id', () {
    late MockEditDioClient mockDio;
    late RoomRepository repo;

    setUp(() {
      mockDio = MockEditDioClient();
      repo = RoomRepository(dioClient: mockDio);
    });

    test('updateRoom thực hiện đúng HTTP PUT tới /rooms/:id với dữ liệu chuẩn', () async {
      final payload = {
        'roomNumber': '101B',
        'floor': 2,
        'status': 'AVAILABLE',
        'pricePerNight': 1600000,
        'description': 'Phòng đã sửa',
      };

      final result = await repo.updateRoom('room_101', payload);

      // Xác minh phương thức là PUT
      expect(mockDio.lastMethod, equals('PUT'));
      // Xác minh endpoint là /rooms/room_101
      expect(mockDio.lastPath, equals(ApiEndpoints.updateRoom('room_101')));
      // Xác minh dữ liệu gửi đi khớp với payload
      expect(mockDio.lastData, equals(payload));

      // Xác minh kết quả trả về parse đúng RoomModel
      expect(result.id, equals('room_101'));
      expect(result.roomNumber, equals('101B'));
      expect(result.floor, equals(2));
      expect(result.pricePerNight, equals(1600000));
    });

    test('updateRoom ném ApiError khi server trả về lỗi 409 Conflict (trùng số phòng)', () async {
      mockDio.shouldThrow409 = true;

      final payload = {
        'roomNumber': '102',
      };

      expect(
        () => repo.updateRoom('room_101', payload),
        throwsA(
          isA<ApiError>().having(
            (e) => e.statusCode,
            'statusCode',
            409,
          ).having(
            (e) => e.message,
            'message',
            contains('Số phòng 102 đã tồn tại'),
          ),
        ),
      );
    });
  });

  group('EditRoomModal Widget Tests', () {
    late MockEditDioClient mockDio;
    late RoomRepository repo;

    final testRoom = RoomModel(
      id: 'room_101',
      roomNumber: '101',
      floor: 1,
      status: RoomStatus.available,
      pricePerNight: 1200000,
      roomTypeId: 'type-deluxe',
      roomTypeName: 'Deluxe City View',
      description: 'Phòng ban công thoáng mát',
      amenities: ['Wifi tốc độ cao', 'Điều hòa 2 chiều'],
      notes: 'Ghi chú thử nghiệm',
    );

    setUp(() {
      mockDio = MockEditDioClient();
      repo = RoomRepository(dioClient: mockDio);
    });

    testWidgets('EditRoomModal hiển thị đúng dữ liệu ban đầu của phòng', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditRoomModal.show(
                  context: ctx,
                  room: testRoom,
                  roomRepository: repo,
                ),
                child: const Text('Mở Modal'),
              ),
            ),
          ),
        ),
      );

      // Bấm mở modal
      await tester.tap(find.text('Mở Modal'));
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và thông tin endpoint
      expect(find.text('Sửa Phòng 101'), findsOneWidget);
      expect(find.text('PUT /api/v1/rooms/:id'), findsOneWidget);
      expect(find.text('QUẢN TRỊ VIÊN'), findsOneWidget);

      // Kiểm tra các trường form đã được nạp sẵn
      expect(find.text('101'), findsOneWidget);
      expect(find.text('Phòng ban công thoáng mát'), findsOneWidget);
      expect(find.text('Ghi chú thử nghiệm'), findsOneWidget);
      expect(find.text('Lưu Thay Đổi (PUT)'), findsOneWidget);
    });

    testWidgets('EditRoomModal submit gọi repo.updateRoom qua PUT', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool successCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => EditRoomModal.show(
                  context: ctx,
                  room: testRoom,
                  roomRepository: repo,
                  onSuccess: () => successCalled = true,
                ),
                child: const Text('Mở Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal'));
      await tester.pumpAndSettle();

      // Nhập số phòng mới
      final roomNumberField = find.widgetWithText(CustomTextField, 'Số phòng *');
      expect(roomNumberField, findsOneWidget);
      await tester.enterText(find.descendant(of: roomNumberField, matching: find.byType(TextField)), '105');
      await tester.pumpAndSettle();

      // Cuộn tới nút Lưu Thay Đổi
      final submitBtn = find.text('Lưu Thay Đổi (PUT)');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Xác minh PUT đã được gọi với số phòng mới
      expect(mockDio.lastMethod, equals('PUT'));
      expect(mockDio.lastPath, equals('/rooms/room_101'));
      expect(mockDio.lastData['roomNumber'], equals('105'));
      expect(successCalled, isTrue);
    });
  });
}
