import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

/// Admin-only user management — list users, change roles, delete accounts.
/// Mirrors the website Admin tab and the backend /api/admin/users endpoints.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  String? _error;
  bool _loading = false;

  static const _roles = ['user', 'staff', 'admin'];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.adminListUsers();
      setState(() => _users = (data['users'] as List?) ?? []);
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
    try {
      await ApiService.adminSetRole(userId, role);
      _toast('Role updated.');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _delete(String userId, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete "$username"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: NHSTheme.riskHigh))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiService.adminDeleteUser(userId);
      _toast(res['message']?.toString() ?? 'Deleted.');
      _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('User Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Admin only. New sign-ups start as read-only users — promote trusted colleagues here.',
              style: TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
          if (_error != null)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: const TextStyle(color: NHSTheme.riskHigh)))),
          for (final u in _users) _userCard(u as Map<String, dynamic>),
          const SizedBox(height: 12),
          _permissionMatrix(),
        ],
      ),
    );
  }

  // Role-permission reference (parity with the website Admin tab).
  Widget _permissionMatrix() {
    Widget cell(String t, {bool head = false}) => Expanded(
          child: Text(t,
              textAlign: t == 'Feature' ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: head ? FontWeight.w700 : FontWeight.w400,
                  color: head ? NHSTheme.blue : NHSTheme.black)),
        );
    Widget rowFor(String feature, bool u, bool s, bool a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(flex: 2, child: cell(feature)),
            cell(u ? '✓' : '—'),
            cell(s ? '✓' : '—'),
            cell(a ? '✓' : '—'),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Role Permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 2, child: cell('Feature', head: true)),
            cell('User', head: true),
            cell('Staff', head: true),
            cell('Admin', head: true),
          ]),
          const Divider(),
          rowFor('Assessment + Results', true, true, true),
          rowFor('Dashboard, Slots, Nudge', false, true, true),
          rowFor('Bias, Ethics, Model info', false, false, true),
          rowFor('Audit log, User management', false, false, true),
        ]),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final userId = u['userId']?.toString() ?? '';
    final username = u['username']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final role = (u['role']?.toString() ?? 'user');
    final current = _roles.contains(role) ? role : 'user';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            Text(email,
                style: const TextStyle(
                    color: NHSTheme.darkGrey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Role:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: current,
                  items: [
                    for (final r in _roles)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: (v) {
                    if (v != null && v != current) _setRole(userId, v);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: NHSTheme.riskHigh),
                  tooltip: 'Delete user',
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
