import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/vibe_model.dart';

/// Repository for vibe (journal entry) operations with REST API and local cache
class VibeRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  VibeRepository(this._apiClient, this._database);

  /// Upload audio file to backend
  ///
  /// Returns audio_path from server on success
  Future<ApiResponse<String>> uploadAudioFile(
    File audioFile, {
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        ApiEndpoints.vibesUpload,
        audioFile.path,
        'audio_file', // Field name expected by backend
        onSendProgress: onSendProgress,
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final audioPath = data['audio_path'] as String?;

        if (audioPath != null) {
          return ApiResponse.success(audioPath);
        } else {
          return ApiResponse.error(
            'Invalid response from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to upload audio';
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
        e.message ?? 'Network error during upload',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  /// Create a new vibe entry
  ///
  /// This should be called after uploadAudioFile
  Future<ApiResponse<VibeModel>> createVibe({
    required String audioPath,
    required String fileName,
    required int durationMs,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.vibes,
        data: {
          'audio_path': audioPath,
          'file_name': fileName,
          'duration_ms': durationMs,
        },
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final vibeModel = VibeModel.fromBackendJson(data);

        // Cache vibe in local database
        await _cacheVibe(vibeModel);

        return ApiResponse.success(vibeModel);
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to create vibe';
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
      return ApiResponse.error(
        'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  /// Fetch vibes with pagination
  Future<ApiResponse<List<VibeModel>>> fetchVibes({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vibes,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final vibesList = data['vibes'] as List<dynamic>;

        final vibes = vibesList
            .map((json) => VibeModel.fromBackendJson(json as Map<String, dynamic>))
            .toList();

        // Cache vibes in local database
        for (final vibe in vibes) {
          await _cacheVibe(vibe);
        }

        return ApiResponse.success(vibes);
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to fetch vibes';

        // On error, try loading from cache
        final cachedVibes = await _loadVibesFromCache();
        if (cachedVibes.isNotEmpty) {
          return ApiResponse.success(cachedVibes);
        }

        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      // Network error - load from cache
      final cachedVibes = await _loadVibesFromCache();
      if (cachedVibes.isNotEmpty) {
        return ApiResponse.success(cachedVibes);
      }

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

  /// Delete a vibe
  Future<ApiResponse<void>> deleteVibe(String vibeId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.vibe(vibeId),
      );

      if (_apiClient.isSuccessful(response)) {
        // Remove from local cache
        await _deleteCachedVibe(vibeId);

        return ApiResponse.success(null);
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to delete vibe';
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
      return ApiResponse.error(
        'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  /// Download audio file URL (for playback)
  Future<ApiResponse<String>> getAudioUrl(String vibeId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vibeAudio(vibeId),
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final audioUrl = data['audio_url'] as String?;

        if (audioUrl != null) {
          return ApiResponse.success(audioUrl);
        } else {
          return ApiResponse.error(
            'Invalid response from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final errorMsg = _apiClient.getErrorMessage(response) ??
            'Failed to get audio URL';
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
      return ApiResponse.error(
        'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  /// Cache vibe in local Drift database
  Future<void> _cacheVibe(VibeModel vibeModel) async {
    try {
      await _database.into(_database.vibes).insertOnConflictUpdate(
        VibesCompanion(
          id: drift.Value(vibeModel.id),
          userId: drift.Value(vibeModel.userId),
          audioPath: drift.Value(vibeModel.audioPath),
          fileName: drift.Value(vibeModel.fileName),
          duration: drift.Value(vibeModel.duration),
          transcription: drift.Value(vibeModel.transcription),
          mood: drift.Value(vibeModel.mood),
          createdAt: drift.Value(vibeModel.createdAt.toDate()),
          isPendingUpload: const drift.Value(false),
          isPendingDelete: const drift.Value(false),
        ),
      );
    } catch (e) {
      // Log error but don't throw - caching failure shouldn't block user
      // ignore: avoid_print
      print('Error caching vibe: $e');
    }
  }

  /// Load vibes from local cache
  Future<List<VibeModel>> _loadVibesFromCache() async {
    try {
      final cachedVibes = await (_database.select(_database.vibes)
            ..orderBy([
              (t) => drift.OrderingTerm(
                    expression: t.createdAt,
                    mode: drift.OrderingMode.desc,
                  ),
            ]))
          .get();

      return cachedVibes.map((vibe) => VibeModel.fromDrift(vibe)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading vibes from cache: $e');
      return [];
    }
  }

  /// Delete cached vibe
  Future<void> _deleteCachedVibe(String vibeId) async {
    try {
      await (_database.delete(_database.vibes)
            ..where((t) => t.id.equals(vibeId)))
          .go();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting cached vibe: $e');
    }
  }

  /// Clear all cached vibes
  Future<void> clearCache() async {
    await _database.delete(_database.vibes).go();
  }
}
