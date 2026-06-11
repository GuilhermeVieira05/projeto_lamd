import '../../../core/network/http_client.dart';

class NotificationModel {
  final String id;
  final String type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  NotificationModel({
    required this.id,
    required this.type,
    required this.read,
    required this.createdAt,
    required this.payload,
  });

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
        payload: payload,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );
}

class NotificationsApi {
  final HttpClient _http;

  NotificationsApi({required HttpClient http}) : _http = http;

  Future<({List<NotificationModel> notifications, int unreadCount})> listNotifications() async {
    final response = await _http.get('/notifications');
    final body = response.data as Map<String, dynamic>;
    final list = body['notifications'] as List? ?? [];
    return (
      notifications: list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: body['unreadCount'] as int? ?? 0,
    );
  }

  Future<void> markRead(String id) async {
    await _http.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _http.patch('/notifications/read-all');
  }
}
