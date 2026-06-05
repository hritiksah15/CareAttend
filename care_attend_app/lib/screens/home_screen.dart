import 'dart:async';
import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'patient_form_screen.dart';
import 'result_screen.dart';
import 'bias_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResult;
  Timer? _sessionTimer;

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

  void _onUserActivity() {
    _resetSessionTimer();
  }

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

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onUserActivity,
      onPanDown: (_) => _onUserActivity(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Care Attend'),
          actions: [
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
        body: IndexedStack(
          index: _currentIndex,
          children: [
            PatientFormScreen(onResult: _onPredictionResult),
            ResultScreen(
              result: _lastResult,
              onNewAssessment: () => setState(() => _currentIndex = 0),
              onBiasDashboard: () => setState(() => _currentIndex = 2),
            ),
            const BiasScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: NHSTheme.blue,
          unselectedItemColor: NHSTheme.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_note), label: 'Assessment'),
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Results'),
            BottomNavigationBarItem(
                icon: Icon(Icons.balance), label: 'Bias Monitor'),
          ],
        ),
      ),
    );
  }
}
