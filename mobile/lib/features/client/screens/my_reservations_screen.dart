import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/reservations_provider.dart';
import '../services/reservations_api.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservationsProvider>(
      builder: (context, provider, _) {
        final filtered = provider.filteredReservations;
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _FilterChip(
                              label: 'Todas',
                              active: provider.timeFilter == TimeFilter.all,
                              onTap: () => provider.setTimeFilter(TimeFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Futuras',
                              active: provider.timeFilter == TimeFilter.future,
                              onTap: () => provider.setTimeFilter(TimeFilter.future),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Passadas',
                              active: provider.timeFilter == TimeFilter.past,
                              onTap: () => provider.setTimeFilter(TimeFilter.past),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _FilterChip(
                              label: 'Pendentes',
                              active: provider.statusFilter.contains('PENDING'),
                              onTap: () => provider.toggleStatusFilter('PENDING'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Aceitas',
                              active: provider.statusFilter.contains('ACCEPTED'),
                              onTap: () => provider.toggleStatusFilter('ACCEPTED'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmpty(
                      icon: provider.reservations.isEmpty
                          ? CupertinoIcons.calendar_badge_plus
                          : CupertinoIcons.line_horizontal_3_decrease_circle,
                      message: provider.reservations.isEmpty
                          ? 'Nenhuma reserva ainda'
                          : 'Nenhuma reserva para este filtro',
                      subtitle: provider.reservations.isEmpty
                          ? 'Explore os serviços disponíveis e faça sua primeira reserva.'
                          : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ReservationCard(
                          reservation: filtered[index],
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF007AFF) : const Color(0xFF2c2c2e),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? CupertinoColors.white : const Color(0xFF8e8e93),
          ),
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
