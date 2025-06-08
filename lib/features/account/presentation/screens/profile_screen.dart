import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../premium/presentation/screens/upgrade_screen.dart'; // For navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserModel _userModel = locator<UserModel>();
  int _totalVibes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    // We can get the total vibes count directly from the user model now
    setState(() {
      _totalVibes = _userModel.cloudVibeCount;
      _isLoading = false;
    });
  }

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
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon!'),
                ),
              );
              // TODO: Implement account deletion logic (delete user from Auth, delete their Firestore docs and Storage files)
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  const SizedBox(height: 24),

                  // Stat Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total Vibes",
                          _totalVibes.toString(),
                          Icons.all_inclusive_rounded,
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Plan",
                          _userModel.plan.toUpperCase(),
                          Icons.workspace_premium_rounded,
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action List
                  _buildProfileMenu(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
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
          if (_userModel.plan == 'free') ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.star_purple500_outlined,
                color: AppColors.secondary,
              ),
              title: Text(
                'Upgrade to Premium',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                );
              },
            ),
          ],
          const Divider(height: 1),
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
              clearUserSession(); // From service_locator.dart
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: AppColors.error.withOpacity(0.7),
            ),
            title: Text(
              'Delete Account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.error.withOpacity(0.7),
              ),
            ),
            onTap: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
