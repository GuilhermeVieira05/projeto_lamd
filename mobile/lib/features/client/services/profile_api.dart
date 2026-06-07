import '../../../core/network/http_client.dart';

class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String role;

  ProfileUser({required this.id, required this.name, required this.email, required this.role});

  factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );
}

class ProfileApi {
  final HttpClient _http;
  ProfileApi({required HttpClient http}) : _http = http;

  Future<ProfileUser> getMe() async {
    final response = await _http.get('/users/me');
    return ProfileUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileUser> updateMe({String? name, String? email, String? password}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    final response = await _http.patch('/users/me', data: body);
    return ProfileUser.fromJson(response.data as Map<String, dynamic>);
  }
}
