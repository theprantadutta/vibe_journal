// lib/features/journal/presentation/screens/journal_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_animations.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/snackbar_utils.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../journal/domain/models/vibe_model.dart';
import '../../../premium/presentation/screens/premium_features_screen.dart';
import '../../data/repositories/vibe_repository.dart';
import 'vibe_detail_screen.dart';

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
    with TickerProviderStateMixin {
  // Audio Engine
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
  final _userService = locator<UserService>();
  final _vibeRepository = locator<VibeRepository>();
  final _hapticService = HapticService();
  bool _isSavingVibe = false;

  ja.PlayerState? _playerState;

  final double _silenceDbThreshold = -45.0;
  final double _maxDbThreshold = 0.0;

  // Animations
  late AnimationController _orbAnimationController;
  late Animation<double> _orbPulseAnimation;
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  final _firestore = FirebaseFirestore.instance;
  bool _showUpgradeBanner = false;
  static const String _bannerDismissedKey = 'upgrade_banner_dismissed';

  // Vibes list state
  List<VibeModel> _recentVibes = [];
  bool _isLoadingVibes = false;
  Timer? _vibesPollingTimer;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = ja.AudioPlayer();

    // Setup animations
    _orbAnimationController = AnimationController(
      vsync: this,
      duration: AppAnimations.orbPulse,
    );
    _orbPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _orbAnimationController, curve: Curves.easeInOut),
    );

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _player.positionStream.listen((position) {
      if (mounted) setState(() => _playerPosition = position);
    });

    _initAudio();
    _loadUserModelAndBannerState();
    _startVibesPolling();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _orbAnimationController.dispose();
    _glowAnimationController.dispose();
    _progressStreamController.close();
    _amplitudeSubscription?.cancel();
    _durationTimer?.cancel();
    _maxDurationTimer?.cancel();
    _vibesPollingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    if (_recordingState != AppRecordingState.uninitialized) return;

    setState(() => _recordingState = AppRecordingState.initializing);

    if (await Permission.microphone.request().isGranted) {
      setState(() => _recordingState = AppRecordingState.ready);
    } else {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Microphone permission is required to record vibes.',
        );
        setState(() => _recordingState = AppRecordingState.uninitialized);
      }
    }
  }

  Future<void> _startRecording() async {
    if (_recordingState != AppRecordingState.ready) return;

    await _hapticService.recordingStart();

    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath =
        '${tempDir.path}/temp_vibe_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final config = RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100);

    try {
      await _recorder.start(config, path: tempPath);
      if (!mounted) return;

      setState(() {
        _recordingState = AppRecordingState.recording;
        _tempAudioPath = tempPath;
        _duration = Duration.zero;
      });

      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _duration += const Duration(milliseconds: 100);
        _progressStreamController.add(RecordingProgress(_duration, 0.0));
      });

      _amplitudeSubscription = _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 150),
      ).listen((amp) {
        final double normalized = _normalizeDb(amp.current);
        _progressStreamController.add(RecordingProgress(_duration, normalized));
      });

      final maxDurationMs = (_userService.isPremium ? 60 : 5) * 60 * 1000;
      _maxDurationTimer = Timer(Duration(milliseconds: maxDurationMs), () {
        if (_recordingState == AppRecordingState.recording) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, message: 'Failed to start recording: $e');
        setState(() => _recordingState = AppRecordingState.ready);
      }
    }
  }

  double _normalizeDb(double db) {
    return ((db - _silenceDbThreshold) / (_maxDbThreshold - _silenceDbThreshold))
        .clamp(0.0, 1.0);
  }

  Future<void> _stopRecording() async {
    if (_recordingState != AppRecordingState.recording) return;

    await _hapticService.recordingStop();

    await _recorder.stop();
    _amplitudeSubscription?.cancel();
    _durationTimer?.cancel();
    _maxDurationTimer?.cancel();

    if (!mounted) return;
    setState(() => _recordingState = AppRecordingState.stopped);
  }

  Future<void> _handlePreviewPlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_tempAudioPath != null) {
      try {
        await _player.setFilePath(_tempAudioPath!);
        await _player.play();
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, message: 'Failed to play preview: $e');
        }
      }
    }
  }

  Future<void> _saveVibe() async {
    if (_tempAudioPath == null || _currentUserModel == null || _isSavingVibe) return;

    setState(() => _isSavingVibe = true);
    await _hapticService.vibeSaved();

    try {
      final fileName = 'vibe_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final audioFile = File(_tempAudioPath!);

      // Premium users: Upload to cloud and sync
      if (_userService.isPremium) {
        // Upload audio file to backend
        final uploadResponse = await _vibeRepository.uploadAudioFile(audioFile);

        if (!uploadResponse.isSuccess || uploadResponse.data == null) {
          throw Exception(uploadResponse.error ?? 'Failed to upload audio');
        }

        final audioPath = uploadResponse.data!;

        // Create vibe entry on backend
        final createResponse = await _vibeRepository.createVibe(
          audioPath: audioPath,
          fileName: fileName,
          durationMs: _duration.inMilliseconds,
        );

        if (!createResponse.isSuccess) {
          throw Exception(createResponse.error ?? 'Failed to create vibe');
        }

        // Fetch updated user profile from backend
        await _userService.fetchAndUpdateUser();

        // Update local user model
        if (_userService.isUserLoggedIn) {
          if (mounted) {
            setState(() => _currentUserModel = _userService.currentUser);
          }
        }

        // Delete temporary audio file after successful upload
        try {
          await audioFile.delete();
        } catch (_) {}

        if (mounted) {
          SnackBarUtils.showSuccess(context, message: 'Vibe saved and synced to cloud!');
          _resetToReadyState();
          _fetchRecentVibes();
        }
      }
      // Free users: Save locally only
      else {
        // Move temp file to permanent location
        final appDir = await getApplicationDocumentsDirectory();
        final vibesDir = Directory('${appDir.path}/vibes');
        if (!vibesDir.existsSync()) {
          vibesDir.createSync(recursive: true);
        }

        final permanentPath = '${vibesDir.path}/$fileName';
        await audioFile.copy(permanentPath);

        // Delete temp file
        try {
          await audioFile.delete();
        } catch (_) {}

        // Save to local database
        final saveResponse = await _vibeRepository.saveVibeLocally(
          audioFile: File(permanentPath),
          fileName: fileName,
          durationMs: _duration.inMilliseconds,
          userId: _currentUserModel!.id,
        );

        if (!saveResponse.isSuccess) {
          throw Exception(saveResponse.error ?? 'Failed to save vibe locally');
        }

        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            message: 'Vibe saved locally! Upgrade to Premium for cloud sync.',
          );
          _resetToReadyState();
          _fetchRecentVibes();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, message: 'Failed to save vibe: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingVibe = false);
    }
  }

  Future<void> _discardRecording() async {
    await _player.stop();
    if (_tempAudioPath != null) {
      try {
        await File(_tempAudioPath!).delete();
      } catch (_) {}
    }
    if (!mounted) return;
    _resetToReadyState();
    SnackBarUtils.showInfo(context, message: 'Vibe draft discarded');
  }

  void _resetToReadyState() {
    _orbAnimationController.stop();
    _orbAnimationController.reset();
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
      await locator<UserService>().updateUser(userModel);
      if (!mounted) return;
      setState(() => _currentUserModel = userModel);
      if (!_userService.isPremium) _checkShowUpgradeBanner();
    } else {
      final currentUserAuth = FirebaseAuth.instance.currentUser;
      if (currentUserAuth != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUserAuth.uid).get();
        final userService = locator<UserService>();
        if (userDoc.exists) {
          final model = UserModel.fromFirestore(userDoc);
          await userService.updateUser(model);
          if (!mounted) return;
          setState(() => _currentUserModel = model);
          if (!_userService.isPremium) _checkShowUpgradeBanner();
        } else {
          FirebaseAuth.instance.signOut();
          userService.clearUser();
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
      if (mounted) setState(() => _showUpgradeBanner = true);
    } else {
      if (mounted) setState(() => _showUpgradeBanner = false);
    }
  }

  void _startVibesPolling() {
    // Initial fetch
    _fetchRecentVibes();

    // Poll every 60 seconds
    _vibesPollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _fetchRecentVibes();
    });
  }

  Future<void> _fetchRecentVibes() async {
    if (_isLoadingVibes) return;

    // Only show loading state if we don't have any vibes yet
    if (_recentVibes.isEmpty) {
      setState(() => _isLoadingVibes = true);
    }

    try {
      // Premium users: Fetch from backend (which also caches locally)
      // Free users: Fetch from local storage only
      final response = _userService.isPremium
          ? await _vibeRepository.fetchVibes(page: 1, pageSize: 5)
          : await _vibeRepository.getLocalVibes();

      if (response.isSuccess && response.data != null) {
        if (mounted) {
          // Take only first 5 vibes for the recent list
          final vibes = response.data!;
          setState(() {
            _recentVibes = vibes.take(5).toList();
            _isLoadingVibes = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingVibes = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVibes = false);
    }
  }

  Future<void> _dismissUpgradeBanner() async {
    await _hapticService.light();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _bannerDismissedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (mounted) setState(() => _showUpgradeBanner = false);
  }

  String _getStatusMessage() {
    switch (_recordingState) {
      case AppRecordingState.ready:
        return 'Tap to start recording';
      case AppRecordingState.recording:
        return 'Recording your vibe...';
      case AppRecordingState.stopped:
        return 'Preview your vibe';
      default:
        return 'Initializing...';
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handlePlayback(VibeModel vibe) async {
    await _hapticService.audioPlayPause();

    if (_currentlyPlayingOrLoadingId == vibe.id && _player.playing) {
      await _player.pause();
      setState(() => _currentlyPlayingOrLoadingId = null);
      return;
    }

    if (_currentlyPlayingOrLoadingId != vibe.id) {
      setState(() => _currentlyPlayingOrLoadingId = vibe.id);
      try {
        await _player.setUrl(vibe.audioPath);
        await _player.play();
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, message: 'Failed to play vibe');
          setState(() => _currentlyPlayingOrLoadingId = null);
        }
      }
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_currentUserModel == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.getPrimary(isDark),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Greeting
                _buildGreeting(theme, isDark),

                // Upgrade Banner
                if (_showUpgradeBanner) _buildUpgradeBanner(theme, isDark),

                const SizedBox(height: AppSpacing.xl),

                // The Orb
                _buildEnhancedOrb(theme, isDark),

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                _buildActionButtons(theme, isDark),

                const SizedBox(height: AppSpacing.xxxl),

                // Recent Vibes
                _buildRecentVibesSection(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Hey ${_currentUserModel!.fullName?.split(" ").first ?? 'Viber'},',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _getStatusMessage(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.getTextPrimary(isDark),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildUpgradeBanner(ThemeData theme, bool isDark) {
    return AnimatedCard(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      gradient: AppColors.primaryGradient,
      onTap: () {
        _hapticService.light();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen()),
        );
      },
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: AppColors.darkOnPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.darkOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Unlock unlimited vibes & AI insights',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.darkOnPrimary),
            onPressed: _dismissUpgradeBanner,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildEnhancedOrb(ThemeData theme, bool isDark) {
    return StreamBuilder<RecordingProgress>(
      stream: _progressStreamController.stream,
      initialData: RecordingProgress(Duration.zero, 0.0),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? RecordingProgress(Duration.zero, 0.0);

        IconData icon;
        Color orbColor;
        VoidCallback? onPressed;
        bool isPulsing = _recordingState == AppRecordingState.recording ||
            _player.playing;

        if (isPulsing && !_orbAnimationController.isAnimating) {
          _orbAnimationController.repeat(reverse: true);
        } else if (!isPulsing && _orbAnimationController.isAnimating) {
          _orbAnimationController.stop();
          _orbAnimationController.reset();
        }

        switch (_recordingState) {
          case AppRecordingState.ready:
            icon = Icons.mic_rounded;
            orbColor = AppColors.getSecondary(isDark);
            onPressed = _startRecording;
            break;
          case AppRecordingState.recording:
            icon = Icons.stop_circle_rounded;
            orbColor = AppColors.getError(isDark);
            onPressed = _stopRecording;
            break;
          case AppRecordingState.stopped:
            icon = Icons.play_arrow_rounded;
            orbColor = AppColors.getPrimary(isDark);
            onPressed = _handlePreviewPlayback;
            break;
          default:
            icon = Icons.mic_off_rounded;
            orbColor = AppColors.getTextSecondary(isDark).withValues(alpha: 0.4);
            onPressed = _initAudio;
        }

        final currentDisplayDuration = _recordingState == AppRecordingState.recording
            ? progress.duration
            : _playerPosition;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Orb with glow
            ScaleTransition(
              scale: _orbPulseAnimation,
              child: GestureDetector(
                onTap: () {
                  _hapticService.medium();
                  onPressed?.call();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    if (_recordingState == AppRecordingState.recording)
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200 + (progress.normalizedDbLevel * 40),
                            height: 200 + (progress.normalizedDbLevel * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  orbColor.withValues(
                                    alpha: 0.4 * _glowAnimation.value,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    // Main orb
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.orbGradient(centerColor: orbColor),
                        boxShadow: [
                          BoxShadow(
                            color: orbColor.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: _recordingState == AppRecordingState.recording
                                ? 10 + (progress.normalizedDbLevel * 15)
                                : 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Duration display
            Text(
              _formatDuration(currentDisplayDuration.inMilliseconds),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),

            if (_player.playing)
              Text(
                'of ${_formatDuration(_duration.inMilliseconds)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                ),
              ),

            // Amplitude bar
            const SizedBox(height: AppSpacing.lg),
            AnimatedContainer(
              duration: AppAnimations.amplitudeUpdate,
              height: 6,
              width: _recordingState == AppRecordingState.recording
                  ? (progress.normalizedDbLevel * 150).clamp(0.0, 150.0)
                  : 0.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getSecondary(isDark).withValues(alpha: 0.5),
                    AppColors.getSecondary(isDark),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    final showActions = _recordingState == AppRecordingState.stopped;

    return AnimatedOpacity(
      duration: AppAnimations.normal,
      opacity: showActions ? 1.0 : 0.0,
      child: showActions
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Discard',
                  color: AppColors.getError(isDark),
                  onPressed: _discardRecording,
                ),
                _buildActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: _isSavingVibe ? 'Saving...' : 'Save Vibe',
                  color: AppColors.getSuccess(isDark),
                  onPressed: _isSavingVibe ? null : _saveVibe,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _hapticService.light();
        onPressed?.call();
      },
      icon: Icon(icon, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Widget _buildRecentVibesSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Vibes',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.getTextPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: AppSpacing.lg),
        _buildVibesList(theme, isDark),
      ],
    );
  }

  Widget _buildVibesList(ThemeData theme, bool isDark) {
    if (_currentUserModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show loading shimmer on first load
    if (_isLoadingVibes && _recentVibes.isEmpty) {
      return Column(
        children: List.generate(
          3,
          (index) => ShimmerLoading(
            child: ShimmerShapes.listItem(),
          ),
        ),
      );
    }

    // Show empty state
    if (_recentVibes.isEmpty) {
      return EmptyStates.noVibes(context: context);
    }

    // Show vibes list
    return ListView.builder(
      itemCount: _recentVibes.length,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final vibe = _recentVibes[index];
        return _buildVibeCard(vibe, theme, isDark, index);
      },
    );
  }

  Widget _buildVibeCard(VibeModel vibe, ThemeData theme, bool isDark, int index) {
    final isActive = _currentlyPlayingOrLoadingId == vibe.id;
    final isLoading = isActive && _playerState?.processingState == ja.ProcessingState.loading;
    final isPlaying = isActive && _playerState?.playing == true;

    final moodColor = AppColors.getMoodColor(vibe.mood, isDark);

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () {
        _hapticService.light();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VibeDetailScreen(vibe: vibe)),
        );
      },
      child: Row(
        children: [
          // Mood indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: moodColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy \'at\' h:mm a').format(
                    vibe.createdAt.toDate(),
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_formatDuration(vibe.duration)} • ${vibe.mood.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.getTextSecondary(isDark).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Play button
          if (isLoading)
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: isPlaying ? AppColors.getPrimary(isDark) : AppColors.getTextSecondary(isDark),
                size: 40,
              ),
              onPressed: () => _handlePlayback(vibe),
            ),
        ],
      ),
    ).animate(delay: (350 + (index * 50)).ms).fadeIn().slideX(begin: 0.2, end: 0);
  }
}
