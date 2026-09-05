import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dio_client.dart';

/// Mô hình một sự kiện Server-Sent Event (SSE)
class SseEvent {
  final String event;
  final dynamic data;
  final String? id;
  final int? retry;
  final DateTime timestamp;

  SseEvent({
    required this.event,
    this.data,
    this.id,
    this.retry,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'SseEvent(event: $event, data: $data, id: $id)';
}

/// Trạng thái kết nối của luồng SSE
enum SseConnectionState {
  connecting,
  connected,
  disconnected,
  error,
}

/// Client quản lý kết nối và phân tích cú pháp luồng SSE (Server-Sent Events)
class SseClient {
  final Dio _dio;
  final String path;
  final Future<String?> Function()? tokenProvider;
  final Duration defaultReconnectDelay;

  final _eventController = StreamController<SseEvent>.broadcast();
  final _stateController = StreamController<SseConnectionState>.broadcast();

  StreamSubscription? _streamSubscription;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  SseConnectionState _state = SseConnectionState.disconnected;
  int _retryMs = 5000;

  SseClient({
    required this.path,
    Dio? dio,
    DioClient? dioClient,
    this.tokenProvider,
    this.defaultReconnectDelay = const Duration(seconds: 5),
  })  : _dio = dio ?? (dioClient ?? DioClient()).dio,
        _retryMs = defaultReconnectDelay.inMilliseconds;

  /// Stream các sự kiện nhận được từ máy chủ
  Stream<SseEvent> get events => _eventController.stream;

  /// Stream trạng thái kết nối
  Stream<SseConnectionState> get connectionState => _stateController.stream;

  /// Trạng thái kết nối hiện tại
  SseConnectionState get state => _state;

  /// Kiểm tra có đang kết nối hay không
  bool get isConnected => _state == SseConnectionState.connected;

  void _setState(SseConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Bắt đầu kết nối luồng SSE
  Future<void> connect() async {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _startConnection();
  }

  Future<void> _startConnection() async {
    if (_isDisposed) return;
    _setState(SseConnectionState.connecting);

    try {
      final token = tokenProvider != null ? await tokenProvider!() : null;

      final queryParams = <String, dynamic>{
        if (token != null && token.isNotEmpty) 'token': token,
      };

      final headers = <String, dynamic>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await _dio.get<ResponseBody>(
        path,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          receiveTimeout: Duration.zero,
        ),
      );

      final responseBody = response.data;
      if (responseBody == null) {
        throw Exception('Phản hồi SSE không có luồng dữ liệu (null stream).');
      }

      _setState(SseConnectionState.connected);

      String? currentEvent;
      String? currentId;
      final dataBuffer = StringBuffer();

      _streamSubscription = responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          final trimmed = line.trim();

          // Dòng comment hoặc ping
          if (trimmed.startsWith(':')) {
            return;
          }

          if (trimmed.startsWith('event:')) {
            currentEvent = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            final val = line.length > 5 ? line.substring(5).trimLeft() : '';
            if (dataBuffer.isNotEmpty) {
              dataBuffer.write('\n');
            }
            dataBuffer.write(val);
          } else if (trimmed.startsWith('id:')) {
            currentId = trimmed.substring(3).trim();
          } else if (trimmed.startsWith('retry:')) {
            final ms = int.tryParse(trimmed.substring(6).trim());
            if (ms != null && ms > 0) {
              _retryMs = ms;
            }
          } else if (trimmed.isEmpty) {
            // Khi gặp dòng trống: Phát tán sự kiện nếu có dữ liệu hoặc tên sự kiện
            if (currentEvent != null || dataBuffer.isNotEmpty) {
              final rawData = dataBuffer.toString();
              dynamic parsedData = rawData;
              if (rawData.isNotEmpty) {
                try {
                  parsedData = jsonDecode(rawData);
                } catch (_) {
                  parsedData = rawData;
                }
              }

              final eventObj = SseEvent(
                event: currentEvent ?? 'message',
                data: parsedData,
                id: currentId,
                retry: _retryMs,
              );

              if (!_eventController.isClosed) {
                _eventController.add(eventObj);
              }
            }

            // Đặt lại buffer cho sự kiện tiếp theo
            currentEvent = null;
            currentId = null;
            dataBuffer.clear();
          }
        },
        onError: (err) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_isDisposed) return;
    _setState(SseConnectionState.disconnected);

    // Lên lịch kết nối lại tự động
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _retryMs), () {
      if (!_isDisposed) {
        _startConnection();
      }
    });
  }

  /// Tạm dừng hoặc ngắt kết nối
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _setState(SseConnectionState.disconnected);
  }

  /// Hủy vĩnh viễn client
  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
