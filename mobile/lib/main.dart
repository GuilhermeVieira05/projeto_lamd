import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/token_storage.dart';
import 'core/network/http_client.dart';
import 'core/network/ws_client.dart';
import 'core/notifications/notification_provider.dart';
import 'core/router/app_router.dart';
import 'features/client/providers/reservations_provider.dart';
import 'features/client/providers/services_provider.dart';
import 'features/client/services/reservations_api.dart';
import 'features/client/services/services_api.dart';
import 'package:go_router/go_router.dart';

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
  late final HttpClient _httpClient;
  late final AuthProvider _authProvider;
  late final NotificationProvider _notificationProvider;
  late final ServicesProvider _servicesProvider;
  late final ReservationsProvider _reservationsProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _wsClient = WsClient();
    _httpClient = HttpClient(tokenStorage: _tokenStorage);
    _authProvider = AuthProvider(tokenStorage: _tokenStorage, wsClient: _wsClient);
    _httpClient.onUnauthorized = _authProvider.logout;
    _notificationProvider = NotificationProvider(wsMessages: _wsClient.messages);
    _servicesProvider = ServicesProvider(api: ServicesApi(http: _httpClient));
    _reservationsProvider = ReservationsProvider(
      api: ReservationsApi(http: _httpClient),
      ws: _wsClient,
    );
    _router = createRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _notificationProvider.dispose();
    _reservationsProvider.dispose();
    _wsClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        ChangeNotifierProvider.value(value: _servicesProvider),
        ChangeNotifierProvider.value(value: _reservationsProvider),
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
