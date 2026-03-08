import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/quotation.dart';
import 'api_client.dart';

class QuotationApi {
  QuotationApi(this._dio);

  final Dio _dio;

  factory QuotationApi.create() => QuotationApi(ApiClient.instance.client);

  static const _quotationsCacheKey = 'quotations_page_1';

  Future<Paginated<Quotation>> listQuotations({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/quotations/',
        queryParameters: queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_quotationsCacheKey, data);
      return Paginated<Quotation>.fromJson(
        data,
        (json) => Quotation.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_quotationsCacheKey);
      if (cached != null) {
        return Paginated<Quotation>.fromJson(
          cached,
          (json) => Quotation.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Paginated<Quotation>> upcomingQuotations({int daysAhead = 7}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/quotations/upcoming',
        queryParameters: {'days_ahead': daysAhead},
      );
      final data = response.data ?? <String, dynamic>{};
      return Paginated<Quotation>.fromJson(
        data,
        (json) => Quotation.fromJson(json),
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Quotation> createQuotation(Quotation quotation) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/quotations/',
      data: quotation.toJson(),
    );
    return Quotation.fromJson(response.data!);
  }

  Future<Quotation> updateQuotation(String id, Quotation quotation) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/quotations/$id',
      data: quotation.toJson(),
    );
    return Quotation.fromJson(response.data!);
  }

  Future<void> deleteQuotation(String id) async {
    await _dio.delete('/api/v1/quotations/$id');
  }
}
