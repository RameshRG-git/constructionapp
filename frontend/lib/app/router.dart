import 'package:flutter/material.dart';

import '../features/budgets/budgets_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/workloads/workloads_screen.dart';
import '../shared/app_shell.dart';

class AppRoutes {
  static const dashboard = '/';
  static const projects = '/projects';
  static const inventory = '/inventory';
  static const workloads = '/workloads';
  static const budgets = '/budgets';

  Map<String, WidgetBuilder> get routes => {
      dashboard: (_) => const AppShell(
        title: 'Dashboard',
        currentRoute: dashboard,
        child: DashboardScreen(),
      ),
      projects: (_) => const AppShell(
        title: 'Projects',
        currentRoute: projects,
        child: ProjectsScreen(),
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
      };
}

final appRoutes = AppRoutes();
