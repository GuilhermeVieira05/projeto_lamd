import 'package:flutter/foundation.dart';
import '../services/services_api.dart';

class ServicesProvider extends ChangeNotifier {
  final ServicesApi _api;

  List<ServiceModel> _all = [];
  List<ServiceModel> _filtered = [];
  bool isLoading = false;
  String? error;
  String _query = '';

  ServicesProvider({required ServicesApi api}) : _api = api;

  List<ServiceModel> get services => _filtered;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _api.listServices();
      _applyFilter();
    } catch (e) {
      error = 'Erro ao carregar serviços';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void filter(String query) {
    _query = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.from(_all);
    } else {
      _filtered = _all
          .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
  }
}
