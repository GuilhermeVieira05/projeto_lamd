import '../../../core/network/http_client.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String providerName;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.providerName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as Map<String, dynamic>?;
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      providerName: provider?['name'] as String? ?? '',
    );
  }
}

class ServicesApi {
  final HttpClient _http;

  ServicesApi({required HttpClient http}) : _http = http;

  Future<List<ServiceModel>> listServices() async {
    final response = await _http.get('/services');
    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceModel> getService(String id) async {
    final response = await _http.get('/services/$id');
    return ServiceModel.fromJson(response.data as Map<String, dynamic>);
  }
}
