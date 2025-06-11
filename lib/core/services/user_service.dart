import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/premium/domain/models/plan_details_model.dart';
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

    // After getting the user, fetch their plan details
    await _fetchPlanDetails(user.plan);

    // Register the user model itself in the locator for direct access if needed
    if (locator.isRegistered<UserModel>()) locator.unregister<UserModel>();
    locator.registerSingleton<UserModel>(user);

    print(
      "✅ UserService updated for: ${user.fullName} with ${user.plan} plan.",
    );
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
      print("Error fetching plan details: $e");
      // Could use a default fallback plan here if fetching fails
    }
  }

  void clearUser() {
    _currentUser = null;
    _currentPlanDetails = null;
    if (locator.isRegistered<UserModel>()) {
      locator.unregister<UserModel>();
    }
    print("🗑️ UserService data cleared.");
  }
}
