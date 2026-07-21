import 'package:flutter/material.dart';

import '../features/budgets/budgets_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/sites/sites_screen.dart';
import '../features/tenants/tenant_admin_screen.dart';
import '../features/workspace/site_workspace_screen.dart';
import '../features/workloads/workloads_screen.dart';
import '../shared/app_shell.dart';

class AppRoutes {
  static const dashboard = '/';
  static const dashboardAlias = '/dashboard';
  static const sites = '/sites';
  static const workspace = '/workspace';
  static const projectsLegacy = '/projects';
  static const inventory = '/inventory';
  static const workloads = '/workloads';
  static const budgets = '/budgets';
  static const tenantAdmin = '/tenant-admin';

  Map<String, WidgetBuilder> get routes => {
      dashboard: (_) => const AppShell(
        title: 'Dashboard',
        currentRoute: dashboard,
        child: DashboardScreen(),
      ),
      dashboardAlias: (_) => const AppShell(
        title: 'Dashboard',
        currentRoute: dashboard,
        child: DashboardScreen(),
      ),
      sites: (_) => const AppShell(
        title: 'Sites',
        currentRoute: sites,
        child: SitesScreen(),
      ),
      workspace: (_) => const AppShell(
        title: 'Site Workspace',
        currentRoute: workspace,
        child: SiteWorkspaceScreen(),
      ),
      projectsLegacy: (_) => const AppShell(
        title: 'Sites',
        currentRoute: sites,
        child: SitesScreen(),
      ),
      inventory: (_) => const AppShell(
        title: 'Inventory',
        currentRoute: inventory,
        child: InventoryScreen(),
      ),
      workloads: (_) => const AppShell(
        title: 'Workloads',
        currentRoute: workloads,
        child: WorkloadsScreen(),
      ),
      budgets: (_) => const AppShell(
        title: 'Budgets',
        currentRoute: budgets,
        child: BudgetsScreen(),
      ),
      tenantAdmin: (_) => const AppShell(
        title: 'Tenant Admin',
        currentRoute: tenantAdmin,
        child: TenantAdminScreen(),
      ),
      };
}

final appRoutes = AppRoutes();
