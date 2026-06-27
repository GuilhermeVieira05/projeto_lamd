import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../services/reservations_api.dart';
import '../services/services_api.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _isLoading = true;
  bool _isBooking = false;
  final Map<String, TextEditingController> _answerControllers = {};
  String? _loadError;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  late ReservationsApi _reservationsApi;

  @override
  void initState() {
    super.initState();
    final tokenStorage = TokenStorage();
    final auth = context.read<AuthProvider>();
    final http = HttpClient(tokenStorage: tokenStorage)..onUnauthorized = auth.logout;
    _reservationsApi = ReservationsApi(http: http);
    _loadService(http);
  }

  @override
  void dispose() {
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadService(HttpClient http) async {
    try {
      final api = ServicesApi(http: http);
      final service = await api.getService(widget.serviceId);
      if (mounted) {
        setState(() { _service = service; _isLoading = false; });
        for (final q in service.requiredFields) {
          _answerControllers[q] = TextEditingController();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _loadError = 'Erro ao carregar serviço'; _isLoading = false; });
    }
  }

  Future<void> _book() async {
    final answers = {
      for (final entry in _answerControllers.entries)
        entry.key: entry.value.text.trim()
    };
    setState(() { _isBooking = true; });
    try {
      await _reservationsApi.createReservation(
        serviceTypeId: widget.serviceId,
        scheduledAt: _selectedDate,
        clientAnswers: answers,
      );
      if (mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Reserva enviada!'),
            content: const Text('Aguarde a confirmação do prestador. Você será notificado em tempo real.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Erro ao reservar'),
            content: const Text('Não foi possível criar a reserva. Tente novamente.'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isBooking = false; });
    }
  }

  bool get _allAnswered =>
      _answerControllers.isEmpty ||
      _answerControllers.values.every((c) => c.text.trim().isNotEmpty);

  void _showDatePicker() {
    final roundedNow = DateTime.now().add(const Duration(hours: 1));
    if (_selectedDate.isBefore(roundedNow)) {
      setState(() => _selectedDate = roundedNow);
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Color(0xFF2c2c2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF3a3a3c), width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Escolha a data e hora', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: CupertinoColors.white)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF34C759))),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now(),
                use24hFormat: true,
                backgroundColor: const Color(0xFF2c2c2e),
                onDateTimeChanged: (dt) => setState(() => _selectedDate = dt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: Color(0xFF1c1c1e),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Color(0xFF1c1c1e),
          border: null,
          middle: Text('Serviço', style: TextStyle(color: CupertinoColors.white)),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_loadError != null || _service == null) {
      return CupertinoPageScaffold(
        backgroundColor: const Color(0xFF1c1c1e),
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Color(0xFF1c1c1e),
          border: null,
          middle: Text('Serviço', style: TextStyle(color: CupertinoColors.white)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Color(0xFF636366)),
              const SizedBox(height: 12),
              Text(_loadError ?? 'Erro', style: const TextStyle(color: Color(0xFF8e8e93))),
            ],
          ),
        ),
      );
    }

    final s = _service!;
    final dateLabel = DateFormat("dd 'de' MMM 'de' yyyy, HH:mm", 'pt_BR').format(_selectedDate);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      navigationBar: CupertinoNavigationBar(
        middle: Text(s.name, style: const TextStyle(color: CupertinoColors.white)),
        backgroundColor: const Color(0xFF1c1c1e),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF007AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.description.isEmpty ? 'Serviço profissional' : s.description,
                      style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _InfoBadge(
                          icon: CupertinoIcons.money_dollar_circle,
                          text: 'R\$ ${s.price.toStringAsFixed(2)}',
                        ),
                        const SizedBox(width: 12),
                        _InfoBadge(
                          icon: CupertinoIcons.clock,
                          text: '${s.durationMinutes} min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _Section(
                title: 'Prestador',
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.person_fill, color: Color(0xFF007AFF), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(s.providerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: CupertinoColors.white)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _Section(
                title: 'Data e hora da reserva',
                child: GestureDetector(
                  onTap: _showDatePicker,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.calendar, color: Color(0xFF34C759), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF007AFF)),
                        ),
                      ),
                      const Icon(CupertinoIcons.pencil, size: 16, color: Color(0xFF8e8e93)),
                    ],
                  ),
                ),
              ),

              if (_service!.requiredFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Informações necessárias',
                  child: Column(
                    children: _service!.requiredFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _service!.requiredFields.length - 1 ? 12 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8e8e93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: _answerControllers[question],
                              placeholder: 'Sua resposta',
                              style: const TextStyle(color: CupertinoColors.white),
                              placeholderStyle: const TextStyle(color: Color(0xFF636366)),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3a3a3c),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: (_isBooking || !_allAnswered) ? null : _book,
                  child: _isBooking
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Confirmar Reserva',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1c1c1e),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Você será notificado quando o prestador aceitar',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8e8e93)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CupertinoColors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: CupertinoColors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF636366),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
