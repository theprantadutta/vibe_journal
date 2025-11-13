import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../services/restore_service.dart';

/// Full-screen blocking dialog for restoring vibes from cloud
class RestoreVibesDialog extends StatelessWidget {
  final Stream<RestoreProgress> progressStream;

  const RestoreVibesDialog({super.key, required this.progressStream});

  /// Show the restore dialog
  static Future<void> show(
    BuildContext context,
    Stream<RestoreProgress> progressStream,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss until complete
      barrierColor: Colors.black87,
      builder: (context) => RestoreVibesDialog(progressStream: progressStream),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                AppColors.getSecondary(isDark).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: StreamBuilder<RestoreProgress>(
              stream: progressStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildLoadingState(isDark);
                }

                final progress = snapshot.data!;

                switch (progress.status) {
                  case RestoreStatus.fetchingVibes:
                    return _buildFetchingState(isDark, progress);

                  case RestoreStatus.restoringVibes:
                    return _buildRestoringState(isDark, progress);

                  case RestoreStatus.completed:
                    // Auto-dismiss after a short delay
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                    return _buildCompletedState(isDark, progress);

                  case RestoreStatus.error:
                    return _buildErrorState(context, isDark, progress);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return _buildDialogCard(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCloudIcon(isDark, isAnimating: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Connecting to cloud...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CircularProgressIndicator(color: AppColors.getPrimary(isDark)),
        ],
      ),
    );
  }

  Widget _buildFetchingState(bool isDark, RestoreProgress progress) {
    return _buildDialogCard(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCloudIcon(isDark, isAnimating: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Fetching your vibes...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            progress.message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CircularProgressIndicator(color: AppColors.getPrimary(isDark)),
        ],
      ),
    );
  }

  Widget _buildRestoringState(bool isDark, RestoreProgress progress) {
    return _buildDialogCard(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCloudIcon(isDark, isAnimating: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Restoring your vibes...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          SizedBox(
            width: 280,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.getBackground(isDark),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.progressText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    Text(
                      '${(progress.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Audio download status
          if (progress.audioDownloaded > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_done_rounded,
                    size: 16,
                    color: AppColors.getPrimary(isDark),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${progress.audioDownloaded} audio files downloaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(bool isDark, RestoreProgress progress) {
    return _buildDialogCard(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Colors.green,
                ),
              )
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Restore Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${progress.vibesRestored} vibes restored',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
          if (progress.audioDownloaded > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${progress.audioDownloaded} available offline',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    bool isDark,
    RestoreProgress progress,
  ) {
    return _buildDialogCard(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Restore Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              progress.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogCard({required bool isDark, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCloudIcon(bool isDark, {bool isAnimating = false}) {
    final icon = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getPrimary(isDark),
            AppColors.getSecondary(isDark),
          ],
        ),
      ),
      child: const Icon(
        Icons.cloud_sync_rounded,
        size: 40,
        color: Colors.white,
      ),
    );

    if (isAnimating) {
      return icon
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.3),
          )
          .then()
          .shake(duration: 500.ms, hz: 2, offset: const Offset(2, 0));
    }

    return icon;
  }
}
