import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import '../../features/premium/domain/models/plan_details_model.dart';
import 'service_locator.dart';

class UserService {
  UserModel? _currentUser;
  PlanDetailsModel? _currentPlanDetails;
  late final UserRepository _userRepository;
  late final VibeRepository _vibeRepository;

  UserService() {
    _userRepository = locator<UserRepository>();
    _vibeRepository = locator<VibeRepository>();
  }

  // Getters for user data
  UserModel get currentUser => _currentUser!;
  bool get isUserLoggedIn => _currentUser != null;

  // Premium status is now determined by backend API response
  bool get isPremium {
    return _currentUser?.isPremium ?? false;
  }

  // Default to the FREE plan limit when plan details are unavailable
  int get maxCloudVibes => _currentPlanDetails?.maxCloudVibes ?? 20;
  int get maxRecordingDurationMinutes =>
      _currentPlanDetails?.maxRecordingDurationMinutes ?? 5;

  /// Fetch user profile from backend API
  /// This is the main method to refresh user data
  Future<bool> fetchAndUpdateUser() async {
    try {
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

  /// Convenience method to refresh user data
  Future<void> refreshUser() async {
    await fetchAndUpdateUser();
  }

  /// Update user in memory and perform related operations
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;

    if (locator.isRegistered<UserModel>()) locator.unregister<UserModel>();
    locator.registerSingleton<UserModel>(user);

    if (kDebugMode) {
      print(
        "✅ UserService updated & UserModel registered in GetIt: ${user.fullName}",
      );
    }

    // Update plan details from user data
    _updatePlanDetailsFromUser(user);
  }

  void _updatePlanDetailsFromUser(UserModel user) {
    // Create plan details from user data
    _currentPlanDetails = PlanDetailsModel(
      planName: user.plan,
      maxCloudVibes: user.maxCloudVibes,
      maxRecordingDurationMinutes: user.maxRecordingDurationMinutes,
    );

    if (kDebugMode) {
      print(
        "✅ Plan details updated: ${user.plan} (${user.maxCloudVibes} vibes max)",
      );
    }
  }

  Future<void> clearUser() async {
    _currentUser = null;
    _currentPlanDetails = null;
    if (locator.isRegistered<UserModel>()) {
      locator.unregister<UserModel>();
    }

    // Clear all cached data from local database
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

    // Clear vibe cache to prevent data leakage between user accounts
    try {
      await _vibeRepository.clearCache();
      if (kDebugMode) {
        print("✅ Local vibe cache cleared");
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error clearing vibe cache: $e");
      }
    }

    if (kDebugMode) {
      print("🗑️ UserService data cleared.");
    }
  }
}
