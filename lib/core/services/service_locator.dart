import 'package:get_it/get_it.dart';
import 'user_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Register our UserService as a singleton.
  // It will be created once and live for the entire app session.
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
