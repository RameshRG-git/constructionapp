import '../../shared/api_client.dart';

class PayrollApi {
  PayrollApi(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> getWeeklyPayroll(int siteId, {String? weekStart}) {
    final query = <String, String>{
      if (weekStart != null && weekStart.isNotEmpty) 'week_start': weekStart,
    };

    return client.getJson('/api/v1/sites/$siteId/payroll', query: query);
  }

  Future<Map<String, dynamic>> listPayrollWeeks(int siteId) =>
      client.getJson('/api/v1/sites/$siteId/payroll/weeks');

  Future<Map<String, dynamic>> recordPayment(int siteId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites/$siteId/payroll/payments', payload);

  Future<Map<String, dynamic>> payAll(int siteId, Map<String, dynamic> payload) =>
      client.postJson('/api/v1/sites/$siteId/payroll/pay-all', payload);
}
