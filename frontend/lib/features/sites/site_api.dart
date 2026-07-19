import '../../shared/api_client.dart';

class SiteApi {
  SiteApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listSites({
    String? status,
    String? ownerName,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
      if (search != null && search.isNotEmpty) 'q': search,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };
    return client.getJson('/api/v1/sites', query: query);
  }

  Future<Map<String, dynamic>> createSite(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites', payload);

  Future<Map<String, dynamic>> updateSite(int siteId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/sites/$siteId', payload);

  Future<Map<String, dynamic>> getSiteSummary(int siteId) =>
      client.getJson('/api/v1/sites/$siteId/summary');
}
