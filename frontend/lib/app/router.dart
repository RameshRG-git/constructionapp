import 'package:flutter/material.dart';

import '../features/budgets/budgets_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/workloads/workloads_screen.dart';

class AppRoutes {
  static const dashboard = '/';
  static const projects = '/projects';
  static const inventory = '/inventory';
  static const workloads = '/workloads';
  static const budgets = '/budgets';

  Map<String, WidgetBuilder> get routes => {
        dashboard: (_) => const DashboardScreen(),
        projects: (_) => const ProjectsScreen(),
        inventory: (_) => const InventoryScreen(),
        workloads: (_) => const WorkloadsScreen(),
        budgets: (_) => const BudgetsScreen(),
      };
}

final appRoutes = AppRoutes();
