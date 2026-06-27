import '../../../core/network/http_client.dart';

class ProviderReservationModel {
  final String id;
  final String serviceTypeName;
  final String clientName;
  final String status;
  final DateTime scheduledAt;
  final String? notes;
  final bool isNew;
  final Map<String, String> clientAnswers;

  const ProviderReservationModel({
    required this.id,
    required this.serviceTypeName,
    required this.clientName,
    required this.status,
    required this.scheduledAt,
    this.notes,
    this.isNew = false,
    this.clientAnswers = const {},
  });

  ProviderReservationModel copyWith({String? status, bool? isNew}) =>
      ProviderReservationModel(
        id: id,
        serviceTypeName: serviceTypeName,
        clientName: clientName,
        status: status ?? this.status,
        scheduledAt: scheduledAt,
        notes: notes,
        isNew: isNew ?? this.isNew,
        clientAnswers: clientAnswers,
      );

  factory ProviderReservationModel.fromJson(Map<String, dynamic> json) {
    final serviceType = json['serviceType'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final answers = json['clientAnswers'] as Map<String, dynamic>?;
    return ProviderReservationModel(
      id: json['id'] as String,
      serviceTypeName: serviceType?['name'] as String? ?? '',
      clientName: client?['name'] as String? ?? '',
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
      clientAnswers: answers?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }
}

class ProviderReservationsApi {
  final HttpClient _http;

  ProviderReservationsApi({required HttpClient http}) : _http = http;

  Future<List<ProviderReservationModel>> listAll() async {
    final response = await _http.get('/reservations');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ProviderReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderReservationModel> getById(String id) async {
    final response = await _http.get('/reservations/$id');
    return ProviderReservationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, String status) async {
    await _http.patch('/reservations/$id/status', data: {'status': status});
  }
}
