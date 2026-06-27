import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/provider_services_provider.dart';
import '../services/provider_services_api.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderServicesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderServicesProvider>(
      builder: (context, provider, _) {
        final services = provider.services;
        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFF1c1c1e),
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                backgroundColor: const Color(0xFF1c1c1e),
                border: null,
                largeTitle: const Text(
                  'Meus Serviços',
                  style: TextStyle(color: CupertinoColors.white),
                ),
                trailing: GestureDetector(
                  onTap: () => context.push('/provider/services/new'),
                  child: const Icon(
                    CupertinoIcons.add_circled_solid,
                    color: Color(0xFF34C759),
                    size: 28,
                  ),
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () => provider.load(),
              ),
              if (provider.isLoading && services.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (provider.error != null && services.isEmpty)
                SliverFillRemaining(
                  child: _Message(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title: provider.error!,
                  ),
                )
              else if (services.isEmpty)
                const SliverFillRemaining(
                  child: _Message(
                    icon: CupertinoIcons.briefcase,
                    title: 'Você ainda não cadastrou serviços',
                    subtitle: 'Toque em + para cadastrar o primeiro.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ServiceCard(service: services[index]),
                      childCount: services.length,
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
  final ProviderServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final priceStr = 'R\$${service.price.toStringAsFixed(2)}';
    return GestureDetector(
      onTap: () => context.push(
        '/provider/services/${service.id}/edit',
        extra: service,
      ),
      child: Container(
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
                    service.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                _StatusBadge(active: service.active),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 0.5, color: const Color(0xFF3a3a3c)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(CupertinoIcons.money_dollar_circle,
                    size: 14, color: Color(0xFF34C759)),
                const SizedBox(width: 6),
                Text(priceStr,
                    style: const TextStyle(
                        fontSize: 14, color: CupertinoColors.white)),
                const SizedBox(width: 16),
                const Icon(CupertinoIcons.clock,
                    size: 14, color: Color(0xFFFF9500)),
                const SizedBox(width: 6),
                Text('${service.durationMinutes}min',
                    style: const TextStyle(
                        fontSize: 14, color: CupertinoColors.white)),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_right,
                    size: 14, color: Color(0xFF636366)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF34C759) : const Color(0xFF8e8e93);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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
