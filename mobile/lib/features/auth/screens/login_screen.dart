import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/http_client.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final tokenStorage = TokenStorage();
      final httpClient = HttpClient(tokenStorage: tokenStorage);
      final service = AuthService(http: httpClient, storage: tokenStorage);
      final result = await service.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      auth.setAuthenticated(
        token: result.token,
        userId: result.userId,
        name: result.name,
        role: result.role,
      );
    } catch (e) {
      if (mounted) setState(() { _error = 'Email ou senha inválidos'; });
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
              const SizedBox(height: 60),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF007AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34C759).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.briefcase_fill, size: 38, color: CupertinoColors.white),
                ),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'Reserva de Serviços',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: CupertinoColors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Entre na sua conta para continuar',
                  style: TextStyle(fontSize: 15, color: Color(0xFF8e8e93)),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2c2c2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _FormField(
                      controller: _emailController,
                      placeholder: 'Email',
                      icon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      isFirst: true,
                    ),
                    Container(height: 0.5, color: const Color(0xFF3a3a3c), margin: const EdgeInsets.only(left: 56)),
                    _FormField(
                      controller: _passwordController,
                      placeholder: 'Senha',
                      icon: CupertinoIcons.lock,
                      obscureText: true,
                      isLast: true,
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
                      Text(_error!, style: const TextStyle(color: Color(0xFFFF453A), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              CupertinoButton(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1c1c1e)),
                      ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem conta? ', style: TextStyle(color: Color(0xFF8e8e93), fontSize: 15)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'Criar conta',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF34C759)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
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
  final bool isFirst;
  final bool isLast;

  const _FormField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.isFirst = false,
    this.isLast = false,
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
