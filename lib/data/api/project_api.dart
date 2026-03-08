import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/project.dart';
import 'api_client.dart';

class ProjectApi {
  ProjectApi(this._dio);

  final Dio _dio;

  factory ProjectApi.create() => ProjectApi(ApiClient.instance.client);

  static const _projectsCacheKey = 'projects_page_1';

  Future<Paginated<Project>> listProjects({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/projects/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_projectsCacheKey, data);
      return Paginated<Project>.fromJson(
        data,
        (json) => Project.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_projectsCacheKey);
      if (cached != null) {
        return Paginated<Project>.fromJson(
          cached,
          (json) => Project.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Project> createProject(Project project) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/projects/',
      data: project.toJson(),
    );
    return Project.fromJson(response.data!);
  }

  Future<Project> updateProject(String id, Project project) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/projects/$id',
      data: project.toJson(),
    );
    return Project.fromJson(response.data!);
  }

  Future<Project> getProject(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/projects/$id',
    );
    return Project.fromJson(response.data!);
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('/api/v1/projects/$id');
  }
}

