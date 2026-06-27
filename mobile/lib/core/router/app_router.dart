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
import '../../features/provider/screens/reservations_screen.dart';
import '../../features/provider/screens/reservation_detail_screen.dart';
import '../../features/provider/screens/my_services_screen.dart';
import '../../features/provider/screens/service_form_screen.dart';
import '../../features/provider/services/provider_reservations_api.dart';
import '../../features/provider/services/provider_services_api.dart';

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
        if (role == 'PROVIDER') return '/provider/reservations';
        return '/login';
      }

      // Block CLIENT from accessing provider routes and vice versa
      final role = authProvider.role;
      final location = state.matchedLocation;
      if (role == 'CLIENT' && location.startsWith('/provider')) {
        return '/client/services';
      }
      if (role == 'PROVIDER' && location.startsWith('/client')) {
        return '/provider/reservations';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // CLIENT shell
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(role: 'CLIENT', child: child),
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

      // PROVIDER shell
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(role: 'PROVIDER', child: child),
        routes: [
          GoRoute(
            path: '/provider/reservations',
            builder: (_, __) => const ReservationsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final reservation =
                      state.extra as ProviderReservationModel;
                  return ReservationDetailScreen(reservation: reservation);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/provider/services',
            builder: (_, __) => const MyServicesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ServiceFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => ServiceFormScreen(
                  service: state.extra as ProviderServiceModel,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/provider/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
