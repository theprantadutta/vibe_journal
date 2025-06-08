import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? fullName;
  final String plan; // e.g., 'free', 'premium'
  final int cloudVibeCount; // Number of vibes currently stored in cloud
  final int maxCloudVibes; // Max vibes allowed in cloud for current plan
  final int
  maxRecordingDurationMinutes; // Max duration per recording for current plan
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    this.email,
    this.fullName,
    required this.plan,
    required this.cloudVibeCount,
    required this.maxCloudVibes,
    required this.maxRecordingDurationMinutes,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      fullName: data['fullName'] as String?,
      plan: data['plan'] as String? ?? 'free', // Default to 'free' if missing
      cloudVibeCount: data['cloudVibeCount'] as int? ?? 0, // Default to 0
      maxCloudVibes: data['maxCloudVibes'] as int? ?? 75, // Default free limit
      maxRecordingDurationMinutes:
          data['maxRecordingDurationMinutes'] as int? ??
          5, // Default free limit
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Method to convert UserModel to Map for Firestore (optional, if you update UserModel locally then save)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'plan': plan,
      'cloudVibeCount': cloudVibeCount,
      'maxCloudVibes': maxCloudVibes,
      'maxRecordingDurationMinutes': maxRecordingDurationMinutes,
      'createdAt': createdAt,
    };
  }
}
