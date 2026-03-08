import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/employee.dart';
import 'api_client.dart';

class EmployeeApi {
  EmployeeApi(this._dio);

  final Dio _dio;

  factory EmployeeApi.create() => EmployeeApi(ApiClient.instance.client);

  static const _employeesCacheKey = 'employees_page_1';

  Future<Paginated<Employee>> listEmployees({
    int page = 1,
    int pageSize = 20,
    String? projectId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_id'] = projectId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/employees/',
        queryParameters: queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_employeesCacheKey, data);
      return Paginated<Employee>.fromJson(
        data,
        (json) => Employee.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_employeesCacheKey);
      if (cached != null) {
        return Paginated<Employee>.fromJson(
          cached,
          (json) => Employee.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Employee> createEmployee(Employee employee) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/employees/',
      data: employee.toJson(),
    );
    return Employee.fromJson(response.data!);
  }

  Future<Employee> updateEmployee(String id, Employee employee) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/employees/$id',
      data: employee.toJson(),
    );
    return Employee.fromJson(response.data!);
  }

  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/api/v1/employees/$id');
  }
}
