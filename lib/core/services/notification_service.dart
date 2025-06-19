import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Top-level function to handle background messages
/// This must be outside any class and marked with @pragma
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("📳 Handling a background message: ${message.messageId}");
  }
  // Note: For background notifications to show, you'll need to implement
  // local notifications in this handler as well if needed
}

class NotificationService {
  // Firebase services instances
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track initialization status
  static bool _initialized = false;

  /// Initializes the notification service with all required setup
  /// This includes:
  /// 1. Permission handling
  /// 2. Notification channel creation (Android)
  /// 3. Foreground message handling
  /// 4. Background message handler setup
  /// 5. FCM token management
  Future<void> initNotifications() async {
    if (_initialized) {
      if (kDebugMode) print("ℹ️ Notifications already initialized");
      return;
    }

    try {
      await _setupNotificationPermissions();
      await _setupNotificationChannel();
      await _setupMessageHandlers();
      await _manageFcmToken();

      _initialized = true;
      if (kDebugMode) print("✅ Notification Service Initialized");
    } catch (e) {
      if (kDebugMode) print("❌ Failed to initialize notifications: $e");
      // Consider adding error handling or retry logic here
    }
  }

  /// Handles notification permission flow
  Future<void> _setupNotificationPermissions() async {
    // Check current permission status
    final settings = await _fcm.getNotificationSettings();
    if (kDebugMode) {
      print(
        "📩 Current Notification Settings: ${settings.authorizationStatus}",
      );
    }

    // If already denied, we can't proceed
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) print("🚫 User has denied notification permissions");
      // Prompt the user with the permission handler package
      final result = await Permission.notification.request();
      if (result.isDenied) {
        if (kDebugMode) print("🚫 User denied notification permissions again");
      } else {
        if (kDebugMode) print("✅ Notification permissions granted");
      }
      return;
    }

    // Request permission if not already granted
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      final result = await _fcm.requestPermission();

      if (kDebugMode) {
        print("📩 Notification Permission: ${result.authorizationStatus}");
      }

      if (result.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) print("🚫 User denied notification permissions");
        return;
      }
    }
  }

  /// Sets up the Android notification channel
  Future<void> _setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Must match AndroidManifest.xml
      'High Importance Notifications',
      description: 'Used for important notifications like daily reminders.',
      importance: Importance.max, // Makes notifications show as heads-up
      playSound: true, // Optional: Enable sound
    );

    // Create the channel on Android devices
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Sets up message handlers for foreground and background
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handles a foreground message by displaying a local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode, // Unique ID for the notification
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Same as channel ID
            'High Importance Notifications',
            channelDescription: 'Used for important notifications',
            icon: '@mipmap/ic_launcher', // Your app's launcher icon
            importance: Importance.max,
            priority: Priority.high,
          ),
          // Add iOS settings here if needed
        ),
      );
    }
  }

  /// Manages the FCM token lifecycle (get, save, and monitor refreshes)
  Future<void> _manageFcmToken() async {
    // Get initial token
    final String? fcmToken = await _fcm.getToken();
    if (kDebugMode) print("📱 FCM Token: $fcmToken");

    // Save token if available
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  /// Saves the FCM token to Firestore under the current user's document
  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (kDebugMode) print("⚠️ No user logged in, can't save FCM token");
      return;
    }

    final userDocRef = _firestore.collection('users').doc(userId);

    try {
      // Try to add the token to the existing array
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      if (kDebugMode) print("💾 Updated FCM token in Firestore");
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        // Document doesn't exist, create it
        await userDocRef.set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
        if (kDebugMode) print("💾 Created new user doc with FCM token");
      } else {
        // Other Firebase errors
        if (kDebugMode) print("🔥 Error saving FCM token: ${e.message}");
        rethrow; // Consider adding retry logic here
      }
    } catch (e) {
      // Non-Firebase exceptions
      if (kDebugMode) print("🔥 Unexpected error saving FCM token: $e");
      rethrow;
    }
  }
}
