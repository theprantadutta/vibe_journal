import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/features/legal/presentation/terms_and_conditions_content.dart';
import 'package:vibe_journal/features/premium/presentation/screens/upgrade_screen.dart';
import 'package:vibe_journal/features/account/presentation/screens/profile_screen.dart';

import '../../../legal/presentation/privacy_policy_content.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel userModel = locator<UserModel>();
    final isPremium = userModel.plan == 'premium';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, "Account"),
          _buildSettingsGroup(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Manage Account'),
                subtitle: const Text('Edit your profile information'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              if (!isPremium) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.star_purple500_outlined,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Upgrade to Premium'),
                  subtitle: const Text('Unlock all advanced features'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "Preferences"),
          _buildSettingsGroup(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Notification Settings'),
                subtitle: const Text('Manage your reminders and alerts'),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: isPremium
                      ? AppColors.textSecondary
                      : AppColors.textDisabled,
                ),
                title: const Text('Biometric Lock'),
                subtitle: Text(
                  'Secure your journal with Face ID / Fingerprint',
                  style: TextStyle(
                    color: isPremium
                        ? AppColors.textHint
                        : AppColors.textDisabled,
                  ),
                ),
                value: false, // Placeholder value
                onChanged: isPremium
                    ? (bool value) {
                        // TODO: Implement biometric lock logic
                      }
                    : null, // Disable the switch for free users
                activeColor: AppColors.primary,
              ),
              if (!isPremium)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 72.0,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Text(
                    'This is a Premium feature.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "About"),
          _buildSettingsGroup(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Privacy Policy'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const Dialog(
                      child: SizedBox(
                        height: 600, // Or some other constraint
                        child: PrivacyPolicyContent(
                          showAcceptanceControls: false,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Terms of Service'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const Dialog(
                      child: SizedBox(
                        height: 600, // Or some other constraint
                        child: TermsAndConditionsContent(
                          showAcceptanceControls: false,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text('App Version'),
                trailing: Text(
                  "1.0.0",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
