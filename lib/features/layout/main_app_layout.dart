import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';
import 'package:vibe_journal/features/account/presentation/screens/profile_screen.dart';
import '../journal/presentation/screens/journal_screen.dart';
import '../calendar/presentation/screens/calendar_screen.dart';
import '../insights/presentation/screens/insights_screen.dart';
import '../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const JournalScreen(),
    const CalendarScreen(),
    const InsightsScreen(),
    const AiAssistantScreen(),
  ];

  // Add a title for the new page
  final List<String> _pageTitles = [
    'My Journal',
    'Mood Calendar',
    'Vibe Insights',
    'AI Assistant', // <-- New Title
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
      body: Stack(
        children: List.generate(_pages.length, (index) {
          final bool isActive = index == _currentIndex;
          return IgnorePointer(
            ignoring: !isActive,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isActive ? 1.0 : 0.0,
              child: Offstage(offstage: !isActive, child: _pages[index]),
            ),
          );
        }),
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
          // --- NEW NAVIGATION ITEM ---
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
