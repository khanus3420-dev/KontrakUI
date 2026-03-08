import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/attendance.dart';
import 'api_client.dart';

class AttendanceApi {
  AttendanceApi(this._dio);

  final Dio _dio;

  factory AttendanceApi.create() => AttendanceApi(ApiClient.instance.client);

  static const _attendanceCacheKey = 'attendance_page_1';

  Future<Paginated<Attendance>> listAttendance({
    int page = 1,
    int pageSize = 20,
    String? employeeId,
    String? projectId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employee_id'] = employeeId;
      }
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_id'] = projectId;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/attendance/',
        queryParameters: queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_attendanceCacheKey, data);
      return Paginated<Attendance>.fromJson(
        data,
        (json) => Attendance.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_attendanceCacheKey);
      if (cached != null) {
        return Paginated<Attendance>.fromJson(
          cached,
          (json) => Attendance.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Attendance> markAttendance(Attendance attendance) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/attendance/',
      data: attendance.toJson(),
    );
    return Attendance.fromJson(response.data!);
  }

  Future<Attendance> updateAttendance(String id, Attendance attendance) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/attendance/$id',
      data: attendance.toJson(),
    );
    return Attendance.fromJson(response.data!);
  }

  Future<void> deleteAttendance(String id) async {
    await _dio.delete('/api/v1/attendance/$id');
  }
}
