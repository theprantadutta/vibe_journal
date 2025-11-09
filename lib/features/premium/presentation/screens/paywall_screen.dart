import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/revenue_cat_service.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/core/utils/snackbar_utils.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _revenueCatService = locator<RevenueCatService>();
  final _userService = locator<UserService>();
  final _hapticService = HapticService();

  bool _isLoading = true;
  Offerings? _offerings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offerings = await _revenueCatService.getOfferings();

      if (offerings == null || offerings.current == null) {
        setState(() {
          _error = 'No subscription plans available at this time.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });

      // Show RevenueCat Paywall UI
      _showRevenueCatPaywall();
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showRevenueCatPaywall() async {
    if (_offerings?.current == null) return;

    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        'Vibe Journal Pro',
        displayCloseButton: true,
      );

      if (paywallResult == PaywallResult.purchased ||
          paywallResult == PaywallResult.restored) {
        _hapticService.success();

        // Sync premium status to Firestore
        if (_userService.isUserLoggedIn) {
          await _revenueCatService.syncPremiumStatusWithFirestore(
            _userService.currentUser.uid,
          );
        }

        if (mounted) {
          SnackBarUtils.success(
            context,
            paywallResult == PaywallResult.purchased
                ? 'Welcome to Premium!'
                : 'Purchases restored successfully!',
          );

          // Pop the paywall screen
          Navigator.of(context).pop(true);
        }
      } else if (paywallResult == PaywallResult.cancelled) {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      } else if (paywallResult == PaywallResult.error) {
        _hapticService.error();
        if (mounted) {
          SnackBarUtils.error(
            context,
            'An error occurred. Please try again.',
          );
        }
      }
    } on PlatformException catch (e) {
      _hapticService.error();

      if (mounted) {
        SnackBarUtils.error(
          context,
          'Failed to process purchase: ${e.message}',
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    _hapticService.light();

    try {
      await _revenueCatService.restorePurchases();

      if (_revenueCatService.isPremium()) {
        _hapticService.success();

        // Sync to Firestore
        if (_userService.isUserLoggedIn) {
          await _revenueCatService.syncPremiumStatusWithFirestore(
            _userService.currentUser.uid,
          );
        }

        if (mounted) {
          SnackBarUtils.success(
            context,
            'Purchases restored successfully!',
          );
          Navigator.of(context).pop(true);
        }
      } else {
        _hapticService.warning();
        if (mounted) {
          SnackBarUtils.info(
            context,
            'No previous purchases found.',
          );
        }
      }
    } on PlatformException catch (e) {
      _hapticService.error();
      if (mounted) {
        SnackBarUtils.error(
          context,
          'Failed to restore purchases: ${e.message}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _restorePurchases,
              child: const Text('Restore'),
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.getPrimary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading subscription plans...',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.getError(isDark),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOfferings,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // The RevenueCat paywall is shown in _showRevenueCatPaywall()
    // This fallback UI is shown if something goes wrong
    return const SizedBox.shrink();
  }
}
