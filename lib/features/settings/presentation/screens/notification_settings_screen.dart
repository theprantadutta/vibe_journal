import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';

const String kDailyReminderEnabled = 'daily_reminder_enabled';
const String kDailyReminderHour = 'daily_reminder_hour';
const String kDailyReminderMinute = 'daily_reminder_minute';
const String kStreaksEnabled = 'streaks_notifications_enabled';
const String kMindfulMomentsEnabled = 'mindful_moments_enabled';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyReminderEnabled = true;
  // TimeOfDay _reminderTime = const TimeOfDay(
  //   hour: 21,
  //   minute: 0,
  // ); // Default 9:00 PM
  bool _streaksEnabled = true;
  bool _mindfulMomentsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled =
          preferences.getBool(kDailyReminderEnabled) ?? true;
      // final hour = preferences.getInt(kDailyReminderHour) ?? 21;
      // final minute = preferences.getInt(kDailyReminderMinute) ?? 0;
      // _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _streaksEnabled = preferences.getBool(kStreaksEnabled) ?? true;
      _mindfulMomentsEnabled =
          preferences.getBool(kMindfulMomentsEnabled) ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Save locally for quick UI updates
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);

    // Also save to Firestore for the backend
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // The 'key' is 'daily_reminder_enabled', 'streaks_notifications_enabled', etc.
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      key: value,
    }, SetOptions(merge: true));
  }

  // Future<void> _selectTime(BuildContext context) async {
  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: _reminderTime,
  //   );
  //   if (picked != null && picked != _reminderTime) {
  //     final preferences = await SharedPreferences.getInstance();
  //     await preferences.setInt(kDailyReminderHour, picked.hour);
  //     await preferences.setInt(kDailyReminderMinute, picked.minute);
  //     setState(() {
  //       _reminderTime = picked;
  //     });
  //     // Here you would also update the scheduled notification time via FCM logic
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, "Reminders"),
          _buildSettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Daily Journaling Reminder'),
                subtitle: const Text('A gentle nudge to record your vibe.'),
                value: _dailyReminderEnabled,
                onChanged: (value) {
                  setState(() => _dailyReminderEnabled = value);
                  _updateSetting(kDailyReminderEnabled, value);
                },
              ),
              // This ListTile is only enabled if the main reminder switch is on
              // ListTile(
              //   enabled: _dailyReminderEnabled,
              //   leading: Icon(
              //     Icons.access_time_rounded,
              //     color: _dailyReminderEnabled
              //         ? AppColors.textSecondary
              //         : AppColors.textDisabled,
              //   ),
              //   title: Text(
              //     'Reminder Time',
              //     style: TextStyle(
              //       color: _dailyReminderEnabled
              //           ? AppColors.textPrimary
              //           : AppColors.textDisabled,
              //     ),
              //   ),
              //   trailing: Text(
              //     _reminderTime.format(context),
              //     style: Theme.of(context).textTheme.bodyLarge,
              //   ),
              //   onTap: _dailyReminderEnabled
              //       ? () => _selectTime(context)
              //       : null,
              // ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "Smart Notifications"),
          _buildSettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Streaks & Milestones'),
                subtitle: const Text('Celebrate your journaling progress.'),
                value: _streaksEnabled,
                onChanged: (value) {
                  setState(() => _streaksEnabled = value);
                  _updateSetting(kStreaksEnabled, value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "Inspiration"),
          _buildSettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.self_improvement_rounded,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Mindful Moments'),
                subtitle: const Text('Occasional inspirational messages.'),
                value: _mindfulMomentsEnabled,
                onChanged: (value) {
                  setState(() => _mindfulMomentsEnabled = value);
                  _updateSetting(kMindfulMomentsEnabled, value);
                },
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
