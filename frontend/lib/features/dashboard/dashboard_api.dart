import '../../shared/api_client.dart';

class DashboardApi {
  DashboardApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> getOverview() => client.getJson('/api/v1/reports/overview');
}