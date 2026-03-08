import 'package:dio/dio.dart';

import '../models/organization.dart';
import 'api_client.dart';

class CustomerStats {
  CustomerStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.expiringSoon,
    required this.expired,
    required this.totalRevenue,
    this.allCustomers,
  });

  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;
  final List<Organization> expiringSoon;
  final List<Organization> expired;
  final double totalRevenue;
  final List<Organization>? allCustomers; // Optional: all customers list

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalCustomers: json['total_customers'] as int,
      activeCustomers: json['active_customers'] as int,
      inactiveCustomers: json['inactive_customers'] as int,
      expiringSoon: (json['expiring_soon'] as List<dynamic>?)
              ?.map((e) => Organization.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expired: (json['expired'] as List<dynamic>?)
              ?.map((e) => Organization.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      allCustomers: (json['all_customers'] as List<dynamic>?)
              ?.map((e) => Organization.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class CustomerStatsApi {
  CustomerStatsApi(this._dio);
  final Dio _dio;

  factory CustomerStatsApi.create() => CustomerStatsApi(ApiClient.instance.client);

  Future<CustomerStats> getCustomerStats({int daysAhead = 30}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/customer-stats',
        queryParameters: {'days_ahead': daysAhead},
      );
      final data = response.data ?? <String, dynamic>{};
      return CustomerStats.fromJson(data);
    } on DioException catch (e) {
      print('Customer Stats API Error: ${e.message}');
      rethrow;
    }
  }
}
