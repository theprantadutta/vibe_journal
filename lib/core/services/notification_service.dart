import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _initialized = false;

  Future<void> initNotifications() async {
    // If we've already initialized, don't do it again.
    if (_initialized) {
      return;
    }

    if (kDebugMode) {
      print("Initializing notifications...");
    }
    // Request permission from the user
    final result = await _fcm.requestPermission(provisional: true);

    if (result.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print("✅ Notification permissions granted.");
      }
    } else {
      if (kDebugMode) {
        print("⚠️ Notification permissions not granted.");
      }
    }

    // Get the FCM token for this device
    final String? fcmToken = await _fcm.getToken();
    if (kDebugMode) {
      print("📱 FCM Token: $fcmToken");
    }

    // Save the token to the current user's Firestore document
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refresh and save it automatically
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    // Set the flag to true so this logic doesn't run again
    _initialized = true;
    if (kDebugMode) {
      print("✅ Notification Service Initialized.");
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDocRef = _firestore.collection('users').doc(userId);

    try {
      // We store tokens in an array to support multiple devices per user.
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      if (kDebugMode) {
        print("✅ FCM Token saved to Firestore.");
      }
    } catch (e) {
      // This can happen if the fcmTokens field doesn't exist yet.
      // In that case, we use set with merge: true to create it.
      if (e is FirebaseException && e.code == 'not-found') {
        await userDocRef.set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
        if (kDebugMode) {
          print("✅ FCM Token field created and token saved to Firestore.");
        }
      } else {
        if (kDebugMode) {
          print("Error saving FCM token: $e");
        }
      }
    }
  }
}
