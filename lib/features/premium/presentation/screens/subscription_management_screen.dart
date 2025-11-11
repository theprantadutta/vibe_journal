import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/api/subscription_api_client.dart';
import 'package:vibe_journal/core/models/subscription_status.dart';
import 'package:vibe_journal/core/utils/snackbar_utils.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final _subscriptionApi = locator<SubscriptionApiClient>();

  bool _isLoading = true;
  SubscriptionStatus? _status;
  List<PurchaseHistoryItem> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await _subscriptionApi.getSubscriptionStatus();
      final history = await _subscriptionApi.getPurchaseHistory();

      setState(() {
        _status = status;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'You will retain premium access until the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _subscriptionApi.cancelSubscription();
      if (mounted) {
        SnackBarUtils.success(
          context,
          'Subscription canceled. Access until ${DateFormat.yMMMd().format(_status!.subscriptionExpiresAt!)}',
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.error(context, 'Failed to cancel subscription: $e');
      }
    }
  }

  Future<void> _manageOnGooglePlay() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        SnackBarUtils.error(context, 'Could not open Google Play');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildActionsSection(),
          const SizedBox(height: 24),
          _buildPurchaseHistory(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _status!.isPremium
              ? [primaryColor, primaryColor.withOpacity(0.7)]
              : [Colors.grey.shade800, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _status!.isPremium ? Icons.star : Icons.star_border,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _status!.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_status!.isInTrial)
            _buildInfoRow(
              Icons.access_time,
              'Free Trial',
              'Until ${DateFormat.yMMMd().format(_status!.trialEndDate!)}',
            ),
          if (_status!.subscriptionExpiresAt != null && !_status!.isInTrial)
            _buildInfoRow(
              Icons.calendar_today,
              _status!.subscriptionStatus == 'canceled' ? 'Access Until' : 'Renews',
              DateFormat.yMMMd().format(_status!.subscriptionExpiresAt!),
            ),
          if (_status!.daysRemaining != null)
            _buildInfoRow(
              Icons.timer,
              'Days Remaining',
              '${_status!.daysRemaining} days',
            ),
          if (_status!.isInGracePeriod)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment issue - update payment method to continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status!.isPremium && _status!.subscriptionType != 'lifetime')
          OutlinedButton.icon(
            onPressed: _manageOnGooglePlay,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Manage on Google Play'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: primaryColor),
              foregroundColor: primaryColor,
            ),
          ),
        if (_status!.isPremium &&
            _status!.subscriptionStatus == 'active' &&
            _status!.subscriptionType != 'lifetime')
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: OutlinedButton.icon(
              onPressed: _cancelSubscription,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPurchaseHistory() {
    if (_history.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Purchase History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_history.map((item) => _buildHistoryItem(item)).toList()),
      ],
    );
  }

  Widget _buildHistoryItem(PurchaseHistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurface(isDark);
    final textSecondaryColor = AppColors.getTextSecondary(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getProductName(item.productId),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.price != null && item.currency != null)
                Text(
                  '${item.currency} ${item.price}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Purchased: ${DateFormat.yMMMd().format(item.purchaseTime)}',
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          if (item.expiresAt != null)
            Text(
              'Expires: ${DateFormat.yMMMd().format(item.expiresAt!)}',
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
        ],
      ),
    );
  }

  String _getProductName(String productId) {
    switch (productId) {
      case 'vibe_journal_monthly':
        return 'Monthly Premium';
      case 'vibe_journal_yearly':
        return 'Yearly Premium';
      case 'vibe_journal_lifetime':
        return 'Lifetime Premium';
      default:
        return productId;
    }
  }
}
