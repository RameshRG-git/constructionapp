import '../../shared/api_client.dart';

class WorkloadApi {
  WorkloadApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listWorkloads(
    int projectId, {
    String? status,
    String? assignee,
    String? sortBy,
    String? sortOrder,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    return client.getJson('/api/v1/projects/$projectId/assignments', query: query);
  }

  Future<Map<String, dynamic>> createWorkload(int projectId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/projects/$projectId/assignments', payload);

  Future<Map<String, dynamic>> updateWorkload(int assignmentId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/assignments/$assignmentId', payload);
}
