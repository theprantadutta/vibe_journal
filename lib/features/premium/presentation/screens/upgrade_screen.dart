import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String _selectedPlanId = 'yearly'; // Default to yearly for best value

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
      ),
      body: Stack(
        children: [
          // Background Gradient
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header
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

                  // Feature List
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
                  _buildFeatureRow(
                    icon: Icons.movie_filter_rounded,
                    text: '"Future Me" Audio Mashups',
                  ),
                  _buildFeatureRow(
                    icon: Icons.no_encryption_gmailerrorred_rounded,
                    text: '100% Ad-Free Experience',
                  ),

                  const SizedBox(height: 32),

                  // Plan Selection
                  _buildPlanSelector(
                    context: context,
                    title: "Yearly",
                    price: "\$29.99/year",
                    subtitle: "Best Value - Save 50%",
                    isSelected: _selectedPlanId == 'yearly',
                    onTap: () => setState(() => _selectedPlanId = 'yearly'),
                  ),
                  const SizedBox(height: 16),
                  _buildPlanSelector(
                    context: context,
                    title: "Monthly",
                    price: "\$4.99/month",
                    subtitle: "Flexible",
                    isSelected: _selectedPlanId == 'monthly',
                    onTap: () => setState(() => _selectedPlanId = 'monthly'),
                  ),

                  const SizedBox(height: 24),

                  // Main CTA Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Trigger Google Play purchase flow for _selectedPlanId
                      if (kDebugMode) {
                        print("Initiating purchase for: $_selectedPlanId");
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connecting to Google Play Store...'),
                        ),
                      );
                    },
                    child: Text(
                      'Upgrade and Start Thriving',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Restore Purchase",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      Text(
                        "•",
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Terms of Service",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    color: AppColors.primary.withValues(alpha: 0.3),
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
