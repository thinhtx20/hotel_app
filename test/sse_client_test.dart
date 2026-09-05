import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/sse_client.dart';

void main() {
  group('SseClient Tests', () {
    test('Phân tích cú pháp chunk SSE đầy đủ: ready, data json, ping, id, retry', () async {
      final dio = Dio();
      final dioAdapter = _MockStreamAdapter();
      dio.httpClientAdapter = dioAdapter;

      final sseClient = SseClient(
        path: '/test/stream',
        dio: dio,
        tokenProvider: () async => 'mock_token',
      );

      final receivedEvents = <SseEvent>[];
      final sub = sseClient.events.listen(receivedEvents.add);

      await sseClient.connect();

      // Giả lập máy chủ gửi chunk SSE
      const ssePayload = '''
: ping comment
event: ready
id: 1
retry: 3000
data: {"message":"connected"}

event: user.created
id: 2
data: {"user":{"id":"u1","fullName":"Test User"}}

event: room.status_changed
id: 3
data: {"room":{"id":"r1","status":"OCCUPIED"}}

''';

      dioAdapter.emitString(ssePayload);

      // Cho Stream xử lý qua microtask
      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedEvents.length, 3);

      expect(receivedEvents[0].event, 'ready');
      expect(receivedEvents[0].id, '1');
      expect(receivedEvents[0].retry, 3000);
      expect(receivedEvents[0].data['message'], 'connected');

      expect(receivedEvents[1].event, 'user.created');
      expect(receivedEvents[1].id, '2');
      expect(receivedEvents[1].data['user']['id'], 'u1');

      expect(receivedEvents[2].event, 'room.status_changed');
      expect(receivedEvents[2].id, '3');
      expect(receivedEvents[2].data['room']['status'], 'OCCUPIED');

      await sub.cancel();
      sseClient.dispose();
    });

    test('Xử lý dữ liệu bị phân mảnh thành nhiều chunk', () async {
      final dio = Dio();
      final dioAdapter = _MockStreamAdapter();
      dio.httpClientAdapter = dioAdapter;

      final sseClient = SseClient(
        path: '/test/stream',
        dio: dio,
      );

      final receivedEvents = <SseEvent>[];
      final sub = sseClient.events.listen(receivedEvents.add);

      await sseClient.connect();

      // Gửi nửa đầu
      dioAdapter.emitString('event: room.updated\nid: 10\ndata: {"roo');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(receivedEvents.isEmpty, isTrue);

      // Gửi nửa sau + dòng trống kết thúc
      dioAdapter.emitString('m":{"id":"r10","status":"CLEANING"}}\n\n');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedEvents.length, 1);
      expect(receivedEvents[0].event, 'room.updated');
      expect(receivedEvents[0].id, '10');
      expect(receivedEvents[0].data['room']['status'], 'CLEANING');

      await sub.cancel();
      sseClient.dispose();
    });
  });
}

class _MockStreamAdapter implements HttpClientAdapter {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>.broadcast();

  void emitString(String text) {
    _controller.add(Uint8List.fromList(utf8.encode(text)));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      _controller.stream,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {
    _controller.close();
  }
}
