import 'package:dio/dio.dart';

import '../models/organization.dart';
import '../models/pagination.dart';
import 'api_client.dart';

class OrganizationApi {
  OrganizationApi(this._dio);
  final Dio _dio;

  factory OrganizationApi.create() => OrganizationApi(ApiClient.instance.client);

  Future<Paginated<Organization>> listOrganizations({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/organizations',
        queryParameters: queryParams,
      );

      final data = response.data ?? <String, dynamic>{};
      return Paginated<Organization>.fromJson(
        data,
        (json) => Organization.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('Organization List API Error: ${e.message}');
      rethrow;
    }
  }

  Future<Organization> createOrganization(OrganizationCreate org) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/organizations',
        data: org.toJson(),
      );
      final data = response.data ?? <String, dynamic>{};
      return Organization.fromJson(data);
    } on DioException catch (e) {
      print('Organization Create API Error: ${e.message}');
      rethrow;
    }
  }

  Future<Organization> getOrganization(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/organizations/$id',
      );
      final data = response.data ?? <String, dynamic>{};
      return Organization.fromJson(data);
    } on DioException catch (e) {
      print('Organization Get API Error: ${e.message}');
      rethrow;
    }
  }

  Future<Organization> updateOrganization(String id, OrganizationUpdate org) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/organizations/$id',
        data: org.toJson(),
      );
      final data = response.data ?? <String, dynamic>{};
      return Organization.fromJson(data);
    } on DioException catch (e) {
      print('Organization Update API Error: ${e.message}');
      rethrow;
    }
  }

  Future<void> deleteOrganization(String id) async {
    try {
      await _dio.delete('/api/v1/organizations/$id');
    } on DioException catch (e) {
      print('Organization Delete API Error: ${e.message}');
      rethrow;
    }
  }
}
