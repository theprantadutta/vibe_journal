/// API Configuration
///
/// Centralized API configuration for different environments
class ApiConfig {
  // Base URLs
  static const String productionBaseUrl = 'https://pranta.vps.webdock.cloud/vibejournal';
  static const String developmentBaseUrl = 'http://localhost:8000';

  // Current environment (change this for different builds)
  static const bool isProduction = true;

  // Get current base URL based on environment
  static String get baseUrl => isProduction ? productionBaseUrl : developmentBaseUrl;

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
