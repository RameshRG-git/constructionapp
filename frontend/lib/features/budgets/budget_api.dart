import '../../shared/api_client.dart';

class BudgetApi {
  BudgetApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listBudgets(int projectId) =>
      client.getJson('/api/v1/projects/$projectId/budgets');
}
