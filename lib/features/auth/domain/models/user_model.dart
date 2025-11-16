// lib/features/auth/domain/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/database/app_database.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? fullName;
  final String plan; // e.g., 'free', 'premium'
  final int cloudVibeCount;
  final int maxCloudVibes; // Maximum vibes allowed based on plan
  final int maxRecordingDurationMinutes; // Maximum recording duration
  final Timestamp createdAt;

  // Subscription fields
  final bool isPremium;
  final String? subscriptionType; // monthly, yearly, lifetime
  final String
  subscriptionStatus; // free, active, expired, grace_period, canceled

  UserModel({
    required this.uid,
    this.email,
    this.fullName,
    required this.plan,
    required this.cloudVibeCount,
    required this.maxCloudVibes,
    required this.maxRecordingDurationMinutes,
    required this.createdAt,
    this.isPremium = false,
    this.subscriptionType,
    this.subscriptionStatus = 'free',
  });

  /// Create UserModel from Firestore document (backward compatibility)
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Calculate isPremium from subscription fields, NOT from plan field
    // This must match the backend's is_premium() logic
    final subscriptionType = data['subscriptionType'] as String?;
    final subscriptionStatus = data['subscriptionStatus'] as String? ?? 'free';

    bool isPremium = false;
    if (subscriptionType == 'lifetime' && subscriptionStatus == 'active') {
      isPremium = true;
    } else if (subscriptionStatus == 'active' || subscriptionStatus == 'grace_period') {
      isPremium = true;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      fullName: data['fullName'] as String?,
      plan: data['plan'] as String? ?? 'free',
      cloudVibeCount: data['cloudVibeCount'] as int? ?? 0,
      maxCloudVibes: data['maxCloudVibes'] as int? ?? 20,
      maxRecordingDurationMinutes:
          data['maxRecordingDurationMinutes'] as int? ?? 5,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isPremium: isPremium,
      subscriptionType: subscriptionType,
      subscriptionStatus: subscriptionStatus,
    );
  }

  /// Create UserModel from backend API JSON response
  factory UserModel.fromBackendJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String?;
    return UserModel(
      uid: json['firebase_uid'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      plan: json['plan_name'] as String? ?? 'free',
      cloudVibeCount: json['cloud_vibe_count'] as int? ?? 0,
      maxCloudVibes: json['max_cloud_vibes'] as int? ?? 20,
      maxRecordingDurationMinutes:
          json['max_recording_duration_minutes'] as int? ?? 5,
      createdAt: createdAt != null
          ? Timestamp.fromDate(DateTime.parse(createdAt))
          : Timestamp.now(),
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionType: json['subscription_type'] as String?,
      subscriptionStatus: json['subscription_status'] as String? ?? 'free',
    );
  }

  /// Create UserModel from Drift database User entity
  factory UserModel.fromDrift(User user) {
    // Determine premium status from subscription info (matching backend logic)
    // This MUST match the backend's is_premium() method logic exactly
    bool isPremium = false;

    // Lifetime subscription
    if (user.subscriptionType == 'lifetime' && user.subscriptionStatus == 'active') {
      isPremium = true;
    }
    // Active or grace_period subscription - must also check expiry
    else if (user.subscriptionStatus == 'active' || user.subscriptionStatus == 'grace_period') {
      // Backend checks expiry dates - we should do the same
      // However, Drift doesn't store expiry dates, so we trust the subscription_status
      // The backend will update the status if expired, so this should be safe
      isPremium = true;
    }

    return UserModel(
      uid: user.uid,
      email: user.email,
      fullName: user.fullName,
      plan: user.plan,
      cloudVibeCount: user.cloudVibeCount,
      maxCloudVibes: user.maxCloudVibes,
      maxRecordingDurationMinutes: user.maxRecordingDurationMinutes,
      createdAt: Timestamp.fromDate(user.createdAt),
      isPremium: isPremium,
      subscriptionType: user.subscriptionType,
      subscriptionStatus: user.subscriptionStatus,
    );
  }
}
