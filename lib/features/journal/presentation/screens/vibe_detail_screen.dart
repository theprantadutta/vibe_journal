import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/features/journal/domain/models/vibe_model.dart';
import 'package:vibe_journal/core/services/service_locator.dart';
import 'package:vibe_journal/features/auth/domain/models/user_model.dart';
import 'package:vibe_journal/features/premium/presentation/screens/upgrade_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _loadUserModel(); // Load the user model to check plan status
    _initPlayer();
  }

  // Added this function to robustly load the user model
  Future<void> _loadUserModel() async {
    if (locator.isRegistered<UserModel>()) {
      final model = locator<UserModel>();
      if (mounted) setState(() => _userModel = model);
    } else {
      // Fallback logic if GetIt is not populated (e.g., hot restart)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final model = UserModel.fromFirestore(doc);
          registerUserSession(model);
          setState(() => _userModel = model);
        }
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
      final storageRef = FirebaseStorage.instance.ref(widget.vibe.audioPath);
      final url = await storageRef.getDownloadURL();
      await _player.setUrl(url);
    } catch (e) {
      print("Error setting up player: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Could not load audio."),
            backgroundColor: AppColors.error,
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
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'aiAssistant',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'action': 'get_feedback',
        'text': widget.vibe.transcription,
      });
      final String responseText =
          result.data['responseText'] ?? "Sorry, I couldn't process that.";
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
    final vibeDate = widget.vibe.createdAt.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM d, yyyy').format(vibeDate)),
        backgroundColor: AppColors.surface,
      ),
      body: _userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(theme),
                  const SizedBox(height: 20),
                  _buildPlayerCard(theme),
                  const SizedBox(height: 20),
                  _buildTranscriptionCard(theme),
                  const SizedBox(height: 20),
                  _buildAiFeedbackSection(
                    theme,
                  ), // This will now check for premium
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.bubble_chart_rounded,
              color:
                  AppColors.moodColors[widget.vibe.mood] ?? AppColors.textHint,
              size: 40,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vibe.mood.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color:
                        AppColors.moodColors[widget.vibe.mood] ??
                        AppColors.textHint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Recorded at ${DateFormat('hh:mm a').format(widget.vibe.createdAt.toDate())}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: 32,
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          _player.seek(position - const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 16),
                    if (processingState == ja.ProcessingState.loading ||
                        processingState == ja.ProcessingState.buffering)
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                        ),
                        iconSize: 64,
                        color: AppColors.primary,
                        onPressed: isPlaying ? _player.pause : _player.play,
                      ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded),
                      iconSize: 32,
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          _player.seek(position + const Duration(seconds: 10)),
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
                          _player.seek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.inputFill,
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
      ),
    );
  }

  Widget _buildTranscriptionCard(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transcription", style: theme.textTheme.titleLarge),
            const Divider(height: 20, color: AppColors.inputFill),
            SelectableText(
              widget.vibe.transcription.isEmpty
                  ? "No transcription available for this vibe."
                  : widget.vibe.transcription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- THIS IS THE CORRECTED WIDGET ---
  Widget _buildAiFeedbackSection(ThemeData theme) {
    final bool isPremium = _userModel?.plan == 'premium';

    // If feedback has already been fetched, display it (for premium users)
    if (_aiFeedback != null && isPremium) {
      return Card(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AI Reflection",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              SelectableText(
                _aiFeedback!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Don't show anything if there's no text to analyze
    if (widget.vibe.transcription.isEmpty) return const SizedBox.shrink();

    // If user is premium and hasn't requested feedback yet, show the button
    if (isPremium) {
      return Center(
        child: _isFetchingFeedback
            ? const CircularProgressIndicator(color: AppColors.secondary)
            : ElevatedButton.icon(
                onPressed: _getAiFeedback,
                icon: const Icon(Icons.psychology_rounded),
                label: const Text("Get AI Feedback"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
      );
    }
    // Otherwise, show the premium up sell card for free users
    else {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock AI-Powered Insights',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get reflective feedback on your entries with VibeJournal Premium.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                ),
                child: const Text("Upgrade to Unlock"),
              ),
            ],
          ),
        ),
      );
    }
  }
}
