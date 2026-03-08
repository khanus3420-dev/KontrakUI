import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config.dart';
import '../models/current_user.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  static const _tokenKey = 'access_token';
  static const _loginDateKey = 'login_date';
  static const _userTypeKey = 'user_type';
  final _secureStorage = const FlutterSecureStorage();

  // Dio client used only for auth calls
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  Future<void> init() async {
    // No-op for now; kept for symmetry if we add any startup logic later.
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final token = data['access_token'] as String?;
      final userType = data['user_type'] as String? ?? 'builder_admin';
      if (token == null || token.isEmpty) {
        throw Exception('No access token returned from server');
      }
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userTypeKey, value: userType);
      
      // Save login date for session persistence
      final now = DateTime.now();
      final loginDateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _secureStorage.write(key: _loginDateKey, value: loginDateStr);
    } on DioException catch (e) {
      final body = e.response?.data;
      String message = 'Login failed';
      if (body is Map && body['detail'] is String) {
        message = body['detail'] as String;
      }
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _loginDateKey);
    await _secureStorage.delete(key: _userTypeKey);
  }

  Future<String?> getStoredToken() => _secureStorage.read(key: _tokenKey);

  /// Get current user information
  Future<CurrentUser?> getCurrentUser() async {
    try {
      final token = await getStoredToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Create a Dio instance with auth header
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/auth/me',
      );

      final data = response.data ?? <String, dynamic>{};
      return CurrentUser.fromJson(data);
    } catch (e) {
      print('Failed to get current user: $e');
      return null;
    }
  }

  /// Check if current user is superadmin
  /// Superadmin is identified by user_type from login response
  Future<bool> isSuperadmin() async {
    try {
      // Check stored user_type first (faster)
      final storedUserType = await _secureStorage.read(key: _userTypeKey);
      if (storedUserType == 'super_admin') {
        return true;
      }
      
      // Fallback: check from CurrentUser
      final user = await getCurrentUser();
      return user?.isSuperAdmin ?? false;
    } catch (e) {
      print('Failed to check superadmin status: $e');
      return false;
    }
  }
  
  /// Get stored user type
  Future<String?> getUserType() async {
    return await _secureStorage.read(key: _userTypeKey);
  }

  Future<void> clearLoginDate() async {
    await _secureStorage.delete(key: _loginDateKey);
  }

  /// Check if user is logged in today (session persistence)
  /// Returns true if token exists and login date is today
  Future<bool> isLoggedInToday() async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final loginDateStr = await _secureStorage.read(key: _loginDateKey);
    if (loginDateStr == null || loginDateStr.isEmpty) {
      return false;
    }

    // Parse stored login date
    try {
      final loginDateParts = loginDateStr.split('-');
      if (loginDateParts.length != 3) {
        return false;
      }
      final loginDate = DateTime(
        int.parse(loginDateParts[0]),
        int.parse(loginDateParts[1]),
        int.parse(loginDateParts[2]),
      );

      // Get today's date (without time)
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Compare dates
      final loginDateOnly = DateTime(loginDate.year, loginDate.month, loginDate.day);
      
      return loginDateOnly.isAtSameMomentAs(todayDate);
    } catch (e) {
      // If parsing fails, return false
      return false;
    }
  }
}

