// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/core/services/sync_service.dart';
import 'package:vibe_journal/core/services/user_service.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/config/theme/app_animations.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/sound_service.dart';
import 'package:vibe_journal/core/utils/snackbar_utils.dart';
import 'package:vibe_journal/core/widgets/animated_card.dart';
import 'package:vibe_journal/core/widgets/animated_button.dart';
import 'package:vibe_journal/features/premium/presentation/screens/premium_features_screen.dart';
import 'package:vibe_journal/features/premium/presentation/screens/subscription_management_screen.dart';

import '../../../auth/presentation/screens/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserModel _userModel = locator<UserModel>();
  final UserService _userService = locator<UserService>();
  final _hapticService = HapticService();
  final _soundService = SoundService();

  String getInitials(String fullName) {
    if (fullName.isEmpty) return "V";
    List<String> names = fullName.split(" ");
    String initials = "";
    if (names.isNotEmpty) {
      initials += names.first[0];
      if (names.length > 1) {
        initials += names.last[0];
      }
    }
    return initials.toUpperCase();
  }

  /// Shows a dialog asking the user for their password to confirm deletion.
  Future<String?> _showPasswordConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: Text(
          'Please Confirm',
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For your security, please enter your password to confirm account deletion.',
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextHint(isDark)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.getError(isDark),
            ),
            child: const Text('Confirm Deletion'),
            onPressed: () {
              Navigator.of(ctx).pop(passwordController.text);
            },
          ),
        ],
      ),
    );
  }

  /// Smart logout with sync validation
  Future<void> _handleSmartLogout(BuildContext context, bool isDark) async {
    _hapticService.light();

    final userService = locator<UserService>();
    final syncService = locator<SyncService>();
    final bool isPremium = userService.isPremium;

    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: const Text('Confirm Logout'),
        content: Text(
          isPremium
              ? 'Your vibes will be synced to cloud before logging out.'
              : 'Your local vibes will be kept for when you log back in.',
          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextHint(isDark)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.getError(isDark),
            ),
            child: const Text('Logout'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      if (isPremium) {
        // Premium users: sync before logout
        if (kDebugMode) {
          print('🚪 LOGOUT: Premium user, syncing pending vibes...');
        }

        // Check if there are pending uploads
        final hasPending = await syncService.hasPendingVibes();

        if (hasPending) {
          // Show syncing dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.getSurface(isDark),
              title: const Text('Syncing...'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Syncing your vibes to cloud...'),
                ],
              ),
            ),
          );

          // Sync pending vibes
          final syncResult = await syncService.syncPendingVibes();

          // Close sync dialog
          if (mounted) Navigator.of(context).pop();

          if (!syncResult.success) {
            if (mounted) {
              SnackBarUtils.error(
                context,
                'Failed to sync vibes. Please check your connection and try again.',
              );
            }
            return; // Block logout if sync fails
          }

          if (kDebugMode) {
            print('✅ LOGOUT: All vibes synced successfully');
          }
        }

        // Clear all local data for premium users
        await _clearAllLocalData();
      } else {
        // Free users: keep local data
        if (kDebugMode) {
          print('🚪 LOGOUT: Free user, keeping local data');
        }
        // Only clear user session, not vibes/audio
      }

      // Clear user service and Firebase session
      await userService.clearUser();
      await FirebaseAuth.instance.signOut();

      _hapticService.success();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LOGOUT: Error during logout: $e');
      }
      if (mounted) {
        SnackBarUtils.error(
          context,
          'Logout failed: $e',
        );
      }
    }
  }

  /// Clear all local data (vibes, audio files)
  Future<void> _clearAllLocalData() async {
    try {
      if (kDebugMode) {
        print('🗑️ LOGOUT: Clearing all local data...');
      }

      final appDir = await getApplicationDocumentsDirectory();

      // Delete vibes directory
      final vibesDir = Directory('${appDir.path}/vibes');
      if (vibesDir.existsSync()) {
        await vibesDir.delete(recursive: true);
        if (kDebugMode) {
          print('✅ LOGOUT: Deleted vibes directory');
        }
      }

      // Delete audio cache directory
      final audioDir = Directory('${appDir.path}/audio');
      if (audioDir.existsSync()) {
        await audioDir.delete(recursive: true);
        if (kDebugMode) {
          print('✅ LOGOUT: Deleted audio cache directory');
        }
      }

      if (kDebugMode) {
        print('✅ LOGOUT: All local data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ LOGOUT: Error clearing local data: $e');
      }
      // Don't throw - allow logout to continue even if cleanup fails
    }
  }

  /// The main logic for handling the entire account deletion process.
  Future<void> _handleAccountDeletion() async {
    if (!mounted) return;

    // 1. Show the password dialog and get the password.
    final password = await _showPasswordConfirmationDialog();
    if (password == null || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion cancelled.')),
      );
      return; // User cancelled
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Re-authenticate the user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      if (kDebugMode) {
        print(
          'User re-authenticated successfully. Proceeding with deletion...',
        );
      }

      // Re-authentication successful, proceed with deletion
      final userId = user.uid;
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // 3. Get all user data to find files for deletion
      final vibesQuery = await firestore
          .collection('vibes')
          .where('userId', isEqualTo: userId)
          .get();

      // 4. Delete all files from Cloud Storage
      if (vibesQuery.docs.isNotEmpty) {
        final deleteFutures = vibesQuery.docs.map((doc) {
          final path = doc.data()['audioPath'] as String?;
          if (path != null && path.isNotEmpty) {
            return storage.ref(path).delete();
          }
          return Future.value(); // Return a completed future if no path
        }).toList();
        await Future.wait(deleteFutures);
        if (kDebugMode) {
          print('Deleted ${deleteFutures.length} files from Storage.');
        }
      }

      // 5. Delete all Firestore documents in a batch for efficiency
      final batch = firestore.batch();
      for (final doc in vibesQuery.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(
        firestore.collection('users').doc(userId),
      ); // Delete the user's document
      await batch.commit();
      if (kDebugMode) {
        print('Deleted user document and all vibe documents from Firestore.');
      }

      // 6. Delete the auth user itself (this must be last)
      await user.delete();
      if (kDebugMode) {
        print('Deleted user from Firebase Authentication.');
      }

      // 7. Pop all screens and navigate out
      if (mounted) {
        // The AuthGuard will automatically handle navigation, but this is a failsafe.
        // We don't need to pop the loading dialog since the context will be gone.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account permanently deleted."),
            backgroundColor: Colors.green,
          ),
        );
        final userService = locator<UserService>();
        await userService.clearUser();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop(); // Pop loading dialog
      if (kDebugMode) {
        print('Re-authentication or deletion error: ${e.code}');
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.message ?? 'Invalid password or error.'}"),
          backgroundColor: AppColors.getError(isDark),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Pop loading dialog
      if (kDebugMode) {
        print("An unexpected error occurred during account deletion: $e");
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("An unexpected error occurred."),
          backgroundColor: AppColors.getError(isDark),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: Text(
          'Are you sure?',
          style: TextStyle(color: AppColors.getError(isDark)),
        ),
        content: Text(
          'This is a permanent action. All your vibes and account data will be deleted forever.',
          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextHint(isDark)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getError(isDark),
            ),
            child: const Text('Delete My Account'),
            onPressed: () {
              // Pop the confirmation dialog first
              Navigator.of(ctx).pop();
              // Then start the full deletion process
              _handleAccountDeletion();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPremium = _userService.isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.getPrimary(isDark),
                  child: Text(
                    getInitials(_userModel.fullName ?? 'Vibe User'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.getOnPrimary(isDark),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: AppAnimations.normal)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
            const SizedBox(height: AppSpacing.lg),
            Text(
                  _userModel.fullName ?? 'Vibe User',
                  style: theme.textTheme.headlineSmall,
                )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
            Text(
                  _userModel.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.getTextHint(isDark),
                  ),
                )
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 150.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xxl),

            // --- REDESIGNED: Plan & Usage Section ---
            (isPremium
                    ? _buildPremiumUserCard(theme)
                    : _buildFreeUserCard(theme))
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppSpacing.xxl),

            // Action List
            _buildProfileMenu(theme)
                .animate()
                .fadeIn(duration: AppAnimations.normal, delay: 250.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  // Card to show for FREE users
  Widget _buildFreeUserCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    double usagePercentage =
        _userModel.cloudVibeCount / _userService.maxCloudVibes;
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Free Plan", style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          _buildLimitIndicator(
            title: "Cloud Vibe Storage",
            valueText:
                "${_userModel.cloudVibeCount} / ${_userService.maxCloudVibes} recordings",
            progress: usagePercentage,
          ),
          _buildLimitInfo(
            icon: Icons.mic_rounded,
            title: "Recording Length",
            subtitle:
                "Up to ${_userService.maxRecordingDurationMinutes} minutes per vibe",
          ),
          Divider(height: AppSpacing.xl, color: AppColors.getInputFill(isDark)),
          _buildLockedFeature(
            icon: Icons.auto_graph_rounded,
            title: "Advanced Trend Charts",
          ),
          _buildLockedFeature(
            icon: Icons.psychology_rounded,
            title: "AI Journal Assistant",
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedButton(
            onPressed: () {
              _hapticService.light();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PremiumFeaturesScreen(),
                ),
              );
            },
            backgroundColor: AppColors.getSecondary(isDark),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text("Upgrade to Premium"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card to show for PREMIUM users
  Widget _buildPremiumUserCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("VibeJournal Premium", style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.getPrimary(isDark),
              child: Icon(
                Icons.star_rounded,
                color: AppColors.getOnPrimary(isDark),
              ),
            ),
            title: Text(
              "You have unlimited access!",
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              "Thank you for supporting VibeJournal.",
              style: TextStyle(color: AppColors.getTextHint(isDark)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedButton(
            onPressed: () {
              _hapticService.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionManagementScreen(),
                ),
              );
            },
            backgroundColor: AppColors.getPrimary(
              isDark,
            ).withValues(alpha: 0.1),
            foregroundColor: AppColors.getPrimary(isDark),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.manage_accounts_rounded, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text("Manage Subscription"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitIndicator({
    required String title,
    required String valueText,
    required double progress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.getInputFill(isDark),
          color: AppColors.getSecondary(isDark),
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          valueText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.getTextHint(isDark)),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildLimitInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.getTextSecondary(isDark)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.getTextHint(isDark)),
      ),
    );
  }

  Widget _buildLockedFeature({required IconData icon, required String title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.getTextDisabled(isDark)),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.getTextDisabled(isDark),
          decoration: TextDecoration.lineThrough,
        ),
      ),
      trailing: Icon(
        Icons.lock_rounded,
        color: AppColors.getTextDisabled(isDark),
        size: 20,
      ),
    );
  }

  Widget _buildProfileMenu(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: AppColors.getError(isDark),
            ),
            title: Text(
              'Logout',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.getError(isDark),
              ),
            ),
            onTap: () => _handleSmartLogout(context, isDark),
          ),
          Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: AppColors.getError(isDark).withValues(alpha: 0.7),
            ),
            title: Text(
              'Delete Account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.getError(isDark).withValues(alpha: 0.7),
              ),
            ),
            onTap: () {
              _hapticService.light();
              _showDeleteConfirmationDialog();
            },
          ),
        ],
      ),
    );
  }
}
