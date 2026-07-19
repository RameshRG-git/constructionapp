import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String _tenantName = 'kaniskahomes';

  String get tenantName => _tenantName;

  void setTenantName(String tenantName) {
    final cleaned = tenantName.trim().toLowerCase();
    if (cleaned.isNotEmpty) {
      _tenantName = cleaned;
    }
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final response = await _client.get(
      _buildUri(path, query),
      headers: {'X-Tenant': _tenantName},
    );
    return _decodeJsonMap(response);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> payload) async {
    final response = await _client.post(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant': _tenantName,
      },
      body: jsonEncode(payload),
    );
    return _decodeJsonMap(response);
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> payload) async {
    final response = await _client.patch(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant': _tenantName,
      },
      body: jsonEncode(payload),
    );
    return _decodeJsonMap(response);
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final cleanedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanedBase$cleanedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Map<String, dynamic> _decodeJsonMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'API request failed ($statusCode): $body';
}
