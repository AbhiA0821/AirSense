import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/journey_planning_screen.dart';
import 'screens/route_map_screen.dart';
import 'screens/exposure_details_screen.dart';
import 'screens/system_info_screen.dart';
import 'widgets/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AeroMobilityApp());
}

class AeroMobilityApp extends StatelessWidget {
  const AeroMobilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider()..loadEnvironment(useGps: true),
        ),
      ],
      child: MaterialApp(
        title: 'Environmental Intelligence & Delhi Smart Mobility',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationHost(),
      ),
    );
  }
}

/// Root Application Container utilizing Top-Navigation AppShell
class MainNavigationHost extends StatefulWidget {
  const MainNavigationHost({super.key});

  @override
  State<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends State<MainNavigationHost> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index != _currentIndex && index >= 0 && index < 5) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardScreen(onNavigateToTab: _onTabSelected),
      JourneyPlanningScreen(onNavigateToTab: _onTabSelected),
      RouteMapScreen(onNavigateToTab: _onTabSelected),
      ExposureDetailsScreen(onNavigateToTab: _onTabSelected),
      const SystemInfoScreen(),
    ];

    return AppShell(
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      child: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
