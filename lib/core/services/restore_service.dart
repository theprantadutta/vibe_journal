import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../api/api_client.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import '../../features/journal/domain/models/vibe_model.dart';
import 'user_service.dart';
import 'service_locator.dart';

/// Service to handle full vibe restore from cloud on app reinstall
class RestoreService {
  final AppDatabase _database;
  final VibeRepository _vibeRepository;
  final UserService _userService;
  final ApiClient _apiClient;

  bool _isRestoring = false;

  RestoreService(this._database, this._vibeRepository, this._userService)
    : _apiClient = locator<ApiClient>();

  bool get isRestoring => _isRestoring;

  /// Restore all vibes from cloud (Premium only)
  /// Returns a stream of progress updates
  Stream<RestoreProgress> restoreAllVibes() async* {
    if (_isRestoring) {
      yield RestoreProgress(
        status: RestoreStatus.error,
        message: 'Restore already in progress',
      );
      return;
    }

    // Only premium users can restore
    if (!_userService.isPremium) {
      yield RestoreProgress(
        status: RestoreStatus.error,
        message: 'Restore is only available for premium users',
      );
      return;
    }

    _isRestoring = true;

    try {
      yield RestoreProgress(
        status: RestoreStatus.fetchingVibes,
        message: 'Connecting to cloud...',
        totalVibes: 0,
        vibesRestored: 0,
        audioDownloaded: 0,
      );

      // Fetch all vibes from backend (use large page size or pagination)
      final List<VibeModel> allVibes = [];
      int page = 1;
      const pageSize = 100;
      bool hasMore = true;

      while (hasMore) {
        final response = await _vibeRepository.fetchVibes(
          page: page,
          pageSize: pageSize,
        );

        if (!response.isSuccess || response.data == null) {
          yield RestoreProgress(
            status: RestoreStatus.error,
            message: 'Failed to fetch vibes: ${response.error}',
          );
          _isRestoring = false;
          return;
        }

        final vibes = response.data!;
        allVibes.addAll(vibes);

        // Check if there are more pages
        hasMore = vibes.length >= pageSize;
        page++;

        yield RestoreProgress(
          status: RestoreStatus.fetchingVibes,
          message: 'Fetching vibes... (${allVibes.length} found)',
          totalVibes: allVibes.length,
          vibesRestored: 0,
          audioDownloaded: 0,
        );
      }

      if (allVibes.isEmpty) {
        yield RestoreProgress(
          status: RestoreStatus.completed,
          message: 'No vibes to restore',
          totalVibes: 0,
          vibesRestored: 0,
          audioDownloaded: 0,
        );
        _isRestoring = false;
        return;
      }

      final totalVibes = allVibes.length;
      int vibesRestored = 0;
      int audioDownloaded = 0;

      yield RestoreProgress(
        status: RestoreStatus.restoringVibes,
        message: 'Restoring vibes...',
        totalVibes: totalVibes,
        vibesRestored: 0,
        audioDownloaded: 0,
      );

      // Process each vibe
      for (final vibe in allVibes) {
        try {
          // Check if vibe already exists locally
          final existingVibe = await (_database.select(
            _database.vibes,
          )..where((t) => t.id.equals(vibe.id))).getSingleOrNull();

          // Download audio file if needed
          String? localAudioPath;
          bool isAudioDownloaded = false;

          if (vibe.audioUrl != null && vibe.audioUrl!.isNotEmpty) {
            try {
              localAudioPath = await _downloadAudio(vibe.id, vibe.audioUrl!);
              if (localAudioPath != null) {
                isAudioDownloaded = true;
                audioDownloaded++;
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Failed to download audio for ${vibe.id}: $e');
              }
              // Continue even if audio download fails
            }
          }

          // Save or update vibe in local database
          if (existingVibe == null) {
            // Insert new vibe
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
                    processingStatus: drift.Value(
                      vibe.processingStatus ?? 'completed',
                    ),
                    createdAt: drift.Value(vibe.createdAt),
                    processedAt: drift.Value(vibe.processedAt),
                    isPendingDelete: const drift.Value(false),
                    localAudioPath: drift.Value(localAudioPath),
                    isAudioDownloaded: drift.Value(isAudioDownloaded),
                  ),
                );
          } else {
            // Update existing vibe with cloud data
            await (_database.update(
              _database.vibes,
            )..where((t) => t.id.equals(vibe.id))).write(
              VibesCompanion(
                audioPath: drift.Value(vibe.audioPath),
                fileName: drift.Value(vibe.fileName),
                duration: drift.Value(vibe.duration),
                transcription: drift.Value(vibe.transcription),
                mood: drift.Value(vibe.mood),
                sentimentScore: drift.Value(vibe.sentimentScore),
                sentimentMagnitude: drift.Value(vibe.sentimentMagnitude),
                processingStatus: drift.Value(
                  vibe.processingStatus ?? 'completed',
                ),
                processedAt: drift.Value(vibe.processedAt),
                localAudioPath: drift.Value(
                  localAudioPath ?? existingVibe.localAudioPath,
                ),
                isAudioDownloaded: drift.Value(
                  isAudioDownloaded || existingVibe.isAudioDownloaded,
                ),
              ),
            );
          }

          vibesRestored++;

          // Yield progress update
          yield RestoreProgress(
            status: RestoreStatus.restoringVibes,
            message: 'Restoring vibes...',
            totalVibes: totalVibes,
            vibesRestored: vibesRestored,
            audioDownloaded: audioDownloaded,
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error restoring vibe ${vibe.id}: $e');
          }
          // Continue with next vibe even if one fails
        }
      }

      // Completed
      yield RestoreProgress(
        status: RestoreStatus.completed,
        message: 'Restore complete!',
        totalVibes: totalVibes,
        vibesRestored: vibesRestored,
        audioDownloaded: audioDownloaded,
      );

      _isRestoring = false;
    } catch (e) {
      yield RestoreProgress(
        status: RestoreStatus.error,
        message: 'Restore failed: $e',
      );
      _isRestoring = false;
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

      // Check if file already exists
      if (File(localPath).existsSync()) {
        return localPath; // Already downloaded
      }

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
}

/// Progress update for restore operation
class RestoreProgress {
  final RestoreStatus status;
  final String message;
  final int totalVibes;
  final int vibesRestored;
  final int audioDownloaded;

  RestoreProgress({
    required this.status,
    required this.message,
    this.totalVibes = 0,
    this.vibesRestored = 0,
    this.audioDownloaded = 0,
  });

  double get progress {
    if (totalVibes == 0) return 0.0;
    return vibesRestored / totalVibes;
  }

  String get progressText => '$vibesRestored / $totalVibes vibes';
}

/// Status of restore operation
enum RestoreStatus { fetchingVibes, restoringVibes, completed, error }
