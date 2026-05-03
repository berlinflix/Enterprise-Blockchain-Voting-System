import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/voting_screen.dart';
import 'screens/red_team_screen.dart';

void main() {
  runApp(const ProviderScope(child: VoteAuditorApp()));
}

class VoteAuditorApp extends StatelessWidget {
  const VoteAuditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockchain Vote Auditor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    RegistrationScreen(),
    VotingScreen(),
    RedTeamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF0A0E27),
            indicatorColor: AppTheme.neonCyan.withOpacity(0.2),
            selectedIconTheme: IconThemeData(color: AppTheme.neonCyan),
            unselectedIconTheme: const IconThemeData(color: Colors.white38),
            selectedLabelTextStyle: TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add_outlined),
                selectedIcon: Icon(Icons.person_add),
                label: Text('Register'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.how_to_vote_outlined),
                selectedIcon: Icon(Icons.how_to_vote),
                label: Text('Vote'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber),
                label: Text('Red Team'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, color: Colors.white10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
