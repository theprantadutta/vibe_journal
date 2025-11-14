import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/config/theme/app_spacing.dart';
import 'package:vibe_journal/config/theme/app_animations.dart';
import 'package:vibe_journal/core/services/haptic_service.dart';
import 'package:vibe_journal/core/services/sound_service.dart';
import 'package:vibe_journal/core/widgets/animated_card.dart';
import 'package:vibe_journal/core/widgets/animated_button.dart';
import 'package:vibe_journal/features/journal/domain/models/vibe_model.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/features/premium/presentation/screens/premium_features_screen.dart';

import '../../../../core/services/user_service.dart';
import '../../data/repositories/vibe_repository.dart';
import '../../../ai_assistant/data/repositories/ai_repository.dart';

class PlayerStreamData {
  final Duration position;
  final Duration duration;
  final ja.PlayerState playerState;
  PlayerStreamData(this.position, this.duration, this.playerState);
}

class VibeDetailScreen extends StatefulWidget {
  final VibeModel vibe;
  const VibeDetailScreen({super.key, required this.vibe});

  @override
  State<VibeDetailScreen> createState() => _VibeDetailScreenState();
}

class _VibeDetailScreenState extends State<VibeDetailScreen> {
  late final ja.AudioPlayer _player;
  Stream<PlayerStreamData>? _playerStream;

  String? _aiFeedback;
  bool _isFetchingFeedback = false;

  // State variable for the user model
  UserModel? _userModel;
  final _userService = locator<UserService>();
  final _vibeRepository = locator<VibeRepository>();
  final _aiRepository = locator<AiRepository>();

  final _hapticService = HapticService();
  final _soundService = SoundService();

  // Polling for transcription updates
  Timer? _transcriptionPollTimer;
  VibeModel? _latestVibeData;
  bool _isRetrying = false;

