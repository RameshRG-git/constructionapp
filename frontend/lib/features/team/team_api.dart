import '../../shared/api_client.dart';

class TeamApi {
  TeamApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listMembers({
    String? query,
    bool includeInactive = false,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, String>{
      if (query != null && query.isNotEmpty) 'q': query,
      'include_inactive': includeInactive.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };
    return client.getJson('/api/v1/team-members', query: params);
  }

  Future<Map<String, dynamic>> createMember(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/team-members', payload);

  Future<Map<String, dynamic>> updateMember(int memberId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/team-members/$memberId', payload);

  Future<Map<String, dynamic>> listRoles({bool includeInactive = true}) {
    return client.getJson(
      '/api/v1/team-roles',
      query: <String, String>{'include_inactive': includeInactive.toString()},
    );
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/team-roles', payload);

  Future<Map<String, dynamic>> updateRole(int roleId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/team-roles/$roleId', payload);
}