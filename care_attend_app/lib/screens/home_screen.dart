import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart' show themeModeNotifier;
import '../nhs_theme.dart';
import '../theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../state/notifications.dart';
import '../widgets/ui.dart';
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
  Timer? _idleWarnTimer;
  bool _loginNotified = false;

  // Visit counter per tab — bumping it rebuilds the screen (via its key) so
  // data screens (dashboard, bias, ethics) refresh live instead of showing stale state.
  final Map<int, int> _visit = {};
  void _go(int i) {
    final next = _canOpenIndex(i) ? i : 0;
    setState(() {
      _currentIndex = next;
      _visit[next] = (_visit[next] ?? 0) + 1;
    });
  }

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

  _NavItem? _itemForIndex(int index) {
    for (final item in _all) {
      if (item.index == index) return item;
    }
    return null;
  }

  bool _canOpenIndex(int index) {
    final item = _itemForIndex(index);
    return item == null ||
        item.roles == null ||
        item.roles!.contains(ApiService.role);
  }

  bool _shouldMountIndex(int index) =>
      index == 0 || index == _currentIndex || _visit.containsKey(index);

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
    // Security notification for this sign-in (once per session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loginNotified) return;
      _loginNotified = true;
      final t = AppLocalizations.of(context);
      Notifications.push(
          t.notifSignedIn, t.notifSignedInBody, NotifKind.security);
    });
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _idleWarnTimer?.cancel();
    // "Remember me" keeps the session alive far longer, matching the backend.
    final timeout = widget.remember
        ? const Duration(days: 30)
        : const Duration(minutes: 30);
    _sessionTimer = Timer(timeout, _sessionExpired);
    // Security alert ~2 min before an inactivity logout (skip for remember-me).
    if (!widget.remember) {
      _idleWarnTimer = Timer(timeout - const Duration(minutes: 2), () {
        if (!mounted) return;
        final t = AppLocalizations.of(context);
        Notifications.push(
            t.notifIdleWarn, t.notifIdleWarnBody, NotifKind.security);
      });
    }
  }

  void _sessionExpired() {
    ApiService.clearSession();
    Notifications.clear();
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
    // Activity notification for the completed assessment.
    final t = AppLocalizations.of(context);
    final tier = '${result['risk_tier'] ?? ''}'.toUpperCase();
    final pct = (result['percentage'] as num?)?.toStringAsFixed(0) ?? '—';
    Notifications.push(t.notifAssessmentDone, t.notifAssessmentBody(tier, pct),
        NotifKind.activity);
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    Notifications.clear();
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

  Color _notifColor(NotifKind k) {
    switch (k) {
      case NotifKind.security:
        return NHSTheme.riskLow;
      case NotifKind.activity:
        return Theme.of(context).colorScheme.primary;
      case NotifKind.info:
        return NHSTheme.lightBlue;
    }
  }

  void _showNotifications() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassPanel(
        borderRadius: const BorderRadius.vertical(top: AppRadius.rLg),
        child: SafeArea(
          child: ValueListenableBuilder<List<AppNotification>>(
            valueListenable: Notifications.items,
            builder: (context, items, _) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(Icons.notifications,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(t.notifTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (items.isNotEmpty)
                    TextButton(
                        onPressed: Notifications.clear,
                        child: Text(t.notifClearAll)),
                ]),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(children: [
                      Icon(Icons.notifications_none,
                          size: 40,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(t.notifEmpty,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ]),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return ListTile(
                          leading: Icon(n.icon, color: _notifColor(n.kind)),
                          title: Text(n.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(n.body),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _idleWarnTimer?.cancel();
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
    if (!_canOpenIndex(i) || !_shouldMountIndex(i)) {
      return const SizedBox.shrink();
    }
    switch (i) {
      case 0:
        return PatientFormScreen(onResult: _onPredictionResult);
      case 1:
        return ResultScreen(
          result: _lastResult,
          onNewAssessment: () => _go(0),
          onBiasDashboard: ApiService.canBias ? () => _go(3) : null,
        );
      case 2:
        return DashboardScreen(
          key: ValueKey('dash-${_visit[2] ?? 0}'),
          onOpenModule: _go,
        );
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
        // Keep the scaffold body above the bottom navigation so content and
        // floating helpers never sit underneath the nav rail on mobile web.
        appBar: AppBar(
          // Left-align so the title isn't squeezed out by the trailing icons on
          // narrow (≤360px) screens; theme centres it by default.
          centerTitle: false,
          titleSpacing: 12,
          title: Text(AppLocalizations.of(context).appTitle,
              overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              tooltip: 'Guided tour',
              onPressed: () => GuidedTour.start(context, (i) => _go(i)),
            ),
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
              tooltip: 'Toggle dark mode',
              onPressed: _toggleDarkMode,
            ),
            ValueListenableBuilder<List<AppNotification>>(
              valueListenable: Notifications.items,
              builder: (context, items, _) => IconButton(
                icon: Badge(
                  isLabelVisible: items.isNotEmpty,
                  label: Text('${items.length}'),
                  child: const Icon(Icons.notifications_outlined, size: 20),
                ),
                tooltip: AppLocalizations.of(context).notifTitle,
                onPressed: _showNotifications,
              ),
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
                        if (MediaQuery.sizeOf(context).width >= 480) ...[
                          const SizedBox(width: 6),
                          Text(widget.username,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white)),
                        ],
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

    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    // Always-on bar: translucent + top border, but NO backdrop blur. A
    // persistent BackdropFilter forces a GPU readback every frame ("GPU stall
    // due to ReadPixels") and stutters under CPU rendering — glass blur is
    // reserved for transient panels (drawer/sheets) via GlassPanel instead.
    final bar = NavigationBar(
      backgroundColor: surface.withValues(alpha: dark ? 0.90 : 0.94),
      elevation: 0,
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
          NavigationDestination(
              icon: Icon(it.icon),
              // Bottom-bar label stays short/single-line (case 0 uses the full
              // "Patient Assessment" in the drawer; here it wraps + misaligns).
              label: it.index == 0 ? t.navAssessment : _navLabel(t, it)),
        if (hasMore)
          NavigationDestination(
              icon: const Icon(Icons.more_horiz), label: t.navMore),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
      ),
      child: bar,
    );
  }

  Widget _buildDrawer() {
    final t = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassPanel(
        borderRadius: const BorderRadius.only(
            topRight: AppRadius.rLg, bottomRight: AppRadius.rLg),
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
                        : Theme.of(context).colorScheme.onSurfaceVariant),
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
      ),
    );
  }
}
