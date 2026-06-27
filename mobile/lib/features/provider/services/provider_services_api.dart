import '../../../core/network/http_client.dart';

class ProviderServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final bool active;
  final List<String> requiredFields;

  const ProviderServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.active,
    this.requiredFields = const [],
  });

  factory ProviderServiceModel.fromJson(Map<String, dynamic> json) {
    final fields = json['requiredFields'] as List<dynamic>?;
    return ProviderServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      requiredFields: fields?.map((e) => e as String).toList() ?? [],
    );
  }
}

class ProviderServicesApi {
  final HttpClient _http;

  ProviderServicesApi({required HttpClient http}) : _http = http;

  Future<List<ProviderServiceModel>> listMine() async {
    final response = await _http.get('/services/mine');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ProviderServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderServiceModel> create({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    List<String>? requiredFields,
  }) async {
    final response = await _http.post('/services', data: {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      if (requiredFields != null) 'requiredFields': requiredFields,
    });
    return ProviderServiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProviderServiceModel> update(
    String id, {
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? active,
    List<String>? requiredFields,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (active != null) 'active': active,
      if (requiredFields != null) 'requiredFields': requiredFields,
    };
    final response = await _http.patch('/services/$id', data: body);
    return ProviderServiceModel.fromJson(response.data as Map<String, dynamic>);
  }
}
