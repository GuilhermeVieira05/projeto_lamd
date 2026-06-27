import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../network/ws_client.dart';

class NotificationToast {
  static void show(BuildContext context, WsMessage message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final WsMessage message;
  final VoidCallback onDismiss;

  const _ToastWidget({required this.message, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  String get _type => widget.message.payload['type'] as String? ?? '';

  Color get _borderColor {
    switch (_type) {
      case 'reservation.created':
        return const Color(0xFFFF9500);
      case 'reservation.accepted':
        return const Color(0xFF34C759);
      case 'reservation.refused':
        return const Color(0xFFFF3B30);
      case 'reservation.completed':
        return const Color(0xFF007AFF);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String get _label {
    switch (_type) {
      case 'reservation.created':
        return 'NOVA RESERVA';
      case 'reservation.accepted':
        return 'RESERVA ACEITA';
      case 'reservation.refused':
        return 'RESERVA RECUSADA';
      case 'reservation.completed':
        return 'SERVIÇO CONCLUÍDO';
      default:
        return 'NOTIFICAÇÃO';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = (widget.message.payload['payload'] as Map<String, dynamic>?) ?? widget.message.payload;
    final scheduledAtRaw = inner['scheduledAt'] as String?;
    final dateStr = scheduledAtRaw != null
        ? DateFormat("dd/MM 'às' HH:mm", 'pt_BR')
            .format(DateTime.parse(scheduledAtRaw).toLocal())
        : '';

    final String primaryText;
    final String secondaryText;
    if (_type == 'reservation.created') {
      primaryText = inner['clientName'] as String? ?? '';
      secondaryText = inner['serviceType'] as String? ?? '';
    } else {
      primaryText = inner['providerName'] as String? ?? '';
      secondaryText = dateStr;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: _borderColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _borderColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (primaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      primaryText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ],
                  if (secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      secondaryText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
