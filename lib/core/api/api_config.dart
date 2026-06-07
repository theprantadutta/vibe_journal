import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration
///
/// Centralized API configuration for different environments
class ApiConfig {
  // Base URLs (loaded from .env)
  static String get productionBaseUrl =>
      dotenv.env['PROD_API_BASE_URL'] ?? 'https://vibejournal.pranta.dev';
  static String get developmentBaseUrl =>
      dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:8000';

  // Current environment (release builds use production, debug/profile use development)
  static const bool isProduction = kReleaseMode;

  // Get current base URL based on environment
  static String get baseUrl =>
      isProduction ? productionBaseUrl : developmentBaseUrl;

  // API version prefix
  static const String apiPrefix = '/api/v1';

  // Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache configuration
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Polling configuration
  static const Duration pollingInterval = Duration(seconds: 15);

  // Debug mode
  static const bool enableLogging = true;
}
