import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../../../core/notifications/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  late HttpClient _http;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tokenStorage = TokenStorage();
    _http = HttpClient(tokenStorage: tokenStorage)..onUnauthorized = auth.logout;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().resetUnreadCount();
    });
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _http.get('/notifications');
      final body = response.data as Map<String, dynamic>;
      final List data = body['notifications'] as List? ?? [];
      if (mounted) {
        setState(() {
          _notifications = data.map((e) => _Notification.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao carregar notificações'; _isLoading = false; });
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _http.patch('/notifications/$id/read');
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) _notifications[idx] = _notifications[idx].copyWith(read: true);
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _http.patch('/notifications/read-all');
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      });
      if (mounted) context.read<NotificationProvider>().resetUnreadCount();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).length;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1c1c1e),
        border: null,
        middle: const Text('Notificações', style: TextStyle(color: CupertinoColors.white)),
        trailing: unread > 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _markAllRead,
                child: const Text(
                  'Ler todas',
                  style: TextStyle(fontSize: 14, color: Color(0xFF34C759)),
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return _buildEmpty(
        icon: CupertinoIcons.exclamationmark_circle,
        message: _error!,
        showRetry: true,
      );
    }
    if (_notifications.isEmpty) {
      return _buildEmpty(
        icon: CupertinoIcons.bell_slash,
        message: 'Nenhuma notificação',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _notifications.length,
      itemBuilder: (context, index) => _NotificationCard(
        notification: _notifications[index],
        onTap: () {
          if (!_notifications[index].read) _markRead(_notifications[index].id);
        },
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message, bool showRetry = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2c2c2e),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF8e8e93)),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
          if (showRetry) ...[
            const SizedBox(height: 16),
            CupertinoButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _Notification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  static _TypeConfig _config(String type) {
    switch (type) {
      case 'reservation.accepted':
        return const _TypeConfig(
          label: 'Reserva aceita',
          icon: CupertinoIcons.checkmark_circle_fill,
          color: Color(0xFF34C759),
        );
      case 'reservation.refused':
        return const _TypeConfig(
          label: 'Reserva recusada',
          icon: CupertinoIcons.xmark_circle_fill,
          color: Color(0xFFFF3B30),
        );
      case 'reservation.completed':
        return const _TypeConfig(
          label: 'Serviço concluído',
          icon: CupertinoIcons.star_circle_fill,
          color: Color(0xFF8E8E93),
        );
      default:
        return const _TypeConfig(
          label: 'Notificação',
          icon: CupertinoIcons.bell_fill,
          color: Color(0xFF007AFF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config(notification.type);
    final dateStr = DateFormat("dd/MM 'às' HH:mm").format(notification.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notification.read ? const Color(0xFF2c2c2e) : cfg.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: notification.read
              ? null
              : Border.all(color: cfg.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cfg.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8e8e93)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF636366)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeConfig({required this.label, required this.icon, required this.color});
}

class _Notification {
  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime createdAt;

  const _Notification({
    required this.id,
    required this.type,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory _Notification.fromJson(Map<String, dynamic> json) {
    return _Notification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      message: _buildMessage(json['type'] as String? ?? '', json['payload'] as Map<String, dynamic>? ?? {}),
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static String _buildMessage(String type, Map<String, dynamic> payload) {
    switch (type) {
      case 'reservation.accepted': return 'Sua reserva foi aceita pelo prestador.';
      case 'reservation.refused': return 'Sua reserva foi recusada pelo prestador.';
      case 'reservation.completed': return 'O serviço foi marcado como concluído.';
      default: return payload['message'] as String? ?? 'Você tem uma nova notificação.';
    }
  }

  _Notification copyWith({bool? read}) => _Notification(
    id: id, type: type, message: message, read: read ?? this.read, createdAt: createdAt,
  );
}
