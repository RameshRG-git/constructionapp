import 'package:flutter/material.dart';

import '../../shared/workspace_scope.dart';
import '../budgets/budgets_screen.dart';
import '../inventory/inventory_screen.dart';
import '../workloads/workloads_screen.dart';

class SiteWorkspaceScreen extends StatefulWidget {
  const SiteWorkspaceScreen({super.key});

  @override
  State<SiteWorkspaceScreen> createState() => _SiteWorkspaceScreenState();
}

class _SiteWorkspaceScreenState extends State<SiteWorkspaceScreen> {
  Widget _buildHeader(BuildContext context, Map<String, dynamic>? site) {
    final theme = Theme.of(context);
    final siteName = site?['name']?.toString() ?? 'Pick a site to open the workspace';
    final status = site?['status']?.toString();
    final location = site?['site_location']?.toString() ?? '';
    final owner = site?['owner_name']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF1F6F7E)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Workspace',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            siteName,
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (status != null && status.isNotEmpty)
                Chip(
                  label: Text(status, style: const TextStyle(color: Color(0xFF0F4C5C))),
                  backgroundColor: Colors.white,
                ),
              if (location.isNotEmpty)
                Chip(
                  label: Text(location, style: const TextStyle(color: Color(0xFF0F4C5C))),
                  backgroundColor: Colors.white,
                ),
              if (owner.isNotEmpty)
                Chip(
                  label: Text(owner, style: const TextStyle(color: Color(0xFF0F4C5C))),
                  backgroundColor: Colors.white,
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspace = WorkspaceScope.of(context);
    final selectedSite = workspace.selectedSite;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedSite != null) ...[
            _buildHeader(context, selectedSite),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Inventory'),
                Tab(icon: Icon(Icons.groups_2_rounded), text: 'Workloads'),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Budgets'),
                Tab(icon: Icon(Icons.settings_rounded), text: 'Workspace'),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: TabBarView(
                children: [
                  InventoryScreen(),
                  WorkloadsScreen(),
                  BudgetsScreen(),
                  _WorkspaceHelpPanel(),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 48),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment_rounded, size: 54, color: Color(0xFF0F4C5C)),
                        const SizedBox(height: 12),
                        Text('Choose a site to open its workspace', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Select one site, then manage inventory, workloads, and budgets without switching screens.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceHelpPanel extends StatelessWidget {
  const _WorkspaceHelpPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.tips_and_updates_rounded, size: 52, color: Color(0xFF0F4C5C)),
                SizedBox(height: 12),
                Text(
                  'Workspace-first flow',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Pick a site once, then move through inventory, workloads, and budgets from one place. Filters are now easier to scan and sort choices are direct.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}