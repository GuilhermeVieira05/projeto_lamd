import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/ws_client.dart';
import '../network/http_client.dart';

class NotificationProvider extends ChangeNotifier {
  final Stream<WsMessage> _wsMessages;
  StreamSubscription<WsMessage>? _subscription;

  int _unreadCount = 0;
  WsMessage? _latestMessage;

  int get unreadCount => _unreadCount;
  WsMessage? get latestMessage => _latestMessage;

  NotificationProvider({required Stream<WsMessage> wsMessages})
      : _wsMessages = wsMessages {
    _subscription = _wsMessages.listen(_handleMessage);
  }

  void _handleMessage(WsMessage msg) {
    if (msg.event != 'notification.new') return;
    _unreadCount++;
    _latestMessage = msg;
    notifyListeners();
  }

  Future<void> fetchInitialCount(HttpClient httpClient) async {
    try {
      final response = await httpClient.get('/notifications');
      final data = response.data as Map<String, dynamic>;
      _unreadCount = data['unreadCount'] as int? ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  void clearLatest() {
    _latestMessage = null;
    notifyListeners();
  }

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
