// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_journal/features/journal/presentation/screens/vibe_detail_screen.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../journal/domain/models/vibe_model.dart';

class RecordingProgress {
  final Duration duration;
  final double normalizedDbLevel;
  RecordingProgress(this.duration, this.normalizedDbLevel);
}

enum AppRecordingState {
  uninitialized,
  initializing,
  ready,
  recording,
  stopped,
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  // --- Final Audio Engine ---
  late final AudioRecorder _recorder;
  late final ja.AudioPlayer _player;

  AppRecordingState _recordingState = AppRecordingState.uninitialized;
  String? _tempAudioPath;
  String? _currentlyPlayingOrLoadingId;

  final StreamController<RecordingProgress> _progressStreamController =
      StreamController.broadcast();
  StreamSubscription? _amplitudeSubscription;
  Timer? _durationTimer;
  Timer? _maxDurationTimer;

  Duration _duration = Duration.zero;
  Duration _playerPosition = Duration.zero;

  UserModel? _currentUserModel;
  bool _isSavingVibe = false;

  ja.PlayerState? _playerState;

  final double _silenceDbThreshold = -45.0;
  final double _maxDbThreshold = 0.0;

  AnimationController? _orbAnimationController;
  Animation<double>? _orbPulseAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _canVibrate = false;
  bool _showUpgradeBanner = false;
  static const String _bannerDismissedKey = 'upgradeBannerDismissedTimestamp';

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = ja.AudioPlayer();

    _initHaptics();
    _loadUserModelAndBannerState();
    _initAudio();
    _setupPlayerListeners();

