// lib/features/layout/main_app_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/config/theme/app_animations.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/restore_service.dart';
import 'package:vibe_journal/core/services/sound_service.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/widgets/page_transitions.dart';
import 'package:vibe_journal/core/widgets/restore_vibes_dialog.dart';
import 'package:vibe_journal/features/account/presentation/screens/profile_screen.dart';
import 'package:vibe_journal/features/settings/presentation/screens/settings_screen.dart';
import '../journal/presentation/screens/journal_screen.dart';
import '../calendar/presentation/screens/calendar_screen.dart';
import '../insights/presentation/screens/insights_screen.dart';
import '../ai_assistant/presentation/screens/ai_assistant_screen.dart';

class MainAppLayout extends StatefulWidget {
  final bool checkForRestore;

  const MainAppLayout({
    super.key,
    this.checkForRestore = false,
  });

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _hapticService = HapticService();
  final _soundService = SoundService();
  final _userService = locator<UserService>();
  final _restoreService = locator<RestoreService>();

  // Animation controller for page transitions
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Lazy loading implementation
  late final List<Widget?> _pageCache;

  final List<Widget> _pageDestinations = [
    const JournalScreen(),
    const CalendarScreen(),
    const InsightsScreen(),
    const AiAssistantScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize page cache with first page
    _pageCache = List.filled(_pageDestinations.length, null);
    _pageCache[0] = _pageDestinations[0];

    // Setup transition animations
    _transitionController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: AppAnimations.fadeCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: AppAnimations.emphasized,
    ));

    // Start with page visible
    _transitionController.value = 1.0;

    // Check if we should restore vibes from cloud
    if (widget.checkForRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndRestoreVibes();
      });
    }
  }

  /// Check if user needs vibe restoration and show dialog
  Future<void> _checkAndRestoreVibes() async {
    if (!_userService.isPremium || !_userService.isUserLoggedIn) {
      return; // Only for premium users
    }

    final userId = _userService.currentUser.uid;
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_sync_complete_$userId';

    // Check if first sync is already complete
    final syncComplete = prefs.getBool(key) ?? false;
    if (syncComplete) {
      return; // Already restored
    }

    // Show restore dialog
    if (mounted) {
      final progressStream = _restoreService.restoreAllVibes();

      await RestoreVibesDialog.show(context, progressStream);

      // Mark sync as complete
      await prefs.setBool(key, true);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  final List<String> _pageTitles = [
    'My Journal',
    'Mood Calendar',
    'Vibe Insights',
    'AI Assistant',
  ];

  final List<IconData> _navIcons = [
    Icons.edit_note_rounded,
    Icons.calendar_today_rounded,
    Icons.insights_rounded,
    Icons.auto_awesome_rounded,
  ];

  final List<String> _navLabels = [
    'Journal',
    'Calendar',
    'Insights',
    'Assistant',
  ];

  Future<void> _onTabTapped(int index) async {
    if (index == _currentIndex) return;

    // Haptic & sound feedback
    _hapticService.navigation();
    _soundService.navigation();

    // Animate out current page
    await _transitionController.reverse();

    // Lazy load page if needed
    if (_pageCache[index] == null) {
      _pageCache[index] = _pageDestinations[index];
    }

    // Update index
    setState(() {
      _currentIndex = index;
    });

    // Animate in new page
    await _transitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex])
            .animate(key: ValueKey(_currentIndex))
            .fadeIn(duration: 200.ms)
            .slideX(begin: -0.1, end: 0, curve: AppAnimations.emphasized),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              _hapticService.light();
              Navigator.push(
                context,
                SlidePageRoute(page: const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Account',
            onPressed: () {
              _hapticService.light();
              Navigator.push(
                context,
                SlidePageRoute(page: const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: AnimatedBuilder(
        animation: _transitionController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _pageCache
              .map((page) => page ?? const SizedBox.shrink())
              .toList(),
        ),
      ),
      bottomNavigationBar: _buildAnimatedBottomNav(isDark, theme),
    );
  }

  Widget _buildAnimatedBottomNav(bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navIcons.length,
              (index) => _buildNavItem(
                index: index,
                icon: _navIcons[index],
                label: _navLabels[index],
                isSelected: _currentIndex == index,
                isDark: isDark,
                theme: theme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
  }) {
    final color = isSelected
        ? AppColors.getPrimary(isDark)
        : AppColors.getTextHint(isDark);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.emphasized,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: AppAnimations.fast,
                  curve: AppAnimations.spring,
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedDefaultTextStyle(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.emphasized,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: isSelected ? 12 : 11,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
