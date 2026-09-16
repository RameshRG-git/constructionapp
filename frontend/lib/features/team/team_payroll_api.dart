import '../../shared/api_client.dart';

class TeamPayrollApi {
  TeamPayrollApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> listSickLeaves({String? employeeName}) {
    final query = <String, String>{
      if (employeeName != null && employeeName.isNotEmpty) 'employee_name': employeeName,
    };
    return client.getJson('/api/v1/team/sick-leaves', query: query);
  }

  Future<Map<String, dynamic>> createSickLeave(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/team/sick-leaves', payload);

  Future<Map<String, dynamic>> deleteSickLeave(int leaveId) =>
      client.deleteJson('/api/v1/team/sick-leaves/$leaveId');

  Future<Map<String, dynamic>> listAdvances({String? employeeName, String? status}) {
    final query = <String, String>{
      if (employeeName != null && employeeName.isNotEmpty) 'employee_name': employeeName,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    return client.getJson('/api/v1/team/advances', query: query);
  }

  Future<Map<String, dynamic>> createAdvance(Map<String, dynamic> payload) =>
      client.postJson('/api/v1/team/advances', payload);

  Future<Map<String, dynamic>> updateAdvance(int advanceId, Map<String, dynamic> payload) =>
      client.patchJson('/api/v1/team/advances/$advanceId', payload);

  Future<Map<String, dynamic>> deleteAdvance(int advanceId) =>
      client.deleteJson('/api/v1/team/advances/$advanceId');

  Future<Map<String, dynamic>> listAdvanceRecoveries(int advanceId) =>
      client.getJson('/api/v1/team/advances/$advanceId/recoveries');
}
