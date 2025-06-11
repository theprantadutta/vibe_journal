// lib/features/auth/domain/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? fullName;
  final String plan; // e.g., 'free', 'premium'
  final int cloudVibeCount;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    this.email,
    this.fullName,
    required this.plan,
    required this.cloudVibeCount,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      fullName: data['fullName'] as String?,
      plan: data['plan'] as String? ?? 'free',
      cloudVibeCount: data['cloudVibeCount'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
