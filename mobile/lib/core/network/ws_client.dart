import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsMessage {
  final String event;
  final Map<String, dynamic> payload;

  WsMessage({required this.event, required this.payload});

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      event: json['event'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }
}

class WsClient {
  static const _baseUrl = 'ws://localhost:3000';
  static const _reconnectDelay = Duration(seconds: 3);

  WebSocketChannel? _channel;
  String? _token;
  bool _shouldReconnect = false;

  final _controller = StreamController<WsMessage>.broadcast();
  Stream<WsMessage> get messages => _controller.stream;

  void connect(String token) {
    _token = token;
    _shouldReconnect = true;
    _connect();
  }

  Future<void> _connect() async {
    if (_token == null) return;

    try {
      final uri = Uri.parse('$_baseUrl?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(WsMessage.fromJson(json));
          } catch (_) {}
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    if (_shouldReconnect) {
      Future.delayed(_reconnectDelay, _connect);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _token = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
