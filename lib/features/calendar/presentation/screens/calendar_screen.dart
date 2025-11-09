// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_animations.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../journal/domain/models/vibe_model.dart';
import '../../../journal/data/repositories/vibe_repository.dart';
import '../../../journal/presentation/screens/vibe_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ja.AudioPlayer _player;
  final _hapticService = HapticService();
  final _soundService = SoundService();
  final _vibeRepository = locator<VibeRepository>();

  // State for calendar and data
  final LinkedHashMap<DateTime, List<VibeModel>> _vibesByDay =
      LinkedHashMap<DateTime, List<VibeModel>>(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<VibeModel> _selectedDayVibes = [];

  // State for managing data fetching
  bool _isLoading = true;
  Timer? _pollingTimer;

  // State for audio playback
  String? _currentlyPlayingOrLoadingId;
  ja.PlayerState? _playerState;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _setupPlayerListeners();

    _selectedDay = _focusedDay;
    _fetchVibesForMonth(_focusedDay);
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
      });

      // When playback finishes, reset the active ID
      if (state.processingState == ja.ProcessingState.completed) {
        setState(() {
          _currentlyPlayingOrLoadingId = null;
        });
      }
    });
  }

  void _fetchVibesForMonth(DateTime month) async {
    // Cancel existing polling timer
    _pollingTimer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    // Initial fetch
    await _fetchAndProcessVibes();

    // Setup polling (every 15 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      await _fetchAndProcessVibes();
    });
  }

  Future<void> _fetchAndProcessVibes() async {
    try {
      // Fetch all vibes from backend (with pagination support if needed)
      final response = await _vibeRepository.fetchVibes(pageSize: 500);

      if (!response.isSuccess || response.data == null) {
        if (kDebugMode) {
          print("Error fetching vibes: ${response.error}");
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final allVibes = response.data!;

      // Clear and rebuild vibes by day map
      _vibesByDay.clear();
      for (final vibe in allVibes) {
        final day = DateTime.utc(
          vibe.createdAt.toDate().year,
          vibe.createdAt.toDate().month,
          vibe.createdAt.toDate().day,
        );

        if (_vibesByDay[day] == null) {
          _vibesByDay[day] = [];
        }
        _vibesByDay[day]!.add(vibe);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedDayVibes = _getVibesForDay(_selectedDay ?? DateTime.now());
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching vibes: $e");
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<VibeModel> _getVibesForDay(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return _vibesByDay[utcDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _hapticService.dateSelection(); // Add haptic feedback
      if (_player.playing) _player.stop(); // Stop playback when changing day
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDayVibes = _getVibesForDay(selectedDay);
        _currentlyPlayingOrLoadingId = null; // Reset playing ID
      });
    }
  }

  Future<void> _handlePlayback(VibeModel vibe) async {
    _hapticService.audioPlayPause(); // Add haptic feedback
    final vibeId = vibe.id;

    // If tapping the currently playing vibe
    if (_currentlyPlayingOrLoadingId == vibeId) {
      if (_player.playing) {
        await _player.pause();
      } else {
        // If paused, play again
        _player.play();
      }
      return;
    }

    // Stop any other vibe before starting a new one
    await _player.stop();

    setState(() {
      _currentlyPlayingOrLoadingId = vibeId;
    });

    try {
      // Get audio URL from backend
      final urlResponse = await _vibeRepository.getAudioUrl(vibeId);

      if (!urlResponse.isSuccess || urlResponse.data == null) {
        throw Exception(urlResponse.error ?? 'Failed to get audio URL');
      }

      final url = urlResponse.data!;
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      if (kDebugMode) {
        print("Error playing vibe: $e");
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error: Could not play audio."),
          backgroundColor: AppColors.getError(isDark),
        ),
      );
      if (mounted) setState(() => _currentlyPlayingOrLoadingId = null);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(int milliseconds) {
    final d = Duration(milliseconds: milliseconds);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getDominantMoodForDay(List<VibeModel> vibes) {
    if (vibes.isEmpty) return 'none';
    final moodCounts = <String, int>{};
    for (final vibe in vibes) {
      moodCounts[vibe.mood] = (moodCounts[vibe.mood] ?? 0) + 1;
    }
    String dominantMood = 'unknown';
    int maxCount = 0;
    moodCounts.forEach((mood, moodCount) {
      if (moodCount > maxCount) {
        maxCount = moodCount;
        dominantMood = mood;
      }
    });
    return dominantMood;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: _isLoading
          ? Center(child: const CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<VibeModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _fetchVibesForMonth(focusedDay);
                  },
                  eventLoader: _getVibesForDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: textTheme.titleLarge!.copyWith(
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: textTheme.bodyMedium!.copyWith(
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    weekendTextStyle: textTheme.bodyMedium!.copyWith(
                      color: AppColors.getSecondary(isDark).withValues(alpha: 0.8),
                    ),
                    outsideTextStyle: textTheme.bodyMedium!.copyWith(
                      color: AppColors.getTextDisabled(isDark),
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.getSecondary(isDark).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: textTheme.bodyMedium!.copyWith(
                      color: AppColors.getTextPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: textTheme.bodyMedium!.copyWith(
                      color: AppColors.getOnPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    prioritizedBuilder: (context, day, focusedDay) {
                      final vibes = _getVibesForDay(day);
                      if (vibes.isNotEmpty) {
                        final dominantMood = _getDominantMoodForDay(vibes);
                        final moodColor = AppColors.getMoodColor(dominantMood, isDark);
                        return Container(
                          decoration: BoxDecoration(
                            color: moodColor.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          margin: const EdgeInsets.all(6.0),
                          child: Center(
                            child: Text(
                              day.day.toString(),
                              style: textTheme.bodyMedium!.copyWith(
                                color: moodColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingHorizontal,
                    vertical: AppSpacing.elementSpacing,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? DateFormat.yMMMMd().format(_selectedDay!)
                            : '',
                        style: textTheme.titleMedium,
                      ),
                      if (_isLoading)
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: _selectedDayVibes.isEmpty
                      ? Center(
                          child: Text(
                            "No vibes recorded on this day.",
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.getTextHint(isDark),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(AppSpacing.md),
                          itemCount: _selectedDayVibes.length,
                          itemBuilder: (context, index) {
                            final vibe = _selectedDayVibes[index];
                            final isActive =
                                _currentlyPlayingOrLoadingId == vibe.id;
                            final isLoading =
                                isActive &&
                                (_playerState?.processingState ==
                                        ja.ProcessingState.loading ||
                                    _playerState?.processingState ==
                                        ja.ProcessingState.buffering);
                            final isPlaying =
                                isActive && _playerState?.playing == true;

                            Widget trailingWidget;
                            if (isLoading) {
                              trailingWidget = SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              );
                            } else if (isPlaying) {
                              trailingWidget = IconButton(
                                icon: Icon(
                                  Icons.pause_circle_filled_rounded,
                                  color: AppColors.getPrimary(isDark),
                                  size: 32,
                                ),
                                onPressed: () => _handlePlayback(vibe),
                              );
                            } else {
                              trailingWidget = IconButton(
                                icon: Icon(
                                  Icons.play_circle_filled_rounded,
                                  color: AppColors.getTextSecondary(isDark),
                                  size: 32,
                                ),
                                onPressed: () => _handlePlayback(vibe),
                              );
                            }

                            return AnimatedCard(
                              margin: EdgeInsets.symmetric(vertical: AppSpacing.marginXs + 2),
                              color: isActive
                                  ? AppColors.getPrimary(isDark).withValues(alpha: 0.1)
                                  : AppColors.getSurface(isDark),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.getPrimary(isDark).withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1,
                              ),
                              padding: EdgeInsets.zero,
                              onTap: () {
                                _hapticService.light();
                                // Navigate to the Detail Screen
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VibeDetailScreen(vibe: vibe),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: Icon(
                                  isPlaying
                                      ? Icons.graphic_eq_rounded
                                      : Icons.bubble_chart_rounded,
                                  color: AppColors.getMoodColor(vibe.mood, isDark),
                                  size: 30,
                                ),
                                title: Text(
                                  DateFormat(
                                    'hh:mm a',
                                  ).format(vibe.createdAt.toDate()),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  vibe.transcription.isEmpty
                                      ? 'Duration: ${_formatDuration(vibe.duration)}'
                                      : '"${vibe.transcription}"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.getTextHint(isDark),
                                  ),
                                ),
                                trailing: trailingWidget,
                              ),
                            ).animate().fadeIn(
                              duration: AppAnimations.fast,
                              delay: AppAnimations.staggerDelayFor(index),
                            ).slideY(
                              begin: 0.2,
                              end: 0,
                              duration: AppAnimations.fast,
                              delay: AppAnimations.staggerDelayFor(index),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
