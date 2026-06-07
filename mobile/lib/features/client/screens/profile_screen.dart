import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../services/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileApi _api;
  ProfileUser? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _editingName = false;
  bool _editingEmail = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tokenStorage = TokenStorage();
    final http = HttpClient(tokenStorage: tokenStorage)..onUnauthorized = auth.logout;
    _api = ProfileApi(http: http);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _api.getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _emailController.text = user.email;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_user == null) return;
    setState(() => _isSaving = true);
    try {
      final updated = await _api.updateMe(
        name: _editingName ? _nameController.text.trim() : null,
        email: _editingEmail ? _emailController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _user = updated;
          _editingName = false;
          _editingEmail = false;
          _isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Erro'),
            content: const Text('Não foi possível salvar as alterações.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _changePassword() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Nova senha'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            obscureText: true,
            placeholder: 'Digite a nova senha',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Salvar'),
            onPressed: () async {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              final pw = controller.text.trim();
              if (pw.isEmpty) return;
              try {
                await _api.updateMe(password: pw);
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingName || _editingEmail;
    final initial = _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : '?';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1c1c1e),
        border: null,
        middle: const Text('Perfil', style: TextStyle(color: CupertinoColors.white)),
        trailing: isEditing
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text('Salvar', style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.w600)),
              )
            : null,
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF007AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _user?.name ?? '',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (_user?.role ?? '').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2c2c2e),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _FieldRow(
                          label: 'NOME',
                          value: _user?.name ?? '',
                          editing: _editingName,
                          controller: _nameController,
                          onTap: () => setState(() { _editingName = true; }),
                          hasBorder: true,
                        ),
                        _FieldRow(
                          label: 'EMAIL',
                          value: _user?.email ?? '',
                          editing: _editingEmail,
                          controller: _emailController,
                          onTap: () => setState(() { _editingEmail = true; }),
                          hasBorder: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        GestureDetector(
                          onTap: _changePassword,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 64,
                                  child: Text(
                                    'SENHA',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF636366), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('••••••••', style: TextStyle(fontSize: 15, color: CupertinoColors.white.withValues(alpha: 0.4))),
                                ),
                                const Text('Alterar', style: TextStyle(fontSize: 13, color: Color(0xFF34C759), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.read<AuthProvider>().logout(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c2c2e),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text(
                          'Sair da conta',
                          style: TextStyle(color: Color(0xFFFF453A), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onTap;
  final bool hasBorder;
  final TextInputType? keyboardType;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.editing,
    required this.controller,
    required this.onTap,
    this.hasBorder = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: hasBorder
              ? const Border(bottom: BorderSide(color: Color(0xFF3a3a3c), width: 1))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF636366), fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: editing
                  ? CupertinoTextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: keyboardType,
                      style: const TextStyle(color: CupertinoColors.white, fontSize: 15),
                      decoration: const BoxDecoration(),
                      padding: EdgeInsets.zero,
                    )
                  : Text(value, style: const TextStyle(color: CupertinoColors.white, fontSize: 15)),
            ),
            if (!editing)
              const Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFF636366)),
          ],
        ),
      ),
    );
  }
}
