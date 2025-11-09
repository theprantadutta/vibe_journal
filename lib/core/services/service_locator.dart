import 'package:get_it/get_it.dart';
import 'user_service.dart';
import 'auth_service.dart';
import 'revenue_cat_service.dart';
import '../database/app_database.dart';
import '../api/api_client.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Register Database (should be first as other services may depend on it)
  locator.registerSingleton<AppDatabase>(AppDatabase());

  // Register API Client
  locator.registerSingleton<ApiClient>(ApiClient.instance);

  // Register RevenueCatService FIRST (UserService depends on it)
  locator.registerSingleton<RevenueCatService>(RevenueCatService());

  // Register AuthService for Google Sign In
  locator.registerSingleton<AuthService>(AuthService());

  // Register UserService (depends on RevenueCatService, so register it after)
  locator.registerSingleton<UserService>(UserService());
}

// // Helper functions to manage UserModel in GetIt
// void registerUserSession(UserModel userModel) {
//   if (locator.isRegistered<UserModel>()) {
//     locator.unregister<UserModel>();
//   }
//   locator.registerSingleton<UserModel>(userModel);
//   print(
//     "✅ UserModel registered: ${userModel.fullName} (Plan: ${userModel.plan})",
//   );
// }

// void clearUserSession() {
//   if (locator.isRegistered<UserModel>()) {
//     locator.unregister<UserModel>();
//     print("🗑️ UserModel session cleared.");
//   }
// }
