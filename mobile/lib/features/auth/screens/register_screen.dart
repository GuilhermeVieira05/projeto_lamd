import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'CLIENT';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final tokenStorage = TokenStorage();
      final httpClient = HttpClient(tokenStorage: tokenStorage);
      final service = AuthService(http: httpClient, storage: tokenStorage);
      await service.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );
      if (mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Conta criada!'),
            content: const Text('Faça login para continuar.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Fazer login'),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              ),
            ],
          ),
        );
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao criar conta. Verifique os dados.'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1c1c1e),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.pop(),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.chevron_left, size: 18, color: Color(0xFF34C759)),
                        SizedBox(width: 4),
                        Text('Voltar', style: TextStyle(color: Color(0xFF34C759), fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF007AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34C759).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.person_badge_plus, size: 36, color: CupertinoColors.white),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Criar conta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: CupertinoColors.white),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Preencha os dados para começar',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8e8e93)),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2c2c2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _FormField(
                      controller: _nameController,
                      placeholder: 'Nome completo',
                      icon: CupertinoIcons.person,
                      textCapitalization: TextCapitalization.words,
                    ),
                    Container(height: 0.5, color: const Color(0xFF3a3a3c), margin: const EdgeInsets.only(left: 56)),
                    _FormField(
                      controller: _emailController,
                      placeholder: 'Email',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    Container(height: 0.5, color: const Color(0xFF3a3a3c), margin: const EdgeInsets.only(left: 56)),
                    _FormField(
                      controller: _passwordController,
                      placeholder: 'Senha',
                      icon: CupertinoIcons.lock,
                      obscureText: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2c2c2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPO DE CONTA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF636366),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleOption(
                            label: 'Cliente',
                            subtitle: 'Faço reservas',
                            icon: CupertinoIcons.person_fill,
                            color: const Color(0xFF34C759),
                            selected: _selectedRole == 'CLIENT',
                            onTap: () => setState(() => _selectedRole = 'CLIENT'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleOption(
                            label: 'Prestador',
                            subtitle: 'Ofereço serviços',
                            icon: CupertinoIcons.briefcase_fill,
                            color: const Color(0xFF007AFF),
                            selected: _selectedRole == 'PROVIDER',
                            onTap: () => setState(() => _selectedRole = 'PROVIDER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_circle, color: Color(0xFFFF453A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF453A), fontSize: 14))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              CupertinoButton(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Criar conta',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1c1c1e)),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  const _FormField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8e8e93)),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: keyboardType,
              obscureText: obscureText,
              autocorrect: autocorrect,
              textCapitalization: textCapitalization,
              decoration: null,
              padding: const EdgeInsets.symmetric(vertical: 16),
              style: const TextStyle(fontSize: 16, color: CupertinoColors.white),
              placeholderStyle: const TextStyle(color: Color(0xFF636366), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0xFF3a3a3c),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFF3a3a3c),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? color : const Color(0xFF8e8e93), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? color : CupertinoColors.white,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8e8e93)),
            ),
          ],
        ),
      ),
    );
  }
}
