import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

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
  final Map<String, String> _roleDrafts = {};
  String? _activityUserId;
  String? _activityUsername;
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
        _roleDrafts.clear();
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

  Future<void> _approve(String userId, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve user'),
        content: Text(
            'Approve "$username" as staff? They will gain operational access.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiService.adminApproveUser(userId);
      _toast(res['message']?.toString() ?? 'User approved.');
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

  void _toggleActivity(String userId, String username) {
    setState(() {
      if (_activityUserId == userId) {
        _activityUserId = null;
        _activityUsername = null;
      } else {
        _activityUserId = userId;
        _activityUsername = username;
      }
    });
  }

  List<Map<String, dynamic>> _activityLogsFor(String userId, String username) {
    return _auditLogs
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) => _auditLogMatchesUser(entry, userId, username))
        .take(10)
        .toList();
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.adminTitle,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(t.adminSubtitle,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(_adminStatusLine(),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ]),
            ),
            IconButton(
              tooltip: 'Refresh users and session log',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ]),
          const SizedBox(height: 16),
          if (_loading) const SkeletonList(),
          if (_error != null) ErrorView(t.loadFailed, onRetry: _load),
          for (final u in _users) _userCard(u as Map<String, dynamic>),
          const SizedBox(height: 12),
          AdminSessionLogCard(
              logs: _auditLogs, usernameFilter: _activityUsername),
          const SizedBox(height: 12),
          _permissionMatrix(),
        ],
      ),
    );
  }

  String _adminStatusLine() {
    final total = _users.length;
    final pending = _users.where((u) {
      if (u is! Map) return false;
      return u['approved'] != true;
    }).length;
    if (pending == 0) return '$total user(s) loaded.';
    return '$total user(s) loaded - $pending awaiting approval.';
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

  Widget _userCard(Map<String, dynamic> u) {
    final userId = u['userId']?.toString() ?? '';
    final username = u['username']?.toString() ?? '';
    final role = (u['role']?.toString() ?? 'user');
    final current = _roles.contains(role) ? role : 'user';
    final selected = _roleDrafts[userId] ?? current;
    final activityExpanded = _activityUserId == userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminUserManagementCard(
        user: u,
        selectedRole: selected,
        onRoleChanged: (value) => setState(() => _roleDrafts[userId] = value),
        onApprove:
            u['approved'] == true ? null : () => _approve(userId, username),
        onSaveRole:
            selected == current ? null : () => _setRole(userId, selected),
        onDelete: () => _delete(userId, username),
        onToggleActivity: () => _toggleActivity(userId, username),
        activityExpanded: activityExpanded,
        activityLogs: _activityLogsFor(userId, username),
      ),
    );
  }
}

class AdminUserManagementCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback? onApprove;
  final VoidCallback? onSaveRole;
  final VoidCallback onDelete;
  final VoidCallback onToggleActivity;
  final bool activityExpanded;
  final List<dynamic> activityLogs;

  const AdminUserManagementCard({
    super.key,
    required this.user,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onDelete,
    required this.onToggleActivity,
    this.onApprove,
    this.onSaveRole,
    this.activityExpanded = false,
    this.activityLogs = const [],
  });

  static const _roles = ['user', 'staff', 'admin'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final username = user['username']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final approved = user['approved'] == true;
    final safeRole = _roles.contains(selectedRole) ? selectedRole : 'user';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(username,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text(email,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13)),
            ]),
          ),
          _StatusPill(approved: approved),
        ]),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;
          final rolePicker = DropdownButtonFormField<String>(
            initialValue: safeRole,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.adminRoleLabel.replaceAll(':', ''),
              isDense: true,
            ),
            items: [
              for (final role in _roles)
                DropdownMenuItem(value: role, child: Text(_roleLabel(t, role))),
            ],
            onChanged: (value) {
              if (value != null) onRoleChanged(value);
            },
          );
          final actions = Wrap(spacing: 2, runSpacing: 2, children: [
            if (!approved)
              _AdminIconAction(
                tooltip: 'Approve user',
                icon: Icons.verified_user_outlined,
                color: NHSTheme.riskLow,
                onPressed: onApprove,
              ),
            _AdminIconAction(
              tooltip: 'Save role',
              icon: Icons.save_outlined,
              color: Theme.of(context).colorScheme.primary,
              onPressed: onSaveRole,
            ),
            _AdminIconAction(
              tooltip: activityExpanded
                  ? 'Hide user activity'
                  : 'View login/activity',
              icon: Icons.manage_history,
              color: Theme.of(context).colorScheme.secondary,
              onPressed: onToggleActivity,
            ),
            _AdminIconAction(
              tooltip: t.adminDeleteTitle,
              icon: Icons.delete_outline,
              color: NHSTheme.riskHigh,
              onPressed: onDelete,
            ),
          ]);

          if (narrow) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  rolePicker,
                  const SizedBox(height: 8),
                  actions,
                ]);
          }
          return Row(children: [
            Expanded(child: rolePicker),
            const SizedBox(width: 10),
            actions,
          ]);
        }),
        if (activityExpanded) ...[
          const SizedBox(height: 12),
          AdminUserActivityCard(username: username, logs: activityLogs),
        ],
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool approved;

  const _StatusPill({required this.approved});

  @override
  Widget build(BuildContext context) {
    final color = approved ? NHSTheme.riskLow : NHSTheme.riskHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        approved ? 'Approved' : 'Pending',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _AdminIconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: onPressed == null ? Theme.of(context).disabledColor : color,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
    );
  }
}

