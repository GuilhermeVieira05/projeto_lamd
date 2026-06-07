import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/ws_client.dart';
import '../../../core/storage/local_db.dart';
import '../services/reservations_api.dart';

class ReservationsProvider extends ChangeNotifier {
  final ReservationsApi _api;
  final WsClient _ws;
  StreamSubscription<WsMessage>? _wsSub;

  List<ReservationModel> _reservations = [];
  bool isLoading = false;
  String? error;

  ReservationsProvider({required ReservationsApi api, required WsClient ws})
      : _api = api,
        _ws = ws {
    _listenToWs();
  }

  List<ReservationModel> get reservations => _reservations;

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
