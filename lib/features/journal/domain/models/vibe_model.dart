// lib/features/journal/domain/models/vibe_model.dart
import '../../../../core/database/app_database.dart';

class VibeModel {
  final String id;
  final String userId;
  final String audioPath;
  final String fileName;
  final int duration; // in milliseconds
  final DateTime createdAt;
  final String transcription;
  final String mood; // 'positive', 'negative', 'neutral', 'unknown'
  final double? sentimentScore;
  final double? sentimentMagnitude;
  final String?
  processingStatus; // 'pending', 'processing', 'completed', 'failed'
  final DateTime? processedAt;
  final String? audioUrl; // Pre-signed URL for playback

  // Local audio cache fields
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
    this.localAudioPath,
    this.isAudioDownloaded = false,
  });

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
      createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
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
      createdAt: vibe.createdAt,
      localAudioPath: vibe.localAudioPath,
      isAudioDownloaded: vibe.isAudioDownloaded,
    );
  }
}
