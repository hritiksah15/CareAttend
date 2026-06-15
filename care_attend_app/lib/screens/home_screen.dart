import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart' show themeModeNotifier;
import '../nhs_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'patient_form_screen.dart';
import 'result_screen.dart';
import 'bias_screen.dart';
import 'dashboard_screen.dart';
import 'slots_screen.dart';
import 'nudge_screen.dart';
import 'ethics_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// One navigation entry mapping a label/icon to a stack index.
class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem(this.label, this.icon, this.index);
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResult;
  Timer? _sessionTimer;

  // Stack order — index used by IndexedStack and every nav target.
  static const _all = [
    _NavItem('Assessment', Icons.edit_note, 0),
    _NavItem('Results', Icons.insights, 1),
    _NavItem('Dashboard', Icons.dashboard, 2),
    _NavItem('Bias Monitor', Icons.balance, 3),
    _NavItem('Slot Optimisation', Icons.event_available, 4),
    _NavItem('Patient Nudge', Icons.message, 5),
    _NavItem('Ethics', Icons.verified_user, 6),
    _NavItem('Personal Account', Icons.account_circle, 7),
  ];

  // The four core destinations shown in the bottom bar (index 4 = More).
  static const _coreCount = 4;

  @override
  void initState() {
    super.initState();
    _resetSessionTimer();
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 30), _sessionExpired);
  }

  void _sessionExpired() {
    ApiService.clearSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Session expired due to 30 minutes of inactivity.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onUserActivity() => _resetSessionTimer();

  void _onPredictionResult(Map<String, dynamic> result) {
    setState(() {
      _lastResult = result;
      _currentIndex = 1;
    });
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _toggleDarkMode() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: const [
            Icon(Icons.notifications, color: NHSTheme.blue),
            SizedBox(width: 8),
            Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.info_outline, color: NHSTheme.lightBlue),
            title: Text('Session active'),
            subtitle: Text('All data is session-scoped and not stored.'),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined, color: NHSTheme.riskLow),
            title: Text('Secure session'),
            subtitle: Text('30-minute inactivity timeout is active.'),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  Widget _screenFor(int i) {
    switch (i) {
      case 0:
        return PatientFormScreen(onResult: _onPredictionResult);
      case 1:
        return ResultScreen(
          result: _lastResult,
          onNewAssessment: () => setState(() => _currentIndex = 0),
          onBiasDashboard: () => setState(() => _currentIndex = 3),
        );
      case 2:
        return const DashboardScreen();
      case 3:
        return const BiasScreen();
      case 4:
        return const SlotsScreen();
      case 5:
        return const NudgeScreen();
      case 6:
        return const EthicsScreen();
      case 7:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeModeNotifier.value == ThemeMode.dark;
    return GestureDetector(
      onTap: _onUserActivity,
      onPanDown: (_) => _onUserActivity(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Care Attend'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
              tooltip: 'Toggle dark mode',
              onPressed: _toggleDarkMode,
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              tooltip: 'Notifications',
              onPressed: _showNotifications,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.username,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: 'Log Out',
              onPressed: _handleLogout,
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [for (var i = 0; i < _all.length; i++) _screenFor(i)],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex:
              _currentIndex < _coreCount ? _currentIndex : _coreCount,
          onDestinationSelected: (i) {
            if (i < _coreCount) {
              setState(() => _currentIndex = i);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: 'Assess'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Results'),
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.balance_outlined),
                selectedIcon: Icon(Icons.balance),
                label: 'Bias'),
            NavigationDestination(
                icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: NHSTheme.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                const Text('Care Attend',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text(widget.username,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          for (final item in _all)
            ListTile(
              leading: Icon(item.icon,
                  color: _currentIndex == item.index
                      ? NHSTheme.blue
                      : NHSTheme.darkGrey),
              title: Text(item.label),
              selected: _currentIndex == item.index,
              onTap: () {
                setState(() => _currentIndex = item.index);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: NHSTheme.riskHigh),
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
