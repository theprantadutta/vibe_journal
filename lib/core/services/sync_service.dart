import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../api/api_client.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import 'user_service.dart';
import 'service_locator.dart';

/// Service to handle background sync for premium users
class SyncService {
  final AppDatabase _database;
  final VibeRepository _vibeRepository;
  final UserService _userService;
  final ApiClient _apiClient;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService(this._database, this._vibeRepository, this._userService)
    : _apiClient = locator<ApiClient>();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Delete vibes marked for deletion from backend (Premium only)
  ///
  /// This should be called BEFORE syncing uploads to avoid uploading vibes
  /// that are marked for deletion.
  Future<SyncResult> deletePendingVibes() async {
    // Only premium users can sync deletions
    if (!_userService.isPremium) {
      return SyncResult(
        success: false,
        message: 'Sync deletions is only available for premium users',
      );
    }

    try {
      // Get all vibes marked for deletion
      final pendingDeleteVibes = await (_database.select(
        _database.vibes,
      )..where((t) => t.isPendingDelete.equals(true))).get();

      if (pendingDeleteVibes.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No vibes to delete',
          uploadedCount: 0,
        );
      }

      int successCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      for (final vibe in pendingDeleteVibes) {
        try {
          if (kDebugMode) {
            print('🗑️ Syncing deletion for vibe ${vibe.id}');
          }

          // Delete from backend
          final deleteResponse = await _vibeRepository.deleteVibe(vibe.id);

          if (deleteResponse.isSuccess) {
            // Already deleted from local database by deleteVibe method
            successCount++;
            if (kDebugMode) {
              print('✅ Vibe ${vibe.id} deleted from backend and local');
            }
          } else {
            // If 404, it's already deleted on backend - treat as success
            if (deleteResponse.statusCode == 404) {
              // Remove from local database
              await (_database.delete(
                _database.vibes,
              )..where((t) => t.id.equals(vibe.id))).go();

              successCount++;
              if (kDebugMode) {
                print('✅ Vibe ${vibe.id} was already deleted on backend');
              }
            } else {
              failedCount++;
              errors.add('Failed to delete ${vibe.fileName}: ${deleteResponse.error}');
              if (kDebugMode) {
                print('❌ Failed to delete vibe ${vibe.id}: ${deleteResponse.error}');
              }
            }
          }
        } catch (e) {
          failedCount++;
          errors.add('Error deleting ${vibe.fileName}: $e');
          if (kDebugMode) {
            print('❌ Error deleting vibe ${vibe.id}: $e');
          }
        }
      }

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Successfully deleted $successCount vibes'
            : 'Deleted $successCount vibes, $failedCount failed',
        uploadedCount: successCount,
        failedCount: failedCount,
        errors: errors,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in deletePendingVibes: $e');
      }
      return SyncResult(success: false, message: 'Failed to sync deletions: $e');
    }
  }

  /// Sync all local vibes to cloud (All users)
  Future<SyncResult> syncPendingVibes() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;

    try {
      // Sync deletions FIRST to avoid uploading vibes marked for deletion
      await deletePendingVibes();

      // Get all vibes (excluding those marked for deletion)
      // In simplified architecture, we try to sync all vibes
      final pendingVibes = await (_database.select(
        _database.vibes,
      )..where((t) => t.isPendingDelete.equals(false))).get();

      if (pendingVibes.isEmpty) {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
        return SyncResult(
          success: true,
          message: 'Nothing to sync',
          uploadedCount: 0,
        );
      }

      int successCount = 0;
      int failedCount = 0;
      int audioDownloadedCount = 0;
      List<String> errors = [];

      for (final vibeData in pendingVibes) {
        try {
          // Check if audio file exists locally
          final audioFile = File(vibeData.localAudioPath ?? vibeData.audioPath);
          if (!audioFile.existsSync()) {
            if (kDebugMode) {
              print('⚠️ Audio file not found for vibe ${vibeData.id}');
            }
            errors.add('Audio file not found for ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          // Upload audio file
          final uploadResponse = await _vibeRepository.uploadAudioFile(
            audioFile,
          );

          if (!uploadResponse.isSuccess || uploadResponse.data == null) {
            errors.add('Failed to upload ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          final cloudAudioPath = uploadResponse.data!;

          // Create vibe entry on backend with the same UUID
          final createResponse = await _vibeRepository.createVibe(
            id: vibeData.id,
            audioPath: cloudAudioPath,
            fileName: vibeData.fileName,
            durationMs: vibeData.duration,
          );

          if (!createResponse.isSuccess) {
            errors.add('Failed to create vibe ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          final cloudVibe = createResponse.data!;

          // Download audio file from cloud for offline playback
          String? localAudioPath;
          bool audioDownloaded = false;

          try {
            localAudioPath = await _downloadAudio(
              cloudVibe.id,
              cloudVibe.audioUrl ?? '',
            );
            if (localAudioPath != null) {
              audioDownloaded = true;
              audioDownloadedCount++;
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Failed to download audio for ${cloudVibe.id}: $e');
            }
            // Continue even if audio download fails
          }

          // Update local vibe with cloud data
          await (_database.update(
            _database.vibes,
          )..where((t) => t.id.equals(vibeData.id))).write(
            VibesCompanion(
              id: drift.Value(cloudVibe.id),
              userId: drift.Value(cloudVibe.userId),
              audioPath: drift.Value(cloudVibe.audioPath),
              fileName: drift.Value(cloudVibe.fileName),
              duration: drift.Value(cloudVibe.duration),
              transcription: drift.Value(cloudVibe.transcription),
              mood: drift.Value(cloudVibe.mood),
              sentimentScore: drift.Value(cloudVibe.sentimentScore),
              sentimentMagnitude: drift.Value(cloudVibe.sentimentMagnitude),
              processingStatus: drift.Value(
                cloudVibe.processingStatus ?? 'completed',
              ),
              createdAt: drift.Value(cloudVibe.createdAt.toDate()),
              processedAt: drift.Value(cloudVibe.processedAt),
              isPendingDelete: const drift.Value(false),
              localAudioPath: drift.Value(localAudioPath),
              isAudioDownloaded: drift.Value(audioDownloaded),
            ),
          );

          // Delete original local audio file after successful upload
          try {
            if (audioFile.existsSync()) {
              await audioFile.delete();
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not delete original audio file: $e');
            }
          }

          successCount++;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error syncing vibe ${vibeData.id}: $e');
          }
          errors.add('Error syncing ${vibeData.fileName}: $e');
          failedCount++;
        }
      }

      _lastSyncTime = DateTime.now();
      _isSyncing = false;

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Successfully synced $successCount vibes'
            : 'Synced $successCount vibes, $failedCount failed',
        uploadedCount: successCount,
        failedCount: failedCount,
        audioDownloadedCount: audioDownloadedCount,
        errors: errors,
      );
    } catch (e) {
      _isSyncing = false;
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }


  /// Download audio file from backend and store locally
  Future<String?> _downloadAudio(String vibeId, String audioUrl) async {
    if (audioUrl.isEmpty) return null;

    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      final localPath = '${audioDir.path}/$vibeId.m4a';

      // Download using Dio
      final response = await _apiClient.dio.download(
        audioUrl,
        localPath,
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );

      if (response.statusCode == 200) {
        return localPath;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading audio: $e');
      }
      return null;
    }
  }

  /// Get count of vibes (for UI display)
  Future<int> getVibesCount() async {
    final count =
        await (_database.selectOnly(_database.vibes)
              ..addColumns([_database.vibes.id.count()])
              ..where(_database.vibes.isPendingDelete.equals(false)))
            .getSingle();

    return count.read(_database.vibes.id.count()) ?? 0;
  }

  /// Check if there are any vibes to sync
  Future<bool> hasPendingVibes() async {
    final count = await getVibesCount();
    return count > 0;
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int failedCount;
  final int audioDownloadedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.failedCount = 0,
    this.audioDownloadedCount = 0,
    this.errors = const [],
  });
}
