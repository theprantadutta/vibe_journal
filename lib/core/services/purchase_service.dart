import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Service to handle Google Play in-app purchases
class PurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs (must match Google Play Console and backend)
  static const String productMonthly = 'vibe_journal_monthly';
  static const String productYearly = 'vibe_journal_yearly';
  static const String productLifetime = 'vibe_journal_lifetime';

  // All product IDs
  static const Set<String> _productIds = {
    productMonthly,
    productYearly,
    productLifetime,
  };

  // Stream of purchase updates
  final _purchaseUpdatesController =
      StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseUpdates =>
      _purchaseUpdatesController.stream;

  // Available products
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PurchaseService already initialized');
      return;
    }

    try {
      // Check if billing is available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchases not available on this device');
        return;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseUpdateDone,
        onError: _onPurchaseUpdateError,
      );

      // Load products
      await _loadProducts();

      _isInitialized = true;
      debugPrint('✅ PurchaseService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize PurchaseService: $e');
    }
  }

  /// Load available products from Google Play
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        debugPrint('❌ Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('✅ Loaded ${_products.length} products');

      for (var product in _products) {
        debugPrint('  - ${product.id}: ${product.price}');
      }
    } catch (e) {
      debugPrint('❌ Failed to load products: $e');
    }
  }

  /// Get a specific product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    final product = getProduct(productId);
    if (product == null) {
      debugPrint('❌ Product not found: $productId');
      return false;
    }

    try {
      late PurchaseParam purchaseParam;

      if (Platform.isAndroid) {
        // For Android, specify if it's a subscription or one-time purchase
        final isSubscription = productId != productLifetime;

        if (isSubscription) {
          purchaseParam = GooglePlayPurchaseParam(
            productDetails: product,
            changeSubscriptionParam: null,
          );
        } else {
          purchaseParam = PurchaseParam(productDetails: product);
        }
      } else {
        purchaseParam = PurchaseParam(productDetails: product);
      }

      // Initiate purchase
      final bool success;
      if (productId == productLifetime) {
        // One-time purchase (lifetime)
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        // Subscription (monthly/yearly)
        success = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
      }

      if (!success) {
        debugPrint('❌ Failed to initiate purchase');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      debugPrint('🔄 Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('❌ Failed to restore purchases: $e');
      rethrow;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint(
        '📦 Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      // Broadcast the purchase update
      _purchaseUpdatesController.add(purchaseDetails);

      // Handle different purchase states
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase(purchaseDetails);
          break;
      }

      // Complete pending Android purchases
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('⏳ Purchase pending: ${purchaseDetails.productID}');
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('✅ Purchase successful: ${purchaseDetails.productID}');
    // The backend verification will be handled by the UI layer listening to purchaseUpdates
  }

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    debugPrint('❌ Purchase error: ${purchaseDetails.error}');
  }

  void _handleCanceledPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('🚫 Purchase canceled: ${purchaseDetails.productID}');
  }

  void _onPurchaseUpdateDone() {
    debugPrint('Purchase stream done');
  }

  void _onPurchaseUpdateError(dynamic error) {
    debugPrint('❌ Purchase stream error: $error');
  }

  /// Get purchase token from purchase details (Android only)
  String? getPurchaseToken(PurchaseDetails purchaseDetails) {
    if (Platform.isAndroid) {
      final androidDetails = purchaseDetails as GooglePlayPurchaseDetails;
      return androidDetails.billingClientPurchase.purchaseToken;
    }
    return null;
  }

  /// Get order ID from purchase details
  String? getOrderId(PurchaseDetails purchaseDetails) {
    if (Platform.isAndroid) {
      final androidDetails = purchaseDetails as GooglePlayPurchaseDetails;
      return androidDetails.billingClientPurchase.orderId;
    }
    return purchaseDetails.purchaseID;
  }

  /// Dispose resources
  void dispose() {
    _subscription.cancel();
    _purchaseUpdatesController.close();
    _isInitialized = false;
  }
}
