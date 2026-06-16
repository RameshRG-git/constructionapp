import '../../shared/api_client.dart';

class ProjectApi {
  ProjectApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listProjects({
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
    return client.getJson('/api/v1/projects', query: query);
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/projects', payload);

  Future<Map<String, dynamic>> updateProject(int projectId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/projects/$projectId', payload);

  Future<Map<String, dynamic>> getProjectSummary(int projectId) =>
      client.getJson('/api/v1/projects/$projectId/summary');
}
