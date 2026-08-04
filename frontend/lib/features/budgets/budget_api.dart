import '../../shared/api_client.dart';

class BudgetApi {
  BudgetApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listBudgets(
    int siteId, {
    String? status,
    String? sortBy,
    String? sortOrder,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'budget_status': status,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    return client.getJson('/api/v1/sites/$siteId/budgets', query: query);
  }

  Future<Map<String, dynamic>> createBudget(int siteId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites/$siteId/budgets', payload);

  Future<Map<String, dynamic>> updateBudget(int budgetId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/budgets/$budgetId', payload);

    Future<Map<String, dynamic>> deleteBudget(int budgetId) =>
      client.deleteJson('/api/v1/budgets/$budgetId');
}
