import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';

const String _monthlySubscriptionId = 'vibejournal_premium_monthly';
const String _yearlySubscriptionId = 'vibejournal_premium_yearly';
const List<String> _kProductIds = <String>[
  _monthlySubscriptionId,
  _yearlySubscriptionId,
];

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State for which plan is selected in the UI
  ProductDetails? _selectedPlan;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        setState(() {
          _errorMessage = "Failed to connect to the store. Please try again.";
        });
      },
    );

    _initStoreInfo();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!mounted) return;

    if (!isAvailable) {
      setState(() {
        _products = [];
        _isLoading = false;
        _errorMessage = 'The store is not available on this device.';
      });
      return;
    }

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase
        .queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _errorMessage =
            "Error fetching plans: ${productDetailResponse.error!.message}";
        _products = [];
        _isLoading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _errorMessage =
            'No subscription plans could be found. This may be a temporary issue or they may not be configured in the Play Store yet.';
        _products = [];
        _isLoading = false;
      });
      return;
    }

    productDetailResponse.productDetails.sort(
      (a, b) => a.id == _yearlySubscriptionId ? -1 : 1,
    );

    if (mounted) {
      setState(() {
        _products = productDetailResponse.productDetails;
        _isLoading = false;
        if (_products.isNotEmpty) {
          _selectedPlan = _products.first;
        }
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // You can show a pending UI if needed, but the store usually handles this.
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handlePurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("An error occurred: ${error.message}"),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase successful! Verifying with server...'),
        ),
      );

      try {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
          'verifyPlayPurchase',
        );
        await callable.call<Map<String, dynamic>>({
          'purchaseToken':
              purchaseDetails.verificationData.serverVerificationData,
          'subscriptionId': purchaseDetails.productID,
        });

        // After verification, the backend updates Firestore. The app state
        // will refresh when the user model is reloaded upon returning to a screen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success! VibeJournal Premium is now active.'),
            backgroundColor: AppColors.primary,
          ),
        );

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        print("Error verifying purchase with backend: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed. Please contact support.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (purchaseDetails.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchaseDetails);
    }
  }

  void _buySubscription(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _inAppPurchase.restorePurchases();
            },
            child: const Text("Restore"),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a0e2e), AppColors.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4],
              ),
            ),
          ),

          // --- THIS IS THE CORRECTED LOGIC ---
          // It now handles the loading, error, and success states.
          _buildBody(textTheme),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If loading is done and there are no errors, show the content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.star_purple500_rounded,
              color: AppColors.primary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock Your Full Potential',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go Premium to get unlimited access to all features and gain deeper insights into your emotional well-being.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            _buildFeatureRow(
              icon: Icons.cloud_done_rounded,
              text: 'Unlimited Cloud Vibe Storage',
            ),
            _buildFeatureRow(
              icon: Icons.mic_rounded,
              text: 'Longer Recordings (up to 60 mins)',
            ),
            _buildFeatureRow(
              icon: Icons.transcribe_rounded,
              text: 'Automatic Speech-to-Text Transcription',
            ),
            _buildFeatureRow(
              icon: Icons.auto_graph_rounded,
              text: 'Advanced Mood & Trend Charts',
            ),
            _buildFeatureRow(
              icon: Icons.psychology_rounded,
              text: 'AI-Powered Journaling Assistant',
            ),

            const SizedBox(height: 32),

            ..._products.map((product) {
              final isYearly = product.id == _yearlySubscriptionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildPlanSelector(
                  context: context,
                  title: product.title,
                  price: product.price,
                  subtitle: isYearly ? "Best Value - Save 50%" : "Flexible",
                  isSelected: _selectedPlan?.id == product.id,
                  onTap: () => setState(() => _selectedPlan = product),
                ),
              );
            }),

            const SizedBox(height: 8),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedPlan == null
                  ? null
                  : () => _buySubscription(_selectedPlan!),
              child: Text(
                'Upgrade and Start Thriving',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector({
    required BuildContext context,
    required String title,
    required String price,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitle.contains("Best")
                          ? AppColors.secondary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
