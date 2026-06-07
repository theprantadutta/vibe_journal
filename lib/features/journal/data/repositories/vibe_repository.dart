import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
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
        'file', // Field name expected by backend
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
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to upload audio';
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
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Create a new vibe entry
  ///
  /// This should be called after uploadAudioFile
  Future<ApiResponse<VibeModel>> createVibe({
    required String id,
    required String audioPath,
    required String fileName,
    required int durationMs,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.vibes,
        data: {
          'id': id,
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
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to create vibe';
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

  /// Fetch vibes with pagination
  Future<ApiResponse<List<VibeModel>>> fetchVibes({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vibes,
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final vibesList = data['vibes'] as List<dynamic>;

        final vibes = vibesList
            .map(
              (json) => VibeModel.fromBackendJson(json as Map<String, dynamic>),
            )
            .toList();

        // Cache vibes in local database
        for (final vibe in vibes) {
          await _cacheVibe(vibe);
        }

        return ApiResponse.success(vibes);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to fetch vibes';

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
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Fetch ALL vibes from backend (for login sync)
  /// Returns total count of vibes fetched
  Future<ApiResponse<int>> fetchAllVibesMetadata() async {
    try {
      int totalFetched = 0;
      int page = 1;
      const int pageSize = 100; // Larger page size for initial sync
      bool hasMore = true;

      while (hasMore) {
        final response = await _apiClient.get(
          ApiEndpoints.vibes,
          queryParameters: {'page': page, 'page_size': pageSize},
        );

        if (!_apiClient.isSuccessful(response)) {
          if (page == 1) {
            // If first page fails, return error
            final errorMsg =
                _apiClient.getErrorMessage(response) ?? 'Failed to fetch vibes';
            return ApiResponse.error(errorMsg, statusCode: response.statusCode);
          } else {
            // If subsequent pages fail, return what we have so far
            break;
          }
        }

        final data = response.data as Map<String, dynamic>;
        final vibesList = data['vibes'] as List<dynamic>;
        final total = data['total'] as int;
        hasMore = data['has_more'] as bool? ?? false;

        // Cache each vibe (metadata only, audio downloaded lazily on play)
        for (final vibeJson in vibesList) {
          final vibe = VibeModel.fromBackendJson(vibeJson as Map<String, dynamic>);
          await _cacheVibe(vibe);
          totalFetched++;
        }

        if (kDebugMode) {
          print('🔄 LOGIN SYNC: Fetched page $page ($totalFetched/$total vibes)');
        }

        page++;
      }

      if (kDebugMode) {
        print('✅ LOGIN SYNC: Downloaded $totalFetched vibe metadata entries');
      }

      return ApiResponse.success(totalFetched);
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

  /// Delete a vibe
  Future<ApiResponse<void>> deleteVibe(String vibeId) async {
    try {
      // Get vibe from local database to find audio file path
      final localVibe = await (_database.select(_database.vibes)
            ..where((t) => t.id.equals(vibeId)))
          .getSingleOrNull();

      // Delete from backend
      final response = await _apiClient.delete(ApiEndpoints.vibe(vibeId));

      // Handle 404 as success (already deleted)
      if (_apiClient.isSuccessful(response) || response.statusCode == 404) {
        // Delete local audio file if it exists
        if (localVibe?.localAudioPath != null) {
          try {
            final audioFile = File(localVibe!.localAudioPath!);
            if (await audioFile.exists()) {
              await audioFile.delete();
              debugPrint('🗑️ Deleted local audio file: ${localVibe.localAudioPath}');
            }
          } catch (e) {
            debugPrint('⚠️ Failed to delete local audio file: $e');
            // Continue with deletion even if file delete fails
          }
        }

        // Remove from local cache
        await _deleteCachedVibe(vibeId);

        return ApiResponse.success(null);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to delete vibe';
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

  /// Download audio file URL (for playback)
  /// Get single vibe by ID from API
  Future<ApiResponse<VibeModel>> getVibe(String vibeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vibe(vibeId));

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final vibe = VibeModel.fromBackendJson(data);

        // Cache the updated vibe to local database
        await _cacheVibe(vibe);

        return ApiResponse.success(vibe);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to get vibe';
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

  Future<ApiResponse<String>> getAudioUrl(String vibeId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vibeAudio(vibeId));

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
        final errorMsg =
            _apiClient.getErrorMessage(response) ?? 'Failed to get audio URL';
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

  /// Retry transcription by uploading the audio file
  ///
  /// This is useful for free users whose audio files are not stored on the backend.
  /// They can upload the file again to retry transcription.
  Future<ApiResponse<VibeModel>> retryTranscription({
    required String vibeId,
    required File audioFile,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        '/vibes/$vibeId/retry-transcription',
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;
        final vibe = VibeModel.fromBackendJson(data);

        // Update cache
        await _cacheVibe(vibe);

        return ApiResponse.success(vibe);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ??
            'Failed to retry transcription';
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

  /// Cache vibe in local Drift database
  Future<void> _cacheVibe(VibeModel vibeModel) async {
    try {
      // Check if vibe already exists in cache
      final existing = await (_database.select(_database.vibes)
            ..where((t) => t.id.equals(vibeModel.id)))
          .getSingleOrNull();

      // If exists with local file, preserve the local path
      String audioPathToUse = vibeModel.audioPath;
      String? localAudioPathToUse = vibeModel.localAudioPath;
      bool isDownloaded = vibeModel.isAudioDownloaded;

      if (existing != null && existing.localAudioPath != null && existing.localAudioPath!.isNotEmpty) {
        // Preserve existing local file path
        audioPathToUse = existing.localAudioPath!;
        localAudioPathToUse = existing.localAudioPath;
        isDownloaded = true;
      }

      await _database
          .into(_database.vibes)
          .insertOnConflictUpdate(
            VibesCompanion(
              id: drift.Value(vibeModel.id),
              userId: drift.Value(vibeModel.userId),
              audioPath: drift.Value(audioPathToUse), // Preserve local path if exists
              fileName: drift.Value(vibeModel.fileName),
              duration: drift.Value(vibeModel.duration),
              transcription: drift.Value(vibeModel.transcription),
              mood: drift.Value(vibeModel.mood),
              sentimentScore: drift.Value(vibeModel.sentimentScore),
              sentimentMagnitude: drift.Value(vibeModel.sentimentMagnitude),
              processingStatus: drift.Value(vibeModel.processingStatus ?? 'completed'),
              processedAt: drift.Value(vibeModel.processedAt),
              createdAt: drift.Value(vibeModel.createdAt.toDate()),
              isPendingDelete: const drift.Value(false),
              localAudioPath: drift.Value(localAudioPathToUse), // Preserve local path
              isAudioDownloaded: drift.Value(isDownloaded),
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
      final cachedVibes =
          await (_database.select(_database.vibes)
                ..where((t) => t.isPendingDelete.equals(false)) // Exclude deleted vibes
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
      await (_database.delete(
        _database.vibes,
      )..where((t) => t.id.equals(vibeId))).go();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting cached vibe: $e');
    }
  }

  /// Save vibe locally only (for free users)
  /// Returns the local vibe model
  Future<ApiResponse<VibeModel>> saveVibeLocally({
    required File audioFile,
    required String fileName,
    required int durationMs,
    required String userId,
  }) async {
    try {
      // Generate a UUID for the vibe (unique across local and remote)
      const uuid = Uuid();
      final vibeId = uuid.v4();
      final localAudioPath = audioFile.path;

      // Create vibe model
      final vibe = VibeModel(
        id: vibeId,
        userId: userId,
        audioPath: localAudioPath,
        fileName: fileName,
        duration: durationMs,
        transcription: '',
        mood: 'unknown',
        sentimentScore: null,
        sentimentMagnitude: null,
        processingStatus: 'local',
        createdAt: Timestamp.now(),
        processedAt: null,
        audioUrl: localAudioPath,
        localAudioPath: localAudioPath, // Store absolute local path
        isAudioDownloaded: true, // Already downloaded (it's local)
      );

      // Save to local database with pending upload flag
      await _database
          .into(_database.vibes)
          .insert(
            VibesCompanion(
              id: drift.Value(vibe.id),
              userId: drift.Value(vibe.userId),
              audioPath: drift.Value(vibe.audioPath),
              fileName: drift.Value(vibe.fileName),
              duration: drift.Value(vibe.duration),
              transcription: drift.Value(vibe.transcription),
              mood: drift.Value(vibe.mood),
              sentimentScore: drift.Value(vibe.sentimentScore),
              sentimentMagnitude: drift.Value(vibe.sentimentMagnitude),
              processingStatus: drift.Value(vibe.processingStatus ?? 'local'),
              createdAt: drift.Value(vibe.createdAt.toDate()),
              processedAt: drift.Value(vibe.processedAt),
              isPendingDelete: const drift.Value(false),
              localAudioPath: drift.Value(vibe.localAudioPath), // Absolute local path
              isAudioDownloaded: drift.Value(vibe.isAudioDownloaded),
            ),
          );

      return ApiResponse.success(vibe);
    } catch (e) {
      return ApiResponse.error(
        'Failed to save vibe locally: $e',
        statusCode: 500,
      );
    }
  }

  /// Get all local vibes (including cloud-synced ones)
  Future<ApiResponse<List<VibeModel>>> getLocalVibes() async {
    try {
      final vibes = await _loadVibesFromCache();
      return ApiResponse.success(vibes);
    } catch (e) {
      return ApiResponse.error(
        'Failed to load local vibes: $e',
        statusCode: 500,
      );
    }
  }

  /// Delete vibe locally
  Future<ApiResponse<void>> deleteVibeLocally(String vibeId) async {
    try {
      await _deleteCachedVibe(vibeId);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(
        'Failed to delete vibe locally: $e',
        statusCode: 500,
      );
    }
  }

  /// Mark vibe for deletion (for offline delete that will sync later)
  ///
  /// This marks the vibe as pending deletion and deletes the local audio file.
  /// The vibe entry remains in the database for sync tracking.
  /// When the device goes online, the sync service will delete it from the backend.
  Future<ApiResponse<void>> markVibeForDeletion(String vibeId) async {
    try {
      // Get vibe from local database
      final localVibe = await (_database.select(_database.vibes)
            ..where((t) => t.id.equals(vibeId)))
          .getSingleOrNull();

      if (localVibe == null) {
        return ApiResponse.error('Vibe not found', statusCode: 404);
      }

      // Delete local audio file if it exists
      if (localVibe.localAudioPath != null) {
        try {
          final audioFile = File(localVibe.localAudioPath!);
          if (await audioFile.exists()) {
            await audioFile.delete();
            debugPrint('🗑️ Deleted local audio file: ${localVibe.localAudioPath}');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to delete local audio file: $e');
          // Continue even if file delete fails
        }
      }

      // Mark as pending deletion in database
      await (_database.update(_database.vibes)
            ..where((t) => t.id.equals(vibeId)))
          .write(
        const VibesCompanion(
          isPendingDelete: drift.Value(true),
        ),
      );

      debugPrint('🗑️ Marked vibe for deletion: $vibeId (will sync when online)');

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(
        'Failed to mark vibe for deletion: $e',
        statusCode: 500,
      );
    }
  }

  /// Download audio file and cache locally
  /// Returns local path if successful, null otherwise
  Future<String?> _downloadAndCacheAudio(String vibeId, String audioUrl) async {
    try {
      if (kDebugMode) {
        print('⬇️ LAZY DOWNLOAD: Downloading audio for vibe $vibeId...');
      }

      // Get app directory for caching audio
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      // Download audio file
      final localPath = '${audioDir.path}/$vibeId.m4a';
      final response = await _apiClient.dio.download(
        audioUrl,
        localPath,
      );

      if (response.statusCode == 200) {
        // Update database with local path
        await (_database.update(_database.vibes)
          ..where((t) => t.id.equals(vibeId))).write(
          VibesCompanion(
            localAudioPath: drift.Value(localPath),
            isAudioDownloaded: const drift.Value(true),
          ),
        );

        if (kDebugMode) {
          print('✅ LAZY DOWNLOAD: Audio cached at $localPath');
        }

        return localPath;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LAZY DOWNLOAD: Failed to download audio: $e');
      }
      return null;
    }
  }

  /// Get audio path for playback with lazy download
  /// Downloads audio if not cached, returns local path or streaming URL
  Future<String> getAudioPath(String vibeId) async {
    final vibe = await (_database.select(
      _database.vibes,
    )..where((t) => t.id.equals(vibeId))).getSingleOrNull();

    if (vibe == null) {
      throw Exception('Vibe not found: $vibeId');
    }

    // Check if audio is already cached locally
    if (vibe.localAudioPath != null && vibe.isAudioDownloaded) {
      final localFile = File(vibe.localAudioPath!);
      if (localFile.existsSync()) {
        if (kDebugMode) {
          print('✅ Using cached audio: ${vibe.localAudioPath}');
        }
        return vibe.localAudioPath!;
      }
    }

    // Audio not cached - download it now (lazy download)
    if (kDebugMode) {
      print('📥 Audio not cached, downloading for vibe $vibeId...');
    }

    // Get streaming URL from backend
    final urlResponse = await getAudioUrl(vibeId);
    if (!urlResponse.isSuccess || urlResponse.data == null) {
      throw Exception('Failed to get audio URL: ${urlResponse.error}');
    }

    final audioUrl = urlResponse.data!;

    // Try to download and cache
    final cachedPath = await _downloadAndCacheAudio(vibeId, audioUrl);
    if (cachedPath != null) {
      return cachedPath;
    }

    // If download fails, return streaming URL as fallback
    if (kDebugMode) {
      print('⚠️ Using streaming URL as fallback');
    }
    return audioUrl;
  }

  /// Check if vibe audio is available offline
  Future<bool> isAudioAvailableOffline(String vibeId) async {
    final vibe = await (_database.select(
      _database.vibes,
    )..where((t) => t.id.equals(vibeId))).getSingleOrNull();

    if (vibe == null) return false;

    if (vibe.localAudioPath != null && vibe.isAudioDownloaded) {
      final localFile = File(vibe.localAudioPath!);
      return localFile.existsSync();
    }

    return false;
  }

  /// Clear all cached vibes
  Future<void> clearCache() async {
    await _database.delete(_database.vibes).go();
  }

  /// Clear audio cache (delete downloaded audio files)
  Future<int> clearAudioCache() async {
    int deletedCount = 0;

    final vibes = await (_database.select(
      _database.vibes,
    )..where((t) => t.isAudioDownloaded.equals(true))).get();

    for (final vibe in vibes) {
      if (vibe.localAudioPath != null) {
        try {
          final file = File(vibe.localAudioPath!);
          if (file.existsSync()) {
            await file.delete();
            deletedCount++;
          }

          // Update database to reflect deleted audio
          await (_database.update(
            _database.vibes,
          )..where((t) => t.id.equals(vibe.id))).write(
            const VibesCompanion(
              localAudioPath: drift.Value(null),
              isAudioDownloaded: drift.Value(false),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting audio file: $e');
          }
        }
      }
    }

    return deletedCount;
  }

  /// Get total size of cached audio files
  Future<int> getAudioCacheSize() async {
    int totalSize = 0;

    final vibes = await (_database.select(
      _database.vibes,
    )..where((t) => t.isAudioDownloaded.equals(true))).get();

    for (final vibe in vibes) {
      if (vibe.localAudioPath != null) {
        try {
          final file = File(vibe.localAudioPath!);
          if (file.existsSync()) {
            totalSize += file.lengthSync();
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }

    return totalSize;
  }
}
