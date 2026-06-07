import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../providers/reservations_provider.dart';
import '../services/reservations_api.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  late ReservationsProvider _provider;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tokenStorage = TokenStorage();
    final http = HttpClient(tokenStorage: tokenStorage)..onUnauthorized = auth.logout;
    _provider = ReservationsProvider(
      api: ReservationsApi(http: http),
      ws: auth.wsClient,
    );
    _provider.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<ReservationsProvider>(
        builder: (context, provider, _) {
          return CupertinoPageScaffold(
            backgroundColor: const Color(0xFF1c1c1e),
            child: CustomScrollView(
              slivers: [
                const CupertinoSliverNavigationBar(
                  backgroundColor: Color(0xFF1c1c1e),
                  border: null,
                  largeTitle: Text(
                    'Minhas Reservas',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ),
                if (provider.isLoading && provider.reservations.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (provider.error != null && provider.reservations.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmpty(
                      icon: CupertinoIcons.exclamationmark_circle,
                      message: provider.error!,
                    ),
                  )
                else if (provider.reservations.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmpty(
                      icon: CupertinoIcons.calendar_badge_plus,
                      message: 'Nenhuma reserva ainda',
                      subtitle: 'Explore os serviços disponíveis e faça sua primeira reserva.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ReservationCard(
                          reservation: provider.reservations[index],
                        ),
                        childCount: provider.reservations.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF8e8e93)), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;

  const _ReservationCard({required this.reservation});

  static const _statusConfig = {
    'PENDING':   _StatusConfig(label: 'Pendente',  color: Color(0xFFFF9500), icon: CupertinoIcons.clock_fill),
    'ACCEPTED':  _StatusConfig(label: 'Aceito',    color: Color(0xFF34C759), icon: CupertinoIcons.checkmark_circle_fill),
    'REFUSED':   _StatusConfig(label: 'Recusado',  color: Color(0xFFFF3B30), icon: CupertinoIcons.xmark_circle_fill),
    'COMPLETED': _StatusConfig(label: 'Concluído', color: Color(0xFF8E8E93), icon: CupertinoIcons.star_circle_fill),
  };

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[reservation.status] ?? _statusConfig['PENDING']!;
    final dateStr = DateFormat("dd/MM/yyyy 'às' HH:mm").format(reservation.scheduledAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.serviceTypeName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CupertinoColors.white),
                  ),
                ),
                _StatusBadge(config: config),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 0.5, color: const Color(0xFF3a3a3c)),
            const SizedBox(height: 10),
            _InfoRow(
              icon: CupertinoIcons.person_fill,
              text: reservation.providerName,
              color: const Color(0xFF007AFF),
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: CupertinoIcons.calendar,
              text: dateStr,
              color: const Color(0xFF34C759),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusConfig config;

  const _StatusBadge({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: CupertinoColors.white)),
      ],
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusConfig({required this.label, required this.color, required this.icon});
}
