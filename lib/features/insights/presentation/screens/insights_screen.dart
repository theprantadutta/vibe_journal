// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:vibe_journal/features/premium/presentation/screens/upgrade_screen.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../journal/domain/models/vibe_model.dart';
import '../../../../config/theme/app_colors.dart';

enum ChartTimeRange { week, month, all }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // Core state
  bool _isLoading = true;
  UserModel? _userModel;
  List<VibeModel> _allVibes = [];

  // Audio Player for "Future Me"
  late final ja.AudioPlayer _player;
  bool _isMashupPlaying = false;

  // Chart state
  ChartTimeRange _selectedTimeRange = ChartTimeRange.month;
  List<FlSpot> _moodChartSpots = [];
  double _minX = 0, _maxX = 0;

  // Free stats
  Map<String, int> _moodCounts = {};
  int _longestStreak = 0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _setupPlayerListener();
    _loadInsights();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _setupPlayerListener() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final isPlaying =
          state.playing &&
          state.processingState != ja.ProcessingState.completed;
      if (isPlaying != _isMashupPlaying) {
        setState(() => _isMashupPlaying = isPlaying);
      }
    });
  }

  Future<void> _loadInsights() async {
    if (locator.isRegistered<UserModel>()) {
      _userModel = locator<UserModel>();
    } else {
      final currentUserAuth = FirebaseAuth.instance.currentUser;
      if (currentUserAuth != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserAuth.uid)
            .get();
        if (userDoc.exists) {
          final model = UserModel.fromFirestore(userDoc);
          registerUserSession(model);
          _userModel = model;
        } else {
          FirebaseAuth.instance.signOut();
          clearUserSession();
        }
      }
    }

    if (_userModel != null && mounted) {
      await _fetchAndProcessVibeData();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAndProcessVibeData() async {
    final user = _userModel;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('vibes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt') // Fetch oldest first for streak/chart calculation
        .get();

    _allVibes = snapshot.docs
        .map(
          (doc) => VibeModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .toList();

    // Process data for free insights
    _moodCounts = {'positive': 0, 'negative': 0, 'neutral': 0, 'unknown': 0};
    for (var vibe in _allVibes) {
      _moodCounts.update(vibe.mood, (v) => v + 1, ifAbsent: () => 1);
    }
    _longestStreak = _calculateLongestStreak();

    // Process data for premium charts
    _updateChartData();
  }

  void _updateChartData() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
      case ChartTimeRange.week:
        startDate = now.subtract(const Duration(days: 6));
        break;
      case ChartTimeRange.month:
        startDate = now.subtract(const Duration(days: 29));
        break;
      case ChartTimeRange.all:
        startDate = _allVibes.isNotEmpty
            ? _allVibes.first.createdAt.toDate()
            : now;
        break;
    }

    final filteredVibes = _allVibes.where((v) {
      final vibeDate = v.createdAt.toDate();
      return !vibeDate.isBefore(startDate) && (v.sentimentScore != null);
    }).toList();

    final Map<DateTime, List<double>> dailyScores = {};
    for (var vibe in filteredVibes) {
      final day = DateTime.utc(
        vibe.createdAt.toDate().year,
        vibe.createdAt.toDate().month,
        vibe.createdAt.toDate().day,
      );
      if (dailyScores[day] == null) dailyScores[day] = [];
      dailyScores[day]!.add(vibe.sentimentScore!);
    }

    final Map<DateTime, double> averageDailyScores = dailyScores.map(
      (key, value) => MapEntry(key, value.average),
    );
    final sortedDays = averageDailyScores.keys.toList()..sort();

    if (sortedDays.isEmpty) {
      _moodChartSpots = [FlSpot(now.millisecondsSinceEpoch.toDouble(), 0)];
      _minX = now
          .subtract(const Duration(days: 6))
          .millisecondsSinceEpoch
          .toDouble();
      _maxX = now.millisecondsSinceEpoch.toDouble();
      return;
    }

    _minX = sortedDays.first.millisecondsSinceEpoch.toDouble();
    _maxX = sortedDays.last.millisecondsSinceEpoch.toDouble();
    // Ensure the chart always shows at least a 7-day range for better visualization
    if (_maxX - _minX < const Duration(days: 6).inMilliseconds) {
      _minX = _maxX - const Duration(days: 6).inMilliseconds;
    }

    _moodChartSpots = sortedDays
        .map(
          (day) => FlSpot(
            day.millisecondsSinceEpoch.toDouble(),
            averageDailyScores[day]!,
          ),
        )
        .toList();
  }

  Future<void> _playFutureMeMashup() async {
    if (_player.playing) {
      _player.stop();
      return;
    }

    setState(() => _isMashupPlaying = true); // Show loading/playing state

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentVibes = _allVibes
        .where((v) => !v.createdAt.toDate().isBefore(thirtyDaysAgo))
        .toList();

    if (recentVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No vibes recorded in the last 30 days.")),
      );
      setState(() => _isMashupPlaying = false);
      return;
    }

    try {
      final List<ja.AudioSource> playlist = [];
      for (var vibe in recentVibes) {
        final url = await FirebaseStorage.instance
            .ref(vibe.audioPath)
            .getDownloadURL();
        playlist.add(
          ja.ClippingAudioSource(
            child: ja.AudioSource.uri(Uri.parse(url)),
            start: const Duration(seconds: 1), // Start 1 second in
            end: const Duration(
              seconds: 6,
            ), // End at 6 seconds (a 5-second clip)
            tag: vibe.id,
          ),
        );
      }
      await _player.setAudioSource(
        // ignore: deprecated_member_use
        ja.ConcatenatingAudioSource(children: playlist),
      );
      _player.play();
    } catch (e) {
      if (kDebugMode) {
        print("Error creating FutureMe playlist: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not create audio mashup.")),
      );
      if (mounted) setState(() => _isMashupPlaying = false);
    }
  }

  int _calculateLongestStreak() {
    if (_allVibes.isEmpty) return 0;
    final uniqueDays =
        _allVibes
            .map(
              (v) => DateTime.utc(
                v.createdAt.toDate().year,
                v.createdAt.toDate().month,
                v.createdAt.toDate().day,
              ),
            )
            .toSet()
            .toList()
          ..sort();
    if (uniqueDays.isEmpty) return 0;
    int longest = 1, current = 1;
    for (int i = 1; i < uniqueDays.length; i++) {
      if (uniqueDays[i].difference(uniqueDays[i - 1]).inDays == 1) {
        current++;
      } else if (uniqueDays[i].difference(uniqueDays[i - 1]).inDays > 1) {
        // If there's a gap
        if (current > longest) {
          longest = current;
        }
        current = 1;
      }
    }
    return max(longest, current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_userModel == null) {
      return const Center(child: Text("Could not load user data."));
    }
    bool isPremium = _userModel!.plan == 'premium';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Vibe Summary", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Vibes",
                    _allVibes.length.toString(),
                    Icons.all_inclusive_rounded,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Longest Streak",
                    "$_longestStreak Days",
                    Icons.local_fire_department_rounded,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPieChartCard(theme),
            const SizedBox(height: 40),
            Text("Advanced Insights", style: theme.textTheme.headlineSmall),
            Text(
              "Go deeper into your emotional patterns.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            _PremiumFeatureLock(
              isPremium: isPremium,
              child: _buildLineChartCard(theme),
            ),
            const SizedBox(height: 20),
            _PremiumFeatureLock(
              isPremium: isPremium,
              child: _buildFutureMeCard(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme) {
    final totalCount = _moodCounts.values.reduce((a, b) => a + b);
    if (totalCount == 0) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              "Record some vibes to see your mood distribution!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mood Distribution", style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _moodCounts.entries
                      .mapIndexed((index, entry) {
                        final isTouched = index == _touchedIndex;
                        final radius = isTouched ? 60.0 : 50.0;
                        final percentage = (entry.value / totalCount * 100)
                            .round();
                        if (entry.value == 0) return null;
                        return PieChartSectionData(
                          color: AppColors.moodColors[entry.key],
                          value: entry.value.toDouble(),
                          title: '$percentage%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 16.0 : 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        );
                      })
                      // ignore: deprecated_member_use
                      .whereNotNull()
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mood Over Time", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<ChartTimeRange>(
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.inputFill,
                foregroundColor: AppColors.textSecondary,
                selectedForegroundColor: AppColors.onPrimary,
                selectedBackgroundColor: AppColors.primary,
              ),
              segments: const [
                ButtonSegment(
                  value: ChartTimeRange.week,
                  label: Text('7D'),
                  icon: Icon(Icons.view_week_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ChartTimeRange.month,
                  label: Text('30D'),
                  icon: Icon(Icons.calendar_view_month_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ChartTimeRange.all,
                  label: Text('All'),
                  icon: Icon(Icons.all_inclusive_rounded, size: 18),
                ),
              ],
              selected: {_selectedTimeRange},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedTimeRange = newSelection.first;
                  _updateChartData();
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _moodChartSpots.isEmpty
                  ? Center(
                      child: Text(
                        "Not enough data for this time range.",
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: AppColors.inputFill,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) {
                                if (v == 1 || v == 0 || v == -1) {
                                  return Text(
                                    v.toStringAsFixed(0),
                                    style: theme.textTheme.bodySmall,
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: (_maxX - _minX) / 4,
                              getTitlesWidget: (v, m) => Text(
                                DateFormat.MMMd().format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    v.toInt(),
                                  ),
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppColors.inputFill),
                        ),
                        minX: _minX,
                        maxX: _maxX,
                        minY: -1.1,
                        maxY: 1.1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _moodChartSpots,
                            isCurved: true,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: _moodChartSpots.length < 15,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.secondary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureMeCard(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(
          Icons.forward_5_rounded,
          color: AppColors.primary,
          size: 32,
        ),
        title: Text("Future Me Playback", style: theme.textTheme.titleLarge),
        subtitle: Text(
          "A mashup of your vibes from the last 30 days.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            _isMashupPlaying
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_filled_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          onPressed: _playFutureMeMashup,
        ),
      ),
    );
  }
}

class _PremiumFeatureLock extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  const _PremiumFeatureLock({required this.isPremium, required this.child});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPremium
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UpgradeScreen()),
              );
            },
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (!isPremium)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Available in Premium",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
