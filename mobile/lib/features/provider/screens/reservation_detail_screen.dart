import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/provider_reservations_provider.dart';
import '../services/provider_reservations_api.dart';

class ReservationDetailScreen extends StatefulWidget {
  final ProviderReservationModel reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  late ProviderReservationModel _reservation;
  bool _isFetchingFull = false;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
    if (_reservation.notes == null) {
      _fetchFullReservation();
    }
  }

  Future<void> _fetchFullReservation() async {
    setState(() => _isFetchingFull = true);
    try {
      final full = await context
          .read<ProviderReservationsProvider>()
          .getById(_reservation.id);
      if (mounted) setState(() => _reservation = full);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isFetchingFull = false);
    }
  }

  Future<void> _accept() async {
    final provider = context.read<ProviderReservationsProvider>();
    setState(() => _isActing = true);
    try {
      await provider.accept(_reservation.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        _showError('Erro ao aceitar reserva. Tente novamente.');
        setState(() => _isActing = false);
      }
    }
  }

  Future<void> _refuse() async {
    final provider = context.read<ProviderReservationsProvider>();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Recusar reserva'),
        content: const Text('Tem certeza que deseja recusar esta reserva? Esta ação não pode ser desfeita.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: const Text('Recusar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActing = true);
    try {
      await provider.refuse(_reservation.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        _showError('Erro ao recusar reserva. Tente novamente.');
        setState(() => _isActing = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yyyy 'às' HH:mm")
        .format(_reservation.scheduledAt.toLocal());

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1c1c1e),
        border: null,
        middle: Text('Detalhes da Reserva', style: TextStyle(color: CupertinoColors.white)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                children: [
                  _DetailRow(
                    icon: CupertinoIcons.briefcase_fill,
                    label: 'Serviço',
                    value: _reservation.serviceTypeName,
                    iconColor: const Color(0xFF007AFF),
                  ),
                  const _Divider(),
                  _DetailRow(
                    icon: CupertinoIcons.person_fill,
                    label: 'Cliente',
                    value: _reservation.clientName,
                    iconColor: const Color(0xFF34C759),
                  ),
                  const _Divider(),
                  _DetailRow(
                    icon: CupertinoIcons.calendar,
                    label: 'Data e hora',
                    value: dateStr,
                    iconColor: const Color(0xFFFF9500),
                  ),
                  if (_isFetchingFull) ...[
                    const _Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CupertinoActivityIndicator(),
                    ),
                  ] else if (_reservation.notes != null &&
                      _reservation.notes!.isNotEmpty) ...[
                    const _Divider(),
                    _DetailRow(
                      icon: CupertinoIcons.text_alignleft,
                      label: 'Observações',
                      value: _reservation.notes!,
                      iconColor: const Color(0xFF8e8e93),
                    ),
                  ],
                  if (_reservation.clientAnswers.isNotEmpty) ...[
                    const _Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMAÇÕES DO CLIENTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF636366),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._reservation.clientAnswers.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(CupertinoIcons.chat_bubble_text_fill, size: 16, color: Color(0xFF636366)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8e8e93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              if (_isActing)
                const Center(child: CupertinoActivityIndicator())
              else ...[
                _ActionButton(
                  label: 'Aceitar',
                  color: const Color(0xFF34C759),
                  icon: CupertinoIcons.checkmark_circle_fill,
                  onTap: _accept,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Recusar',
                  color: const Color(0xFFFF3B30),
                  icon: CupertinoIcons.xmark_circle_fill,
                  onTap: _refuse,
                  outlined: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8e8e93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: const Color(0xFF3a3a3c),
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: outlined ? const Color(0x00000000) : color,
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: outlined ? color : CupertinoColors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: outlined ? color : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
