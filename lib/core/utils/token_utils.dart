import 'package:jwt_decoder/jwt_decoder.dart';

/// Utilities for handling JWT tokens
class TokenUtils {
  /// Check if a JWT token is expired
  /// Returns true if the token is expired or invalid
  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // If we can't decode the token, consider it expired
      return true;
    }
  }

  /// Check if token will expire within the given duration
  /// Default is 5 minutes before expiration
  static bool isTokenExpiringSoon(
    String? token, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final timeUntilExpiry = expirationDate.difference(now);

      return timeUntilExpiry <= threshold;
    } catch (e) {
      // If we can't decode the token, consider it expiring
      return true;
    }
  }

  /// Get remaining time until token expires
  static Duration? getTimeUntilExpiry(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      return expirationDate.difference(now);
    } catch (e) {
      return null;
    }
  }

  /// Get the decoded token payload
  static Map<String, dynamic>? decodeToken(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }
}
