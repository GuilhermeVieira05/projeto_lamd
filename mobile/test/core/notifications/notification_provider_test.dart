import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/notifications/notification_provider.dart';
import 'package:mobile/core/network/ws_client.dart';

void main() {
  group('NotificationProvider', () {
    late StreamController<WsMessage> controller;
    late NotificationProvider provider;

    setUp(() {
      controller = StreamController<WsMessage>.broadcast();
      provider = NotificationProvider(wsMessages: controller.stream);
    });

    tearDown(() {
      provider.dispose();
      controller.close();
    });

    test('initial unreadCount is 0', () {
      expect(provider.unreadCount, 0);
    });

    test('initial latestMessage is null', () {
      expect(provider.latestMessage, isNull);
    });

    test('notification.new increments unreadCount', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      await Future.delayed(Duration.zero);
      expect(provider.unreadCount, 1);
    });

    test('notification.new with refused type increments unreadCount', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.refused'}));
      await Future.delayed(Duration.zero);
      expect(provider.unreadCount, 1);
    });

    test('notification.new with completed type increments unreadCount', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.completed'}));
      await Future.delayed(Duration.zero);
      expect(provider.unreadCount, 1);
    });

    test('non notification.new event does not change unreadCount', () async {
      controller.add(WsMessage(event: 'reservation.accepted', payload: {}));
      await Future.delayed(Duration.zero);
      expect(provider.unreadCount, 0);
    });

    test('notification.new sets latestMessage', () async {
      final msg = WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted', 'payload': {'providerName': 'Maria'}});
      controller.add(msg);
      await Future.delayed(Duration.zero);
      expect(provider.latestMessage, msg);
    });

    test('clearLatest sets latestMessage to null', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      await Future.delayed(Duration.zero);
      provider.clearLatest();
      expect(provider.latestMessage, isNull);
    });

    test('clearLatest does not change unreadCount', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      await Future.delayed(Duration.zero);
      provider.clearLatest();
      expect(provider.unreadCount, 1);
    });

    test('resetUnreadCount sets unreadCount to 0', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      await Future.delayed(Duration.zero);
      provider.resetUnreadCount();
      expect(provider.unreadCount, 0);
    });

    test('multiple notification.new events accumulate unreadCount', () async {
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.refused'}));
      await Future.delayed(Duration.zero);
      expect(provider.unreadCount, 2);
    });

    test('notifyListeners called on notification.new event', () async {
      var notified = false;
      provider.addListener(() => notified = true);
      controller.add(WsMessage(event: 'notification.new', payload: {'type': 'reservation.accepted'}));
      await Future.delayed(Duration.zero);
      expect(notified, true);
    });
  });
}
