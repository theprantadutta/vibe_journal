import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';

// Keys for saving preferences to Firestore
const String kDailyReminderEnabled = 'dailyReminderEnabled';
const String kStreaksEnabled = 'streaksEnabled';
const String kMindfulMomentsEnabled = 'mindfulMomentsEnabled';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true; // To show a loader for the initial fetch

  // Local state for the toggles
  bool _dailyReminderEnabled = true;
  bool _streaksEnabled = true;
  bool _mindfulMomentsEnabled = true;

  // To show a loader on the specific switch being updated
  final Map<String, bool> _isUpdating = {
    kDailyReminderEnabled: false,
    kStreaksEnabled: false,
    kMindfulMomentsEnabled: false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirestore();
  }

  // In your _NotificationSettingsScreenState class:

  // This function is now simpler and also syncs Firestore settings to a local cache.
  Future<void> _loadSettingsFromFirestore() async {
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final preferences = await SharedPreferences.getInstance();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() ?? {};
        final remotePreferences =
            data['notificationPreferences'] as Map<String, dynamic>? ?? {};

        // Load values from Firestore, defaulting to true if somehow null
        _dailyReminderEnabled =
            remotePreferences[kDailyReminderEnabled] ?? true;
        _streaksEnabled = remotePreferences[kStreaksEnabled] ?? true;
        _mindfulMomentsEnabled =
            remotePreferences[kMindfulMomentsEnabled] ?? true;

        // Sync these authoritative settings to our fast local cache
        await preferences.setBool(kDailyReminderEnabled, _dailyReminderEnabled);
        await preferences.setBool(kStreaksEnabled, _streaksEnabled);
        await preferences.setBool(
          kMindfulMomentsEnabled,
          _mindfulMomentsEnabled,
        );
      }
    } catch (e) {
      print("Error loading settings from Firestore: $e");
      // If Firestore fails, we can fall back to loading from the local cache
      final preferences = await SharedPreferences.getInstance();
      _dailyReminderEnabled =
          preferences.getBool(kDailyReminderEnabled) ?? true;
      _streaksEnabled = preferences.getBool(kStreaksEnabled) ?? true;
      _mindfulMomentsEnabled =
          preferences.getBool(kMindfulMomentsEnabled) ?? true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // This function now provides instant UI feedback by saving locally first,
  // then saves to Firestore in the background.
  Future<void> _updateSetting(String key, bool value) async {
    // Update local UI state and SharedPreferences immediately for a snappy feel
    setState(() {
      _isUpdating[key] = true;
      if (key == kDailyReminderEnabled) _dailyReminderEnabled = value;
      if (key == kStreaksEnabled) _streaksEnabled = value;
      if (key == kMindfulMomentsEnabled) _mindfulMomentsEnabled = value;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);

    // Then, save to Firestore in the background.
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isUpdating[key] = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationPreferences.$key': value,
      });
    } catch (e) {
      print("Error updating setting in Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not save setting. Check your connection."),
          backgroundColor: AppColors.error,
        ),
      );

      // If Firestore fails, revert the change in the UI and local cache
      await preferences.setBool(key, !value);
      if (mounted) {
        setState(() {
          if (key == kDailyReminderEnabled) _dailyReminderEnabled = !value;
          if (key == kStreaksEnabled) _streaksEnabled = !value;
          if (key == kMindfulMomentsEnabled) _mindfulMomentsEnabled = !value;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating[key] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader(context, "Reminders"),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.notifications_active_outlined,
                      title: 'Daily Journaling Reminder',
                      subtitle: 'A gentle nudge to record your vibe.',
                      value: _dailyReminderEnabled,
                      isUpdating: _isUpdating[kDailyReminderEnabled] ?? false,
                      onChanged: (value) =>
                          _updateSetting(kDailyReminderEnabled, value),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Smart Notifications"),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.local_fire_department_rounded,
                      title: 'Streaks & Milestones',
                      subtitle: 'Celebrate your journaling progress.',
                      value: _streaksEnabled,
                      isUpdating: _isUpdating[kStreaksEnabled] ?? false,
                      onChanged: (value) =>
                          _updateSetting(kStreaksEnabled, value),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Inspiration"),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.self_improvement_rounded,
                      title: 'Mindful Moments',
                      subtitle: 'Occasional inspirational messages.',
                      value: _mindfulMomentsEnabled,
                      isUpdating: _isUpdating[kMindfulMomentsEnabled] ?? false,
                      onChanged: (value) =>
                          _updateSetting(kMindfulMomentsEnabled, value),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // A reusable helper widget for our SwitchListTile
  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isUpdating,
    required ValueChanged<bool> onChanged,
  }) {
    // We use a regular ListTile to have full control over the trailing widget
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textHint)),
      // The onTap of the whole tile will also toggle the switch
      onTap: isUpdating ? null : () => onChanged(!value),
      trailing: isUpdating
          // If it's updating, show a loading spinner
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          // Otherwise, show the actual Switch
          : Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.secondary,
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
