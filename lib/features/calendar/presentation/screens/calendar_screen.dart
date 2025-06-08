import 'dart:async';
import 'dart:collection';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../journal/domain/models/vibe_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ja.AudioPlayer _player;

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
  StreamSubscription? _vibeSubscription;

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

  void _fetchVibesForMonth(DateTime month) {
    _vibeSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    final firstDayOfMonth = DateTime.utc(month.year, month.month, 1);
    final lastDayOfMonth = DateTime.utc(
      month.year,
      month.month + 1,
      0,
    ).add(const Duration(days: 1));

    final query = FirebaseFirestore.instance
        .collection('vibes')
        .where('userId', isEqualTo: user.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(lastDayOfMonth));

    _vibeSubscription = query.snapshots().listen(
      (snapshot) {
        _vibesByDay.clear();
        for (final doc in snapshot.docs) {
          final vibe = VibeModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          );
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
      },
      onError: (error) {
        print("Error fetching vibes: $error");
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  List<VibeModel> _getVibesForDay(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return _vibesByDay[utcDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
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
    final vibeId = vibe.id;
    final storagePath = vibe.audioPath;

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
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final url = await storageRef.getDownloadURL();
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      print("Error playing vibe: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not play audio."),
          backgroundColor: AppColors.error,
        ),
      );
      if (mounted) setState(() => _currentlyPlayingOrLoadingId = null);
    }
  }

  @override
  void dispose() {
    _vibeSubscription?.cancel();
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
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMood = mood;
      }
    });
    return dominantMood;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Column(
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
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: textTheme.bodyMedium!.copyWith(
                color: AppColors.textSecondary,
              ),
              weekendTextStyle: textTheme.bodyMedium!.copyWith(
                color: AppColors.secondary.withOpacity(0.8),
              ),
              outsideTextStyle: textTheme.bodyMedium!.copyWith(
                color: AppColors.textDisabled,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: textTheme.bodyMedium!.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: textTheme.bodyMedium!.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                final vibes = _getVibesForDay(day);
                if (vibes.isNotEmpty) {
                  final dominantMood = _getDominantMoodForDay(vibes);
                  final moodColor =
                      AppColors.moodColors[dominantMood] ?? Colors.transparent;
                  return Container(
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.all(6.0),
                  );
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
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
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
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
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _selectedDayVibes.length,
                    itemBuilder: (context, index) {
                      final vibe = _selectedDayVibes[index];
                      final isActive = _currentlyPlayingOrLoadingId == vibe.id;
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
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        color: isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.primary.withOpacity(0.5)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isPlaying
                                ? Icons.graphic_eq_rounded
                                : Icons.bubble_chart_rounded,
                            color:
                                AppColors.moodColors[vibe.mood] ??
                                AppColors.textHint,
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
                              color: AppColors.textHint,
                            ),
                          ),
                          trailing: trailingWidget,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