    _orbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _orbPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _orbAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _maxDurationTimer?.cancel();
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _progressStreamController.close();
    _recorder.dispose();
    _player.dispose();
    _orbAnimationController?.dispose();
    super.dispose();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
      });
      if (state.processingState == ja.ProcessingState.completed) {
        setState(() {
          _currentlyPlayingOrLoadingId = null;
        });
      }
    });

    _player.positionStream.listen((position) {
      if (mounted) setState(() => _playerPosition = position);
    });
    _player.durationStream.listen((duration) {
      if (mounted) setState(() => _duration = duration ?? Duration.zero);
    });
  }

  Future<void> _handlePlayback(VibeModel vibe) async {
    if (await _recorder.isRecording()) return;

    final vibeId = vibe.id;
    final storagePath = vibe.audioPath;

    if (_player.playing && _currentlyPlayingOrLoadingId == vibeId) {
      await _player.pause();
      return;
    }
    if (!_player.playing && _currentlyPlayingOrLoadingId == vibeId) {
      _player.play();
      return;
    }

    _triggerHaptic(HapticsType.light);
    await _player.stop();

    setState(() {
      _currentlyPlayingOrLoadingId = vibeId;
      _playerPosition = Duration.zero;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final url = await storageRef.getDownloadURL();
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      if (kDebugMode) {
        print("Error playing file $storagePath: $e");
      }
      if (mounted) {
        setState(() => _currentlyPlayingOrLoadingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Could not play audio."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePreviewPlayback() async {
    if (_tempAudioPath == null) return;
    if (await _recorder.isRecording()) return;

    final previewId = "preview";

    if (_player.playing && _currentlyPlayingOrLoadingId == previewId) {
      await _player.pause();
      return;
    }
    if (!_player.playing && _currentlyPlayingOrLoadingId == previewId) {
      _player.play();
      return;
    }

    _triggerHaptic(HapticsType.light);
    await _player.stop();

    try {
      await _player.setFilePath(_tempAudioPath!);
      if (mounted) setState(() => _currentlyPlayingOrLoadingId = previewId);
      _player.play();
    } catch (e) {
      if (kDebugMode) {
        print("Error playing preview file $_tempAudioPath: $e");
      }
    }
  }

  Future<void> _initAudio() async {
    setState(() => _recordingState = AppRecordingState.initializing);
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      setState(() => _recordingState = AppRecordingState.uninitialized);
      return;
    }
    setState(() => _recordingState = AppRecordingState.ready);
  }

  Future<void> _startRecording() async {
    if (_currentUserModel == null) {
      _loadUserModelAndBannerState();
      return;
    }
    if (_player.playing) await _player.stop();
    // Reset state before starting a new recording
    _resetToReadyState();

    try {
      _triggerHaptic(HapticsType.medium);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'vibe_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.flac';
      _tempAudioPath = '${directory.path}/$fileName';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.flac, numChannels: 1),
        path: _tempAudioPath!,
      );

      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
            if (!mounted) return;
            final db = (amp.current).clamp(
              _silenceDbThreshold,
              _maxDbThreshold,
            );
            final normalizedDb =
                (db - _silenceDbThreshold) /
                (_maxDbThreshold - _silenceDbThreshold);
            _progressStreamController.add(
              RecordingProgress(_duration, normalizedDb),
            );
          });

      _duration = Duration.zero;
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration += const Duration(seconds: 1);
      });

      _orbAnimationController?.repeat(reverse: true);
      _maxDurationTimer?.cancel();
      final maxDuration = Duration(
        minutes: _currentUserModel!.maxRecordingDurationMinutes,
      );
      _maxDurationTimer = Timer(maxDuration, () {
        if (_recordingState == AppRecordingState.recording) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recording limit of ${_currentUserModel!.maxRecordingDurationMinutes} min reached.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          _stopRecording();
        }
      });

      if (!mounted) return;
      setState(() {
        _recordingState = AppRecordingState.recording;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error starting recorder: $e");
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!(await _recorder.isRecording())) return;
    _maxDurationTimer?.cancel();
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    _triggerHaptic(HapticsType.medium);
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      _progressStreamController.add(RecordingProgress(_duration, 0.0));
      setState(() {
        _recordingState = AppRecordingState.stopped;
        _tempAudioPath = path;
      });
    } catch (e) {
      if (mounted) setState(() => _recordingState = AppRecordingState.ready);
    }
  }

  Future<void> _saveVibe() async {
    if (_tempAudioPath == null || _currentUserModel == null) return;
    if (_currentUserModel!.cloudVibeCount >= _currentUserModel!.maxCloudVibes) {
      _triggerHaptic(HapticsType.warning);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Cloud Storage Full',
            style: TextStyle(color: AppColors.primary),
          ),
          content: Text(
            'You\'ve reached your limit of ${_currentUserModel!.maxCloudVibes} saved vibes. Upgrade for unlimited storage!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.textHint),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upgrade screen coming soon!')),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _isSavingVibe = true);
    _triggerHaptic(HapticsType.medium);
    final String fileName = _tempAudioPath!.split('/').last;
    final File fileToUpload = File(_tempAudioPath!);
    final UploadTask uploadTask = FirebaseStorage.instance
        .ref()
        .child('vibes/${_currentUserModel!.uid}/$fileName')
        .putFile(fileToUpload);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Uploading Vibe...',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: StreamBuilder<TaskSnapshot>(
          stream: uploadTask.snapshotEvents,
          builder: (context, snapshot) {
            double progress = 0.0;
            String progressText = "Preparing upload...";
            if (snapshot.hasData) {
              final data = snapshot.data!;
              progress = data.bytesTransferred / data.totalBytes;
              final transferredMB = (data.bytesTransferred / (1024 * 1024))
                  .toStringAsFixed(1);
              final totalMB = (data.totalBytes / (1024 * 1024)).toStringAsFixed(
                1,
              );
              progressText =
                  "${(progress * 100).toStringAsFixed(0)}%  ($transferredMB MB / $totalMB MB)";
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.inputFill,
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 20),
                Text(
                  progressText,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
    try {
      final TaskSnapshot snapshot = await uploadTask;
      final String storagePath = snapshot.ref.fullPath;
      if (!mounted) return;
      Navigator.of(context).pop();
      final vibeData = {
        'userId': _currentUserModel!.uid,
        'audioPath': storagePath,
        'fileName': fileName,
        'duration': _duration.inMilliseconds,
        'createdAt': Timestamp.now(),
        'transcription': '',
        'mood': '',
      };
      await _firestore.collection('vibes').add(vibeData);
      final userDocRef = _firestore
          .collection('users')
          .doc(_currentUserModel!.uid);
      await userDocRef.update({'cloudVibeCount': FieldValue.increment(1)});
      final updatedUserDoc = await userDocRef.get();
      if (updatedUserDoc.exists && mounted) {
        final updatedUserModel = UserModel.fromFirestore(updatedUserDoc);
        registerUserSession(updatedUserModel);
        setState(() {
          _currentUserModel = updatedUserModel;
        });
      }
      try {
        if (await fileToUpload.exists()) await fileToUpload.delete();
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting local temp file: $e');
        }
      }
      _triggerHaptic(HapticsType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Awesome! Your vibe is saved to the cloud.',
            style: TextStyle(color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      if (!mounted) return;
      _resetToReadyState();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _triggerHaptic(HapticsType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vibe: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingVibe = false);
    }
  }

  void _discardRecording() {
    _maxDurationTimer?.cancel();
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _triggerHaptic(HapticsType.selection);
    if (_tempAudioPath != null) {
      final file = File(_tempAudioPath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (e) {
          if (kDebugMode) {
            print("Error deleting file: $e");
          }
        }
      }
    }
    if (!mounted) return;
    _resetToReadyState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vibe draft discarded.'),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _resetToReadyState() {
    _orbAnimationController?.stop();
    _orbAnimationController?.reset();
    _progressStreamController.add(RecordingProgress(Duration.zero, 0.0));
    if (!mounted) return;
    setState(() {
      _recordingState = AppRecordingState.ready;
      _tempAudioPath = null;
      _duration = Duration.zero;
      _playerPosition = Duration.zero;
      _currentlyPlayingOrLoadingId = null;
    });
  }

  Future<void> _loadUserModelAndBannerState() async {
    if (locator.isRegistered<UserModel>()) {
      final userModel = locator<UserModel>();
      if (!mounted) return;
      setState(() {
        _currentUserModel = userModel;
      });
      if (userModel.plan == 'free') _checkShowUpgradeBanner();
    } else {
      final currentUserAuth = FirebaseAuth.instance.currentUser;
      if (currentUserAuth != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserAuth.uid)
            .get();
        if (userDoc.exists) {
          final model = UserModel.fromFirestore(userDoc);
          registerUserSession(model);
          if (!mounted) return;
          setState(() {
            _currentUserModel = model;
          });
          if (model.plan == 'free') _checkShowUpgradeBanner();
        } else {
          FirebaseAuth.instance.signOut();
          clearUserSession();
        }
      }
    }
  }

  Future<void> _checkShowUpgradeBanner() async {
    final preferences = await SharedPreferences.getInstance();
    final lastDismissedTimestamp = preferences.getInt(_bannerDismissedKey);
    if (lastDismissedTimestamp == null ||
        DateTime.now().millisecondsSinceEpoch - lastDismissedTimestamp >
            const Duration(days: 3).inMilliseconds) {
      if (mounted) {
        setState(() {
          _showUpgradeBanner = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _showUpgradeBanner = false;
        });
      }
    }
  }

  Future<void> _dismissUpgradeBanner() async {
    await _triggerHaptic(HapticsType.selection);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _bannerDismissedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (mounted) {
      setState(() {
        _showUpgradeBanner = false;
      });
    }
  }

  Future<void> _initHaptics() async {
    _canVibrate = await Haptics.canVibrate();
  }

  Future<void> _triggerHaptic(HapticsType type) async {
    if (_canVibrate) await Haptics.vibrate(type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_currentUserModel == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: <Widget>[
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                    child: Text(
                      'Hey ${_currentUserModel!.fullName?.split(" ").first ?? 'Viber'},',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    _getStatusMessage(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  _buildUpgradeBanner(theme),
                ],
              ),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreamBuilder<RecordingProgress>(
                      stream: _progressStreamController.stream,
                      initialData: RecordingProgress(Duration.zero, 0.0),
                      builder: (context, snapshot) {
                        final progress =
                            snapshot.data ??
                            RecordingProgress(Duration.zero, 0.0);
                        return _buildVibeOrbUI(theme, progress);
                      },
                    ),
                    // const SizedBox(height: 10),
                    _buildActionButtons(theme),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                        bottom: 8.0,
                        top: 10.0,
                      ),
                      child: Text(
                        "Recent Vibes",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: _buildVibesList(theme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeOrbUI(ThemeData theme, RecordingProgress progress) {
    IconData icon;
    Color orbColor;
    VoidCallback? onPressed;
    double orbSize = 140;
    bool isPulsing =
        _recordingState == AppRecordingState.recording || _player.playing;

    if (isPulsing && !(_orbAnimationController?.isAnimating ?? false)) {
      _orbAnimationController?.repeat(reverse: true);
    } else if (!isPulsing && (_orbAnimationController?.isAnimating ?? false)) {
      _orbAnimationController?.stop();
      _orbAnimationController?.reset();
    }

    switch (_recordingState) {
      case AppRecordingState.ready:
        icon = Icons.graphic_eq_rounded;
        orbColor = AppColors.secondary;
        onPressed = _startRecording;
        break;
      case AppRecordingState.recording:
        icon = Icons.stop_circle_outlined;
        orbColor = AppColors.error;
        onPressed = _stopRecording;
        break;
      case AppRecordingState.stopped:
        icon = Icons.play_circle_outline_rounded;
        orbColor = AppColors.primary;
        onPressed = _handlePreviewPlayback;
        break;
      default:
        icon = Icons.mic_off_rounded;
        orbColor = Colors.grey.shade800;
        onPressed = _initAudio;
    }

    Duration currentDisplayDuration =
        _recordingState == AppRecordingState.recording
        ? progress.duration
        : _playerPosition;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                    color: orbColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius:
                        (_recordingState == AppRecordingState.recording
                                ? (5.0 + progress.normalizedDbLevel * 15.0)
                                : 7.0)
                            .clamp(7.0, 20.0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: orbSize * 0.5,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _formatDuration(currentDisplayDuration.inMilliseconds),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (_player.playing)
          Text(
            "of ${_formatDuration(_duration.inMilliseconds)}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.only(top: 15),
          height: 8,
          width: _recordingState == AppRecordingState.recording
              ? (progress.normalizedDbLevel * 130.0).clamp(0.0, 130.0)
              : 0.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.5),
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    bool showActions = _recordingState == AppRecordingState.stopped;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: showActions ? 1.0 : 0.0,
      child: showActions
          ? Padding(
              padding: const EdgeInsets.only(top: 25.0, bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: "Discard",
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.textHint,
                      ),
                      iconSize: 32,
                      onPressed: _discardRecording,
                    ),
                  ),
                  const SizedBox(width: 25),
                  ElevatedButton.icon(
                    icon: _isSavingVibe
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 22),
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
                    onPressed: _isSavingVibe ? null : _saveVibe,
                  ),
                  const SizedBox(width: 25),
                  Tooltip(
                    message: "Re-record",
                    child: IconButton(
                      icon: const Icon(
                        Icons.replay_rounded,
                        color: AppColors.textHint,
                      ),
                      iconSize: 32,
                      onPressed: () {
                        _triggerHaptic(HapticsType.selection);
                        _discardRecording();
                      },
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(height: 79),
    );
  }

  Widget _buildVibesList(ThemeData theme) {
    if (_currentUserModel == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vibes')
          .where('userId', isEqualTo: _currentUserModel!.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Text(
                "Your 5 most recent vibes will appear here.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          );
        }

        final vibes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: vibes.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final vibe = VibeModel.fromFirestore(
              vibes[index] as DocumentSnapshot<Map<String, dynamic>>,
            );
            final bool isActive = _currentlyPlayingOrLoadingId == vibe.id;
            final bool isLoading =
                isActive &&
                (_playerState?.processingState == ja.ProcessingState.loading ||
                    _playerState?.processingState ==
                        ja.ProcessingState.buffering);
            final bool isPlaying = isActive && _playerState?.playing == true;

            Widget trailingWidget;
            if (isLoading) {
              trailingWidget = const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              );
            } else if (isPlaying) {
              trailingWidget = IconButton(
                icon: const Icon(
                  Icons.pause_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                onPressed: () => _handlePlayback(vibe),
              );
            } else {
              trailingWidget = IconButton(
                icon: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
                onPressed: () => _handlePlayback(vibe),
              );
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VibeDetailScreen(vibe: vibe),
                  ),
                ),
                leading: Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.moodColors[vibe.mood] ?? AppColors.textHint,
                  size: 30,
                ),
                title: Text(
                  DateFormat(
                    'MMM d, yy - hh:mm a',
                  ).format(vibe.createdAt.toDate()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  vibe.transcription.isEmpty
                      ? 'Duration: ${_formatDuration(vibe.duration)}'
                      : '"${vibe.transcription}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                trailing: trailingWidget,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpgradeBanner(ThemeData theme) {
    if (_currentUserModel?.plan == 'free' && _showUpgradeBanner) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_purple500_outlined,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Go Premium!",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Unlock unlimited vibes & longer recordings.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              child: const Text(
                "Upgrade",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _triggerHaptic(HapticsType.light);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upgrade screen coming soon!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 20,
                color: AppColors.textHint,
              ),
              onPressed: _dismissUpgradeBanner,
              tooltip: "Dismiss",
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: const SizedBox.shrink(),
    );
  }

  String _formatDuration(int milliseconds) {
    final d = Duration(milliseconds: milliseconds);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getStatusMessage() {
    switch (_recordingState) {
      case AppRecordingState.uninitialized:
        return "Audio system unavailable.";
      case AppRecordingState.initializing:
        return "Warming up the mic...";
      case AppRecordingState.ready:
        return "Ready to capture your vibe?";
      case AppRecordingState.recording:
        return "Listening closely...";
      case AppRecordingState.stopped:
        return "Vibe captured! What's next?";
    }
  }
}
