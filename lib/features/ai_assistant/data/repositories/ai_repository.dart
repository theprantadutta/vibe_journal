import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';

/// Repository for AI Assistant operations with REST API
class AiRepository {
  final ApiClient _apiClient;

  AiRepository(this._apiClient);

  /// Get AI-generated journaling prompt (Premium only)
  Future<ApiResponse<String>> getJournalingPrompt() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.aiPrompt);

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final prompt = data['prompt'] as String?;

        if (prompt != null) {
          return ApiResponse.success(prompt);
        } else {
          return ApiResponse.error(
            'Invalid response from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ??
            'Failed to get journaling prompt';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
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
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Get AI-generated reflective feedback on journal entry (Premium only)
  ///
  /// Parameters are all optional - AI will work with whatever is provided
  Future<ApiResponse<String>> getReflectiveFeedback({
    String? transcription,
    String? mood,
    int? durationSeconds,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (transcription != null) requestData['transcription'] = transcription;
      if (mood != null) requestData['mood'] = mood;
      if (durationSeconds != null) {
        requestData['duration_seconds'] = durationSeconds;
      }

      final response = await _apiClient.post(
        ApiEndpoints.aiFeedback,
        data: requestData,
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final feedback = data['feedback'] as String?;

        if (feedback != null) {
          return ApiResponse.success(feedback);
        } else {
          return ApiResponse.error(
            'Invalid response from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ??
            'Failed to get reflective feedback';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
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
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Check if AI features are available
  Future<ApiResponse<Map<String, dynamic>>> checkAiStatus() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.aiStatus);

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to check AI status';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
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
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }
}
