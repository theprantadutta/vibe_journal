import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/premium/domain/models/plan_details_model.dart';
import 'notification_service.dart';
import 'service_locator.dart';

class UserService {
  UserModel? _currentUser;
  PlanDetailsModel? _currentPlanDetails; // New: To hold plan limits

  // Getters for user data
  UserModel get currentUser => _currentUser!;
  bool get isUserLoggedIn => _currentUser != null;

  // Getters for plan details (with safe fallbacks)
  bool get isPremium => _currentUser?.plan == 'premium';
  int get maxCloudVibes => _currentPlanDetails?.maxCloudVibes ?? 75;
  int get maxRecordingDurationMinutes =>
      _currentPlanDetails?.maxRecordingDurationMinutes ?? 5;

  // This method now fetches plan details after updating the user
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;

    if (locator.isRegistered<UserModel>()) locator.unregister<UserModel>();
    locator.registerSingleton<UserModel>(user);

    if (kDebugMode) {
      print(
        "✅ UserService updated & UserModel registered in GetIt: ${user.fullName}",
      );
    }

    // After the user session is ready, we kick off notification setup.
    try {
      await NotificationService().initNotifications();
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error initializing notifications: $e");
      }
    }

    // After getting the user, fetch their plan details
    await _fetchPlanDetails(user.plan);
  }

  Future<void> _fetchPlanDetails(String planId) async {
    try {
      final planDoc = await FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .get();
      if (planDoc.exists) {
        _currentPlanDetails = PlanDetailsModel.fromFirestore(planDoc);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching plan details: $e");
      }
      // Could use a default fallback plan here if fetching fails
    }
  }

  void clearUser() {
    _currentUser = null;
    _currentPlanDetails = null;
    if (locator.isRegistered<UserModel>()) {
      locator.unregister<UserModel>();
    }
    if (kDebugMode) {
      print("🗑️ UserService data cleared.");
    }
  }
}
