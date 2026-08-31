import '../../shared/api_client.dart';

class UserApi {
  UserApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listUsers({
    String? query,
    bool includeInactive = true,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, String>{
      if (query != null && query.isNotEmpty) 'q': query,
      'include_inactive': includeInactive.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };
    return client.getJson('/api/v1/users', query: params);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/users', payload);

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/users/$userId', payload);

  Future<Map<String, dynamic>> deleteUser(int userId) => client.deleteJson('/api/v1/users/$userId');

  Future<Map<String, dynamic>> listUserTenants({int? userId, String? tenantSlug}) {
    final params = <String, String>{
      if (userId != null) 'user_id': userId.toString(),
      if (tenantSlug != null && tenantSlug.isNotEmpty) 'tenant_slug': tenantSlug,
    };
    return client.getJson('/api/v1/user-tenants', query: params);
  }

  Future<Map<String, dynamic>> mapUserToTenant(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/user-tenants', payload);

  Future<Map<String, dynamic>> updateUserTenant(int mappingId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/user-tenants/$mappingId', payload);

  Future<Map<String, dynamic>> deleteUserTenant(int mappingId) =>
      client.deleteJson('/api/v1/user-tenants/$mappingId');
}
