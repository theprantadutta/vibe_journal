import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/premium/domain/models/plan_details_model.dart';
import 'service_locator.dart';
import 'revenue_cat_service.dart';

class UserService {
  UserModel? _currentUser;
  PlanDetailsModel? _currentPlanDetails; // New: To hold plan limits
  final _revenueCatService = locator<RevenueCatService>();
  late final UserRepository _userRepository;

  UserService() {
    // Get user repository from service locator
    _userRepository = locator<UserRepository>();
  }

  // Getters for user data
  UserModel get currentUser => _currentUser!;
  bool get isUserLoggedIn => _currentUser != null;

  // Getters for plan details (with safe fallbacks)
  // Check RevenueCat first, then fall back to Firestore plan
  bool get isPremium {
    // Try to get premium status from RevenueCat if available
    if (_revenueCatService.customerInfo != null) {
      return _revenueCatService.isPremium();
    }
    // Fallback to Firestore plan
    return _currentUser?.plan == 'premium';
  }

  int get maxCloudVibes => _currentPlanDetails?.maxCloudVibes ?? 75;
  int get maxRecordingDurationMinutes =>
      _currentPlanDetails?.maxRecordingDurationMinutes ?? 5;

  /// Fetch user profile from backend API (preferred) or Firestore (fallback)
  /// This is the main method to refresh user data
  Future<bool> fetchAndUpdateUser() async {
    try {
      // Try to fetch from backend API first
      final response = await _userRepository.fetchCurrentUser();

      if (response.isSuccess && response.data != null) {
        await updateUser(response.data!);
        return true;
      } else {
        if (kDebugMode) {
          print("⚠️ Failed to fetch user from backend: ${response.error}");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error fetching user: $e");
      }
      return false;
    }
  }

  /// Update user in memory and perform related operations
  /// This method now works with both Firestore and backend API data
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;

    if (locator.isRegistered<UserModel>()) locator.unregister<UserModel>();
    locator.registerSingleton<UserModel>(user);

    if (kDebugMode) {
      print(
        "✅ UserService updated & UserModel registered in GetIt: ${user.fullName}",
      );
    }

    // Log in to RevenueCat with Firebase UID
    try {
      await _revenueCatService.loginUser(user.uid);

      // Sync premium status from RevenueCat to Firestore
      await _revenueCatService.syncPremiumStatusWithFirestore(user.uid);

      if (kDebugMode) {
        print("✅ RevenueCat user logged in and synced");
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error logging in to RevenueCat: $e");
      }
      // Continue even if RevenueCat fails - we can fall back to plan from backend
    }

    // After getting the user, fetch their plan details from Firestore (backward compatibility)
    // TODO: Eventually this should come from backend API
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

  Future<void> clearUser() async {
    _currentUser = null;
    _currentPlanDetails = null;
    if (locator.isRegistered<UserModel>()) {
      locator.unregister<UserModel>();
    }

    // Clear cached user data from local database
    try {
      await _userRepository.clearCache();
      if (kDebugMode) {
        print("✅ Local user cache cleared");
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error clearing user cache: $e");
      }
    }

    // Log out from RevenueCat
    try {
      await _revenueCatService.logoutUser();
      if (kDebugMode) {
        print("✅ RevenueCat user logged out");
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error logging out from RevenueCat: $e");
      }
    }

    if (kDebugMode) {
      print("🗑️ UserService data cleared.");
    }
  }
}
