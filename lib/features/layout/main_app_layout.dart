// lib/features/layout/main_app_layout.dart
import 'package:flutter/material.dart';
import '../journal/presentation/screens/journal_screen.dart'; // Adjust path
import '../calendar/presentation/screens/calendar_screen.dart'; // Adjust path
import '../insights/presentation/screens/insights_screen.dart'; // Adjust path
// Import AppColors if needed for direct styling, though ThemeData is preferred
// import '../../config/theme/app_colors.dart';

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentIndex = 0; // Default to the first tab (Journal)

  final List<Widget> _pages = [
    const JournalScreen(),
    const CalendarScreen(),
    const InsightsScreen(),
  ];

  final List<String> _pageTitles = [
    // Optional: for a dynamic AppBar title
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
    // The BottomNavigationBarTheme is already defined in your main.dart's ThemeData
    // So, it should pick up those styles automatically.
    // You can override specific properties here if needed.

    return Scaffold(
      // You can have a common AppBar here, or each page can define its own.
      // If you have a common AppBar, you can update its title dynamically.
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
        // elevation: 0, // Consistent with your theme
        // backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // From theme
      ),
      body: IndexedStack(
        // Using IndexedStack to preserve state of inactive tabs
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        // type: BottomNavigationBarType.fixed, // Already set in theme
        // selectedItemColor: AppColors.bottomNavSelected, // From theme
        // unselectedItemColor: AppColors.bottomNavUnselected, // From theme
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
