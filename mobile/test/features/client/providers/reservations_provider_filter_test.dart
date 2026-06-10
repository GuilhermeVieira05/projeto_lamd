import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/client/providers/reservations_provider.dart';
import 'package:mobile/features/client/services/reservations_api.dart';
import 'package:mobile/core/network/ws_client.dart';

// Fake API that returns a fixed list
class _FakeApi extends Fake implements ReservationsApi {
  final List<ReservationModel> items;
  _FakeApi(this.items);
  @override
  Future<List<ReservationModel>> listReservations() async => items;
}

// Fake WsClient with a controllable stream
class _FakeWs extends Fake implements WsClient {
  final _ctrl = StreamController<WsMessage>.broadcast();
  @override
  Stream<WsMessage> get messages => _ctrl.stream;
  @override
  void dispose() => _ctrl.close();
}

ReservationModel _res({
  required String id,
  required String status,
  required DateTime scheduledAt,
}) =>
    ReservationModel(
      id: id,
      serviceTypeName: 'Corte',
      providerName: 'João',
      status: status,
      scheduledAt: scheduledAt,
    );

void main() {
  final now = DateTime.now();
  final future = now.add(const Duration(days: 3));
  final past = now.subtract(const Duration(days: 3));

  late _FakeWs fakeWs;

  setUp(() {
    fakeWs = _FakeWs();
  });

  tearDown(() {
    fakeWs.dispose();
  });

  ReservationsProvider makeProvider(List<ReservationModel> items) {
    final p = ReservationsProvider(api: _FakeApi(items), ws: fakeWs);
    p.seedForTest(items);
    return p;
  }

  group('filteredReservations – TimeFilter', () {
    test('TimeFilter.all returns all reservations', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: past),
      ]);
      expect(provider.filteredReservations.length, 2);
    });

    test('TimeFilter.future returns only future reservations', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: past),
      ]);
      provider.setTimeFilter(TimeFilter.future);
      final result = provider.filteredReservations;
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('TimeFilter.past returns only past reservations', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: past),
      ]);
      provider.setTimeFilter(TimeFilter.past);
      final result = provider.filteredReservations;
      expect(result.length, 1);
      expect(result.first.id, '2');
    });
  });

  group('filteredReservations – statusFilter', () {
    test('empty statusFilter returns all reservations', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: future),
        _res(id: '3', status: 'REFUSED', scheduledAt: future),
      ]);
      expect(provider.filteredReservations.length, 3);
    });

    test('PENDING filter returns only pending', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: future),
      ]);
      provider.toggleStatusFilter('PENDING');
      final result = provider.filteredReservations;
      expect(result.length, 1);
      expect(result.first.status, 'PENDING');
    });

    test('toggleStatusFilter twice removes the filter', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: future),
      ]);
      provider.toggleStatusFilter('PENDING');
      provider.toggleStatusFilter('PENDING');
      expect(provider.filteredReservations.length, 2);
    });

    test('PENDING and ACCEPTED filters combined return both', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: future),
        _res(id: '3', status: 'REFUSED', scheduledAt: future),
      ]);
      provider.toggleStatusFilter('PENDING');
      provider.toggleStatusFilter('ACCEPTED');
      final result = provider.filteredReservations;
      expect(result.length, 2);
      expect(result.map((r) => r.status).toSet(), {'PENDING', 'ACCEPTED'});
    });
  });

  group('filteredReservations – combined filters', () {
    test('TimeFilter.future + PENDING returns future pending only', () {
      final provider = makeProvider([
        _res(id: '1', status: 'PENDING', scheduledAt: future),
        _res(id: '2', status: 'ACCEPTED', scheduledAt: future),
        _res(id: '3', status: 'PENDING', scheduledAt: past),
      ]);
      provider.setTimeFilter(TimeFilter.future);
      provider.toggleStatusFilter('PENDING');
      final result = provider.filteredReservations;
      expect(result.length, 1);
      expect(result.first.id, '1');
    });
  });

  group('setTimeFilter', () {
    test('calls notifyListeners', () {
      final provider = makeProvider([]);
      var notified = false;
      provider.addListener(() => notified = true);
      provider.setTimeFilter(TimeFilter.future);
      expect(notified, true);
    });
  });

  group('toggleStatusFilter', () {
    test('calls notifyListeners on add', () {
      final provider = makeProvider([]);
      var notified = false;
      provider.addListener(() => notified = true);
      provider.toggleStatusFilter('PENDING');
      expect(notified, true);
    });

    test('calls notifyListeners on remove', () {
      final provider = makeProvider([]);
      provider.toggleStatusFilter('PENDING');
      var notified = false;
      provider.addListener(() => notified = true);
      provider.toggleStatusFilter('PENDING');
      expect(notified, true);
    });
  });
}
