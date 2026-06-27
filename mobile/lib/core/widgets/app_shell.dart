import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../notifications/notification_provider.dart';
import 'notification_toast.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String role;

  const AppShell({super.key, required this.child, required this.role});

  static const _clientTabs = [
    '/client/services',
    '/client/reservations',
    '/client/notifications',
    '/client/profile',
  ];
  static const _clientLabels = ['Serviços', 'Reservas', 'Notificações', 'Perfil'];
  static const _clientIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.calendar,
    CupertinoIcons.bell_fill,
    CupertinoIcons.person_fill,
  ];
  static const _clientNotifTabIndex = 2;

  static const _providerTabs = [
    '/provider/reservations',
    '/provider/services',
    '/provider/profile',
  ];
  static const _providerLabels = ['Reservas', 'Meus Serviços', 'Perfil'];
  static const _providerIcons = [
    CupertinoIcons.calendar,
    CupertinoIcons.briefcase_fill,
    CupertinoIcons.person_fill,
  ];
  static const _providerNotifTabIndex = -1;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late NotificationProvider _notifProvider;

  List<String> get _tabs => widget.role == 'PROVIDER'
      ? AppShell._providerTabs
      : AppShell._clientTabs;

  List<String> get _labels => widget.role == 'PROVIDER'
      ? AppShell._providerLabels
      : AppShell._clientLabels;

  List<IconData> get _icons => widget.role == 'PROVIDER'
      ? AppShell._providerIcons
      : AppShell._clientIcons;

  int get _notifTabIndex => widget.role == 'PROVIDER'
      ? AppShell._providerNotifTabIndex
      : AppShell._clientNotifTabIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifProvider = context.read<NotificationProvider>();
      _notifProvider.addListener(_onNotification);
    });
  }

  @override
  void dispose() {
    _notifProvider.removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification() {
    final msg = _notifProvider.latestMessage;
    if (msg != null && mounted) {
      NotificationToast.show(context, msg);
      _notifProvider.clearLatest();
    }
  }

  int _activeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex(context);
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      child: Column(
        children: [
          Expanded(child: widget.child),
          _BottomNavBar(
            activeIndex: activeIndex,
            unreadCount: unreadCount,
            notifTabIndex: _notifTabIndex,
            tabs: _tabs,
            labels: _labels,
            icons: _icons,
            onTap: (i) => context.go(_tabs[i]),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final int unreadCount;
  final int notifTabIndex;
  final List<String> tabs;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.activeIndex,
    required this.unreadCount,
    required this.notifTabIndex,
    required this.tabs,
    required this.labels,
    required this.icons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: const Color(0xFF2c2c2e),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: const Color(0xFF3a3a3c)),
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: bottomPadding + 6),
            child: Row(
              children: List.generate(labels.length, (i) {
                final isActive = i == activeIndex;
                final color = isActive
                    ? const Color(0xFF34C759)
                    : const Color(0xFF636366);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(icons[i], size: 24, color: color),
                            if (i == notifTabIndex && unreadCount > 0)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF453A),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
