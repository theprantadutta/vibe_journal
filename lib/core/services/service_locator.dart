import 'package:get_it/get_it.dart';
import '../../features/auth/domain/models/user_model.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // We will register UserModel dynamically after login/signup
  // You can register other app-wide services here if needed
}

// Helper functions to manage UserModel in GetIt
void registerUserSession(UserModel userModel) {
  if (locator.isRegistered<UserModel>()) {
    locator.unregister<UserModel>();
  }
  locator.registerSingleton<UserModel>(userModel);
  print(
    "✅ UserModel registered: ${userModel.fullName} (Plan: ${userModel.plan})",
  );
}

void clearUserSession() {
  if (locator.isRegistered<UserModel>()) {
    locator.unregister<UserModel>();
    print("🗑️ UserModel session cleared.");
  }
}
