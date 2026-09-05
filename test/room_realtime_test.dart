import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoomRepository Realtime SSE Tests', () {
    test('Xử lý room.status_changed, room.created, room.updated, room.deleted', () async {
      final sseAdapter = _MockRoomStreamAdapter();
      DioClient().dio.httpClientAdapter = sseAdapter;

      final repo = RoomRepository();

      // Thêm phòng vào repo
      await repo.addRoom(RoomModel(
        id: 'room-101',
        roomNumber: '101',
        floor: 1,
        status: RoomStatus.available,
        pricePerNight: 500000,
      ));
      expect(repo.rooms.length, 1);
      expect(repo.rooms.first.status, RoomStatus.available);

      repo.startRealtimeStream();
      await Future.delayed(const Duration(milliseconds: 20));

      // 1. Giả lập sự kiện room.status_changed: 101 đổi sang OCCUPIED
      sseAdapter.emitEvent(
        'room.status_changed',
        jsonEncode({
          'room': {'id': 'room-101', 'roomNumber': '101', 'status': 'OCCUPIED'}
        }),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repo.rooms.first.status, RoomStatus.occupied);

      // 2. Kiểm tra room.created
      sseAdapter.emitEvent(
        'room.created',
        jsonEncode({
          'room': {
            'id': 'room-202',
            'roomNumber': '202',
            'floor': 2,
            'status': 'AVAILABLE',
            'pricePerNight': 800000,
          }
        }),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repo.rooms.length, 2);
      expect(repo.rooms.any((r) => r.id == 'room-202'), isTrue);

      // 3. Kiểm tra room.updated
      sseAdapter.emitEvent(
        'room.updated',
        jsonEncode({
          'room': {
            'id': 'room-202',
            'roomNumber': '202',
            'floor': 2,
            'status': 'CLEANING',
            'pricePerNight': 900000,
          }
        }),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repo.rooms.firstWhere((r) => r.id == 'room-202').status, RoomStatus.cleaning);

      // 4. Kiểm tra room.deleted
      sseAdapter.emitEvent(
        'room.deleted',
        jsonEncode({'id': 'room-101'}),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repo.rooms.length, 1);
      expect(repo.rooms.any((r) => r.id == 'room-101'), isFalse);

      repo.stopRealtimeStream();
    });
  });
}

class _MockRoomStreamAdapter implements HttpClientAdapter {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>.broadcast();

  void emitEvent(String eventName, String dataJson) {
    final sse = 'event: $eventName\ndata: $dataJson\n\n';
    _controller.add(Uint8List.fromList(utf8.encode(sse)));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/rooms/stream')) {
      return ResponseBody(
        _controller.stream,
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        },
      );
    }

    final dataMap = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : <String, dynamic>{};
    dataMap.putIfAbsent('id', () => 'room-101');

    return ResponseBody.fromString(
      jsonEncode({
        'statusCode': 201,
        'success': true,
        'data': dataMap,
      }),
      201,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {
    _controller.close();
  }
}
