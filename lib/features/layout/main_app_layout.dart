import 'package:flutter/material.dart';
import '../account/presentation/screens/profile_screen.dart';
import '../journal/presentation/screens/journal_screen.dart';
import '../calendar/presentation/screens/calendar_screen.dart';
import '../insights/presentation/screens/insights_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentIndex = 0;

  // By defining the pages here, they will keep their state when switching tabs
  final List<Widget> _pages = [
    const JournalScreen(),
    const CalendarScreen(),
    const InsightsScreen(),
  ];

  final List<String> _pageTitles = [
    'My Journal',
    'Mood Calendar',
    'Vibe Insights',
  ];

  void _onTabTapped(int index) {
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Account',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      // *** THIS IS THE FIX ***
      // We use a Stack combined with AnimatedOpacity to create a stable fade transition
      // while preserving the state of each page.
      body: Stack(
        children: List.generate(_pages.length, (index) {
          final bool isActive = index == _currentIndex;
          return IgnorePointer(
            // Prevent interaction with inactive tabs that are faded out
            ignoring: !isActive,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isActive ? 1.0 : 0.0,
              // By using Offstage, we also prevent non-visible widgets from being laid out,
              // which improves performance, while still keeping their state alive.
              child: Offstage(offstage: !isActive, child: _pages[index]),
            ),
          );
        }),
      ),
      // *** END OF FIX ***
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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
        ],
      ),
    );
  }
}
