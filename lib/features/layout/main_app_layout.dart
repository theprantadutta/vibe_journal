import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/features/account/presentation/screens/profile_screen.dart';
import 'package:vibe_journal/features/settings/presentation/screens/settings_screen.dart';
import '../journal/presentation/screens/journal_screen.dart';
import '../calendar/presentation/screens/calendar_screen.dart';
import '../insights/presentation/screens/insights_screen.dart';
import '../ai_assistant/presentation/screens/ai_assistant_screen.dart';

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentIndex = 0;

  // --- LAZY LOADING IMPLEMENTATION ---

  // A list that holds the INSTANTIATED page widgets.
  // It starts with nulls for pages that haven't been visited yet.
  late final List<Widget?> _pageCache;

  // This holds the builders for each page.
  final List<Widget> _pageDestinations = [
    const JournalScreen(),
    const CalendarScreen(),
    const InsightsScreen(),
    const AiAssistantScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the cache with nulls, and create the first page immediately.
    _pageCache = List.filled(_pageDestinations.length, null);
    _pageCache[0] = _pageDestinations[0];
  }

  // --- END OF LAZY LOADING IMPLEMENTATION ---

  final List<String> _pageTitles = [
    'My Journal',
    'Mood Calendar',
    'Vibe Insights',
    'AI Assistant',
  ];

  void _onTabTapped(int index) {
    // When a tab is tapped, check if its page has been created yet.
    if (_pageCache[index] == null) {
      // If not, create it and add it to our cache.
      _pageCache[index] = _pageDestinations[index];
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Account',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        // Provide a placeholder for any pages that haven't been built yet.
        children: _pageCache
            .map((page) => page ?? const SizedBox.shrink())
            .toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_rounded),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