  /// Get current vibe data (latest or original)
  VibeModel get _currentVibe => _latestVibeData ?? widget.vibe;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _latestVibeData = widget.vibe;
    _loadUserModel(); // Load the user model to check plan status
    _initPlayer();
    _startTranscriptionPolling(); // Start polling if needed
  }

  // Added this function to robustly load the user model
  Future<void> _loadUserModel() async {
    if (_userService.isUserLoggedIn) {
      if (mounted) setState(() => _userModel = _userService.currentUser);
    } else {
      // Try to fetch from backend
      final fetchSuccess = await _userService.fetchAndUpdateUser();
      if (fetchSuccess && _userService.isUserLoggedIn && mounted) {
        setState(() => _userModel = _userService.currentUser);
      }
    }
  }

  /// Start polling for transcription updates if processing
  void _startTranscriptionPolling() {
    final processingStatus = _latestVibeData?.processingStatus ?? 'completed';
    if (processingStatus == 'pending' || processingStatus == 'processing') {
      // Poll every 10 seconds
      _transcriptionPollTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _refreshTranscriptionStatus(),
      );
    }
  }

  /// Refresh vibe data to check transcription status
  Future<void> _refreshTranscriptionStatus() async {
    try {
      // Fetch latest vibe data from backend
      final response = await _vibeRepository.getVibe(_latestVibeData!.id);

      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          _latestVibeData = response.data!;
        });

        // Stop polling if transcription completed or failed
        final status = response.data!.processingStatus ?? 'completed';
        if (status == 'completed' || status == 'failed') {
          _stopTranscriptionPolling();
        }

        debugPrint('🔄 Transcription status updated: $status');
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing transcription status: $e');
      // Stop polling after repeated errors to avoid spamming
      _stopTranscriptionPolling();
    }
  }

  /// Stop transcription polling
  void _stopTranscriptionPolling() {
    _transcriptionPollTimer?.cancel();
    _transcriptionPollTimer = null;
  }

  /// Handle retry transcription button click
  Future<void> _handleRetryTranscription() async {
    setState(() => _isRetrying = true);

    try {
      // Get the local audio file path (prioritize localAudioPath)
      final localPath = _currentVibe.localAudioPath ??
                        _currentVibe.audioUrl ??
                        _currentVibe.audioPath;

      if (localPath == null || localPath.isEmpty) {
        // Show error if no local file
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No local audio file found. Cannot retry transcription.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if it's a URL (remote file) vs local file
      if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
        // Remote file - cannot retry (we need local file to upload)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file is not stored locally. Cannot retry transcription.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Upload file and retry transcription
      final file = File(localPath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio file not found: $localPath'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try retry endpoint first
      var response = await _vibeRepository.retryTranscription(
        vibeId: _currentVibe.id,
        audioFile: file,
      );

      // If vibe doesn't exist in backend (404), create it first
      if (response.statusCode == 404) {
        debugPrint('📤 Vibe not in backend, uploading and creating...');

        // Upload audio file
        final uploadResponse = await _vibeRepository.uploadAudioFile(file);

        if (!uploadResponse.isSuccess || uploadResponse.data == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload audio: ${uploadResponse.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Create vibe entry
        final createResponse = await _vibeRepository.createVibe(
          id: _currentVibe.id,
          audioPath: uploadResponse.data!,
          fileName: _currentVibe.fileName.isNotEmpty ? _currentVibe.fileName : 'audio.flac',
          durationMs: _currentVibe.duration,
        );

        response = createResponse;
      }

      if (response.isSuccess && response.data != null) {
        if (mounted) {
          setState(() {
            _latestVibeData = response.data!;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transcription started successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Start polling for updates
          _startTranscriptionPolling();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start transcription: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error retrying transcription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _initPlayer() async {
    // We combine player streams for efficient UI updates
    _playerStream = Rx.combineLatest3(
      _player.positionStream,
      _player.durationStream.where((d) => d != null).cast<Duration>(),
      _player.playerStateStream,
      (position, duration, playerState) =>
          PlayerStreamData(position, duration, playerState),
    );

    try {
      // Priority order for audio source:
      // 1. localAudioPath (absolute path on device)
      // 2. audioUrl (pre-signed URL or stored URL)
      // 3. Fetch audio URL from backend

      if (widget.vibe.localAudioPath != null && widget.vibe.localAudioPath!.isNotEmpty) {
        // Use local file
        final localFile = File(widget.vibe.localAudioPath!);
        if (await localFile.exists()) {
          await _player.setFilePath(widget.vibe.localAudioPath!);
        } else {
          throw Exception('Local audio file not found');
        }
      } else if (widget.vibe.audioUrl != null && widget.vibe.audioUrl!.isNotEmpty) {
        // Use existing audio URL
        await _player.setUrl(widget.vibe.audioUrl!);
      } else {
        // Fetch audio URL from backend
        final urlResponse = await _vibeRepository.getAudioUrl(widget.vibe.id);

        if (!urlResponse.isSuccess || urlResponse.data == null) {
          throw Exception(urlResponse.error ?? 'Failed to get audio URL');
        }

        final url = urlResponse.data!;
        await _player.setUrl(url);
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error setting up player: $e");
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error: Could not load audio."),
            backgroundColor: AppColors.getError(isDark),
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopTranscriptionPolling();
    _player.dispose();
    super.dispose();
  }

  Future<void> _getAiFeedback() async {
    if (_isFetchingFeedback) return;
    setState(() => _isFetchingFeedback = true);

    try {
      // Get reflective feedback from backend AI
      final response = await _aiRepository.getReflectiveFeedback(
        transcription: widget.vibe.transcription,
        mood: widget.vibe.mood,
        durationSeconds: (widget.vibe.duration / 1000).round(),
      );

      final String responseText = response.isSuccess && response.data != null
          ? response.data!
          : response.error ?? "Sorry, I couldn't generate feedback.";

      if (mounted) setState(() => _aiFeedback = responseText);
    } catch (e) {
      print("Error calling AI function: $e");
      if (mounted) {
        setState(
          () => _aiFeedback =
              "An error occurred while getting feedback. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingFeedback = false);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vibeDate = widget.vibe.createdAt.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM d, yyyy').format(vibeDate)),
        backgroundColor: AppColors.getSurface(isDark),
      ),
      body: _userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme, isDark)
                      .animate()
                      .fadeIn(duration: AppAnimations.normal)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPlayerCard(theme, isDark)
                      .animate()
                      .fadeIn(duration: AppAnimations.normal, delay: 100.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTranscriptionCard(theme, isDark)
                      .animate()
                      .fadeIn(duration: AppAnimations.normal, delay: 150.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAiFeedbackSection(theme, isDark)
                      .animate()
                      .fadeIn(duration: AppAnimations.normal, delay: 200.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                      ), // This will now check for premium
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    return AnimatedCard(
      child: Row(
        children: [
          Icon(
            Icons.bubble_chart_rounded,
            color: AppColors.getMoodColor(widget.vibe.mood, isDark),
            size: 40,
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vibe.mood.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.getMoodColor(widget.vibe.mood, isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Recorded at ${DateFormat('hh:mm a').format(widget.vibe.createdAt.toDate())}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.getTextHint(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(ThemeData theme, bool isDark) {
    return AnimatedCard(
      child: StreamBuilder<PlayerStreamData>(
        stream: _playerStream,
        builder: (context, snapshot) {
          final position = snapshot.data?.position ?? Duration.zero;
          final duration = snapshot.data?.duration ?? Duration.zero;
          final playerState = snapshot.data?.playerState;
          final isPlaying = playerState?.playing ?? false;
          final processingState = playerState?.processingState;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedIconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    size: 32,
                    color: AppColors.getTextSecondary(isDark),
                    onPressed: () {
                      _hapticService.audioSkip();
                      _player.seek(position - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  if (processingState == ja.ProcessingState.loading ||
                      processingState == ja.ProcessingState.buffering)
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        color: AppColors.getPrimary(isDark),
                      ),
                    )
                  else
                    AnimatedIconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                      ),
                      size: 64,
                      color: AppColors.getPrimary(isDark),
                      onPressed: () {
                        _hapticService.audioPlayPause();
                        isPlaying ? _player.pause() : _player.play();
                      },
                    ),
                  const SizedBox(width: AppSpacing.lg),
                  AnimatedIconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    size: 32,
                    color: AppColors.getTextSecondary(isDark),
                    onPressed: () {
                      _hapticService.audioSkip();
                      _player.seek(position + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: theme.textTheme.bodySmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                        0,
                        duration.inMilliseconds.toDouble(),
                      ),
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _hapticService.light();
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: AppColors.getPrimary(isDark),
                      inactiveColor: AppColors.getInputFill(isDark),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionCard(ThemeData theme, bool isDark) {
    // Check processing status using current vibe data
    final processingStatus = _currentVibe.processingStatus ?? 'completed';
    final isProcessing = processingStatus == 'pending' || processingStatus == 'processing';
    final isFailed = processingStatus == 'failed';
    final hasTranscription = _currentVibe.transcription.isNotEmpty;

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Transcription", style: theme.textTheme.titleLarge),
              if (isProcessing) ...[
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Divider(height: AppSpacing.lg, color: AppColors.getInputFill(isDark)),
          if (isProcessing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 16,
                      color: AppColors.getPrimary(isDark),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "Processing transcription...",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.getPrimary(isDark),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetryTranscription,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(_isRetrying ? "Uploading..." : "Retry Transcription"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            )
          else if (isFailed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.getError(isDark),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "Transcription failed.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.getError(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetryTranscription,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(_isRetrying ? "Uploading..." : "Retry Transcription"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            )
          else if (hasTranscription)
            SelectableText(
              _currentVibe.transcription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextSecondary(isDark),
                height: 1.5,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "No transcription available for this vibe.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.getTextSecondary(isDark),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetryTranscription,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(_isRetrying ? "Uploading..." : "Retry Transcription"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- THIS IS THE CORRECTED WIDGET ---
  Widget _buildAiFeedbackSection(ThemeData theme, bool isDark) {
    final bool isPremium = _userService.isPremium;

    // If feedback has already been fetched, display it (for premium users)
    if (_aiFeedback != null && isPremium) {
      return AnimatedCard(
        color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.getPrimary(isDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "AI Reflection",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ],
            ),
            Divider(height: AppSpacing.lg),
            SelectableText(
              _aiFeedback!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextSecondary(isDark),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Don't show anything if there's no text to analyze
    if (widget.vibe.transcription.isEmpty) return const SizedBox.shrink();

    // If user is premium and hasn't requested feedback yet, show the button
    if (isPremium) {
      return Center(
        child: _isFetchingFeedback
            ? CircularProgressIndicator(color: AppColors.getSecondary(isDark))
            : AnimatedButton(
                onPressed: () {
                  _hapticService.light();
                  _getAiFeedback();
                },
                backgroundColor: AppColors.getSecondary(isDark),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded),
                    SizedBox(width: AppSpacing.sm),
                    Text("Get AI Feedback"),
                  ],
                ),
              ),
      );
    }
    // Otherwise, show the premium up sell card for free users
    else {
      return AnimatedCard(
        child: Column(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: AppColors.getPrimary(isDark),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unlock AI-Powered Insights',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Get reflective feedback on your entries with VibeJournal Premium.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.getTextHint(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedButton(
              onPressed: () {
                _hapticService.light();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PremiumFeaturesScreen(),
                  ),
                );
              },
              child: const Text("Upgrade to Unlock"),
            ),
          ],
        ),
      );
    }
  }
}
