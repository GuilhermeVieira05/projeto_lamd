import '../../../core/network/http_client.dart';
import '../../../core/auth/token_storage.dart';

class AuthResult {
  final String token;
  final String userId;
  final String name;
  final String role;

  AuthResult({
    required this.token,
    required this.userId,
    required this.name,
    required this.role,
  });
}

class AuthService {
  final HttpClient _http;
  final TokenStorage _storage;

  AuthService({required HttpClient http, required TokenStorage storage})
      : _http = http,
        _storage = storage;

  Future<AuthResult> login(String email, String password) async {
    final response = await _http.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    final result = AuthResult(
      token: token,
      userId: user['id'] as String,
      name: user['name'] as String,
      role: user['role'] as String,
    );
    await _storage.save(
      token: token,
      role: result.role,
      name: result.name,
      userId: result.userId,
    );
    return result;
  }

  Future<void> register(String name, String email, String password, String role) async {
    await _http.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }
}
