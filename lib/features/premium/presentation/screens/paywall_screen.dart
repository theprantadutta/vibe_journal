import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/purchase_service.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/core/api/subscription_api_client.dart';
import 'package:vibe_journal/core/utils/snackbar_utils.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _purchaseService = locator<PurchaseService>();
  final _userService = locator<UserService>();
  final _subscriptionApi = locator<SubscriptionApiClient>();
  final _hapticService = HapticService();

  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
    _listenToPurchaseUpdates();
  }

  Future<void> _initializePurchases() async {
    setState(() => _isLoading = true);

    try {
      await _purchaseService.initialize();

      if (_purchaseService.products.isEmpty) {
        setState(() {
          _error = 'No subscription plans available at this time.';
          _isLoading = false;
        });
        return;
      }

      // Pre-select monthly by default
      _selectedProductId = PurchaseService.productMonthly;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
    }
  }

  void _listenToPurchaseUpdates() {
    _purchaseService.purchaseUpdates.listen((purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        setState(() => _isPurchasing = false);
        if (mounted) {
          SnackBarUtils.error(
            context,
            'Purchase failed: ${purchaseDetails.error?.message ?? 'Unknown error'}',
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        setState(() => _isPurchasing = false);
      }
    });
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final purchaseToken = _purchaseService.getPurchaseToken(purchaseDetails);
      final orderId = _purchaseService.getOrderId(purchaseDetails);

      if (purchaseToken == null) {
        throw Exception('Failed to get purchase token');
      }

      // Verify with backend
      await _subscriptionApi.verifyPurchase(
        productId: purchaseDetails.productID,
        purchaseToken: purchaseToken,
        orderId: orderId,
      );

      // Refresh user data
      await _userService.refreshUser();

      _hapticService.success();

      if (mounted) {
        SnackBarUtils.success(
          context,
          purchaseDetails.status == PurchaseStatus.purchased
              ? 'Welcome to Premium! 🎉'
              : 'Purchases restored successfully!',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.error(context, 'Failed to activate subscription: $e');
      }
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedProductId == null) return;

    setState(() => _isPurchasing = true);
    _hapticService.light();

    try {
      final success = await _purchaseService.purchaseProduct(_selectedProductId!);
      if (!success) {
        setState(() => _isPurchasing = false);
        if (mounted) {
          SnackBarUtils.error(context, 'Failed to start purchase');
        }
      }
    } catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        SnackBarUtils.error(context, 'Purchase error: $e');
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isPurchasing = true);
    _hapticService.light();

    try {
      await _purchaseService.restorePurchases();

      // Also try backend restore
      final result = await _subscriptionApi.restorePurchases();

      if (result['success'] == true) {
        await _userService.refreshUser();
        _hapticService.success();

        if (mounted) {
          SnackBarUtils.success(context, result['message'] ?? 'Purchases restored');
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          SnackBarUtils.info(context, result['message'] ?? 'No purchases to restore');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.error(context, 'Failed to restore purchases: $e');
      }
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildPaywallContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializePurchases,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start your 7-day free trial',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features
          _buildFeaturesList(),
          const SizedBox(height: 32),

          // Subscription options
          _buildSubscriptionOptions(),
          const SizedBox(height: 24),

          // Purchase button
          _buildPurchaseButton(),
          const SizedBox(height: 16),

          // Restore button
          TextButton(
            onPressed: _isPurchasing ? null : _handleRestore,
            child: const Text('Restore Purchases'),
          ),
          const SizedBox(height: 16),

          // Fine print
          Text(
            'Payment will be charged to your Google Play account. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    final features = [
      {'icon': Icons.cloud_outlined, 'title': 'Unlimited Cloud Storage', 'subtitle': 'Never lose a vibe'},
      {'icon': Icons.mic_outlined, 'title': 'Extended Recording', 'subtitle': 'Up to 60 minutes per vibe'},
      {'icon': Icons.insights_outlined, 'title': 'Advanced Insights', 'subtitle': 'Mood trends & emotional patterns'},
      {'icon': Icons.psychology_outlined, 'title': 'AI Journaling Assistant', 'subtitle': 'Personalized prompts & feedback'},
      {'icon': Icons.lock_outlined, 'title': 'Biometric Lock', 'subtitle': 'Keep your journal private'},
      {'icon': Icons.block_outlined, 'title': 'Ad-Free Experience', 'subtitle': 'Uninterrupted journaling'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      feature['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionOptions() {
    return Column(
      children: [
        _buildSubscriptionOption(
          productId: PurchaseService.productMonthly,
          title: 'Monthly',
          badge: '7-day free trial',
        ),
        const SizedBox(height: 12),
        _buildSubscriptionOption(
          productId: PurchaseService.productYearly,
          title: 'Yearly',
          badge: 'Save 17%',
          popular: true,
        ),
        const SizedBox(height: 12),
        _buildSubscriptionOption(
          productId: PurchaseService.productLifetime,
          title: 'Lifetime',
          badge: 'One-time payment',
        ),
      ],
    );
  }

  Widget _buildSubscriptionOption({
    required String productId,
    required String title,
    String? badge,
    bool popular = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);
    final surfaceColor = AppColors.getSurface(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);

    final product = _purchaseService.getProduct(productId);
    final isSelected = _selectedProductId == productId;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedProductId = productId);
        _hapticService.light();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : surfaceColor,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? primaryColor : textSecondaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: popular
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: popular ? Colors.white : primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (product != null)
                        Text(
                          product.price,
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (popular)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    return ElevatedButton(
      onPressed: _isPurchasing ? null : _handlePurchase,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: _isPurchasing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Start Free Trial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
