import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _nameKey = 'auth_name';
  static const _userIdKey = 'auth_user_id';

  Future<void> save({
    required String token,
    required String role,
    required String name,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _nameKey, value: name),
      _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  Future<Map<String, String?>> load() async {
    final results = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _roleKey),
      _storage.read(key: _nameKey),
      _storage.read(key: _userIdKey),
    ]);
    return {
      'token': results[0],
      'role': results[1],
      'name': results[2],
      'userId': results[3],
    };
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _nameKey),
      _storage.delete(key: _userIdKey),
    ]);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
}
