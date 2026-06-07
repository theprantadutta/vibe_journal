import 'package:get_it/get_it.dart';
import 'user_service.dart';
import 'auth_service.dart';
import 'purchase_service.dart';
import 'sync_service.dart';
import 'restore_service.dart';
import '../database/app_database.dart';
import '../api/api_client.dart';
import '../api/subscription_api_client.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import '../../features/ai_assistant/data/repositories/ai_repository.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Register Database (should be first as other services may depend on it)
  locator.registerSingleton<AppDatabase>(AppDatabase());

  // Register API Client
  locator.registerSingleton<ApiClient>(ApiClient.instance);

  // Register Repositories (depend on ApiClient and Database)
  locator.registerSingleton<AuthRepository>(
    AuthRepository(locator<ApiClient>()),
  );
  locator.registerSingleton<UserRepository>(
    UserRepository(locator<ApiClient>(), locator<AppDatabase>()),
  );
  locator.registerSingleton<VibeRepository>(
    VibeRepository(locator<ApiClient>(), locator<AppDatabase>()),
  );
  locator.registerSingleton<AiRepository>(AiRepository(locator<ApiClient>()));

  // Register Subscription API Client
  locator.registerSingleton<SubscriptionApiClient>(
    SubscriptionApiClient(locator<ApiClient>().dio),
  );

  // Register PurchaseService (for Google Play in-app purchases)
  locator.registerSingleton<PurchaseService>(PurchaseService());

  // Register AuthService for Google Sign In (depends on AuthRepository)
  locator.registerSingleton<AuthService>(AuthService());

  // Register UserService (depends on UserRepository)
  locator.registerSingleton<UserService>(UserService());

  // Register SyncService (depends on Database, VibeRepository, and UserService)
  locator.registerSingleton<SyncService>(
    SyncService(
      locator<AppDatabase>(),
      locator<VibeRepository>(),
      locator<UserService>(),
    ),
  );

  // Register RestoreService (depends on Database, VibeRepository, and UserService)
  locator.registerSingleton<RestoreService>(
    RestoreService(
      locator<AppDatabase>(),
      locator<VibeRepository>(),
      locator<UserService>(),
    ),
  );
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
