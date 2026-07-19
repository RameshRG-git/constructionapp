import '../../shared/api_client.dart';

class InventoryApi {
  InventoryApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listSiteInventory(
    int siteId, {
    String? category,
    bool? lowStock,
    String? sortBy,
    String? sortOrder,
  }) {
    final query = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (lowStock != null) 'low_stock': lowStock.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    return client.getJson('/api/v1/sites/$siteId/inventory', query: query);
  }

  Future<Map<String, dynamic>> createSiteInventory(int siteId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites/$siteId/inventory', payload);

  Future<Map<String, dynamic>> updateInventoryItem(int itemId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/inventory/$itemId', payload);
}
