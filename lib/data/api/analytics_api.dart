import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/analytics.dart';
import 'api_client.dart';

class AnalyticsApi {
  AnalyticsApi(this._dio);

  final Dio _dio;

  factory AnalyticsApi.create() => AnalyticsApi(ApiClient.instance.client);

  static const _monthlyExpensesCacheKey = 'monthly_expenses';

  Future<MonthlyExpenseData> getMonthlyExpenses({
    required int year,
    String? projectId,
  }) async {
    try {
      print('AnalyticsApi.getMonthlyExpenses called with year=$year, projectId=$projectId');
      final queryParams = <String, dynamic>{'year': year};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_id'] = projectId;
      }
      print('Query params: $queryParams');
      
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/analytics/monthly-expenses',
        queryParameters: queryParams,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      
      final data = response.data ?? <String, dynamic>{};
      print('Analytics API Response data: $data');
      print('Response data type: ${data.runtimeType}');
      print('Points in response: ${data['points']}');
      print('Points type: ${data['points']?.runtimeType}');
      
      if (data.isEmpty) {
        print('Warning: Empty response data');
        return MonthlyExpenseData(points: []);
      }
      
      await CacheService.saveJson(_monthlyExpensesCacheKey, data);
      final result = MonthlyExpenseData.fromJson(data);
      print('Successfully parsed MonthlyExpenseData: ${result.points.length} points');
      for (var point in result.points) {
        print('  - Month: ${point.month}, Expense: ${point.totalExpense}');
      }
      return result;
    } on DioException catch (e) {
      // Log the error for debugging
      print('Analytics API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      
      // Try to use cached data if available
      final cached = CacheService.getJson(_monthlyExpensesCacheKey);
      if (cached != null) {
        try {
          return MonthlyExpenseData.fromJson(cached);
        } catch (_) {
          // If cached data is invalid, rethrow original error
        }
      }
      rethrow;
    } catch (e) {
      // Handle any other errors
      print('Unexpected Analytics API Error: $e');
      rethrow;
    }
  }

  Future<ProjectProfitData> getProjectProfit() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/analytics/project-profit');
      final data = response.data ?? <String, dynamic>{};
      return ProjectProfitData.fromJson(data);
    } on DioException catch (e) {
      print('Project Profit API Error: ${e.message}');
      rethrow;
    }
  }

  Future<CategoryExpenseData> getCategoryExpenses({String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_id'] = projectId;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/analytics/category-expenses',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      return CategoryExpenseData.fromJson(data);
    } on DioException catch (e) {
      print('Category Expenses API Error: ${e.message}');
      rethrow;
    }
  }

  Future<BudgetVsActualData> getBudgetVsActual() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/analytics/budget-vs-actual');
      final data = response.data ?? <String, dynamic>{};
      return BudgetVsActualData.fromJson(data);
    } on DioException catch (e) {
      print('Budget vs Actual API Error: ${e.message}');
      rethrow;
    }
  }

  Future<EmployeeSalaryData> getEmployeeSalaryDistribution({DateTime? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) {
        queryParams['month'] = month.toIso8601String().split('T')[0];
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/analytics/employee-salary-distribution',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      return EmployeeSalaryData.fromJson(data);
    } on DioException catch (e) {
      print('Employee Salary API Error: ${e.message}');
      rethrow;
    }
  }
}

