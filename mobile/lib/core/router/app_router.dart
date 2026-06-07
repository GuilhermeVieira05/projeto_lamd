import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/client/screens/services_list_screen.dart';
import '../../features/client/screens/service_detail_screen.dart';
import '../../features/client/screens/my_reservations_screen.dart';
import '../../features/client/screens/notifications_screen.dart';
import '../../features/client/screens/profile_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) {
        final role = authProvider.role;
        if (role == 'CLIENT') return '/client/services';
        if (role == 'PROVIDER') return '/provider/home';
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/provider/home', builder: (_, __) => const _ProviderPlaceholder()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/client/services',
            builder: (_, __) => const ServicesListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ServiceDetailScreen(
                  serviceId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/client/reservations',
            builder: (_, __) => const MyReservationsScreen(),
          ),
          GoRoute(
            path: '/client/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class _ProviderPlaceholder extends StatelessWidget {
  const _ProviderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Prestador')),
      child: Center(child: Text('Telas do prestador disponíveis na Sprint 4')),
    );
  }
}
