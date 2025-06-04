// lib/features/journal/presentation/screens/journal_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_haptic_feedback/flutter_haptic_feedback.dart';

import '../../../../config/theme/app_colors.dart';

enum RecordingState {
  uninitialized,
  initializing,
  ready,
  recording,
  stopped,
  playing,
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  RecordingState _recordingState = RecordingState.uninitialized;
  String? _tempAudioPath;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;

  double _normalizedDbLevel = 0.0;
  Duration _duration = Duration.zero;
  Duration _playerPosition = Duration.zero;

  String _userFullName = "Viber"; // Default, will be fetched
  final double _silenceDbThreshold = -70.0;
  final double _maxDbThreshold = 0.0;

  AnimationController? _orbAnimationController;
  Animation<double>? _orbPulseAnimation;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _fetchUserFullName();
    _initAudio();

    _orbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _orbPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _orbAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _fetchUserFullName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists &&
            doc.data() != null &&
            doc.data()!['fullName'] != null) {
          if (!mounted) return;
          setState(() {
            _userFullName = doc.data()!['fullName'];
          });
        } else {
          if (!mounted) return;
          setState(() {
            _userFullName = user.email ?? "Viber";
          });
        }
      } catch (e) {
        print("Error fetching user's full name: $e");
        if (!mounted) return;
        setState(() {
          _userFullName = user.email ?? "Viber";
        });
      }
    }
  }

  Future<void> _initAudio() async {
    if (!mounted) return;
    setState(() => _recordingState = RecordingState.initializing);
    var microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      microphoneStatus = await Permission.microphone.request();
      if (!mounted) return;
      if (!microphoneStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is crucial to record your vibes.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _recordingState = RecordingState.uninitialized);
        return;
      }
    }

    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );
      if (!mounted) return;
      setState(() => _recordingState = RecordingState.ready);
    } catch (e) {
      print("Error initializing audio: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio system error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _recordingState = RecordingState.uninitialized);
    }
  }

  Future<void> _startRecording() async {
    if (_recordingState != RecordingState.ready &&
        _recordingState != RecordingState.stopped)
      return;
    if (!await Permission.microphone.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission needed.'),
          backgroundColor: AppColors.error,
        ),
      );
      _initAudio();
      return;
    }
    try {
      FlutterHapticFeedback.impact(ImpactFeedbackStyle.medium);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'vibe_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.aac';
      _tempAudioPath = '${directory.path}/$fileName';

      await _recorder!.startRecorder(
        toFile: _tempAudioPath,
        codec: Codec.aacMP4,
      );
      _recorderSubscription?.cancel();
      _recorderSubscription = _recorder!.onProgress!.listen((e) {
        if (!mounted) return;
        setState(() {
          _duration = e.duration;
          if (e.decibels != null) {
            double db = (e.decibels!).clamp(
              _silenceDbThreshold,
              _maxDbThreshold,
            );
            _normalizedDbLevel =
                (db - _silenceDbThreshold) /
                (_maxDbThreshold - _silenceDbThreshold);
          } else {
            _normalizedDbLevel = 0.0;
          }
        });
      });
      _orbAnimationController?.repeat(reverse: true);
      if (!mounted) return;
      setState(() {
        _recordingState = RecordingState.recording;
        _duration = Duration.zero;
        _playerPosition = Duration.zero;
        _normalizedDbLevel = 0.0;
      });
    } catch (e) {
      print("Error starting recorder: $e");
      _orbAnimationController?.stop();
      _orbAnimationController?.reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start recording: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _recordingState = RecordingState.ready);
    }
  }

  Future<void> _stopRecording() async {
    if (_recordingState != RecordingState.recording) return;
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    FlutterHapticFeedback.impact(ImpactFeedbackStyle.medium);
    try {
      await _recorder!.stopRecorder();
      _recorderSubscription?.cancel();
      _recorderSubscription = null;
      if (!mounted) return;
      setState(() {
        _recordingState = RecordingState.stopped;
        _normalizedDbLevel = 0.0;
      });
    } catch (e) {
      print("Error stopping recorder: $e");
      if (!mounted) return;
      setState(() => _recordingState = RecordingState.ready);
    }
  }

  Future<void> _playPreview() async {
    if (_recordingState != RecordingState.stopped || _tempAudioPath == null)
      return;
    FlutterHapticFeedback.impact(ImpactFeedbackStyle.light);
    try {
      await _player!.startPlayer(
        fromURI: _tempAudioPath!,
        codec: Codec.aacMP4,
        whenFinished: () {
          if (!mounted) return;
          _orbAnimationController?.stop();
          _orbAnimationController?.reset();
          setState(() {
            _recordingState = RecordingState.stopped;
            _playerPosition = Duration.zero;
          });
        },
      );
      _playerSubscription?.cancel();
      _playerSubscription = _player!.onProgress!.listen((e) {
        if (!mounted) return;
        setState(() {
          _playerPosition = e.position;
          _duration = e.duration;
        });
      });
      _orbAnimationController?.repeat(reverse: true);
      if (!mounted) return;
      setState(() => _recordingState = RecordingState.playing);
    } catch (e) {
      print("Error playing preview: $e");
      _orbAnimationController?.stop();
      _orbAnimationController?.reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play preview: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopPreview() async {
    if (_recordingState != RecordingState.playing) return;
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    FlutterHapticFeedback.impact(ImpactFeedbackStyle.light);
    try {
      await _player!.stopPlayer();
      _playerSubscription?.cancel();
      _playerSubscription = null;
      if (!mounted) return;
      setState(() {
        _recordingState = RecordingState.stopped;
      });
    } catch (e) {
      print("Error stopping preview: $e");
    }
  }

  void _discardRecording() {
    FlutterHapticFeedback.selection();
    if (_tempAudioPath != null) {
      final file = File(_tempAudioPath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (e) {
          print("Error deleting file: $e");
        }
      }
    }
    if (!mounted) return;
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    setState(() {
      _recordingState = RecordingState.ready;
      _tempAudioPath = null;
      _duration = Duration.zero;
      _playerPosition = Duration.zero;
      _normalizedDbLevel = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vibe draft discarded.'),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _saveVibe() {
    if (_tempAudioPath == null) return;
    FlutterHapticFeedback.impact(ImpactFeedbackStyle.heavy);
    print('Vibe to be saved: $_tempAudioPath, Duration: $_duration');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Awesome! Your vibe is captured.',
          style: TextStyle(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
    if (!mounted) return;
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    setState(() {
      _recordingState = RecordingState.ready;
      _tempAudioPath = null;
      _duration = Duration.zero;
      _playerPosition = Duration.zero;
      _normalizedDbLevel = 0.0;
    });
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _playerSubscription?.cancel();
    _recorder?.closeRecorder().catchError(
      (e) => print("Recorder Close Error: $e"),
    );
    _player?.closePlayer().catchError((e) => print("Player Close Error: $e"));
    _recorder = null;
    _player = null;
    _orbAnimationController?.dispose();
    super.dispose();
  }

  Widget _buildVibeOrb(ThemeData theme) {
    IconData icon;
    Color orbColor;
    VoidCallback? onPressed;
    double orbSize = 160;
    bool isPulsing =
        _recordingState == RecordingState.recording ||
        _recordingState == RecordingState.playing;

    if (isPulsing && !(_orbAnimationController?.isAnimating ?? false)) {
      _orbAnimationController?.repeat(reverse: true);
    } else if (!isPulsing && (_orbAnimationController?.isAnimating ?? false)) {
      _orbAnimationController?.stop();
      _orbAnimationController?.reset();
    }

    switch (_recordingState) {
      case RecordingState.ready:
        icon = Icons.graphic_eq_rounded;
        orbColor = AppColors.secondary;
        onPressed = _startRecording;
        break;
      case RecordingState.recording:
        icon = Icons.stop_circle_outlined;
        orbColor = AppColors.error;
        onPressed = _stopRecording;
        break;
      case RecordingState.stopped:
        icon = Icons.play_circle_outline_rounded;
        orbColor = AppColors.primary;
        onPressed = _playPreview;
        break;
      case RecordingState.playing:
        icon = Icons.pause_circle_outline_rounded;
        orbColor = AppColors.primary.withOpacity(0.9);
        onPressed = _stopPreview;
        break;
      case RecordingState.initializing:
        icon = Icons.hourglass_empty_rounded;
        orbColor = Colors.grey.shade600;
        onPressed = null;
        break;
      case RecordingState.uninitialized:
      default:
        icon = Icons.mic_off_rounded;
        orbColor = Colors.grey.shade800;
        onPressed = _initAudio;
    }

    return Column(
      children: [
        ScaleTransition(
          scale: _orbPulseAnimation ?? const AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orbColor,
                boxShadow: [
                  BoxShadow(
                    color: orbColor.withOpacity(0.5),
                    blurRadius: 25,
                    // Use normalizedDbLevel for dynamic spread only when recording
                    spreadRadius:
                        (_recordingState == RecordingState.recording
                                ? (5.0 + _normalizedDbLevel * 20.0)
                                : 8.0)
                            .clamp(8.0, 25.0),
                  ),
                ],
              ),
              child: onPressed == null
                  ? Center(
                      child: SizedBox(
                        width: orbSize * 0.4,
                        height: orbSize * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.onSecondary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        icon,
                        size: orbSize * 0.55,
                        color: AppColors.onSecondary,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          _formatDuration(
            _recordingState == RecordingState.playing
                ? _playerPosition
                : _duration,
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        // Simple visualizer bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.only(top: 20),
          height: 10,
          width: _recordingState == RecordingState.recording
              ? (_normalizedDbLevel * 150.0).clamp(0.0, 150.0)
              : 0.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.5),
                AppColors.secondary,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    bool showActions =
        _recordingState == RecordingState.stopped ||
        _recordingState == RecordingState.playing;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showActions ? 1.0 : 0.0,
      child: showActions
          ? Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Discard',
                    onPressed: _discardRecording,
                    color: AppColors.textHint,
                    theme: theme,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_rounded, size: 20),
                    label: const Text('Save Vibe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _saveVibe,
                  ),
                  _buildActionButton(
                    icon: Icons.replay_circle_filled_outlined,
                    label: 'Re-record',
                    onPressed: () {
                      _discardRecording();
                    },
                    color: AppColors.textHint,
                    theme: theme,
                  ),
                ],
              ),
            )
          : const SizedBox(height: 74), // Maintain space to avoid layout jumps
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    required Color color,
    required ThemeData theme,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 24, color: color),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getStatusMessage() {
    switch (_recordingState) {
      case RecordingState.uninitialized:
        return "Audio system unavailable. Tap mic to retry.";
      case RecordingState.initializing:
        return "Warming up the mic...";
      case RecordingState.ready:
        return "Ready to catch your vibe?";
      case RecordingState.recording:
        return "Listening closely...";
      case RecordingState.stopped:
        return "Vibe captured! What's next?";
      case RecordingState.playing:
        return "Here's your vibe back...";
      default:
        return "Let's record a vibe!";
    }
  }

  Future<String> _getUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    const String defaultName = "Viber"; // Default if no name found

    if (user == null) {
      return defaultName; // No user logged in
    }

    try {
      // Ensure Firestore instance is available
      // DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      // For a more robust way if using an older Firestore version or for clarity:
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        // Cast data to Map<String, dynamic> to access fields
        final data = doc.data() as Map<String, dynamic>;
        final String? fullName = data['fullName'] as String?;

        if (fullName != null && fullName.isNotEmpty) {
          // Return just the first name for a more casual greeting
          return fullName.split(" ").first;
        }
      }
      // Fallback to email's user part if fullName is not found or empty
      if (user.email != null && user.email!.isNotEmpty) {
        return user.email!.split("@").first;
      }
    } catch (e) {
      print("Error fetching user's display name from Firestore: $e");
      // Fallback in case of error
      if (user.email != null && user.email!.isNotEmpty) {
        return user.email!.split("@").first;
      }
    }

    return defaultName; // Absolute fallback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 5.0),
                child: FutureBuilder<String?>(
                  future: _getUserDisplayName(),
                  builder: (context, _) {
                    return Text(
                      'Hey ${_userFullName.split(" ").first},', // Just first name
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
              Text(
                _getStatusMessage(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
              _buildVibeOrb(theme),
              const Spacer(flex: 1),
              _buildActionButtons(theme),
              const Expanded(flex: 2, child: SizedBox.shrink()),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TextButton(
                    // Simpler logout, less prominent
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.textHint.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () async {
                      if (_recordingState == RecordingState.recording)
                        await _stopRecording();
                      if (_recordingState == RecordingState.playing)
                        await _stopPreview();
                      _discardRecording();
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
