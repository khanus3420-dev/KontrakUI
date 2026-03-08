import 'package:dio/dio.dart';

import '../models/user.dart';
import '../models/pagination.dart';
import 'api_client.dart';

class UserApi {
  UserApi(this._dio);
  final Dio _dio;

  factory UserApi.create() => UserApi(ApiClient.instance.client);

  Future<Paginated<User>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? organizationId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (organizationId != null && organizationId.isNotEmpty) {
        queryParams['organization_id'] = organizationId;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/users',
        queryParameters: queryParams,
      );

      final data = response.data ?? <String, dynamic>{};
      return Paginated<User>.fromJson(
        data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      print('User List API Error: ${e.message}');
      rethrow;
    }
  }

  Future<User> createUser(UserCreate user) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/users',
        data: user.toJson(),
      );
      final data = response.data ?? <String, dynamic>{};
      return User.fromJson(data);
    } on DioException catch (e) {
      print('User Create API Error: ${e.message}');
      rethrow;
    }
  }
}
