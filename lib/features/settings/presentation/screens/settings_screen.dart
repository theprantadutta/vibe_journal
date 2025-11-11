// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_provider.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/widgets/snackbar_utils.dart';
import '../../../account/presentation/screens/profile_screen.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../legal/presentation/privacy_policy_content.dart';
import '../../../legal/presentation/terms_and_conditions_content.dart';
import '../../../premium/presentation/screens/subscription_management_screen.dart';
import '../../../premium/presentation/screens/premium_features_screen.dart';
import 'notification_settings_screen.dart';

const String kBiometricLockEnabled = 'biometric_lock_enabled';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserModel _userModel = locator<UserModel>();
  final _userService = locator<UserService>();
  final _hapticService = HapticService();
  final _soundService = SoundService();

  bool _biometricLockEnabled = false;
  bool _isLoadingBiometrics = true;
  bool _hapticsEnabled = true;
  bool _soundsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      _biometricLockEnabled =
          preferences.getBool(kBiometricLockEnabled) ?? false;
      _hapticsEnabled = _hapticService.isEnabled;
      _soundsEnabled = _soundService.isEnabled;
      _isLoadingBiometrics = false;
    });
  }

  Future<void> _onBiometricLockChanged(bool newValue) async {
    if (newValue) {
      final didAuthenticate = await BiometricAuthService.authenticate(
        'Please authenticate to enable Biometric Lock',
      );
      if (didAuthenticate && mounted) {
        setState(() => _biometricLockEnabled = true);
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(kBiometricLockEnabled, true);
        if (mounted) {
          SnackBarUtils.showSuccess(context, message: 'Biometric Lock Enabled');
          _hapticService.success();
        }
      }
    } else {
      setState(() => _biometricLockEnabled = false);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(kBiometricLockEnabled, false);
      if (mounted) {
        _hapticService.light();
      }
    }
  }

  Future<void> _onHapticsChanged(bool value) async {
    await _hapticService.setEnabled(value);
    setState(() => _hapticsEnabled = value);
    if (value) {
      _hapticService.success();
    }
  }

  Future<void> _onSoundsChanged(bool value) async {
    await _soundService.setEnabled(value);
    setState(() => _soundsEnabled = value);
    if (value) {
      _soundService.success();
    } else {
      _hapticService.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _userService.isPremium;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsGroup(
            context: context,
            isDark: isDark,
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.person_outline_rounded,
                title: 'Manage Account',
                subtitle: 'Profile, usage, and data',
                onTap: () {
                  _hapticService.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                context: context,
                icon: Icons.workspace_premium_rounded,
                iconColor: isPremium
                    ? AppColors.getPrimary(isDark)
                    : AppColors.getSecondary(isDark),
                title: isPremium ? 'Premium Features' : 'Upgrade to Premium',
                subtitle: isPremium
                    ? 'View all premium benefits'
                    : 'Unlock all features',
                onTap: () {
                  _hapticService.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PremiumFeaturesScreen(),
                    ),
                  );
                },
              ),
              if (isPremium) ...[
                _buildDivider(),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.manage_accounts_rounded,
                  title: 'Manage Subscription',
                  subtitle: 'View and manage your subscription',
                  onTap: () {
                    _hapticService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 50.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsGroup(
            context: context,
            isDark: isDark,
            children: [
              _buildThemeSelector(context),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsGroup(
            context: context,
            isDark: isDark,
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Reminders and alerts',
                onTap: () {
                  _hapticService.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              if (!_isLoadingBiometrics) ...[
                _buildDivider(),
                _buildSwitchTile(
                  context: context,
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Lock',
                  subtitle: 'Secure with Face ID / Fingerprint',
                  value: _biometricLockEnabled,
                  onChanged: isPremium ? _onBiometricLockChanged : null,
                  isLocked: !isPremium,
                  lockMessage: 'Premium feature',
                ),
              ],
              _buildDivider(),
              _buildSwitchTile(
                context: context,
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle: 'Tactile responses',
                value: _hapticsEnabled,
                onChanged: _onHapticsChanged,
              ),
              _buildDivider(),
              _buildSwitchTile(
                context: context,
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                subtitle: 'UI sounds (opt-in)',
                value: _soundsEnabled,
                onChanged: _onSoundsChanged,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 150.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsGroup(
            context: context,
            isDark: isDark,
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  _hapticService.light();
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: SizedBox(
                        height: 600,
                        child: const PrivacyPolicyContent(
                          showAcceptanceControls: false,
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                context: context,
                icon: Icons.gavel_rounded,
                title: 'Terms of Service',
                onTap: () {
                  _hapticService.light();
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: SizedBox(
                        height: 600,
                        child: const TermsAndConditionsContent(
                          showAcceptanceControls: false,
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildDivider(),
              ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.getTextSecondary(isDark),
                ),
                title: const Text('App Version'),
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.6),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required bool isDark,
    required List<Widget> children,
  }) {
    return AnimatedCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      color: AppColors.getSurface(isDark),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.getTextSecondary(isDark),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isLocked = false,
    String? lockMessage,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            icon,
            color: isLocked
                ? AppColors.getTextSecondary(isDark).withValues(alpha: 0.4)
                : AppColors.getTextSecondary(isDark),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isLocked
                  ? AppColors.getTextSecondary(isDark).withValues(alpha: 0.4)
                  : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: isLocked
                  ? AppColors.getTextSecondary(isDark).withValues(alpha: 0.4)
                  : null,
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
        if (isLocked && lockMessage != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 72.0,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lockMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.getPrimary(isDark),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Choose your preferred theme',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  isSelected: themeProvider.isLightMode,
                  onTap: () {
                    _hapticService.themeToggle();
                    themeProvider.setLightMode();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  isSelected: themeProvider.isDarkMode,
                  onTap: () {
                    _hapticService.themeToggle();
                    themeProvider.setDarkMode();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  icon: Icons.settings_suggest_rounded,
                  label: 'System',
                  isSelected: themeProvider.isSystemMode,
                  onTap: () {
                    _hapticService.themeToggle();
                    themeProvider.setSystemMode();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.getPrimary(isDark).withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.getPrimary(isDark)
                : AppColors.getTextSecondary(isDark).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.getPrimary(isDark)
                  : AppColors.getTextSecondary(isDark),
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.getPrimary(isDark)
                    : AppColors.getTextSecondary(isDark),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: AppSpacing.iconMd + AppSpacing.lg * 2,
      endIndent: AppSpacing.lg,
    );
  }
}
