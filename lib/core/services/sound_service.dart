// lib/core/services/sound_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for providing subtle UI sound effects throughout the app
/// Enhances user experience with audio feedback for interactions
class SoundService {
  // Singleton pattern
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const String _soundsEnabledKey = 'sounds_enabled';
  static const String _soundVolumeKey = 'sound_volume';

  bool _soundsEnabled = false; // Default to disabled (opt-in)
  double _volume = 0.5; // Default volume (0.0 to 1.0)

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the sound service and load user preferences
  Future<void> initialize() async {
    await _loadSoundPreferences();
  }

  /// Load sound preferences from SharedPreferences
  Future<void> _loadSoundPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundsEnabled = prefs.getBool(_soundsEnabledKey) ?? false;
      _volume = prefs.getDouble(_soundVolumeKey) ?? 0.5;
    } catch (e) {
      // Default to disabled if there's an error
      _soundsEnabled = false;
      _volume = 0.5;
    }
  }

  /// Save sound preferences to SharedPreferences
  Future<void> _saveSoundPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundsEnabledKey, _soundsEnabled);
      await prefs.setDouble(_soundVolumeKey, _volume);
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  /// Check if sounds are enabled
  bool get isEnabled => _soundsEnabled;

  /// Get current volume (0.0 to 1.0)
  double get volume => _volume;

  /// Enable or disable sounds
  Future<void> setEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    await _saveSoundPreferences();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _saveSoundPreferences();
  }

  /// Toggle sounds on/off
  Future<void> toggle() async {
    await setEnabled(!_soundsEnabled);
  }

  // ============================================================
  // BASIC SOUND EFFECTS
  // ============================================================

  /// Play a subtle tap sound
  /// Use for: Button presses, taps
  Future<void> tap() async {
    if (!_soundsEnabled) return;
    // Using system sounds as placeholder
    // In production, you'd play: await _playSound('assets/sounds/tap.wav');
    await SystemSound.play(SystemSoundType.click);
  }

  /// Play a success sound
  /// Use for: Successful operations, confirmations
  Future<void> success() async {
    if (!_soundsEnabled) return;
    // Placeholder: would play a pleasant chime sound
    // await _playSound('assets/sounds/success.wav');
  }

  /// Play an error sound
  /// Use for: Errors, failures
  Future<void> error() async {
    if (!_soundsEnabled) return;
    // Placeholder: would play a subtle error tone
    // await _playSound('assets/sounds/error.wav');
  }

  /// Play a notification sound
  /// Use for: Alerts, notifications
  Future<void> notification() async {
    if (!_soundsEnabled) return;
    // Placeholder: would play a notification sound
    // await _playSound('assets/sounds/notification.wav');
  }

  /// Play a whoosh sound
  /// Use for: Page transitions, swipes
  Future<void> whoosh() async {
    if (!_soundsEnabled) return;
    // Placeholder: would play a whoosh sound
    // await _playSound('assets/sounds/whoosh.wav');
  }

  /// Play a pop sound
  /// Use for: Modals appearing, pop-ups
  Future<void> pop() async {
    if (!_soundsEnabled) return;
    // Placeholder: would play a pop sound
    // await _playSound('assets/sounds/pop.wav');
  }

  // ============================================================
  // SEMANTIC SOUNDS (Contextual)
  // ============================================================

  /// Sound for button press
  Future<void> buttonPress() async {
    await tap();
  }

  /// Sound for navigation/tab change
  Future<void> navigation() async {
    // Softer sound for navigation
    // await _playSound('assets/sounds/navigation.wav');
  }

  /// Sound for modal appearing
  Future<void> modalAppear() async {
    await pop();
  }

  /// Sound for modal dismissing
  Future<void> modalDismiss() async {
    // Softer pop for dismiss
    // await _playSound('assets/sounds/dismiss.wav');
  }

  /// Sound for toggle switch
  Future<void> toggleSwitch() async {
    await tap();
  }

  /// Sound for pull to refresh
  Future<void> refresh() async {
    // Subtle whoosh for refresh
    // await _playSound('assets/sounds/refresh.wav');
  }

  // ============================================================
  // APP-SPECIFIC SOUNDS
  // ============================================================

  /// Sound for starting recording
  Future<void> recordingStart() async {
    if (!_soundsEnabled) return;
    // Ascending tone to indicate start
    // await _playSound('assets/sounds/recording_start.wav');
  }

  /// Sound for stopping recording
  Future<void> recordingStop() async {
    if (!_soundsEnabled) return;
    // Descending tone to indicate stop
    // await _playSound('assets/sounds/recording_stop.wav');
  }

  /// Sound for saving a vibe
  Future<void> vibeSaved() async {
    await success();
  }

  /// Sound for deleting a vibe
  Future<void> vibeDeleted() async {
    if (!_soundsEnabled) return;
    // Soft deletion sound
    // await _playSound('assets/sounds/delete.wav');
  }

  /// Sound for unlocking premium
  Future<void> premiumUnlocked() async {
    if (!_soundsEnabled) return;
    // Celebratory chime
    // await _playSound('assets/sounds/premium_unlock.wav');
  }

  /// Sound for reaching a milestone/streak
  Future<void> milestone() async {
    if (!_soundsEnabled) return;
    // Celebration sound
    // await _playSound('assets/sounds/milestone.wav');
  }

  /// Sound for theme toggle
  Future<void> themeToggle() async {
    await tap();
  }

  /// Sound for biometric authentication success
  Future<void> biometricSuccess() async {
    await success();
  }

  /// Sound for biometric authentication failure
  Future<void> biometricFailure() async {
    await error();
  }

  /// Sound for calendar date selection
  Future<void> dateSelection() async {
    await tap();
  }

  /// Sound for audio play
  Future<void> audioPlay() async {
    if (!_soundsEnabled) return;
    // Play button sound
    // await _playSound('assets/sounds/play.wav');
  }

  /// Sound for audio pause
  Future<void> audioPause() async {
    if (!_soundsEnabled) return;
    // Pause button sound
    // await _playSound('assets/sounds/pause.wav');
  }

  /// Sound for audio skip
  Future<void> audioSkip() async {
    if (!_soundsEnabled) return;
    // Skip sound
    // await _playSound('assets/sounds/skip.wav');
  }

  // ============================================================
  // PRIVATE METHODS (for future implementation)
  // ============================================================

  /// Play a sound file from assets
  /// This is a placeholder for when actual sound files are added
  /*
  Future<void> _playSound(String assetPath) async {
    if (!_soundsEnabled) return;

    try {
      final player = AudioPlayer();
      await player.setVolume(_volume);
      await player.setAsset(assetPath);
      await player.play();

      // Dispose after playing
      player.dispose();
    } catch (e) {
      // Silently fail if sound can't be played
      debugPrint('Error playing sound: $e');
    }
  }
  */

  // ============================================================
  // UTILITY
  // ============================================================

  /// Play a test sound to preview volume
  Future<void> playTestSound() async {
    final wasEnabled = _soundsEnabled;
    _soundsEnabled = true; // Temporarily enable for test
    await tap();
    _soundsEnabled = wasEnabled; // Restore original state
  }
}
