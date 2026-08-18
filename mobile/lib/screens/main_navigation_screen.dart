import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_list_screen.dart';
import 'event_history_screen.dart';
import 'home_screen.dart';
import 'map_overview_screen.dart';
import 'profile_screen.dart';
import 'push_to_talk_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(onNavigateTab: _onSelectTab),
      const ChatListScreen(),
      const MapOverviewScreen(),
      const EventHistoryScreen(),
      ProfileScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      // Quick PTT Intercom Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
        tooltip: "Push-To-Talk Intercom",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PushToTalkScreen()),
          );
        },
        child: const Icon(Icons.mic, size: 26),
      ),

      // Bottom Navigation Bar with 5 tabs: Home | Chats | Map | History | Profile
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onSelectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: "Chats",
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: "Map",
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: "History",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
