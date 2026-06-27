import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/provider_services_provider.dart';
import '../services/provider_services_api.dart';

/// Formulário de serviço usado tanto para criar (service == null) quanto para
/// editar (service != null) um serviço do prestador.
class ServiceFormScreen extends StatefulWidget {
  final ProviderServiceModel? service;

  const ServiceFormScreen({super.key, this.service});

  bool get isEditing => service != null;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _newQuestionController;
  late List<String> _requiredFields;

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameController = TextEditingController(text: s?.name ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _priceController =
        TextEditingController(text: s != null ? s.price.toStringAsFixed(2) : '');
    _durationController = TextEditingController(
        text: s != null ? s.durationMinutes.toString() : '');
    _newQuestionController = TextEditingController();
    _requiredFields = List<String>.from(s?.requiredFields ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _newQuestionController.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    final duration = int.tryParse(_durationController.text.trim());

    if (name.length < 2 || name.length > 100) {
      return 'O nome deve ter entre 2 e 100 caracteres.';
    }
    if (description.length < 10) {
      return 'A descrição deve ter pelo menos 10 caracteres.';
    }
    if (price == null || price <= 0) {
      return 'Informe um preço válido maior que zero.';
    }
    if (duration == null || duration <= 0) {
      return 'Informe uma duração válida em minutos.';
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    final provider = context.read<ProviderServicesProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim().replaceAll(',', '.'));
    final duration = int.parse(_durationController.text.trim());

    try {
      if (widget.isEditing) {
        await provider.update(
          widget.service!.id,
          name: name,
          description: description,
          price: price,
          durationMinutes: duration,
          requiredFields: _requiredFields,
        );
      } else {
        await provider.create(
          name: name,
          description: description,
          price: price,
          durationMinutes: duration,
          requiredFields: _requiredFields,
        );
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Não foi possível salvar o serviço. Tente novamente.');
      }
    }
  }

  Future<void> _toggleActive() async {
    final service = widget.service!;
    final provider = context.read<ProviderServicesProvider>();
    final willDeactivate = service.active;

    if (willDeactivate) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Desativar serviço'),
          content: const Text(
              'Desativar este serviço cancelará as reservas pendentes e aceitas dele. Deseja continuar?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(true),
              child: const Text('Desativar'),
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
    }

    setState(() => _isSaving = true);
    try {
      await provider.update(service.id, active: !service.active);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Não foi possível alterar o serviço. Tente novamente.');
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
    final isEditing = widget.isEditing;
    final isActive = widget.service?.active ?? true;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1c1c1e),
        border: null,
        middle: Text(isEditing ? 'Editar Serviço' : 'Novo Serviço',
            style: const TextStyle(color: CupertinoColors.white)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Nome'),
              _Field(
                controller: _nameController,
                placeholder: 'Ex.: Corte de Cabelo',
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Descrição'),
              _Field(
                controller: _descriptionController,
                placeholder: 'Descreva o serviço (mín. 10 caracteres)',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Preço (R\$)'),
              _Field(
                controller: _priceController,
                placeholder: 'Ex.: 50.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Duração (minutos)'),
              _Field(
                controller: _durationController,
                placeholder: 'Ex.: 30',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Informações solicitadas ao cliente'),
              if (_requiredFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._requiredFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c2c2e),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(color: CupertinoColors.white, fontSize: 15),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            child: const Icon(CupertinoIcons.minus_circle, color: Color(0xFFFF3B30), size: 20),
                            onPressed: () => setState(() => _requiredFields.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (_requiredFields.length < 10) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _newQuestionController,
                        placeholder: 'Ex.: Quantos pets serão?',
                        style: const TextStyle(color: CupertinoColors.white),
                        placeholderStyle: const TextStyle(color: Color(0xFF636366)),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2c2c2e),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        final q = _newQuestionController.text.trim();
                        if (q.isNotEmpty) {
                          setState(() {
                            _requiredFields.add(q);
                            _newQuestionController.clear();
                          });
                        }
                      },
                      child: const Text('Adicionar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 14),
                ),
              ],
              const SizedBox(height: 28),
              if (_isSaving)
                const Center(child: CupertinoActivityIndicator())
              else ...[
                _PrimaryButton(
                  label: isEditing ? 'Salvar alterações' : 'Salvar',
                  color: const Color(0xFF34C759),
                  icon: CupertinoIcons.checkmark_circle_fill,
                  onTap: _save,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: isActive ? 'Desativar serviço' : 'Ativar serviço',
                    color: isActive
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF007AFF),
                    icon: isActive
                        ? CupertinoIcons.pause_circle_fill
                        : CupertinoIcons.play_circle_fill,
                    onTap: _toggleActive,
                    outlined: true,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _PrimaryButton({
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8e8e93),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: CupertinoColors.white),
      placeholderStyle: const TextStyle(color: Color(0xFF636366)),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2e),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
