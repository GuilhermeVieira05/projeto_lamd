import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/ws_client.dart';
import '../services/provider_reservations_api.dart';

enum ReservationStatusFilter { pending, active, completed }

class ProviderReservationsProvider extends ChangeNotifier {
  final ProviderReservationsApi _api;
  final WsClient _ws;
  StreamSubscription<WsMessage>? _wsSub;

  List<ProviderReservationModel> _pending = [];
  List<ProviderReservationModel> _active = [];
  List<ProviderReservationModel> _completed = [];
  bool isLoading = false;
  String? error;

  ReservationStatusFilter statusFilter = ReservationStatusFilter.pending;

  ProviderReservationsProvider({
    required ProviderReservationsApi api,
    required WsClient ws,
  })  : _api = api,
        _ws = ws {
    _listenToWs();
  }

  List<ProviderReservationModel> get pending => List.unmodifiable(_pending);
  List<ProviderReservationModel> get active => List.unmodifiable(_active);
  List<ProviderReservationModel> get completed => List.unmodifiable(_completed);

  List<ProviderReservationModel> get visible => switch (statusFilter) {
        ReservationStatusFilter.pending => pending,
        ReservationStatusFilter.active => active,
        ReservationStatusFilter.completed => completed,
      };

  void setStatusFilter(ReservationStatusFilter filter) {
    if (statusFilter == filter) return;
    statusFilter = filter;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final all = await _api.listAll();
      _pending = all.where((r) => r.status == 'PENDING').toList();
      _active = all.where((r) => r.status == 'ACCEPTED').toList();
      _completed = all.where((r) => r.status == 'COMPLETED').toList();
    } catch (_) {
      error = 'Erro ao carregar reservas';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ProviderReservationModel> getById(String id) async {
    return _api.getById(id);
  }

  Future<void> accept(String id) async {
    await _api.updateStatus(id, 'ACCEPTED');
    final idx = _pending.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final reservation = _pending[idx].copyWith(status: 'ACCEPTED', isNew: false);
      _pending.removeAt(idx);
      _active.insert(0, reservation);
      notifyListeners();
    }
  }

  Future<void> refuse(String id) async {
    await _api.updateStatus(id, 'REFUSED');
    _pending.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> complete(String id) async {
    await _api.updateStatus(id, 'COMPLETED');
    final idx = _active.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final reservation = _active[idx].copyWith(status: 'COMPLETED');
      _active.removeAt(idx);
      _completed.insert(0, reservation);
      notifyListeners();
    }
  }

  void markSeen(String id) {
    final idx = _pending.indexWhere((r) => r.id == id);
    if (idx != -1 && _pending[idx].isNew) {
      _pending[idx] = _pending[idx].copyWith(isNew: false);
      notifyListeners();
    }
  }

  void _listenToWs() {
    _wsSub = _ws.messages.listen((msg) {
      if (msg.event != 'notification.new') return;
      final type = msg.payload['type'] as String?;
      final inner = msg.payload['payload'] as Map<String, dynamic>?;
      if (inner == null) return;

      final reservationId = inner['reservationId'] as String?;
      if (reservationId == null) return;

      // Cliente cancelou uma reserva pendente → remove da lista em tempo real.
      if (type == 'reservation.cancelled') {
        final before = _pending.length;
        _pending.removeWhere((r) => r.id == reservationId);
        if (_pending.length != before) notifyListeners();
        return;
      }

      if (type != 'reservation.created') return;

      if (_pending.any((r) => r.id == reservationId)) return;

      final scheduledRaw = inner['scheduledAt'];
      final scheduledAt = scheduledRaw is String
          ? DateTime.tryParse(scheduledRaw) ?? DateTime.now()
          : DateTime.now();

      _pending.insert(
        0,
        ProviderReservationModel(
          id: reservationId,
          serviceTypeName: inner['serviceType'] as String? ?? '',
          clientName: inner['clientName'] as String? ?? '',
          status: 'PENDING',
          scheduledAt: scheduledAt,
          isNew: true,
        ),
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
