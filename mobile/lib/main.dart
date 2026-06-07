import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/token_storage.dart';
import 'core/network/ws_client.dart';
import 'core/notifications/notification_provider.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final TokenStorage _tokenStorage;
  late final WsClient _wsClient;
  late final AuthProvider _authProvider;
  late final NotificationProvider _notificationProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _wsClient = WsClient();
    _authProvider = AuthProvider(tokenStorage: _tokenStorage, wsClient: _wsClient);
    _notificationProvider = NotificationProvider(wsMessages: _wsClient.messages);
    _router = createRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _notificationProvider.dispose();
    _wsClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
      ],
      child: CupertinoApp.router(
        title: 'Reserva de Serviços',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        routerConfig: _router,
      ),
    );
  }
}
