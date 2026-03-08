import 'package:dio/dio.dart';

import '../cache/cache_service.dart';
import '../models/pagination.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class TransactionApi {
  TransactionApi(this._dio);

  final Dio _dio;

  factory TransactionApi.create() => TransactionApi(ApiClient.instance.client);

  static const _transactionsCacheKey = 'transactions_page_1';

  Future<Paginated<Transaction>> listTransactions({
    int page = 1,
    int pageSize = 20,
    String? projectId,
    String? category,
    String? paymentMethod,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_id'] = projectId;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        queryParams['payment_method'] = paymentMethod;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transactions/',
        queryParameters: queryParams,
      );
      final data = response.data ?? <String, dynamic>{};
      await CacheService.saveJson(_transactionsCacheKey, data);
      return Paginated<Transaction>.fromJson(
        data,
        (json) => Transaction.fromJson(json),
      );
    } on DioException {
      final cached = CacheService.getJson(_transactionsCacheKey);
      if (cached != null) {
        return Paginated<Transaction>.fromJson(
          cached,
          (json) => Transaction.fromJson(json),
        );
      }
      rethrow;
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/transactions/',
      data: transaction.toJson(),
    );
    return Transaction.fromJson(response.data!);
  }

  Future<Transaction> updateTransaction(String id, Transaction transaction) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/transactions/$id',
      data: transaction.toJson(),
    );
    return Transaction.fromJson(response.data!);
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/api/v1/transactions/$id');
  }
}
