import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const String _apiKey = 'test_sDhrBBZeRIoVbgHBkNSdjnBfJGs';
  static const String _entitlementId = 'Vibe Journal Pro';

  bool _isConfigured = false;
  CustomerInfo? _customerInfo;

  // Getters
  bool get isConfigured => _isConfigured;
  CustomerInfo? get customerInfo => _customerInfo;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isConfigured) {
      if (kDebugMode) {
        print('✅ RevenueCat already configured');
      }
      return;
    }

    try {
      // Enable debug logs in development
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      // Configure the SDK
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);

      await Purchases.configure(configuration);

      _isConfigured = true;

      if (kDebugMode) {
        print('✅ RevenueCat SDK initialized successfully');
      }

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error initializing RevenueCat: ${e.message}');
      }
      rethrow;
    }
  }

  /// Log in user with their Firebase UID
  Future<void> loginUser(String userId) async {
    if (!_isConfigured) {
      if (kDebugMode) {
        print('⚠️ RevenueCat not yet configured, will retry login');
      }
      // Wait for initialization to complete
      await initialize();
    }

    try {
      final loginResult = await Purchases.logIn(userId);
      _customerInfo = loginResult.customerInfo;

      if (kDebugMode) {
        print('✅ User logged in to RevenueCat: $userId');
        print('   Premium status: ${isPremium()}');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error logging in user to RevenueCat: ${e.message}');
      }
      rethrow;
    }
  }

  /// Log out current user
  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
      _customerInfo = null;

      if (kDebugMode) {
        print('✅ User logged out from RevenueCat');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error logging out user from RevenueCat: ${e.message}');
      }
      rethrow;
    }
  }

  /// Check if user has premium entitlement
  bool isPremium() {
    if (_customerInfo == null) return false;

    final entitlements = _customerInfo!.entitlements.active;
    return entitlements.containsKey(_entitlementId);
  }

  /// Get current customer info from RevenueCat
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo!;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error fetching customer info: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get available offerings
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (kDebugMode) {
        print('✅ Fetched offerings: ${offerings.current?.identifier}');
        print(
            '   Available packages: ${offerings.current?.availablePackages.length}');
      }

      return offerings;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error fetching offerings: ${e.message}');
      }
      return null;
    }
  }

  /// Purchase a package
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
      final purchaseResult = await Purchases.purchasePackage(package);
      _customerInfo = purchaseResult.customerInfo;

      if (kDebugMode) {
        print('✅ Purchase successful: ${package.identifier}');
        print('   Premium status: ${isPremium()}');
      }

      return _customerInfo;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error purchasing package: ${e.message}');
      }

      // Handle specific error codes
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          print('ℹ️ User cancelled the purchase');
        }
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        if (kDebugMode) {
          print('🚨 User not allowed to purchase');
        }
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        if (kDebugMode) {
          print('ℹ️ Payment is pending');
        }
      }

      rethrow;
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();

      if (kDebugMode) {
        print('✅ Purchases restored successfully');
        print('   Premium status: ${isPremium()}');
      }

      return _customerInfo!;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🚨 Error restoring purchases: ${e.message}');
      }
      rethrow;
    }
  }

  /// Sync premium status with Firestore
  Future<void> syncPremiumStatusWithFirestore(String userId) async {
    try {
      await getCustomerInfo(); // Refresh customer info
      final isPremiumUser = isPremium();

      // Update Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'plan': isPremiumUser ? 'premium' : 'free',
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Synced premium status to Firestore: $isPremiumUser');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error syncing premium status to Firestore: $e');
      }
      rethrow;
    }
  }

  /// Get active subscription info
  String? getActiveSubscriptionPeriod() {
    if (_customerInfo == null || !isPremium()) return null;

    final entitlement = _customerInfo!.entitlements.active[_entitlementId];
    if (entitlement == null) return null;

    // Return the period type
    final periodType = entitlement.periodType;
    switch (periodType) {
      case PeriodType.trial:
        return 'Trial';
      case PeriodType.intro:
        return 'Intro';
      case PeriodType.normal:
        return 'Active';
      default:
        return 'Active';
    }
  }

  /// Get subscription expiration date
  DateTime? getExpirationDate() {
    if (_customerInfo == null || !isPremium()) return null;

    final entitlement = _customerInfo!.entitlements.active[_entitlementId];
    if (entitlement == null) return null;

    final expirationDate = entitlement.expirationDate;
    return expirationDate != null ? DateTime.parse(expirationDate) : null;
  }

  /// Check if subscription will renew
  bool willRenew() {
    if (_customerInfo == null || !isPremium()) return false;

    final entitlement = _customerInfo!.entitlements.active[_entitlementId];
    if (entitlement == null) return false;

    return entitlement.willRenew;
  }

  /// Get product identifier (monthly, yearly, lifetime)
  String? getActiveProductIdentifier() {
    if (_customerInfo == null || !isPremium()) return null;

    final entitlement = _customerInfo!.entitlements.active[_entitlementId];
    if (entitlement == null) return null;

    return entitlement.productIdentifier;
  }

  /// Customer info update listener
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;

    if (kDebugMode) {
      print('🔄 Customer info updated');
      print('   Premium status: ${isPremium()}');
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    _customerInfo = null;
    _isConfigured = false;

    if (kDebugMode) {
      print('🗑️ RevenueCatService disposed');
    }
  }
}
