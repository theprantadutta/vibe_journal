import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/user_model.dart';

/// Repository for user operations with REST API and local cache
class UserRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  UserRepository(this._apiClient, this._database);

  /// Fetch current user profile from backend API
  Future<ApiResponse<UserModel>> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.usersMe);

      if (_apiClient.isSuccessful(response)) {
        final data = response.data as Map<String, dynamic>;

        // Convert backend response to UserModel
        final userModel = UserModel.fromBackendJson(data);

        // Cache user in local database
        await _cacheUser(userModel);

        return ApiResponse.success(userModel);
      } else {
        final errorMsg =
            _apiClient.getErrorMessage(response) ??
            'Failed to fetch user profile';
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      // If network error, try to load from cache
      if (e.error is ApiError) {
        final apiError = e.error as ApiError;

        // Try loading from cache on network error
        if (apiError.statusCode == null) {
          final cachedUser = await _loadUserFromCache();
          if (cachedUser != null) {
            return ApiResponse.success(cachedUser);
          }
        }

        return ApiResponse.error(
          apiError.message,
          statusCode: apiError.statusCode,
        );
      }

      // Try cache as fallback
      final cachedUser = await _loadUserFromCache();
      if (cachedUser != null) {
        return ApiResponse.success(cachedUser);
      }

      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e', statusCode: 500);
    }
  }

  /// Cache user profile in local Drift database
  Future<void> _cacheUser(UserModel userModel) async {
    try {
      await _database
          .into(_database.users)
          .insertOnConflictUpdate(
            UsersCompanion(
              uid: drift.Value(userModel.uid),
              email: drift.Value(userModel.email),
              fullName: drift.Value(userModel.fullName),
              plan: drift.Value(userModel.plan),
              cloudVibeCount: drift.Value(userModel.cloudVibeCount),
              maxCloudVibes: drift.Value(userModel.maxCloudVibes),
              maxRecordingDurationMinutes: drift.Value(userModel.maxRecordingDurationMinutes),
              subscriptionType: drift.Value(userModel.subscriptionType),
              subscriptionStatus: drift.Value(userModel.subscriptionStatus),
              notificationPreferences: drift.Value(
                _serializeNotificationPreferences(userModel),
              ),
              createdAt: drift.Value(userModel.createdAt.toDate()),
              lastSyncedAt: drift.Value(DateTime.now()),
            ),
          );
    } catch (e) {
      // Log error but don't throw - caching failure shouldn't block user
      // ignore: avoid_print
      print('Error caching user: $e');
    }
  }

  /// Load user from local cache
  Future<UserModel?> _loadUserFromCache() async {
    try {
      final users = await _database.select(_database.users).get();
      if (users.isEmpty) return null;

      // Get the most recently synced user
      users.sort((a, b) {
        if (a.lastSyncedAt == null) return 1;
        if (b.lastSyncedAt == null) return -1;
        return b.lastSyncedAt!.compareTo(a.lastSyncedAt!);
      });

      final cachedUser = users.first;
      return UserModel.fromDrift(cachedUser);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user from cache: $e');
      return null;
    }
  }

  /// Clear cached user data
  Future<void> clearCache() async {
    await _database.delete(_database.users).go();
  }

  /// Serialize notification preferences to JSON string
  String _serializeNotificationPreferences(UserModel userModel) {
    // For now, return empty JSON object
    // TODO: Implement proper serialization if backend returns notification prefs
    return '{}';
  }
}
