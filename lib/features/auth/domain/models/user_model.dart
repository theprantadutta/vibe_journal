// lib/features/auth/domain/models/user_model.dart

import 'dart:convert';

import '../../../../core/database/app_database.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? fullName;
  final String plan; // e.g., 'free', 'premium'
  final int cloudVibeCount;
  final int maxCloudVibes; // Maximum vibes allowed based on plan
  final int maxRecordingDurationMinutes; // Maximum recording duration
  final DateTime createdAt;
  final Map<String, dynamic> notificationPreferences;

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
    this.notificationPreferences = const {},
    this.isPremium = false,
    this.subscriptionType,
    this.subscriptionStatus = 'free',
  });

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
      createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      notificationPreferences:
          (json['notification_preferences'] as Map<String, dynamic>?) ?? {},
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

    Map<String, dynamic> notificationPreferences = {};
    try {
      final decoded = jsonDecode(user.notificationPreferences);
      if (decoded is Map<String, dynamic>) {
        notificationPreferences = decoded;
      }
    } catch (_) {
      // Corrupt/legacy cache value - fall back to defaults
    }

    return UserModel(
      uid: user.uid,
      email: user.email,
      fullName: user.fullName,
      plan: user.plan,
      cloudVibeCount: user.cloudVibeCount,
      maxCloudVibes: user.maxCloudVibes,
      maxRecordingDurationMinutes: user.maxRecordingDurationMinutes,
      createdAt: user.createdAt,
      notificationPreferences: notificationPreferences,
      isPremium: isPremium,
      subscriptionType: user.subscriptionType,
      subscriptionStatus: user.subscriptionStatus,
    );
  }
}
