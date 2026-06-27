import 'package:flutter/foundation.dart';
import '../services/provider_services_api.dart';

class ProviderServicesProvider extends ChangeNotifier {
  final ProviderServicesApi _api;

  List<ProviderServiceModel> _services = [];
  bool isLoading = false;
  String? error;

  ProviderServicesProvider({required ProviderServicesApi api}) : _api = api;

  List<ProviderServiceModel> get services => List.unmodifiable(_services);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _services = await _api.listMine();
    } catch (_) {
      error = 'Erro ao carregar seus serviços';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    List<String>? requiredFields,
  }) async {
    final created = await _api.create(
      name: name,
      description: description,
      price: price,
      durationMinutes: durationMinutes,
      requiredFields: requiredFields,
    );
    _services = [created, ..._services];
    notifyListeners();
  }

  Future<void> update(
    String id, {
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? active,
    List<String>? requiredFields,
  }) async {
    final updated = await _api.update(
      id,
      name: name,
      description: description,
      price: price,
      durationMinutes: durationMinutes,
      active: active,
      requiredFields: requiredFields,
    );
    final idx = _services.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _services[idx] = updated;
      _services = List.of(_services);
      notifyListeners();
    }
  }
}
