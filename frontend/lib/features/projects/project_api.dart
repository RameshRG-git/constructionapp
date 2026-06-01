import '../../shared/api_client.dart';

class ProjectApi {
  ProjectApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listProjects() => client.getJson('/api/v1/projects');
  Future<Map<String, dynamic>> getProjectSummary(int projectId) =>
      client.getJson('/api/v1/projects/$projectId/summary');
}
