import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_status.dart';

/// API client for subscription endpoints
class SubscriptionApiClient {
  final Dio _dio;

  SubscriptionApiClient(this._dio);

  /// Verify a purchase with the backend
  Future<SubscriptionStatus> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
  }) async {
    try {
      final response = await _dio.post(
        '/subscriptions/verify-purchase/',
        data: {
          'product_id': productId,
          'purchase_token': purchaseToken,
          if (orderId != null) 'order_id': orderId,
        },
      );

      return SubscriptionStatus.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ Error verifying purchase: ${e.message}');
      rethrow;
    }
  }

  /// Get current subscription status
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscriptions/status/');
      return SubscriptionStatus.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ Error getting subscription status: ${e.message}');
      rethrow;
    }
  }

  /// Get purchase history
  Future<List<PurchaseHistoryItem>> getPurchaseHistory() async {
    try {
      final response = await _dio.get('/subscriptions/history/');
      final purchases = response.data['purchases'] as List;
      return purchases.map((p) => PurchaseHistoryItem.fromJson(p)).toList();
    } on DioException catch (e) {
      debugPrint('❌ Error getting purchase history: ${e.message}');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await _dio.post('/subscriptions/cancel/');
      return response.data;
    } on DioException catch (e) {
      debugPrint('❌ Error canceling subscription: ${e.message}');
      rethrow;
    }
  }

  /// Restore purchases
  Future<Map<String, dynamic>> restorePurchases() async {
    try {
      final response = await _dio.post('/subscriptions/restore/');
      return response.data;
    } on DioException catch (e) {
      debugPrint('❌ Error restoring purchases: ${e.message}');
      rethrow;
    }
  }
}
