import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

/// Admin-only user management — list users, change roles, delete accounts.
/// Mirrors the website Admin tab and the backend /api/admin/users endpoints.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  List<dynamic> _auditLogs = [];
  String? _error;
  bool _loading = false;

  static const _roles = ['user', 'staff', 'admin'];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ApiService.adminListUsers();
      final audit = await ApiService.auditLog();
      setState(() {
        _users = (users['users'] as List?) ?? [];
        _auditLogs = (audit['logs'] as List?) ?? [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _setRole(String userId, String role) async {
    final t = AppLocalizations.of(context);
    try {
      await ApiService.adminSetRole(userId, role);
      _toast(t.adminRoleUpdated);
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _delete(String userId, String username) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.adminDeleteTitle),
        content: Text(t.adminDeleteConfirm(username)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.adminCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.adminDelete,
                  style: const TextStyle(color: NHSTheme.riskHigh))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiService.adminDeleteUser(userId);
      _toast(res['message']?.toString() ?? t.adminDeleted);
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(t.adminTitle,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.adminSubtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (_loading) const SkeletonList(),
          if (_error != null) ErrorView(t.loadFailed, onRetry: _load),
          for (final u in _users) _userCard(u as Map<String, dynamic>),
          const SizedBox(height: 12),
          AdminSessionLogCard(logs: _auditLogs),
          const SizedBox(height: 12),
          _permissionMatrix(),
        ],
      ),
    );
  }

  // Role-permission reference (parity with the website Admin tab).
  Widget _permissionMatrix() {
    final t = AppLocalizations.of(context);
    // flex applied here once — the cell itself must NOT be an Expanded, or two
    // Expanded compete for the same child's parent data and the tree throws.
    Widget cell(String label, int flex, {bool head = false}) => Expanded(
          flex: flex,
          child: Text(label,
              textAlign: flex == 2 ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: head ? FontWeight.w700 : FontWeight.w400,
                  color: head
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface)),
        );
    Widget rowFor(String feature, bool u, bool s, bool a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            cell(feature, 2),
            cell(u ? '✓' : '—', 1),
            cell(s ? '✓' : '—', 1),
            cell(a ? '✓' : '—', 1),
          ]),
        );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.adminRolePerms,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          cell(t.adminFeature, 2, head: true),
          cell(t.adminRoleUser, 1, head: true),
          cell(t.adminRoleStaff, 1, head: true),
          cell(t.adminRoleAdmin, 1, head: true),
        ]),
        const Divider(),
        rowFor(t.adminPermAssessment, true, true, true),
        rowFor(t.adminPermDashboard, false, true, true),
        rowFor(t.adminPermBias, false, false, true),
        rowFor(t.adminPermAudit, false, false, true),
      ]),
    );
  }

  String _roleLabel(AppLocalizations t, String role) {
    switch (role) {
      case 'staff':
        return t.adminRoleStaff;
      case 'admin':
        return t.adminRoleAdmin;
      default:
        return t.adminRoleUser;
    }
  }

  Widget _userCard(Map<String, dynamic> u) {
    final t = AppLocalizations.of(context);
    final userId = u['userId']?.toString() ?? '';
    final username = u['username']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final role = (u['role']?.toString() ?? 'user');
    final current = _roles.contains(role) ? role : 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(email,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${t.adminRoleLabel} '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: current,
                  items: [
                    for (final r in _roles)
                      DropdownMenuItem(value: r, child: Text(_roleLabel(t, r))),
                  ],
                  onChanged: (v) {
                    if (v != null && v != current) _setRole(userId, v);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: NHSTheme.riskHigh),
                  tooltip: t.adminDeleteTitle,
                  onPressed: () => _delete(userId, username),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSessionLogCard extends StatelessWidget {
  final List<dynamic> logs;

  const AdminSessionLogCard({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sessionLogs = logs
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) {
          final action = entry['action']?.toString();
          return action == 'login_success' || action == 'logout';
        })
        .take(8)
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.manage_history,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.adminSessionLogTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(t.adminSessionLogSubtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 12),
        if (sessionLogs.isEmpty)
          Text(t.adminSessionEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          for (final log in sessionLogs) _sessionLogRow(context, log),
      ]),
    );
  }

  Widget _sessionLogRow(BuildContext context, Map<String, dynamic> log) {
    final t = AppLocalizations.of(context);
    final action = log['action']?.toString() ?? '';
    final isLogin = action == 'login_success';
    final color =
        isLogin ? NHSTheme.riskLow : Theme.of(context).colorScheme.primary;
    final username = log['username']?.toString().isNotEmpty == true
        ? log['username'].toString()
        : t.adminSessionUnknownUser;
    final detail = log['detail']?.toString() ?? '';
    final ip = log['ipAddress']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isLogin ? Icons.login : Icons.logout,
              color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${isLogin ? t.adminSessionLogin : t.adminSessionLogout} · $username',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              [
                _formatTimestamp(log['createdAt']),
                if (ip.isNotEmpty) ip,
              ].join(' · '),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(detail,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12)),
            ],
          ]),
        ),
      ]),
    );
  }

  String _formatTimestamp(dynamic raw) {
    final seconds = double.tryParse(raw?.toString() ?? '');
    if (seconds == null) return '--';
    final dt =
        DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round()).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
