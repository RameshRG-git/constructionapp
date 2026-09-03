import '../features/auth/auth_api.dart';
import '../features/budgets/budget_api.dart';
import '../features/dashboard/dashboard_api.dart';
import '../features/inventory/inventory_api.dart';
import '../features/payroll/payroll_api.dart';
import '../features/sites/site_api.dart';
import '../features/team/team_api.dart';
import '../features/tenants/tenant_api.dart';
import '../features/tenants/user_api.dart';
import '../features/workloads/workload_api.dart';
import 'api_client.dart';

class ApiRegistry {
  static final ApiClient client = ApiClient(baseUrl: Uri.base.origin);

  static final SiteApi sites = SiteApi(client);
  static final InventoryApi inventory = InventoryApi(client);
  static final WorkloadApi workloads = WorkloadApi(client);
  static final BudgetApi budgets = BudgetApi(client);
  static final PayrollApi payroll = PayrollApi(client);
  static final DashboardApi dashboard = DashboardApi(client);
  static final TeamApi team = TeamApi(client);
  static final TenantApi tenants = TenantApi(client);
  static final UserApi users = UserApi(client);
  static final AuthApi auth = AuthApi(client);
}
