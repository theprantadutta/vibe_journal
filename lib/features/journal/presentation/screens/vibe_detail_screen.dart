import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _loadUserModel(); // Load the user model to check plan status
    _initPlayer();
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
      // Get audio URL from backend
      final urlResponse = await _vibeRepository.getAudioUrl(widget.vibe.id);

      if (!urlResponse.isSuccess || urlResponse.data == null) {
        throw Exception(urlResponse.error ?? 'Failed to get audio URL');
      }

      final url = urlResponse.data!;
      await _player.setUrl(url);
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
                  _buildAiFeedbackSection(
                    theme,
                    isDark,
                  )
                      .animate()
                      .fadeIn(duration: AppAnimations.normal, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0), // This will now check for premium
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
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transcription", style: theme.textTheme.titleLarge),
          Divider(height: AppSpacing.lg, color: AppColors.getInputFill(isDark)),
          SelectableText(
            widget.vibe.transcription.isEmpty
                ? "No transcription available for this vibe."
                : widget.vibe.transcription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.getTextSecondary(isDark),
              height: 1.5,
            ),
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
