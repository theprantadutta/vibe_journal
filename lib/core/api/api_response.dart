// ignore_for_file: dangling_library_doc_comments

/// API Response Wrappers
///
/// Generic wrappers for API responses with success/error handling
library;

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool success;

  ApiResponse.success(this.data, {this.statusCode = 200})
    : error = null,
      success = true;

  ApiResponse.error(this.error, {this.statusCode})
    : data = null,
      success = false;

  bool get isSuccess => success;
  bool get isError => !success;
}

/// API Error
class ApiError {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiError({required this.message, this.statusCode, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['detail'] ?? json['message'] ?? 'Unknown error',
      statusCode: json['status_code'],
      details: json['details'],
    );
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiError($statusCode): $message';
    }
    return 'ApiError: $message';
  }
}

/// Common error messages
class ApiErrorMessages {
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String timeout = 'Request timeout. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Session expired. Please login again.';
  static const String forbidden =
      'You don\'t have permission to perform this action.';
  static const String notFound = 'Resource not found.';
  static const String badRequest = 'Invalid request. Please check your input.';
  static const String unknown = 'Something went wrong. Please try again.';
  static const String planLimitExceeded =
      'Plan limit exceeded. Upgrade to premium for unlimited access.';
}
