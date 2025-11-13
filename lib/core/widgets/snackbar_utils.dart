// lib/core/widgets/snackbar_utils.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../services/haptic_service.dart';

/// Utility class for showing elegant snackbars
class SnackBarUtils {
  static final _hapticService = HapticService();

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool enableHaptic = true,
  }) {
    if (enableHaptic) {
      _hapticService.success();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.getSuccess(isDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    bool enableHaptic = true,
    VoidCallback? onRetry,
  }) {
    if (enableHaptic) {
      _hapticService.error();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.getError(isDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
        margin: const EdgeInsets.all(AppSpacing.lg),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: AppColors.getError(isDark),
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool enableHaptic = false,
  }) {
    if (enableHaptic) {
      _hapticService.light();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.getInfo(isDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool enableHaptic = true,
  }) {
    if (enableHaptic) {
      _hapticService.warning();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.getWarning(isDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  /// Show a custom snackbar with an action
  static void showCustom(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool enableHaptic = false,
  }) {
    if (enableHaptic) {
      _hapticService.light();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: duration,
        margin: const EdgeInsets.all(AppSpacing.lg),
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: iconColor,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}
