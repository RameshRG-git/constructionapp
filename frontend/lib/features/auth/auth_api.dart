import '../../shared/api_client.dart';

class AuthApi {
  AuthApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> login(String identifier, String password) =>
      client.postJson('/api/v1/auth/login', <String, dynamic>{
        'identifier': identifier,
        'password': password,
      });

  Future<Map<String, dynamic>> logout() => client.postJson('/api/v1/auth/logout', <String, dynamic>{});

  Future<Map<String, dynamic>> session() => client.getJson('/api/v1/auth/session');
}
