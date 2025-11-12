import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import '../../features/journal/domain/models/vibe_model.dart';
import 'user_service.dart';
import 'service_locator.dart';

/// Service to handle background sync for premium users
class SyncService {
  final AppDatabase _database;
  final VibeRepository _vibeRepository;
  final UserService _userService;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService(this._database, this._vibeRepository, this._userService);

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sync all pending vibes to cloud (Premium only)
  Future<SyncResult> syncPendingVibes() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
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
      // Get all vibes pending upload
      final pendingVibes = await (_database.select(_database.vibes)
            ..where((t) => t.isPendingUpload.equals(true)))
          .get();

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
      List<String> errors = [];

      for (final vibeData in pendingVibes) {
        try {
          // Check if audio file exists locally
          final audioFile = File(vibeData.audioPath);
          if (!audioFile.existsSync()) {
            if (kDebugMode) {
              print('⚠️ Audio file not found for vibe ${vibeData.id}');
            }
            errors.add('Audio file not found for ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          // Upload audio file
          final uploadResponse = await _vibeRepository.uploadAudioFile(audioFile);

          if (!uploadResponse.isSuccess || uploadResponse.data == null) {
            errors.add('Failed to upload ${vibeData.fileName}');
            failedCount++;
            continue;
          }

          final cloudAudioPath = uploadResponse.data!;

          // Create vibe entry on backend
          final createResponse = await _vibeRepository.createVibe(
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

          // Update local vibe with cloud data
          await _database.update(_database.vibes).replace(
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
                  processingStatus: drift.Value(cloudVibe.processingStatus),
                  createdAt: drift.Value(cloudVibe.createdAt.toDate()),
                  processedAt: drift.Value(cloudVibe.processedAt?.toDate()),
                  lastSyncedAt: drift.Value(DateTime.now()),
                  isPendingUpload: const drift.Value(false),
                  isPendingDelete: const drift.Value(false),
                ),
              );

          // Delete local audio file after successful upload
          try {
            if (audioFile.existsSync()) {
              await audioFile.delete();
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not delete local audio file: $e');
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
        errors: errors,
      );
    } catch (e) {
      _isSyncing = false;
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    }
  }

  /// Get count of pending vibes
  Future<int> getPendingVibesCount() async {
    final count = await (_database.selectOnly(_database.vibes)
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
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}
