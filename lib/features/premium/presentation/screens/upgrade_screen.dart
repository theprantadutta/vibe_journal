import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/config/theme/app_animations.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/sound_service.dart';
import 'package:vibe_journal/core/widgets/animated_card.dart';
import 'package:vibe_journal/core/widgets/animated_button.dart';

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

  final _hapticService = HapticService();
  final _soundService = SoundService();

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
            'No subscription plans could be found. This may be a temporary issue, rest assured we are actively working to resolve it.';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("An error occurred: ${error.message}"),
        backgroundColor: AppColors.getError(isDark),
      ),
    );
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      _hapticService.success();
      _soundService.premiumUnlocked();
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _hapticService.premiumUnlocked();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Success! VibeJournal Premium is now active.'),
            backgroundColor: AppColors.getPrimary(isDark),
          ),
        );

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        print("Error verifying purchase with backend: $e");
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _hapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification failed. Please contact support.'),
            backgroundColor: AppColors.getError(isDark),
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
    final isDark = theme.brightness == Brightness.dark;
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a0e2e), AppColors.getBackground(isDark)],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.getPrimary(isDark)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.getTextHint(isDark)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If loading is done and there are no errors, show the content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(
              Icons.star_purple500_rounded,
              color: AppColors.getPrimary(isDark),
              size: 60,
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Unlock Your Full Potential',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Go Premium to get unlimited access to all features and gain deeper insights into your emotional well-being.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 150.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xxl),

            _buildFeatureRow(
              icon: Icons.cloud_done_rounded,
              text: 'Unlimited Cloud Vibe Storage',
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 200.ms)
                .slideX(begin: -0.2, end: 0),
            _buildFeatureRow(
              icon: Icons.mic_rounded,
              text: 'Longer Recordings (up to 60 mins)',
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 250.ms)
                .slideX(begin: -0.2, end: 0),
            _buildFeatureRow(
              icon: Icons.transcribe_rounded,
              text: 'Automatic Speech-to-Text Transcription',
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 300.ms)
                .slideX(begin: -0.2, end: 0),
            _buildFeatureRow(
              icon: Icons.auto_graph_rounded,
              text: 'Advanced Mood & Trend Charts',
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 350.ms)
                .slideX(begin: -0.2, end: 0),
            _buildFeatureRow(
              icon: Icons.psychology_rounded,
              text: 'AI-Powered Journaling Assistant',
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 400.ms)
                .slideX(begin: -0.2, end: 0),

            const SizedBox(height: AppSpacing.xxl),

            ..._products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final isYearly = product.id == _yearlySubscriptionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _buildPlanSelector(
                  context: context,
                  title: product.title,
                  price: product.price,
                  subtitle: isYearly ? "Best Value - Save 50%" : "Flexible",
                  isSelected: _selectedPlan?.id == product.id,
                  onTap: () {
                    _hapticService.selection();
                    setState(() => _selectedPlan = product);
                  },
                )
                    .animate()
                    .fadeIn(duration: AppAnimations.normal, delay: (450 + (index * 50)).ms)
                    .slideY(begin: 0.2, end: 0),
              );
            }),

            const SizedBox(height: AppSpacing.sm),

            AnimatedButton(
              onPressed: _selectedPlan == null
                  ? null
                  : () {
                      _hapticService.medium();
                      _buySubscription(_selectedPlan!);
                    },
              backgroundColor: AppColors.getSecondary(isDark),
              child: Text(
                'Upgrade and Start Thriving',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getOnSecondary(isDark),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 550.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.getPrimary(isDark), size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.lg),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedCard(
      onTap: onTap,
      color: AppColors.getSurface(isDark),
      border: Border.all(
        color: isSelected ? AppColors.getPrimary(isDark) : AppColors.getSurface(isDark),
        width: 2.5,
      ),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? AppColors.getPrimary(isDark) : AppColors.getTextHint(isDark),
            size: 28,
          )
              .animate(target: isSelected ? 1 : 0)
              .scale(duration: AppAnimations.fast),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subtitle.contains("Best")
                        ? AppColors.getSecondary(isDark)
                        : AppColors.getTextHint(isDark),
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
    );
  }
}
