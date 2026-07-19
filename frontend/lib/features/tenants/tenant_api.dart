import '../../shared/api_client.dart';

class TenantApi {
  TenantApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listTenants() => client.getJson('/api/v1/tenants');

  Future<Map<String, dynamic>> createTenant(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/tenants', payload);

  Future<Map<String, dynamic>> getCurrentTenant() => client.getJson('/api/v1/tenants/current');
}