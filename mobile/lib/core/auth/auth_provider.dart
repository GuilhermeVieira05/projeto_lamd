import 'package:flutter/foundation.dart';
import 'token_storage.dart';
import '../network/ws_client.dart';

class AuthUser {
  final String id;
  final String name;
  final String role;

  AuthUser({required this.id, required this.name, required this.role});
}

class AuthProvider extends ChangeNotifier {
  final TokenStorage tokenStorage;
  final WsClient wsClient;

  AuthUser? _user;
  String? _token;
  final bool _isLoading = false;

  AuthProvider({required this.tokenStorage, required this.wsClient});

  AuthUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get role => _user?.role;

  Future<void> loadFromStorage() async {
    final data = await tokenStorage.load();
    final token = data['token'];
    final role = data['role'];
    final name = data['name'];
    final userId = data['userId'];

    if (token != null && role != null && name != null && userId != null) {
      _token = token;
      _user = AuthUser(id: userId, name: name, role: role);
      wsClient.connect(token);
      notifyListeners();
    }
  }

  void setAuthenticated({
    required String token,
    required String userId,
    required String name,
    required String role,
  }) {
    _token = token;
    _user = AuthUser(id: userId, name: name, role: role);
    wsClient.connect(token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    wsClient.disconnect();
    await tokenStorage.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    wsClient.dispose();
    super.dispose();
  }
}
