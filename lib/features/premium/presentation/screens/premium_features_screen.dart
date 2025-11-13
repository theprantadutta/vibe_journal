import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/core/widgets/page_transitions.dart';
import 'package:vibe_journal/features/premium/presentation/screens/paywall_screen.dart';
import 'dart:ui';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen>
    with TickerProviderStateMixin {
  final _hapticService = HapticService();
  final _userService = locator<UserService>();
  late AnimationController _floatingController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Premium features data with enhanced information
  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'icon': Icons.cloud_done_rounded,
      'title': 'Unlimited Cloud Storage',
      'description':
          'Save unlimited voice vibes to the cloud. Never worry about running out of space for your memories.',
      'free': '75 vibes',
      'premium': 'Unlimited',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      'icon': Icons.timer_outlined,
      'title': 'Extended Recording',
      'description':
          'Record vibes up to 60 minutes long. Perfect for deep journaling sessions and detailed thoughts.',
      'free': '5 minutes',
      'premium': '60 minutes',
      'gradient': [Color(0xFFf093fb), Color(0xFFF5576C)],
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'AI Assistant',
      'description':
          'Get personalized insights, journaling prompts, and emotional support from your AI companion.',
      'free': 'Limited',
      'premium': 'Unlimited',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Advanced Analytics',
      'description':
          'Visualize your emotional patterns with beautiful interactive charts and detailed trend analysis.',
      'free': 'Basic stats',
      'premium': 'Full analytics',
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)],
    },
    {
      'icon': Icons.playlist_play_rounded,
      'title': 'Future Me Mashup',
      'description':
          'Create audio playlists from your recent vibes. Listen to your emotional journey unfold.',
      'free': '✗',
      'premium': '✓',
      'gradient': [Color(0xFFfa709a), Color(0xFFfee140)],
    },
    {
      'icon': Icons.lock_person_rounded,
      'title': 'Biometric Lock',
      'description':
          'Protect your private thoughts with fingerprint or face recognition. Your journal, your privacy.',
      'free': '✗',
      'premium': '✓',
      'gradient': [Color(0xFF30cfd0), Color(0xFF330867)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPremium = _userService.isPremium;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isPremium
                ? Colors.white
                : AppColors.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(isDark),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: _buildHeroSection(isDark, isPremium)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
              ),

              // Stats Section
              SliverToBoxAdapter(
                child: _buildStatsSection(isDark)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

              // Features Grid
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildFeatureCard(
                        feature: _premiumFeatures[index],
                        isDark: isDark,
                        index: index,
                      )
                          .animate()
                          .fadeIn(
                            delay: (300 + 100 * index).ms,
                            duration: 500.ms,
                          )
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            delay: (300 + 100 * index).ms,
                          );
                    },
                    childCount: _premiumFeatures.length,
                  ),
                ),
              ),

              // Comparison Table
              SliverToBoxAdapter(
                child: _buildComparisonTable(isDark)
                    .animate()
                    .fadeIn(delay: 900.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

              // Bottom CTA
              if (!isPremium)
                SliverToBoxAdapter(
                  child: _buildCTASection(isDark)
                      .animate()
                      .fadeIn(delay: 1000.ms)
                      .slideY(begin: 0.2, end: 0),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                    ]
                  : [
                      const Color(0xFFfef9f3),
                      const Color(0xFFf3f4f9),
                      const Color(0xFFe8f0fe),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Floating orbs
              Positioned(
                top: 100,
                right: -50,
                child: Transform.rotate(
                  angle: _rotationController.value * 2 * 3.14159,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.getPrimary(isDark).withValues(alpha: 0.3),
                          AppColors.getPrimary(isDark).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -80,
                child: Transform.rotate(
                  angle: -_rotationController.value * 2 * 3.14159,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.getSecondary(isDark)
                              .withValues(alpha: 0.2),
                          AppColors.getSecondary(isDark)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(bool isDark, bool isPremium) {
    return Container(
      margin: const EdgeInsets.only(
        top: 100,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
              : [
                  AppColors.getPrimary(isDark),
                  AppColors.getSecondary(isDark),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (isPremium ? const Color(0xFF11998e) : AppColors.getPrimary(
              isDark,
            )).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Icon
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  10 * _floatingController.value,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.verified_rounded
                        : Icons.workspace_premium_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isPremium ? '✨ You\'re Premium!' : '✨ Unlock Premium',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isPremium
                ? 'Thank you for supporting Vibe Journal!\nEnjoy all these amazing features.'
                : 'Elevate your journaling with unlimited\nfeatures and insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Starting at \$4.99/month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_outline_rounded,
              value: '10K+',
              label: 'Active Users',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite_border_rounded,
              value: '4.8',
              label: 'App Rating',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.mic_rounded,
              value: '1M+',
              label: 'Vibes Recorded',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getTextHint(isDark).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.getPrimary(isDark),
            size: 24,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.getSurface(isDark).withValues(alpha: 0.8),
                        AppColors.getSurface(isDark).withValues(alpha: 0.6),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: (feature['gradient'] as List<Color>)[0]
                    .withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feature['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['gradient'] as List<Color>)[0]
                              .withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Spacer(),

                  // Title
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Description
                  Text(
                    feature['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(isDark),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Free vs Premium
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FREE',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.getTextHint(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              feature['free'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.getTextSecondary(isDark),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.getTextHint(isDark)
                              .withValues(alpha: 0.3),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                color: (feature['gradient'] as List<Color>)[0],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              feature['premium'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: (feature['gradient'] as List<Color>)[0],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getTextHint(isDark).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose Premium?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildComparisonRow(
            '🚀',
            'Unlimited cloud storage',
            isDark,
          ),
          _buildComparisonRow(
            '⏱️',
            'Record up to 60 minutes',
            isDark,
          ),
          _buildComparisonRow(
            '🤖',
            'AI-powered insights',
            isDark,
          ),
          _buildComparisonRow(
            '📊',
            'Advanced analytics & charts',
            isDark,
          ),
          _buildComparisonRow(
            '🎵',
            'Future Me audio mashups',
            isDark,
          ),
          _buildComparisonRow(
            '🔒',
            'Biometric security',
            isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                  AppColors.getSecondary(isDark).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.getPrimary(isDark),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Cancel anytime. No commitments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String emoji, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.getPrimary(isDark),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Main CTA Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _hapticService.medium();
                Navigator.of(context).push(
                  SlidePageRoute(page: const PaywallScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.getPrimary(isDark),
                      AppColors.getSecondary(isDark),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getPrimary(isDark)
                          .withValues(alpha: 0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
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
                    const SizedBox(width: AppSpacing.md),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Your Premium Journey',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '7-day free trial included',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTrustBadge(
                Icons.security_rounded,
                'Secure',
                isDark,
              ),
              const SizedBox(width: AppSpacing.lg),
              _buildTrustBadge(
                Icons.cancel_outlined,
                'Cancel Anytime',
                isDark,
              ),
              const SizedBox(width: AppSpacing.lg),
              _buildTrustBadge(
                Icons.privacy_tip_outlined,
                'Private',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.getTextSecondary(isDark),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.getTextHint(isDark),
          ),
        ),
      ],
    );
  }
}
