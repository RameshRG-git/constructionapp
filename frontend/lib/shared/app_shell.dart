import 'package:flutter/material.dart';

import 'api_registry.dart';
import 'workspace_scope.dart';

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
    (route: '/inventory', icon: Icons.inventory_rounded, label: 'Inventory'),
    (route: '/team', icon: Icons.groups_rounded, label: 'Team'),
    (route: '/tenant-admin', icon: Icons.business_rounded, label: 'Tenant Admin'),
  ];

  int get _selectedIndex => _destinations.indexWhere((item) => item.route == widget.currentRoute);

  void _navigate(BuildContext context, int index) {
    final destination = _destinations[index];
    if (destination.route == widget.currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(destination.route);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 1024;

        return FutureBuilder<Map<String, dynamic>>(
          future: _tenantFuture,
          builder: (context, snapshot) {
            final tenant = snapshot.data ?? const <String, dynamic>{};
            final tenantName = tenant['name']?.toString() ?? 'KaniskaHomes';
            final logoUrl = tenant['logo_url']?.toString();
            final workspace = WorkspaceScope.of(context);
            final selectedSite = workspace.selectedSite;

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
                            if (selectedSite != null) ...[
                              ActionChip(
                                avatar: const Icon(Icons.apartment_rounded, size: 18),
                                label: Text('Workspace: ${selectedSite['name']?.toString() ?? ''}'),
                                onPressed: () => Navigator.of(context).pushNamed('/site-workspace'),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2F4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F4C5C),
                                  fontWeight: FontWeight.w700,
                                ),
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
                                    for (var i = 0; i < _destinations.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: _NavButton(
                                          destination: _destinations[i],
                                          selected: (_selectedIndex < 0 ? 0 : _selectedIndex) == i,
                                          onTap: () => _navigate(context, i),
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
                        selectedIndex: _selectedIndex < 0 ? 0 : _selectedIndex,
                        onDestinationSelected: (index) => _navigate(context, index),
                        destinations: [
                          for (final destination in _destinations)
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
