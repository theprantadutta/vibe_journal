import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/api/api_interceptor.dart';

/// Repository for authentication operations with REST API
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Verify Firebase ID token with backend and store it for API requests
  ///
  /// This stores the Firebase token directly (backend expects Firebase tokens,
  /// not JWT tokens like Pinpoint does)
  /// Returns the Firebase token if successful, null otherwise
  Future<ApiResponse<String>> verifyFirebaseToken(User firebaseUser) async {
    try {
      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();

      if (idToken == null) {
        return ApiResponse.error(
          'Failed to get Firebase token',
          statusCode: 500,
        );
      }

      // Store Firebase ID token directly (backend verifies Firebase tokens on each request)
      await ApiInterceptor.setToken(idToken);

      // Send to backend for verification and user sync
      final response = await _apiClient.post(
        ApiEndpoints.authVerify,
        data: {
          'firebase_token': idToken,
        },
      );

      if (_apiClient.isSuccessful(response)) {
        // Backend verified the token successfully
        // User is now synced to backend database
        return ApiResponse.success(idToken);
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to verify token';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      // Extract error from interceptor
      if (e.error is ApiError) {
        final apiError = e.error as ApiError;
        return ApiResponse.error(
          apiError.message,
          statusCode: apiError.statusCode,
        );
      }
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  /// Logout - clear JWT token from secure storage
  Future<void> logout() async {
    await ApiInterceptor.clearToken();
  }

  /// Check if user has valid JWT token
  Future<bool> hasValidToken() async {
    final token = await ApiInterceptor.getToken();
    return token != null && token.isNotEmpty;
  }
}
