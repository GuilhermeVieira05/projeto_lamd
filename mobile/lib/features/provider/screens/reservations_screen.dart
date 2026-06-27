import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/provider_reservations_provider.dart';
import '../services/provider_reservations_api.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderReservationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderReservationsProvider>(
      builder: (context, provider, _) {
        final items = provider.visible;
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFF1c1c1e),
          child: CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                backgroundColor: Color(0xFF1c1c1e),
                border: null,
                largeTitle: Text(
                  'Reservas',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () => provider.load(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Pendentes',
                        active: provider.statusFilter ==
                            ReservationStatusFilter.pending,
                        onTap: () => provider
                            .setStatusFilter(ReservationStatusFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Ativas',
                        active: provider.statusFilter ==
                            ReservationStatusFilter.active,
                        onTap: () => provider
                            .setStatusFilter(ReservationStatusFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Concluídas',
                        active: provider.statusFilter ==
                            ReservationStatusFilter.completed,
                        onTap: () => provider
                            .setStatusFilter(ReservationStatusFilter.completed),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading && items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (provider.error != null && items.isEmpty)
                SliverFillRemaining(
                  child: _Message(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title: provider.error!,
                  ),
                )
              else if (items.isEmpty)
                SliverFillRemaining(child: _emptyForFilter(provider.statusFilter))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildCard(context, provider, items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ProviderReservationsProvider provider,
    ProviderReservationModel reservation,
  ) {
    switch (provider.statusFilter) {
      case ReservationStatusFilter.pending:
        return _PendingCard(
          reservation: reservation,
          onTap: () {
            provider.markSeen(reservation.id);
            context.push(
              '/provider/reservations/${reservation.id}',
              extra: reservation,
            );
          },
        );
      case ReservationStatusFilter.active:
        return _ActiveCard(
          reservation: reservation,
          onComplete: () => _confirmComplete(context, provider, reservation),
        );
      case ReservationStatusFilter.completed:
        return _CompletedCard(reservation: reservation);
    }
  }

  Future<void> _confirmComplete(
    BuildContext context,
    ProviderReservationsProvider provider,
    ProviderReservationModel reservation,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Concluir reserva'),
        content: Text(
          'Marcar "${reservation.serviceTypeName}" com ${reservation.clientName} como concluído?',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: const Text('Concluir'),
          ),
          CupertinoDialogAction(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.complete(reservation.id);
    } catch (_) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Erro'),
            content:
                const Text('Não foi possível concluir a reserva. Tente novamente.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _emptyForFilter(ReservationStatusFilter filter) {
    return switch (filter) {
      ReservationStatusFilter.pending => const _Message(
          icon: CupertinoIcons.clock,
          title: 'Nenhuma reserva pendente',
          subtitle: 'Novas reservas de clientes aparecerão aqui em tempo real.',
        ),
      ReservationStatusFilter.active => const _Message(
          icon: CupertinoIcons.checkmark_circle,
          title: 'Nenhuma reserva ativa',
          subtitle: 'Reservas aceitas aparecerão aqui.',
        ),
      ReservationStatusFilter.completed => const _Message(
          icon: CupertinoIcons.flag,
          title: 'Nenhuma reserva concluída',
          subtitle: 'Reservas finalizadas aparecerão aqui.',
        ),
    };
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF34C759) : const Color(0xFF2c2c2e),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? CupertinoColors.white : const Color(0xFF8e8e93),
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final ProviderReservationModel reservation;
  final VoidCallback onTap;

  const _PendingCard({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yyyy 'às' HH:mm")
        .format(reservation.scheduledAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2c2c2e),
          borderRadius: BorderRadius.circular(18),
          border: reservation.isNew
              ? Border.all(color: const Color(0xFFFF9500), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.serviceTypeName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                if (reservation.isNew) const _NewBadge(),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 0.5, color: const Color(0xFF3a3a3c)),
            const SizedBox(height: 10),
            _InfoRow(
              icon: CupertinoIcons.person_fill,
              text: reservation.clientName,
              color: const Color(0xFF007AFF),
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: CupertinoIcons.calendar,
              text: dateStr,
              color: const Color(0xFF34C759),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver detalhes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(CupertinoIcons.chevron_right,
                    size: 14, color: Color(0xFF007AFF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final ProviderReservationModel reservation;
  final VoidCallback onComplete;

  const _ActiveCard({required this.reservation, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yyyy 'às' HH:mm")
        .format(reservation.scheduledAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.serviceTypeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const _StatusPill(
                label: 'Aceita',
                color: Color(0xFF34C759),
                icon: CupertinoIcons.checkmark_circle_fill,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: const Color(0xFF3a3a3c)),
          const SizedBox(height: 10),
          _InfoRow(
            icon: CupertinoIcons.person_fill,
            text: reservation.clientName,
            color: const Color(0xFF007AFF),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: CupertinoIcons.calendar,
            text: dateStr,
            color: const Color(0xFFFF9500),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.flag_fill,
                      size: 16, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text(
                    'Marcar como Concluído',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final ProviderReservationModel reservation;

  const _CompletedCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yyyy 'às' HH:mm")
        .format(reservation.scheduledAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.serviceTypeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const _StatusPill(
                label: 'Concluída',
                color: Color(0xFF8e8e93),
                icon: CupertinoIcons.flag_fill,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: const Color(0xFF3a3a3c)),
          const SizedBox(height: 10),
          _InfoRow(
            icon: CupertinoIcons.person_fill,
            text: reservation.clientName,
            color: const Color(0xFF007AFF),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: CupertinoIcons.calendar,
            text: dateStr,
            color: const Color(0xFF8e8e93),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sparkles, size: 11, color: Color(0xFFFF9500)),
          SizedBox(width: 4),
          Text(
            'Nova',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9500),
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
        Text(text,
            style: const TextStyle(fontSize: 14, color: CupertinoColors.white)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _Message({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8e8e93)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
