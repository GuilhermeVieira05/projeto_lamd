import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role == requiredRole) return child;
    return const CupertinoPageScaffold(
      child: Center(child: Text('Acesso negado')),
    );
  }
}
