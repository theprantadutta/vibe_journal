/// API Endpoints
///
/// Centralized endpoint constants for all API calls
class ApiEndpoints {
  // Base
  static const String root = '/';
  static const String health = '/health';

  // Authentication
  static const String authVerify = '/auth/verify';

  // Users
  static const String usersMe = '/users/me';
  static const String usersMeNotifications = '/users/me/notifications';
  static const String usersMeFcmTokens = '/users/me/fcm-tokens';
  static String usersMeFcmToken(String token) => '/users/me/fcm-tokens/$token';

  // Vibes (Journal Entries)
  static const String vibes = '/vibes/';
  static const String vibesUpload = '/vibes/upload';
  static String vibe(String id) => '/vibes/$id';
  static String vibeAudio(String id) => '/vibes/$id/audio';

  // AI Assistant
  static const String aiPrompt = '/ai/prompt';
  static const String aiFeedback = '/ai/feedback';
  static const String aiStatus = '/ai/status';

  // Notifications
  static const String notificationsTest = '/notifications/test';
  static const String notificationsTriggerDaily =
      '/notifications/trigger-daily-reminders';
  static const String notificationsTriggerStreak =
      '/notifications/trigger-streak-reminders';
  static const String notificationsSchedulerStatus =
      '/notifications/scheduler-status';
}
