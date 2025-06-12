import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// This function must be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you want to do any background processing, this is the place.
  print("📳 Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NEW: Add the local notifications plugin ---
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;

    // 1. Request permission from the user
    await _fcm.requestPermission();

    // 2. --- NEW: Create the Android Notification Channel ---
    // This channel ID MUST match the one in your AndroidManifest.xml
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications like daily reminders.', // description
      importance: Importance.max, // This is key for making notifications pop up
    );

    // Create the channel on the device
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Handle messages that arrive while the app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        // Display the notification using flutter_local_notifications
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher', // Use your app's launcher icon
            ),
          ),
        );
      }
    });

    // 4. Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Get and save the FCM token
    final String? fcmToken = await _fcm.getToken();
    if (kDebugMode) print("📱 FCM Token: $fcmToken");
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    _initialized = true;
    print("✅ Notification Service Initialized with High Importance Channel.");
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // ... this function remains exactly the same as before
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final userDocRef = _firestore.collection('users').doc(userId);
    try {
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        await userDocRef.set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
      } else {
        print("Error saving FCM token: $e");
      }
    }
  }
}
