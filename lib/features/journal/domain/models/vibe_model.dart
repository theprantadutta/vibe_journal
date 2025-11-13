// lib/features/journal/domain/models/vibe_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/database/app_database.dart';

class VibeModel {
  final String id;
  final String userId;
  final String audioPath;
  final String fileName;
  final int duration; // in milliseconds
  final Timestamp createdAt;
  final String transcription;
  final String mood; // 'positive', 'negative', 'neutral', 'unknown'
  final double? sentimentScore;
  final double? sentimentMagnitude;
  final String?
  processingStatus; // 'pending', 'processing', 'completed', 'failed'
  final DateTime? processedAt;
  final String? audioUrl; // Pre-signed URL for playback

  // Sync status fields (NEW)
  final bool isSynced;
  final int syncRetryCount;
  final DateTime? lastSyncAttempt;

  // Local audio cache fields (NEW)
  final String? localAudioPath;
  final bool isAudioDownloaded;

  VibeModel({
    required this.id,
    required this.userId,
    required this.audioPath,
    required this.fileName,
    required this.duration,
    required this.createdAt,
    required this.transcription,
    required this.mood,
    this.sentimentScore,
    this.sentimentMagnitude,
    this.processingStatus,
    this.processedAt,
    this.audioUrl,
    this.isSynced = false,
    this.syncRetryCount = 0,
    this.lastSyncAttempt,
    this.localAudioPath,
    this.isAudioDownloaded = false,
  });

  /// Create VibeModel from Firestore document (backward compatibility)
  factory VibeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VibeModel(
      id: doc.id,
      userId: data['userId'] as String,
      audioPath: data['audioPath'] as String,
      fileName: data['fileName'] as String,
      duration: data['duration'] as int,
      createdAt: data['createdAt'] as Timestamp,
      transcription: data['transcription'] as String? ?? '',
      mood: data['mood'] as String? ?? 'unknown',
      sentimentScore: (data['sentimentScore'] as num?)?.toDouble(),
      sentimentMagnitude: (data['sentimentMagnitude'] as num?)?.toDouble(),
      processingStatus: data['processingStatus'] as String?,
      processedAt: null,
      audioUrl:
          data['audioPath']
              as String?, // In Firestore, audioPath is the download URL
    );
  }

  /// Create VibeModel from backend API JSON response
  factory VibeModel.fromBackendJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String?;
    final processedAt = json['processed_at'] as String?;

    return VibeModel(
      id: json['id'].toString(), // UUID from backend
      userId: json['user_id'].toString(),
      audioPath: json['audio_path'] as String,
      fileName: json['file_name'] as String,
      duration: json['duration_ms'] as int,
      transcription: json['transcription'] as String? ?? '',
      mood: json['mood'] as String? ?? 'unknown',
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      sentimentMagnitude: (json['sentiment_magnitude'] as num?)?.toDouble(),
      processingStatus: json['processing_status'] as String?,
      processedAt: processedAt != null ? DateTime.parse(processedAt) : null,
      audioUrl: json['audio_url'] as String?,
      createdAt: createdAt != null
          ? Timestamp.fromDate(DateTime.parse(createdAt))
          : Timestamp.now(),
      // Cloud vibes are always synced by definition
      isSynced: true,
      syncRetryCount: 0,
      lastSyncAttempt: null,
      localAudioPath: null,
      isAudioDownloaded: false,
    );
  }

  /// Create VibeModel from Drift database Vibe entity
  factory VibeModel.fromDrift(Vibe vibe) {
    return VibeModel(
      id: vibe.id,
      userId: vibe.userId,
      audioPath: vibe.audioPath,
      fileName: vibe.fileName,
      duration: vibe.duration,
      transcription: vibe.transcription,
      mood: vibe.mood,
      sentimentScore: vibe.sentimentScore,
      sentimentMagnitude: vibe.sentimentMagnitude,
      processingStatus: vibe.processingStatus,
      processedAt: vibe.processedAt,
      audioUrl: vibe.localAudioPath ?? vibe.audioPath, // Use local if available
      createdAt: Timestamp.fromDate(vibe.createdAt),
      // Sync status from database
      isSynced: vibe.isSynced,
      syncRetryCount: vibe.syncRetryCount,
      lastSyncAttempt: vibe.lastSyncAttempt,
      localAudioPath: vibe.localAudioPath,
      isAudioDownloaded: vibe.isAudioDownloaded,
    );
  }
}
