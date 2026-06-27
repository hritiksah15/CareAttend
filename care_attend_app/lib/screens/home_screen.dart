import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart' show themeModeNotifier;
import '../nhs_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/offline_banner.dart';
import 'patient_form_screen.dart';
import 'result_screen.dart';
import 'bias_screen.dart';
import 'dashboard_screen.dart';
import 'clinic_screen.dart';
import 'slots_screen.dart';
import 'nudge_screen.dart';
import 'ethics_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'batch_screen.dart';
import '../widgets/chatbot.dart';
import '../widgets/guided_tour.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final bool remember;
  const HomeScreen({super.key, required this.username, this.remember = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// One navigation entry mapping a label/icon to a stack index.
/// [roles] null = visible to every role; otherwise restricted to those roles.
class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  final List<String>? roles;
  const _NavItem(this.label, this.icon, this.index, [this.roles]);
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  Map<String, dynamic>? _lastResult;
  Timer? _sessionTimer;

  // Visit counter per tab — bumping it rebuilds the screen (via its key) so
  // data screens (dashboard, bias, ethics) refresh live instead of showing stale state.
  final Map<int, int> _visit = {};
  void _go(int i) => setState(() {
        _currentIndex = i;
        _visit[i] = (_visit[i] ?? 0) + 1;
      });

  // Stack order — index used by IndexedStack and every nav target.
  // roles gate visibility to mirror the backend role_required rules.
  static const _all = [
    _NavItem('Assessment', Icons.edit_note, 0),
    _NavItem('Results', Icons.insights, 1),
    _NavItem('Dashboard', Icons.dashboard, 2, ['staff', 'admin']),
    _NavItem('Clinic List', Icons.event_note, 10, ['staff', 'admin']),
    _NavItem('Batch Upload', Icons.upload_file, 9, ['staff', 'admin']),
    _NavItem('Slot Optimisation', Icons.event_available, 4, ['staff', 'admin']),
    _NavItem('Patient Nudge', Icons.message, 5, ['staff', 'admin']),
    _NavItem('Bias Monitor', Icons.balance, 3, ['admin']),
    _NavItem('Ethics', Icons.verified_user, 6, ['admin']),
    _NavItem('User Management', Icons.admin_panel_settings, 8, ['admin']),
    _NavItem('Personal Account', Icons.account_circle, 7),
  ];

  // Items visible to the current role.
  List<_NavItem> get _visibleItems => _all
      .where((it) => it.roles == null || it.roles!.contains(ApiService.role))
      .toList();

  /// Localized label for a nav item, keyed by its stack index.
  String _navLabel(AppLocalizations t, _NavItem it) {
    switch (it.index) {
      case 0:
        return t.patientAssessment;
      case 1:
        return t.navResults;
      case 2:
        return t.navDashboard;
      case 10:
        return t.navClinic;
      case 9:
        return t.batchUpload;
      case 4:
        return t.navSlots;
      case 5:
        return t.navNudge;
      case 3:
        return t.biasMonitor;
      case 6:
        return t.navEthics;
      case 8:
        return t.navAdmin;
      case 7:
        return t.personalAccount;
      default:
        return it.label;
    }
  }

  // Up to four destinations in the bottom bar; the rest go under "More".
  static const _maxCore = 4;

  @override
  void initState() {
    super.initState();
    _resetSessionTimer();
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    // "Remember me" keeps the session alive far longer, matching the backend.
    final timeout = widget.remember
        ? const Duration(days: 30)
        : const Duration(minutes: 30);
    _sessionTimer = Timer(timeout, _sessionExpired);
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
      _visit[1] = (_visit[1] ?? 0) + 1;
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

  // Cache the decoded avatar so it isn't re-decoded (new MemoryImage) every
  // build, which would make the app-bar photo flicker/disappear.
  String? _avKey;
  ImageProvider? _avImg;
  ImageProvider? get _appBarAvatar {
    final a = ApiService.avatar;
    if (a != _avKey) {
      _avKey = a;
      if (a != null && a.contains(',')) {
        try {
          _avImg = kIsWeb
              ? NetworkImage(a) as ImageProvider
              : MemoryImage(base64Decode(a.split(',').last));
        } catch (_) {
          _avImg = null;
        }
      } else {
        _avImg = null;
      }
    }
    return _avImg;
  }

  Widget _screenFor(int i) {
    switch (i) {
      case 0:
        return PatientFormScreen(onResult: _onPredictionResult);
      case 1:
        return ResultScreen(
          result: _lastResult,
          onNewAssessment: () => _go(0),
          onBiasDashboard: () => _go(3),
        );
      case 2:
        return DashboardScreen(key: ValueKey('dash-${_visit[2] ?? 0}'));
      case 3:
        return BiasScreen(key: ValueKey('bias-${_visit[3] ?? 0}'));
      case 4:
        return const SlotsScreen();
      case 5:
        return const NudgeScreen();
      case 6:
        return EthicsScreen(key: ValueKey('ethics-${_visit[6] ?? 0}'));
      case 7:
        return ProfileScreen(key: ValueKey('profile-${_visit[7] ?? 0}'));
      case 8:
        return const AdminScreen();
      case 9:
        return const BatchScreen();
      case 10:
        return const ClinicScreen();
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
          title: Text(AppLocalizations.of(context).appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              tooltip: 'Guided tour',
              onPressed: () => GuidedTour.start(
                  context, (i) => _go(i)),
            ),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _go(7), // open Personal Account
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white24,
                          backgroundImage: _appBarAvatar,
                          child: _appBarAvatar == null
                              ? const Icon(Icons.person,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(widget.username,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: [
                      for (var i = 0; i < _all.length; i++) _screenFor(i)
                    ],
                  ),
                  const Align(
                      alignment: Alignment.bottomRight,
                      child: ChatbotOverlay()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    final t = AppLocalizations.of(context);
    final visible = _visibleItems;
    final core = visible.take(_maxCore).toList();
    final hasMore = visible.length > core.length;

    var selected = core.indexWhere((it) => it.index == _currentIndex);
    if (selected == -1) selected = hasMore ? core.length : 0;

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i < core.length) {
          _go(core[i].index);
        } else {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      destinations: [
        for (final it in core)
          NavigationDestination(icon: Icon(it.icon), label: _navLabel(t, it)),
        if (hasMore)
          NavigationDestination(
              icon: const Icon(Icons.more_horiz), label: t.navMore),
      ],
    );
  }

  Widget _buildDrawer() {
    final t = AppLocalizations.of(context);
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
                Text(t.appTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text(widget.username,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          for (final item in _visibleItems)
            ListTile(
              leading: Icon(item.icon,
                  color: _currentIndex == item.index
                      ? NHSTheme.blue
                      : NHSTheme.darkGrey),
              title: Text(_navLabel(t, item)),
              selected: _currentIndex == item.index,
              onTap: () {
                _go(item.index);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: NHSTheme.riskHigh),
            title: Text(t.logout),
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
