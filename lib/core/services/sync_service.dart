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

  // Exponential backoff delays in seconds: 5s, 15s, 30s, 60s, 300s
  static const List<int> _retryDelays = [5, 15, 30, 60, 300];
  static const int _maxRetries = 5;

  SyncService(this._database, this._vibeRepository, this._userService)
    : _apiClient = locator<ApiClient>();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sync all pending vibes to cloud (Premium only)
  Future<SyncResult> syncPendingVibes() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    // Only premium users can sync
    if (!_userService.isPremium) {
      return SyncResult(
        success: false,
        message: 'Sync is only available for premium users',
      );
    }

    _isSyncing = true;

    try {
      // Get all vibes pending upload (including those ready for retry)
      final allPendingVibes = await (_database.select(
        _database.vibes,
      )..where((t) => t.isPendingUpload.equals(true))).get();

      // Filter vibes that can be retried (not exceeded max retries and passed retry delay)
      final pendingVibes = allPendingVibes.where((vibe) {
        // Skip if exceeded max retries
        if (vibe.syncRetryCount >= _maxRetries) {
          return false;
        }

        // Check if enough time has passed since last attempt for retry
        if (vibe.lastSyncAttempt != null && vibe.syncRetryCount > 0) {
          final delayIndex = (vibe.syncRetryCount - 1).clamp(
            0,
            _retryDelays.length - 1,
          );
          final requiredDelay = Duration(seconds: _retryDelays[delayIndex]);
          final timeSinceLastAttempt = DateTime.now().difference(
            vibe.lastSyncAttempt!,
          );

          if (timeSinceLastAttempt < requiredDelay) {
            return false; // Not ready for retry yet
          }
        }

        return true;
      }).toList();

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
          // Update last sync attempt
          await (_database.update(
            _database.vibes,
          )..where((t) => t.id.equals(vibeData.id))).write(
            VibesCompanion(lastSyncAttempt: drift.Value(DateTime.now())),
          );

          // Check if audio file exists locally
          final audioFile = File(vibeData.audioPath);
          if (!audioFile.existsSync()) {
            if (kDebugMode) {
              print('⚠️ Audio file not found for vibe ${vibeData.id}');
            }
            await _incrementRetryCount(vibeData.id, vibeData.syncRetryCount);
            errors.add('Audio file not found for ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          // Upload audio file
          final uploadResponse = await _vibeRepository.uploadAudioFile(
            audioFile,
          );

          if (!uploadResponse.isSuccess || uploadResponse.data == null) {
            await _incrementRetryCount(vibeData.id, vibeData.syncRetryCount);
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
            await _incrementRetryCount(vibeData.id, vibeData.syncRetryCount);
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
              lastSyncedAt: drift.Value(DateTime.now()),
              isPendingUpload: const drift.Value(false),
              isPendingDelete: const drift.Value(false),
              isSynced: const drift.Value(true), // Mark as synced
              syncRetryCount: const drift.Value(0), // Reset retry count
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
          await _incrementRetryCount(vibeData.id, vibeData.syncRetryCount);
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

  /// Increment retry count for a vibe
  Future<void> _incrementRetryCount(String vibeId, int currentCount) async {
    await (_database.update(_database.vibes)..where((t) => t.id.equals(vibeId)))
        .write(VibesCompanion(syncRetryCount: drift.Value(currentCount + 1)));
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

  /// Get count of pending vibes
  Future<int> getPendingVibesCount() async {
    final count =
        await (_database.selectOnly(_database.vibes)
              ..addColumns([_database.vibes.id.count()])
              ..where(_database.vibes.isPendingUpload.equals(true)))
            .getSingle();

    return count.read(_database.vibes.id.count()) ?? 0;
  }

  /// Check if there are any pending vibes to sync
  Future<bool> hasPendingVibes() async {
    final count = await getPendingVibesCount();
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
