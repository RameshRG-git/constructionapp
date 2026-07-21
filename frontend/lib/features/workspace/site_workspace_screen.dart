import 'package:flutter/material.dart';

import '../../shared/api_registry.dart';
import '../../shared/workspace_scope.dart';
import '../budgets/budgets_screen.dart';
import '../inventory/inventory_screen.dart';
import '../workloads/workloads_screen.dart';

class SiteWorkspaceScreen extends StatelessWidget {
  const SiteWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceScope.of(context);
    final site = workspace.selectedSite;
    final siteName = site?['name']?.toString() ?? 'No site selected';
    final siteLocation = site?['site_location']?.toString() ?? '';
    final siteId = workspace.selectedSiteId;

    if (workspace.isLoading && !workspace.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workspace.error != null && workspace.sites.isEmpty) {
      return Center(child: Text('Unable to load sites: ${workspace.error}'));
    }

    if (siteId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apartment_rounded, size: 42),
            const SizedBox(height: 12),
            const Text('Create a site first to open a workspace.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: workspace.reloadSites,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh sites'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE7F8F6), Color(0xFFF2FBF9)],
              ),
              border: Border.all(color: const Color(0xFFC7ECE6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C5C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspaces_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        siteLocation.isEmpty ? 'Site workspace' : siteLocation,
                        style: const TextStyle(color: Color(0xFF475467)),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/sites'),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change Site'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Inventory'),
              Tab(icon: Icon(Icons.engineering_rounded), text: 'Workloads'),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Budgets'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                InventoryScreen(lockedSiteId: siteId),
                WorkloadsScreen(lockedSiteId: siteId),
                BudgetsScreen(lockedSiteId: siteId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
