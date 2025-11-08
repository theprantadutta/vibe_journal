// lib/core/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme/app_spacing.dart';

/// A widget that displays an empty state with icon, message, and optional action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconSize = 80,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.5),
            )
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                .fade(),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Preset empty states for common scenarios
class EmptyStates {
  /// No vibes recorded yet
  static Widget noVibes({
    required BuildContext context,
    VoidCallback? onActionTap,
  }) {
    return EmptyState(
      icon: Icons.mic_none,
      title: 'No vibes yet',
      message: 'Start recording your first vibe to see it here',
      action: onActionTap != null
          ? ElevatedButton.icon(
              onPressed: onActionTap,
              icon: const Icon(Icons.mic),
              label: const Text('Record Vibe'),
            )
          : null,
    );
  }

  /// No vibes for selected date
  static Widget noVibesForDate(BuildContext context) {
    return const EmptyState(
      icon: Icons.event_busy,
      title: 'No vibes on this day',
      message: 'You didn\'t record any vibes on this date',
    );
  }

  /// No search results
  static Widget noSearchResults(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      message: 'Try adjusting your search criteria',
    );
  }

  /// No internet connection
  static Widget noConnection({
    required BuildContext context,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No connection',
      message: 'Please check your internet connection',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  /// Generic error state
  static Widget error({
    required BuildContext context,
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message ?? 'An unexpected error occurred',
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          : null,
    );
  }
}
