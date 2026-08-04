import '../../shared/api_client.dart';

class WorkloadApi {
  WorkloadApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listWorkloads(
    int siteId, {
    String? status,
    String? assignee,
    String? query,
    String? onDate,
    String? fromDate,
    String? toDate,
    bool includePast = false,
    String? weekStart,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
      if (query != null && query.isNotEmpty) 'q': query,
      if (onDate != null && onDate.isNotEmpty) 'on_date': onDate,
      if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      'include_past': includePast.toString(),
      if (weekStart != null && weekStart.isNotEmpty) 'week_start': weekStart,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    return client.getJson('/api/v1/sites/$siteId/assignments', query: params);
  }

  Future<Map<String, dynamic>> createWorkload(int siteId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites/$siteId/assignments', payload);

  Future<Map<String, dynamic>> updateWorkload(int assignmentId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/assignments/$assignmentId', payload);

    Future<Map<String, dynamic>> deleteWorkload(int assignmentId) =>
      client.deleteJson('/api/v1/assignments/$assignmentId');
}
