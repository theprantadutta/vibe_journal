import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/journal/data/repositories/vibe_repository.dart';
import 'service_locator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final AuthRepository _authRepository;
  late final VibeRepository _vibeRepository;

  AuthService() {
    // Initialize with web client ID from environment
    _googleSignIn.initialize(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );

    // Get repositories from service locator
    _authRepository = locator<AuthRepository>();
    _vibeRepository = locator<VibeRepository>();
  }

  /// Sign in with Google account
  /// Returns UserCredential if successful, null if cancelled or failed
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if platform supports authentication
      if (!_googleSignIn.supportsAuthenticate()) {
        return null;
      }

      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Create a new credential using the ID token
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      if (result.user != null) {
        // Verify Firebase token with backend and get JWT
        // (the backend auto-creates the user on first login)
        final authResponse = await _authRepository.verifyFirebaseToken(
          result.user!,
        );

        if (!authResponse.isSuccess) {
          if (kDebugMode) {
            print('⚠️ Backend auth verification failed: ${authResponse.error}');
          }
          // Continue with Firebase-only auth as fallback
          // Don't fail the entire login if backend is temporarily unavailable
        } else {
          if (kDebugMode) {
            print('✅ Backend JWT token received and stored');
          }

          // Fetch all vibe metadata from backend (audio downloaded lazily)
          if (kDebugMode) {
            print('🔄 LOGIN: Fetching vibe metadata from cloud...');
          }

          final vibesSyncResponse = await _vibeRepository.fetchAllVibesMetadata();

          if (vibesSyncResponse.isSuccess) {
            if (kDebugMode) {
              print('✅ LOGIN: Synced ${vibesSyncResponse.data} vibes from cloud');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ LOGIN: Failed to fetch vibes: ${vibesSyncResponse.error}');
            }
            // Don't fail login if vibe sync fails - user can still use the app
          }
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during Google Sign-In: $e');
      }
      // Error occurred during sign in - returning null to indicate failure
      return null;
    }
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();

    // Clear backend JWT token
    await _authRepository.logout();

    if (kDebugMode) {
      print('✅ Signed out from Firebase and backend');
    }
  }

  /// Check if user is currently signed in with Google
  bool isSignedInWithGoogle() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // Check if any of the user's providers is Google
    return currentUser.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  /// Get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Get current user's display name
  String? getCurrentUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  /// Get current user's photo URL
  String? getCurrentUserPhotoURL() {
    return _auth.currentUser?.photoURL;
  }
}
