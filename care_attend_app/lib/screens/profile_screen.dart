import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../widgets/password_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = false;

  final _current = TextEditingController();
  final _newPw = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ApiService.getProfile();
      setState(() => _profile = p);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _changePassword() async {
    if (_newPw.text.length < 8) {
      _snack('New password must be at least 8 characters');
      return;
    }
    if (_newPw.text != _confirm.text) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.changePassword(
        currentPassword: _current.text,
        newPassword: _newPw.text,
      );
      _current.clear();
      _newPw.clear();
      _confirm.clear();
      _snack('Password changed successfully');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _current.dispose();
    _newPw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Personal Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null)
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
        if (_profile != null) _profileCard(),
        const SizedBox(height: 8),
        _passwordCard(),
      ],
    );
  }

  Widget _profileCard() {
    final p = _profile!;
    return Card(
      child: Column(children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: NHSTheme.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text('${p['username'] ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${p['email'] ?? '-'}'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.badge_outlined, color: NHSTheme.darkGrey),
          title: const Text('Role'),
          trailing: Text('${p['role'] ?? '-'}'.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: NHSTheme.darkGrey),
          title: const Text('Two-factor auth'),
          trailing: Text(
            (p['totpEnabled'] == true) ? 'Enabled' : 'Disabled',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: (p['totpEnabled'] == true)
                    ? NHSTheme.riskLow
                    : NHSTheme.darkGrey),
          ),
        ),
      ]),
    );
  }

  Widget _passwordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Change Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          PasswordField(controller: _current, label: 'Current password'),
          const SizedBox(height: 10),
          PasswordField(controller: _newPw, label: 'New password (min 8)'),
          const SizedBox(height: 10),
          PasswordField(controller: _confirm, label: 'Confirm new password'),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saving ? null : _changePassword,
            icon: const Icon(Icons.lock_reset),
            label: Text(_saving ? 'Saving…' : 'Update password'),
          ),
        ]),
      ),
    );
  }
}
