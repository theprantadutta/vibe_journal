import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibe_journal/config/theme/app_animations.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/core/widgets/page_transitions.dart';
import 'package:vibe_journal/features/premium/presentation/screens/paywall_screen.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  final _hapticService = HapticService();
  final _userService = locator<UserService>();

  // Premium features data
  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'icon': Icons.cloud_done_rounded,
      'title': 'Unlimited Cloud Storage',
      'description': 'Save unlimited voice vibes to the cloud, never worry about running out of space',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      'icon': Icons.timer_outlined,
      'title': 'Extended Recording Time',
      'description': 'Record vibes up to 60 minutes long, perfect for deep journaling sessions',
      'gradient': [Color(0xFFf093fb), Color(0xFff5576c)],
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'AI Assistant Access',
      'description': 'Get personalized insights, journaling prompts, and feedback from your AI companion',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Advanced Trend Charts',
      'description': 'Visualize your mood patterns over time with beautiful interactive charts',
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)],
    },
    {
      'icon': Icons.playlist_play_rounded,
      'title': 'Future Me Mashup',
      'description': 'Create audio playlists of your recent vibes to reflect on your journey',
      'gradient': [Color(0xFFfa709a), Color(0xFFfee140)],
    },
    {
      'icon': Icons.lock_person_rounded,
      'title': 'Biometric Lock',
      'description': 'Protect your private thoughts with fingerprint or face recognition',
      'gradient': [Color(0xFF30cfd0), Color(0xFF330867)],
    },
    {
      'icon': Icons.article_outlined,
      'title': 'Full Transcription',
      'description': 'Automatically transcribe all your voice vibes to searchable text',
      'gradient': [Color(0xFFa8edea), Color(0xFFfed6e3)],
    },
    {
      'icon': Icons.priority_high_rounded,
      'title': 'Priority Support',
      'description': 'Get fast, dedicated support whenever you need help',
      'gradient': [Color(0xFFff9a9e), Color(0xFFfecfef)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPremium = _userService.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: _buildHeader(isDark, isPremium)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1, end: 0),
          ),

          // Feature cards
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final feature = _premiumFeatures[index];
                  return _buildFeatureCard(
                    feature: feature,
                    isDark: isDark,
                    index: index,
                  )
                      .animate()
                      .fadeIn(
                        delay: (100 * index).ms,
                        duration: 400.ms,
                      )
                      .slideX(
                        begin: 0.2,
                        end: 0,
                        delay: (100 * index).ms,
                        duration: 400.ms,
                        curve: AppAnimations.emphasized,
                      );
                },
                childCount: _premiumFeatures.length,
              ),
            ),
          ),

          // Bottom CTA button
          if (!isPremium)
            SliverToBoxAdapter(
              child: _buildCTAButton(isDark)
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.2, end: 0, delay: 600.ms),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [Color(0xFF11998e), Color(0xFF38ef7d)]
              : [AppColors.getPrimary(isDark), AppColors.getSecondary(isDark)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? Color(0xFF11998e) : AppColors.getPrimary(isDark))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isPremium ? 'You\'re Premium!' : 'Unlock Premium',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isPremium
                ? 'Thank you for your support! Enjoy all these amazing features.'
                : 'Get unlimited access to all premium features and elevate your journaling experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required Map<String, dynamic> feature,
    required bool isDark,
    required int index,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.getTextHint(isDark).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          children: [
            // Gradient accent on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: feature['gradient'] as List<Color>,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feature['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          feature['description'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.getTextSecondary(isDark),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _hapticService.medium();
            Navigator.of(context).push(
              SlidePageRoute(page: const PaywallScreen()),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark),
                  AppColors.getSecondary(isDark),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'See Premium Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
