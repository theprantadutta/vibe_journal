// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/features/premium/presentation/screens/upgrade_screen.dart';

import '../../../auth/presentation/screens/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserModel _userModel = locator<UserModel>();

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
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Please Confirm',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For your security, please enter your password to confirm account deletion.',
              style: TextStyle(color: AppColors.textSecondary),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Deletion'),
            onPressed: () {
              Navigator.of(ctx).pop(passwordController.text);
            },
          ),
        ],
      ),
    );
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
        clearUserSession(); // From service_locator.dart
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop(); // Pop loading dialog
      if (kDebugMode) {
        print('Re-authentication or deletion error: ${e.code}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.message ?? 'Invalid password or error.'}"),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Pop loading dialog
      if (kDebugMode) {
        print("An unexpected error occurred during account deletion: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Are you sure?',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'This is a permanent action. All your vibes and account data will be deleted forever.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
    final isPremium = _userModel.plan == 'premium';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                getInitials(_userModel.fullName ?? 'Vibe User'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userModel.fullName ?? 'Vibe User',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              _userModel.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 32),

            // --- REDESIGNED: Plan & Usage Section ---
            isPremium
                ? _buildPremiumUserCard(theme)
                : _buildFreeUserCard(theme),

            const SizedBox(height: 32),

            // Action List
            _buildProfileMenu(theme),
          ],
        ),
      ),
    );
  }

  // Card to show for FREE users
  Widget _buildFreeUserCard(ThemeData theme) {
    double usagePercentage =
        _userModel.cloudVibeCount / _userModel.maxCloudVibes;
    return _buildSectionCard(
      title: "Free Plan",
      children: [
        _buildLimitIndicator(
          title: "Cloud Vibe Storage",
          valueText:
              "${_userModel.cloudVibeCount} / ${_userModel.maxCloudVibes} recordings",
          progress: usagePercentage,
        ),
        _buildLimitInfo(
          icon: Icons.mic_rounded,
          title: "Recording Length",
          subtitle:
              "Up to ${_userModel.maxRecordingDurationMinutes} minutes per vibe",
        ),
        const Divider(height: 24, color: AppColors.inputFill),
        _buildLockedFeature(
          icon: Icons.auto_graph_rounded,
          title: "Advanced Trend Charts",
        ),
        _buildLockedFeature(
          icon: Icons.psychology_rounded,
          title: "AI Journal Assistant",
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UpgradeScreen())),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, size: 20),
              SizedBox(width: 8),
              Text("Upgrade to Premium"),
            ],
          ),
        ),
      ],
    );
  }

  // Card to show for PREMIUM users
  Widget _buildPremiumUserCard(ThemeData theme) {
    return _buildSectionCard(
      title: "VibeJournal Premium",
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.star_rounded, color: AppColors.onPrimary),
          ),
          title: Text(
            "You have unlimited access!",
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            "Thank you for supporting VibeJournal.",
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets for the new cards ---
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLimitIndicator({
    required String title,
    required String valueText,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.inputFill,
          color: AppColors.secondary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          valueText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLimitInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textHint)),
    );
  }

  Widget _buildLockedFeature({required IconData icon, required String title}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textDisabled),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textDisabled,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      trailing: Icon(
        Icons.lock_rounded,
        color: AppColors.textDisabled,
        size: 20,
      ),
    );
  }

  Widget _buildProfileMenu(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text('Edit Profile', style: theme.textTheme.bodyLarge),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit Profile screen coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Logout',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.error,
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              clearUserSession();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            title: Text(
              'Delete Account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            onTap: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
