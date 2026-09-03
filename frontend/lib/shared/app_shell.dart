import 'package:flutter/material.dart';

import '../app/router.dart';
import 'api_registry.dart';
import 'auth_scope.dart';

const _appVersion = '0.1.1+2';

class AppShell extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Future<Map<String, dynamic>>? _tenantFuture;

  @override
  void initState() {
    super.initState();
    _tenantFuture = ApiRegistry.tenants.getCurrentTenant();
  }

  static const _destinations = <({String route, IconData icon, String label})>[
    (route: '/', icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (route: '/sites', icon: Icons.apartment_rounded, label: 'Sites'),
    (route: '/inventory', icon: Icons.inventory_rounded, label: 'Materials Hub'),
    (route: '/team', icon: Icons.groups_rounded, label: 'Team'),
    (route: '/tenant-admin', icon: Icons.business_rounded, label: 'Tenant Admin'),
  ];

  List<({String route, IconData icon, String label})> _visibleDestinations(bool isTenantAdmin) {
    return _destinations
        .where((item) => item.route != AppRoutes.tenantAdmin || isTenantAdmin)
        .toList();
  }

  int _selectedIndexOf(List<({String route, IconData icon, String label})> destinations) {
    return destinations.indexWhere((item) => item.route == widget.currentRoute);
  }

  void _navigate(
    BuildContext context,
    List<({String route, IconData icon, String label})> destinations,
    int index,
  ) {
    final destination = destinations[index];
    if (destination.route == widget.currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(destination.route);
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthScope.of(context).signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.currentRoute == AppRoutes.tenantAdmin && !auth.isTenantAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final destinations = _visibleDestinations(auth.isTenantAdmin);
    final selectedIndex = _selectedIndexOf(destinations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 1024;

        return FutureBuilder<Map<String, dynamic>>(
          future: _tenantFuture,
          builder: (context, snapshot) {
            final tenant = snapshot.data ?? const <String, dynamic>{};
            final tenantName = tenant['name']?.toString() ?? 'KaniskaHomes';
            final logoUrl = tenant['logo_url']?.toString();

            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF4F8FB),
                      Color(0xFFEEF3F7),
                      Color(0xFFF7F9FC),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFDCE4EE)),
                        ),
                        child: Row(
                          children: [
                            _TenantBadge(logoUrl: logoUrl),
                            const SizedBox(width: 12),
                            Text(
                              tenantName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              tooltip: 'Account',
                              onSelected: (value) {
                                if (value == 'logout') {
                                  _signOut(context);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(auth.displayName),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Version $_appVersion',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.logout_rounded),
                                    title: Text('Sign out'),
                                  ),
                                ),
                              ],
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFFEAF2F4),
                                child: Icon(Icons.person_rounded, color: Color(0xFF0F4C5C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (useRail)
                              Container(
                                width: 240,
                                margin: const EdgeInsets.fromLTRB(20, 8, 0, 20),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFFDCE4EE)),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 4),
                                    for (var i = 0; i < destinations.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: _NavButton(
                                          destination: destinations[i],
                                          selected: (selectedIndex < 0 ? 0 : selectedIndex) == i,
                                          onTap: () => _navigate(context, destinations, i),
                                        ),
                                      ),
                                    const Spacer(),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        'Modern Construction Ops',
                                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.fromLTRB(useRail ? 14 : 20, 8, 20, useRail ? 20 : 86),
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.84),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFFDCE4EE)),
                                ),
                                child: widget.child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: useRail
                  ? null
                  : Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDCE4EE)),
                      ),
                      child: NavigationBar(
                        backgroundColor: Colors.transparent,
                        indicatorColor: const Color(0xFFDCEFF4),
                        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                        onDestinationSelected: (index) => _navigate(context, destinations, index),
                        destinations: [
                          for (final destination in destinations)
                            NavigationDestination(
                              icon: Icon(destination.icon),
                              label: destination.label,
                            ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}

class _TenantBadge extends StatelessWidget {
  final String? logoUrl;

  const _TenantBadge({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          logoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF2C7A7B)],
        ),
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.white),
    );
  }
}

class _NavButton extends StatelessWidget {
  final ({String route, IconData icon, String label}) destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDCEFF4) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: selected ? const Color(0xFF0F4C5C) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? const Color(0xFF0F4C5C) : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
