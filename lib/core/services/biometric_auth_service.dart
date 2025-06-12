import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Method to check if biometrics are available on the device
  static Future<bool> canAuthenticate() async {
    final bool canCheckBiometrics = await _auth.canCheckBiometrics;
    final bool isDeviceSupported = await _auth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  // Method to trigger the authentication prompt
  static Future<bool> authenticate(String reason) async {
    try {
      if (!await canAuthenticate()) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep prompt open on app switch
          biometricOnly: true, // Only allow biometrics, no PIN/Pattern
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Biometric Error: $e");
      }
      return false;
    }
  }
}
