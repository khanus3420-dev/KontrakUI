import 'package:dio/dio.dart';

import 'api_client.dart';

class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  factory NotificationApi.create() => NotificationApi(ApiClient.instance.client);

  Future<void> registerDevice({
    required String platform,
    required String deviceToken,
  }) async {
    await _dio.post(
      '/api/v1/notifications/devices',
      data: {
        'platform': platform,
        'device_token': deviceToken,
      },
    );
  }
}

