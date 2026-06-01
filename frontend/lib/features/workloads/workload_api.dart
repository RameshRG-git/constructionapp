import '../../shared/api_client.dart';

class WorkloadApi {
  WorkloadApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listWorkloads(int projectId) =>
      client.getJson('/api/v1/projects/$projectId/assignments');
}
