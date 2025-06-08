import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../journal/domain/models/vibe_model.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../premium/presentation/screens/upgrade_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  UserModel? _userModel;
  List<VibeModel> _allVibes = [];

  // Calculated Stats
  Map<String, int> _moodCounts = {};
  int _totalVibes = 0;
  int _longestStreak = 0;
  int _touchedIndex = -1; // For pie chart interaction

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    // Check if UserModel is registered in our service locator
    if (locator.isRegistered<UserModel>()) {
      _userModel = locator<UserModel>();
    } else {
      // If not, it's likely a hot restart or startup race condition.
      // Re-fetch the data to ensure robustness.
      print("⚠️ UserModel not found in InsightsScreen. Attempting re-fetch.");
      final currentUserAuth = FirebaseAuth.instance.currentUser;
      if (currentUserAuth != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserAuth.uid)
            .get();
        if (userDoc.exists) {
          final model = UserModel.fromFirestore(userDoc);
          registerUserSession(model); // Re-register it so other screens have it
          _userModel = model;
        } else {
          // This is a critical error state, sign out for safety
          FirebaseAuth.instance.signOut();
          clearUserSession();
        }
      }
    }

    // Now that we're sure we have a user model (or have handled the error),
    // proceed to fetch the vibe data for the charts.
    if (_userModel != null && mounted) {
      await _fetchAndProcessVibeData();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAndProcessVibeData() async {
    final user = _userModel;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('vibes')
        .where('userId', isEqualTo: user.uid)
        .orderBy(
          'createdAt',
          descending: false,
        ) // Fetch oldest first for streak calculation
        .get();

    _allVibes = snapshot.docs
        .map(
          (doc) => VibeModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          ),
        )
        .toList();

    _totalVibes = _allVibes.length;

    // Calculate Mood Distribution
    _moodCounts = {'positive': 0, 'negative': 0, 'neutral': 0, 'unknown': 0};
    for (var vibe in _allVibes) {
      _moodCounts.update(vibe.mood, (value) => value + 1, ifAbsent: () => 1);
    }

    // Calculate Longest Streak
    _longestStreak = _calculateLongestStreak();
  }

  int _calculateLongestStreak() {
    if (_allVibes.isEmpty) return 0;

    // Get unique days, sorted
    final uniqueDays = _allVibes
        .map(
          (vibe) => DateTime.utc(
            vibe.createdAt.toDate().year,
            vibe.createdAt.toDate().month,
            vibe.createdAt.toDate().day,
          ),
        )
        .toSet()
        .toList();

    uniqueDays.sort();

    if (uniqueDays.isEmpty) return 0;

    int longest = 1;
    int current = 1;

    for (int i = 1; i < uniqueDays.length; i++) {
      if (uniqueDays[i].difference(uniqueDays[i - 1]).inDays == 1) {
        current++;
      } else {
        if (current > longest) {
          longest = current;
        }
        current = 1; // Reset streak
      }
    }
    // Final check for the last streak
    return current > longest ? current : longest;
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
            Text("Free Insights", style: theme.textTheme.headlineSmall),
            Text(
              "A quick look at your recent vibe trends.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),

            // --- STATS CARDS ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Vibes",
                    _totalVibes.toString(),
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

            // --- MOOD DISTRIBUTION PIE CHART ---
            _buildPieChartCard(theme),
            const SizedBox(height: 40),

            // --- PREMIUM SECTION ---
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
      return const Card(
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Record some vibes to see your mood distribution!"),
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
                        final fontSize = isTouched ? 16.0 : 14.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        final percentage = totalCount > 0
                            ? (entry.value / totalCount * 100).round()
                            : 0;

                        if (entry.value == 0) {
                          return null; // Don't show section if count is 0
                        }

                        return PieChartSectionData(
                          color: AppColors.moodColors[entry.key],
                          value: entry.value.toDouble(),
                          title: '$percentage%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        );
                      })
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
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  // We would use real data here for premium users
                  // For now, this is a placeholder visual
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: AppColors.inputFill, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.inputFill),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: -1,
                  maxY: 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0.5),
                        FlSpot(1, -0.2),
                        FlSpot(2, 0.8),
                        FlSpot(3, 0.1),
                        FlSpot(4, -0.5),
                        FlSpot(5, 0.3),
                        FlSpot(6, 0.9),
                      ],
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      barWidth: 5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.secondary.withOpacity(0.3),
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
        leading: const Icon(
          Icons.forward_5_rounded,
          color: AppColors.primary,
          size: 32,
        ),
        title: Text("Future Me Playback", style: theme.textTheme.titleLarge),
        subtitle: Text(
          "Listen to a mashup of your recent vibes.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
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
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // Match Card's border radius
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
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
