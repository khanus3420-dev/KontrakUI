import 'package:dio/dio.dart';

import '../models/salary.dart';
import 'api_client.dart';

class SalaryApi {
  SalaryApi(this._dio);

  final Dio _dio;

  factory SalaryApi.create() => SalaryApi(ApiClient.instance.client);

  Future<SalaryCalculationResponse> calculateSalaries({
    required DateTime month,
  }) async {
    try {
      // Ensure month is first day
      final monthStart = DateTime(month.year, month.month, 1);
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/salary/calculate',
        queryParameters: {
          'month': monthStart.toIso8601String().split('T')[0],
        },
      );
      final data = response.data ?? <String, dynamic>{};
      return SalaryCalculationResponse.fromJson(data);
    } on DioException catch (e) {
      print('Salary Calculation API Error: ${e.message}');
      rethrow;
    }
  }

  Future<SalaryPaymentResponse> paySalary({
    required String employeeId,
    required DateTime month,
    required double amount,
    String? projectId,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    try {
      // Ensure month is first day
      final monthStart = DateTime(month.year, month.month, 1);
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/salary/pay',
        data: {
          'employee_id': employeeId,
          'month': monthStart.toIso8601String().split('T')[0],
          'amount': amount,
          if (projectId != null) 'project_id': projectId,
          'payment_method': paymentMethod,
          if (notes != null) 'notes': notes,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      return SalaryPaymentResponse.fromJson(data);
    } on DioException catch (e) {
      print('Salary Payment API Error: ${e.message}');
      rethrow;
    }
  }
}
