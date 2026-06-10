import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/ws_client.dart';
import '../../../core/storage/local_db.dart';
import '../services/reservations_api.dart';

enum TimeFilter { all, future, past }

class ReservationsProvider extends ChangeNotifier {
  final ReservationsApi _api;
  final WsClient _ws;
  StreamSubscription<WsMessage>? _wsSub;

  List<ReservationModel> _reservations = [];
  bool isLoading = false;
  String? error;

  TimeFilter timeFilter = TimeFilter.all;
  Set<String> statusFilter = {};

  ReservationsProvider({required ReservationsApi api, required WsClient ws})
      : _api = api,
        _ws = ws {
    _listenToWs();
  }

  List<ReservationModel> get reservations => _reservations;

  List<ReservationModel> get filteredReservations {
    final now = DateTime.now();
    return _reservations.where((r) {
      final passesTime = switch (timeFilter) {
        TimeFilter.future => r.scheduledAt.isAfter(now),
        TimeFilter.past   => r.scheduledAt.isBefore(now),
        TimeFilter.all    => true,
      };
      final passesStatus =
          statusFilter.isEmpty || statusFilter.contains(r.status);
      return passesTime && passesStatus;
    }).toList();
  }

  void setTimeFilter(TimeFilter f) {
    timeFilter = f;
    notifyListeners();
  }

  void toggleStatusFilter(String status) {
    if (statusFilter.contains(status)) {
      statusFilter.remove(status);
    } else {
      statusFilter.add(status);
    }
    notifyListeners();
  }

  @visibleForTesting
  void seedForTest(List<ReservationModel> items) {
    _reservations = items;
  }

  Future<void> load() async {
    final cached = await LocalDb.getReservations();
    if (cached.isNotEmpty) {
      _reservations = cached.map((r) => ReservationModel(
        id: r.id,
        serviceTypeName: r.serviceTypeName,
        providerName: r.providerName,
        status: r.status,
        scheduledAt: DateTime.parse(r.scheduledAt),
        notes: r.notes,
      )).toList();
      notifyListeners();
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fresh = await _api.listReservations();
      _reservations = fresh;
      await LocalDb.saveReservations(fresh.map((r) => LocalReservation(
        id: r.id,
        serviceTypeName: r.serviceTypeName,
        providerName: r.providerName,
        status: r.status,
        scheduledAt: r.scheduledAt.toIso8601String(),
        notes: r.notes,
        createdAt: DateTime.now().toIso8601String(),
      )).toList());
    } catch (e) {
      error = 'Erro ao carregar reservas';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _listenToWs() {
    _wsSub = _ws.messages.listen((msg) {
      if (msg.event != 'notification.new') return;
      final type = msg.payload['type'] as String?;
      final isReservationEvent = type == 'reservation.accepted' ||
          type == 'reservation.refused' ||
          type == 'reservation.completed';
      if (!isReservationEvent) return;

      final inner = msg.payload['payload'] as Map<String, dynamic>?;
      final reservationId = inner?['reservationId'] as String?;
      if (reservationId == null) return;

      final newStatus = type!.split('.').last.toUpperCase();
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx != -1) {
        _reservations[idx] = _reservations[idx].copyWith(status: newStatus);
        LocalDb.updateStatus(reservationId, newStatus);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