class AdminSessionLogCard extends StatelessWidget {
  final List<dynamic> logs;
  final String? usernameFilter;

  const AdminSessionLogCard({
    super.key,
    required this.logs,
    this.usernameFilter,
  });

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
        .where((entry) => _auditLogMatchesUser(entry, '', usernameFilter ?? ''))
        .take(12)
        .toList();
    final isFiltered = usernameFilter?.isNotEmpty == true;

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
        Text(
            isFiltered
                ? 'Showing login and logout sessions for $usernameFilter.'
                : t.adminSessionLogSubtitle,
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
    return _formatAuditTimestamp(raw);
  }
}

class AdminUserActivityCard extends StatelessWidget {
  final String username;
  final List<dynamic> logs;

  const AdminUserActivityCard({
    super.key,
    required this.username,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final activityLogs = logs
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .take(10)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.manage_history,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Activity for $username',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Login sessions and admin actions linked to this account.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 10),
        if (activityLogs.isEmpty)
          Text('No recorded activity for this user yet.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12))
        else
          for (final log in activityLogs) _activityRow(context, log),
      ]),
    );
  }

  Widget _activityRow(BuildContext context, Map<String, dynamic> log) {
    final action = log['action']?.toString() ?? '';
    final detail = log['detail']?.toString() ?? '';
    final ip = log['ipAddress']?.toString() ?? '';
    final color = _auditActionColor(context, action);
    final meta = [
      _formatAuditTimestamp(log['createdAt']),
      if (ip.isNotEmpty) ip,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_auditActionIcon(action), color: color, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_auditActionLabel(action),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 1),
            Text(meta,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 1),
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
}

bool _auditLogMatchesUser(
    Map<String, dynamic> entry, String userId, String username) {
  final id = userId.trim();
  final name = username.trim().toLowerCase();
  if (id.isEmpty && name.isEmpty) return true;

  final logUserId = entry['userId']?.toString() ?? '';
  final logUsername = (entry['username']?.toString() ?? '').toLowerCase();
  final detail = (entry['detail']?.toString() ?? '').toLowerCase();

  return (id.isNotEmpty && logUserId == id) ||
      (name.isNotEmpty && logUsername == name) ||
      (name.isNotEmpty && detail.contains(name));
}

String _formatAuditTimestamp(dynamic raw) {
  final seconds = double.tryParse(raw?.toString() ?? '');
  if (seconds == null) return '--';
  final dt =
      DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round()).toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
}

IconData _auditActionIcon(String action) {
  switch (action) {
    case 'login_success':
      return Icons.login;
    case 'logout':
      return Icons.logout;
    case 'user_approved':
      return Icons.verified_user_outlined;
    case 'role_changed':
      return Icons.admin_panel_settings_outlined;
    case 'user_deleted':
      return Icons.delete_outline;
    default:
      return Icons.history;
  }
}

String _auditActionLabel(String action) {
  switch (action) {
    case 'login_success':
      return 'Login';
    case 'logout':
      return 'Logout';
    case 'user_approved':
      return 'Approved';
    case 'role_changed':
      return 'Role changed';
    case 'user_deleted':
      return 'Deleted';
    default:
      if (action.isEmpty) return 'Activity';
      return action.replaceAll('_', ' ');
  }
}

Color _auditActionColor(BuildContext context, String action) {
  switch (action) {
    case 'login_success':
    case 'user_approved':
      return NHSTheme.riskLow;
    case 'user_deleted':
      return NHSTheme.riskHigh;
    case 'logout':
    case 'role_changed':
      return Theme.of(context).colorScheme.primary;
    default:
      return Theme.of(context).colorScheme.secondary;
  }
}
