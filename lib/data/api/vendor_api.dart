import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/vendor.dart';
import 'api_client.dart';

class VendorApi {
  VendorApi(this._dio);

  final Dio _dio;

  factory VendorApi.create() => VendorApi(ApiClient.instance.client);

  static const _vendorsCacheKey = 'vendors_page_1';

  Future<Paginated<Vendor>> listVendors({
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
        '/api/v1/vendors/',
        queryParameters: queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_vendorsCacheKey, data);
      return Paginated<Vendor>.fromJson(
        data,
        (json) => Vendor.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_vendorsCacheKey);
      if (cached != null) {
        return Paginated<Vendor>.fromJson(
          cached,
          (json) => Vendor.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/vendors/',
      data: vendor.toJson(),
    );
    return Vendor.fromJson(response.data!);
  }

  Future<Vendor> updateVendor(String id, Vendor vendor) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/vendors/$id',
      data: vendor.toJson(),
    );
    return Vendor.fromJson(response.data!);
  }

  Future<void> deleteVendor(String id) async {
    await _dio.delete('/api/v1/vendors/$id');
  }
}
