// lib/core/services/haptic_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for providing haptic feedback throughout the app
/// with various patterns and intensities
class HapticService {
  // Singleton pattern
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  static const String _hapticsEnabledKey = 'haptics_enabled';
  bool _hapticsEnabled = true;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the haptic service and load user preferences
  Future<void> initialize() async {
    await _loadHapticsPreference();
  }

  /// Load haptics preference from SharedPreferences
  Future<void> _loadHapticsPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    } catch (e) {
      // Default to enabled if there's an error
      _hapticsEnabled = true;
    }
  }

  /// Save haptics preference to SharedPreferences
  Future<void> _saveHapticsPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsEnabledKey, _hapticsEnabled);
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  /// Check if haptics are enabled
  bool get isEnabled => _hapticsEnabled;

  /// Enable or disable haptics
  Future<void> setEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    await _saveHapticsPreference();
  }

  /// Toggle haptics on/off
  Future<void> toggle() async {
    await setEnabled(!_hapticsEnabled);
  }

  // ============================================================
  // BASIC FEEDBACK PATTERNS
  // ============================================================

  /// Light haptic feedback (subtle tap)
  /// Use for: Minor interactions, hover states
  Future<void> light() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback (standard tap)
  /// Use for: Button presses, list item selection
  Future<void> medium() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback (strong tap)
  /// Use for: Important actions, confirmations
  Future<void> heavy() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed feedback (subtle click)
  /// Use for: Picker scrolling, slider adjustment
  Future<void> selection() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibration feedback (longer rumble)
  /// Use for: Notifications, alerts
  Future<void> vibrate() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.vibrate();
  }

  // ============================================================
  // SEMANTIC FEEDBACK (Contextual)
  // ============================================================

  /// Feedback for button tap
  Future<void> buttonTap() async {
    await medium();
  }

  /// Feedback for navigation/tab change
  Future<void> navigation() async {
    await light();
  }

  /// Feedback for successful action
  Future<void> success() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Feedback for error or failure
  Future<void> error() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Feedback for warning
  Future<void> warning() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for toggle switch
  Future<void> toggleSwitch() async {
    await selection();
  }

  /// Feedback for pull to refresh
  Future<void> refresh() async {
    await light();
  }

  /// Feedback for modal appearing
  Future<void> modalAppear() async {
    await light();
  }

  /// Feedback for modal dismissing
  Future<void> modalDismiss() async {
    await selection();
  }

  /// Feedback for long press detected
  Future<void> longPress() async {
    await heavy();
  }

  /// Feedback for swipe action
  Future<void> swipe() async {
    await light();
  }

  // ============================================================
  // APP-SPECIFIC FEEDBACK
  // ============================================================

  /// Feedback for starting recording
  Future<void> recordingStart() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Feedback for stopping recording
  Future<void> recordingStop() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for saving a vibe
  Future<void> vibeSaved() async {
    await success();
  }

  /// Feedback for deleting a vibe
  Future<void> vibeDeleted() async {
    await heavy();
  }

  /// Feedback for unlocking premium feature
  Future<void> premiumUnlocked() async {
    if (!_hapticsEnabled) return;
    // Triple pulse pattern
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Feedback for reaching a milestone/streak
  Future<void> milestone() async {
    if (!_hapticsEnabled) return;
    // Celebration pattern
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// Feedback for biometric authentication success
  Future<void> biometricSuccess() async {
    await success();
  }

  /// Feedback for biometric authentication failure
  Future<void> biometricFailure() async {
    await error();
  }

  /// Feedback for theme toggle
  Future<void> themeToggle() async {
    await selection();
  }

  /// Feedback for calendar date selection
  Future<void> dateSelection() async {
    await light();
  }

  /// Feedback for audio play/pause
  Future<void> audioPlayPause() async {
    await light();
  }

  /// Feedback for audio skip
  Future<void> audioSkip() async {
    await selection();
  }

  // ============================================================
  // CUSTOM PATTERNS
  // ============================================================

  /// Create a custom pulse pattern
  /// Use for: Special effects, unique interactions
  Future<void> customPulse({
    int pulseCount = 3,
    Duration interval = const Duration(milliseconds: 100),
    HapticFeedbackType type = HapticFeedbackType.medium,
  }) async {
    if (!_hapticsEnabled) return;

    for (int i = 0; i < pulseCount; i++) {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
      }

      if (i < pulseCount - 1) {
        await Future.delayed(interval);
      }
    }
  }

  /// Create a descending intensity pattern
  Future<void> descendingPattern() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Create an ascending intensity pattern
  Future<void> ascendingPattern() async {
    if (!_hapticsEnabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}

/// Enum for haptic feedback types
enum HapticFeedbackType { light, medium, heavy, selection }
