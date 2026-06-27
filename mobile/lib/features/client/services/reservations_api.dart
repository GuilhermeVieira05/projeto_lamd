import '../../../core/network/http_client.dart';

class ReservationModel {
  final String id;
  final String serviceTypeName;
  final String providerName;
  final String status;
  final DateTime scheduledAt;
  final String? notes;

  ReservationModel({
    required this.id,
    required this.serviceTypeName,
    required this.providerName,
    required this.status,
    required this.scheduledAt,
    this.notes,
  });

  ReservationModel copyWith({String? status}) => ReservationModel(
    id: id,
    serviceTypeName: serviceTypeName,
    providerName: providerName,
    status: status ?? this.status,
    scheduledAt: scheduledAt,
    notes: notes,
  );

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final serviceType = json['serviceType'] as Map<String, dynamic>?;
    final provider = json['provider'] as Map<String, dynamic>?;
    return ReservationModel(
      id: json['id'] as String,
      serviceTypeName: serviceType?['name'] as String? ?? '',
      providerName: provider?['name'] as String? ?? '',
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class ReservationsApi {
  final HttpClient _http;

  ReservationsApi({required HttpClient http}) : _http = http;

  Future<List<ReservationModel>> listReservations() async {
    final response = await _http.get('/reservations');
    final data = response.data as List<dynamic>;
    return data.map((e) => ReservationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createReservation({
    required String serviceTypeId,
    required DateTime scheduledAt,
    String? notes,
    Map<String, String> clientAnswers = const {},
  }) async {
    await _http.post('/reservations', data: {
      'serviceTypeId': serviceTypeId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
      if (clientAnswers.isNotEmpty) 'clientAnswers': clientAnswers,
    });
  }
}
