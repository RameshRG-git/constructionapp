import '../features/budgets/budget_api.dart';
import '../features/dashboard/dashboard_api.dart';
import '../features/inventory/inventory_api.dart';
import '../features/projects/project_api.dart';
import '../features/workloads/workload_api.dart';
import 'api_client.dart';

class ApiRegistry {
  static final ApiClient client = ApiClient(baseUrl: Uri.base.origin);

  static final ProjectApi projects = ProjectApi(client);
  static final InventoryApi inventory = InventoryApi(client);
  static final WorkloadApi workloads = WorkloadApi(client);
  static final BudgetApi budgets = BudgetApi(client);
  static final DashboardApi dashboard = DashboardApi(client);
}
