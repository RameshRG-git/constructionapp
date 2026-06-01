import '../../shared/api_client.dart';

class InventoryApi {
  InventoryApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listProjectInventory(int projectId) =>
      client.getJson('/api/v1/projects/$projectId/inventory');
}
