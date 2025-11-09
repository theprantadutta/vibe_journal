// lib/features/onboarding/presentation/screens/onboarding_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_animations.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../auth/presentation/widgets/auth_guard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _hapticService = HapticService();
  final _soundService = SoundService();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.mic_rounded,
      title: 'Voice Your Vibes',
      description: 'Record your thoughts and feelings with just your voice. Quick, easy, and natural.',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Insights',
      description: 'Get intelligent feedback and discover patterns in your emotional journey.',
      gradient: AppColors.vibeyGradient,
    ),
    OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Track Your Growth',
      description: 'Visualize your mood trends and celebrate your progress over time.',
      gradient: AppColors.secondaryGradient,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    _hapticService.success();
    _soundService.success();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Sign out any existing Firebase Auth session
    await FirebaseAuth.instance.signOut();

    // Clear any user service data
    if (locator.isRegistered<UserService>()) {
      await locator<UserService>().clearUser();
    }

    if (mounted) {
      // Navigate back to AuthGuard with a fresh instance to re-evaluate auth state
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGuard()),
        (route) => false,
      );
    }
  }

  void _nextPage() {
    _hapticService.light();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.normal,
        curve: AppAnimations.emphasized,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _hapticService.light();
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _hapticService.selection();
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageWidget(
                      page: _pages[index],
                      theme: theme,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index, isDark),
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AnimatedButton(
                  onPressed: _nextPage,
                  enableHaptic: true,
                  gradient: _pages[_currentPage].gradient,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index, bool isDark) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.emphasized,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.getPrimary(isDark)
            : AppColors.getTextHint(isDark).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }
}

// Separate stateful widget for each page to handle animations properly
class _OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;
  final ThemeData theme;
  final bool isDark;

  const _OnboardingPageWidget({
    required this.page,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<_OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation when widget appears
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.page.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.page.gradient as LinearGradient)
                          .colors
                          .first
                          .withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  widget.page.icon,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Title
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.page.title,
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(widget.isDark),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.page.description,
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.getTextSecondary(widget.isDark),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
