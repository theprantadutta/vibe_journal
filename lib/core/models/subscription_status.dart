/// Model for subscription status from backend
class SubscriptionStatus {
  final bool isPremium;
  final String? subscriptionType; // monthly, yearly, lifetime
  final String subscriptionStatus; // free, active, expired, grace_period, canceled
  final DateTime? subscriptionExpiresAt;
  final DateTime? trialEndDate;
  final DateTime? gracePeriodEndDate;
  final bool? autoRenewing;
  final int? daysRemaining;
  final String? productId;

  SubscriptionStatus({
    required this.isPremium,
    this.subscriptionType,
    required this.subscriptionStatus,
    this.subscriptionExpiresAt,
    this.trialEndDate,
    this.gracePeriodEndDate,
    this.autoRenewing,
    this.daysRemaining,
    this.productId,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isPremium: json['is_premium'] ?? false,
      subscriptionType: json['subscription_type'],
      subscriptionStatus: json['subscription_status'] ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.parse(json['trial_end_date'])
          : null,
      gracePeriodEndDate: json['grace_period_end_date'] != null
          ? DateTime.parse(json['grace_period_end_date'])
          : null,
      autoRenewing: json['auto_renewing'],
      daysRemaining: json['days_remaining'],
      productId: json['product_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
      'subscription_type': subscriptionType,
      'subscription_status': subscriptionStatus,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'grace_period_end_date': gracePeriodEndDate?.toIso8601String(),
      'auto_renewing': autoRenewing,
      'days_remaining': daysRemaining,
      'product_id': productId,
    };
  }

  bool get isInTrial {
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  bool get isInGracePeriod {
    return subscriptionStatus == 'grace_period';
  }

  String get displayName {
    if (subscriptionType == null) return 'Free';
    switch (subscriptionType) {
      case 'monthly':
        return 'Monthly Premium';
      case 'yearly':
        return 'Yearly Premium';
      case 'lifetime':
        return 'Lifetime Premium';
      default:
        return 'Premium';
    }
  }
}

/// Model for purchase history item
class PurchaseHistoryItem {
  final String id;
  final String productId;
  final String? subscriptionType;
  final DateTime purchaseTime;
  final DateTime? expiresAt;
  final String purchaseState;
  final String? price;
  final String? currency;
  final bool? autoRenewing;

  PurchaseHistoryItem({
    required this.id,
    required this.productId,
    this.subscriptionType,
    required this.purchaseTime,
    this.expiresAt,
    required this.purchaseState,
    this.price,
    this.currency,
    this.autoRenewing,
  });

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> json) {
    return PurchaseHistoryItem(
      id: json['id'],
      productId: json['product_id'],
      subscriptionType: json['subscription_type'],
      purchaseTime: DateTime.parse(json['purchase_time']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      purchaseState: json['purchase_state'],
      price: json['price']?.toString(),
      currency: json['currency'],
      autoRenewing: json['auto_renewing'],
    );
  }
}
