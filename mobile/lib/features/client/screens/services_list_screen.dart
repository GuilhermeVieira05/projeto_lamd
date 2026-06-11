import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../providers/services_provider.dart';
import '../services/services_api.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  String _selectedCategory = 'Todos';

  static const _categories = ['Todos', 'Beleza', 'Casa', 'Saúde', 'Tech'];

  static const _categoryKeywords = {
    'Beleza': ['corte', 'cabelo', 'massagem', 'relaxante', 'estetica', 'unhas'],
    'Casa': ['limpeza', 'residencial', 'jardim'],
    'Saúde': ['personal', 'treino', 'fisio', 'nutri'],
    'Tech': ['ti', 'consultoria', 'tecnologia', 'suporte'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().load();
    });
  }

  List<ServiceModel> _filterByCategory(List<ServiceModel> services) {
    if (_selectedCategory == 'Todos') return services;
    final keywords = _categoryKeywords[_selectedCategory] ?? [];
    return services.where((s) {
      final name = s.name.toLowerCase();
      return keywords.any((k) => name.contains(k));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firstName = auth.user?.name.split(' ').first ?? '';

    return Consumer<ServicesProvider>(
      builder: (context, provider, _) {
        final displayed = _filterByCategory(provider.services);

        return CupertinoPageScaffold(
            backgroundColor: const Color(0xFF1c1c1e),
            child: CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  backgroundColor: const Color(0xFF1c1c1e),
                  border: null,
                  largeTitle: Text(
                    'Olá, $firstName',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: CupertinoSearchTextField(
                      onChanged: provider.filter,
                      placeholder: 'Buscar serviço',
                      placeholderStyle: const TextStyle(color: Color(0xFF8e8e93)),
                      backgroundColor: const Color(0xFF2c2c2e),
                      style: const TextStyle(color: CupertinoColors.white),
                      prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF8e8e93)),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isActive = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF34C759) : const Color(0xFF2c2c2e),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? const Color(0xFF1c1c1e) : const Color(0xFF8e8e93),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: _EmptyState(
                      icon: CupertinoIcons.exclamationmark_circle,
                      message: provider.error!,
                      actionLabel: 'Tentar novamente',
                      onAction: provider.load,
                    ),
                  )
                else if (displayed.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyState(
                      icon: CupertinoIcons.bag,
                      message: 'Nenhum serviço disponível',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ServiceCard(
                          service: displayed[index],
                          onTap: () => context.push('/client/services/${displayed[index].id}'),
                        ),
                        childCount: displayed.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  static const _icons = [
    CupertinoIcons.scissors,
    CupertinoIcons.heart,
    CupertinoIcons.sparkles,
    CupertinoIcons.hand_raised,
    CupertinoIcons.person,
  ];

  static const _colors = [
    Color(0xFF007AFF),
    Color(0xFFFF2D55),
    Color(0xFFAF52DE),
    Color(0xFF34C759),
    Color(0xFFFF9500),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = service.name.length % _icons.length;
    final color = _colors[idx];
    final icon = _icons[idx];

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.person, size: 12, color: Color(0xFF8e8e93)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.providerName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8e8e93)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Pill(
                          text: 'R\$ ${service.price.toStringAsFixed(2)}',
                          color: const Color(0xFF34C759),
                          icon: CupertinoIcons.money_dollar_circle,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          text: '${service.durationMinutes} min',
                          color: const Color(0xFF007AFF),
                          icon: CupertinoIcons.clock,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right, color: Color(0xFF636366), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Pill({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: const Color(0xFF636366)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF8e8e93), fontSize: 15)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            CupertinoButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
