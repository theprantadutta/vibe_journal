import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';
import 'api_response.dart';

/// API Interceptor for JWT injection and error handling
class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  ApiInterceptor(this._storage);

  // Storage keys
  static const String _jwtTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('🌐 API Request: ${options.method} ${options.path}');
    }

    // Inject JWT token in Authorization header
    final token = await _storage.read(key: _jwtTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      if (ApiConfig.enableLogging) {
        // ignore: avoid_print
        print('🔑 Token injected: Bearer ${token.substring(0, 20)}...');
      }
    } else if (ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('⚠️ No token found in storage');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('❌ API Error: ${err.response?.statusCode} ${err.requestOptions.path}');
      // ignore: avoid_print
      print('   Message: ${err.message}');
    }

    // Handle specific error codes
    if (err.response?.statusCode == 401) {
      // Unauthorized - token expired or invalid
      await _handleUnauthorized(err, handler);
      return;
    }

    // Convert DioException to a friendly error message
    final apiError = _convertToApiError(err);

    // Create a custom exception with ApiError details
    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiError,
      message: apiError.message,
    );

    return handler.next(customError);
  }

  /// Handle 401 Unauthorized error
  Future<void> _handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // TODO: Implement token refresh logic if your backend supports it
    // For now, just clear tokens and force re-login

    if (ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('🔐 Unauthorized: Logging out user');
    }

    // Clear stored tokens
    await _storage.delete(key: _jwtTokenKey);
    await _storage.delete(key: _refreshTokenKey);

    // Sign out from Firebase - this will trigger AuthGuard's authStateChanges
    // and automatically navigate to login screen
    try {
      await FirebaseAuth.instance.signOut();
      if (ApiConfig.enableLogging) {
        // ignore: avoid_print
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        // ignore: avoid_print
        print('⚠️ Error signing out: $e');
      }
    }

    // Create unauthorized error
    final apiError = ApiError(
      message: ApiErrorMessages.unauthorized,
      statusCode: 401,
    );

    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiError,
      message: apiError.message,
    );

    return handler.next(customError);
  }

  /// Convert DioException to ApiError
  ApiError _convertToApiError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          message: ApiErrorMessages.timeout,
          statusCode: null,
        );

      case DioExceptionType.connectionError:
        return ApiError(
          message: ApiErrorMessages.networkError,
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return ApiError(
          message: 'Request cancelled',
          statusCode: null,
        );

      default:
        return ApiError(
          message: ApiErrorMessages.unknown,
          statusCode: null,
          details: error.message,
        );
    }
  }

  /// Handle bad response (4xx, 5xx errors)
  ApiError _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    // Try to extract error message from response
    String message = ApiErrorMessages.unknown;

    if (data is Map<String, dynamic>) {
      message = data['detail'] ?? data['message'] ?? ApiErrorMessages.unknown;

      // Check for plan limit error
      if (message.toLowerCase().contains('limit') ||
          message.toLowerCase().contains('upgrade')) {
        message = ApiErrorMessages.planLimitExceeded;
      }
    }

    // Map status codes to user-friendly messages
    switch (statusCode) {
      case 400:
        return ApiError(
          message: message.isEmpty ? ApiErrorMessages.badRequest : message,
          statusCode: 400,
        );
      case 401:
        return ApiError(
          message: ApiErrorMessages.unauthorized,
          statusCode: 401,
        );
      case 403:
        return ApiError(
          message: message.isEmpty ? ApiErrorMessages.forbidden : message,
          statusCode: 403,
        );
      case 404:
        return ApiError(
          message: ApiErrorMessages.notFound,
          statusCode: 404,
        );
      case 413:
        return ApiError(
          message: 'File too large. Maximum size is 100MB.',
          statusCode: 413,
        );
      case 500:
      case 502:
      case 503:
        return ApiError(
          message: ApiErrorMessages.serverError,
          statusCode: statusCode,
        );
      default:
        return ApiError(
          message: message,
          statusCode: statusCode,
        );
    }
  }

  /// Store JWT token
  static Future<void> setToken(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _jwtTokenKey, value: token);
  }

  /// Get JWT token
  static Future<String?> getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _jwtTokenKey);
  }

  /// Clear JWT token
  static Future<void> clearToken() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _jwtTokenKey);
    await storage.delete(key: _refreshTokenKey);
  }
}
