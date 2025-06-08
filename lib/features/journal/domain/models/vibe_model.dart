// lib/features/journal/domain/models/vibe_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

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
    );
  }
}
