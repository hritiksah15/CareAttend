import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = false;
  bool _savingProfile = false;
  ImageProvider? _avatarProvider; // decoded once, not on every build

  // Decode a base64 data-URL to an ImageProvider once (re-decoding each build
  // makes a new MemoryImage every frame, which flickers/clears the avatar).
  ImageProvider? _decodeAvatar(String? dataUrl) {
    if (dataUrl == null || !dataUrl.contains(',')) return null;
    // On web, MemoryImage routes bytes through the browser ImageDecoder API,
    // which fails on some JPEGs ("Failed to retrieve track metadata"). A
    // NetworkImage of the data: URL uses the tolerant <img> decode path instead.
    if (kIsWeb) return NetworkImage(dataUrl);
    try {
      return MemoryImage(base64Decode(dataUrl.split(',').last));
    } catch (_) {
      return null;
    }
  }

  // Editable identity fields
  final _displayName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _department = TextEditingController();
  final _pronouns = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();

  // Password fields
  final _current = TextEditingController();
  final _newPw = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  // 2FA (TOTP)
  bool _totpEnabled = false;
  String? _twoFaSecret;
  bool _twoFaBusy = false;
  final _twoFaCode = TextEditingController();
  final _twoFaPw = TextEditingController();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ApiService.getProfile();
      setState(() {
        _profile = p;
        _totpEnabled = p['totpEnabled'] == true;
        _avatarProvider = _decodeAvatar(p['avatar'] as String?);
        _displayName.text = (p['displayName'] ?? '').toString();
        _jobTitle.text = (p['jobTitle'] ?? '').toString();
        _department.text = (p['department'] ?? '').toString();
        _pronouns.text = (p['pronouns'] ?? '').toString();
        _phone.text = (p['phone'] ?? '').toString();
        _bio.text = (p['bio'] ?? '').toString();
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

  // Tap the avatar -> choose to view, change, or remove the photo.
  void _avatarOptions() {
    final hasPhoto = _avatarProvider != null;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.visibility, color: NHSTheme.blue),
                title: const Text('View photo'),
                onTap: () {
                  Navigator.pop(context);
                  _viewAvatar();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: NHSTheme.blue),
              title: Text(hasPhoto ? 'Change photo' : 'Add photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: NHSTheme.riskHigh),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewAvatar() {
    if (_avatarProvider == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image(image: _avatarProvider!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    try {
      final updated = await ApiService.updateProfile({'avatar': ''});
      ApiService.avatar = null;
      setState(() {
        _profile = updated;
        _avatarProvider = null;
      });
      _snack('Photo removed.');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final raw = await file.readAsBytes();
      // image_picker ignores maxWidth/quality on web, so resize ourselves —
      // any source image becomes a small 256px square JPEG (keeps payload tiny).
      final decoded = img.decodeImage(raw);
      if (decoded == null) {
        _snack('Unsupported image format.');
        return;
      }
      final square = img.copyResizeCropSquare(decoded, size: 512);
      final jpg = img.encodeJpg(square, quality: 90);
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(jpg)}';
      final updated = await ApiService.updateProfile({'avatar': dataUrl});
      ApiService.avatar = updated['avatar'] as String?; // keep app-bar in sync
      setState(() {
        _profile = updated;
        _avatarProvider = _decodeAvatar(updated['avatar'] as String?);
      });
      _snack('Photo updated.');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final updated = await ApiService.updateProfile({
        'displayName': _displayName.text.trim(),
        'jobTitle': _jobTitle.text.trim(),
        'department': _department.text.trim(),
        'pronouns': _pronouns.text.trim(),
        'phone': _phone.text.trim(),
        'bio': _bio.text.trim(),
      });
      setState(() => _profile = updated);
      _snack('Profile saved.');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final pwErr = passwordError(_newPw.text);
    if (pwErr != null) {
      _snack(pwErr);
      return;
    }
    if (_newPw.text == _current.text) {
      _snack('New password must be different from the current password');
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
    _displayName.dispose();
    _jobTitle.dispose();
    _department.dispose();
    _pronouns.dispose();
    _phone.dispose();
    _bio.dispose();
    _current.dispose();
    _newPw.dispose();
    _confirm.dispose();
    _twoFaCode.dispose();
    _twoFaPw.dispose();
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
        if (_profile != null) ...[
          _headerCard(),
          const SizedBox(height: 8),
          _accountInfoCard(),
          const SizedBox(height: 8),
          _editCard(),
        ],
        const SizedBox(height: 8),
        _passwordCard(),
        const SizedBox(height: 8),
        _twoFactorCard(),
        const SizedBox(height: 8),
        _privacyCard(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: NHSTheme.riskHigh,
            side: const BorderSide(color: NHSTheme.riskHigh),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log Out & Clear Session'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _fmtDate(dynamic epoch) {
    if (epoch == null) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(
        (epoch as num).round() * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _accountInfoCard() {
    final p = _profile!;
    Widget row(IconData ic, String label, String value) => ListTile(
          dense: true,
          leading: Icon(ic, color: NHSTheme.darkGrey, size: 20),
          title: Text(label),
          trailing: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        );
    return Card(
      child: Column(children: [
        row(Icons.person_outline, 'Username', '${p['username'] ?? '—'}'),
        const Divider(height: 1),
        row(Icons.badge_outlined, 'Role', '${p['role'] ?? '—'}'.toUpperCase()),
        const Divider(height: 1),
        row(Icons.event_outlined, 'Member since', _fmtDate(p['createdAt'])),
        const Divider(height: 1),
        row(Icons.lock_clock_outlined, 'Password changed',
            p['lastPasswordChange'] == null
                ? 'Never'
                : _fmtDate(p['lastPasswordChange'])),
      ]),
    );
  }

  Widget _headerCard() {
    final p = _profile!;
    final sub = [p['jobTitle'], p['department']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: _avatarOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: NHSTheme.blue,
                    backgroundImage: _avatarProvider,
                    child: _avatarProvider == null
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: NHSTheme.blue,
                      child: Icon(Icons.camera_alt,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (p['displayName'] ?? p['username'] ?? '-').toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                      if ((p['pronouns'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('· ${p['pronouns']}',
                            style: const TextStyle(
                                color: NHSTheme.darkGrey, fontSize: 13)),
                      ],
                    ],
                  ),
                  Text('${p['email'] ?? ''}',
                      style: const TextStyle(
                          color: NHSTheme.darkGrey, fontSize: 13)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: const TextStyle(
                            color: NHSTheme.darkGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: NHSTheme.riskLowBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${p['role'] ?? '-'}'.toUpperCase(),
                        style: const TextStyle(
                            color: NHSTheme.riskLow,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _field(_displayName, 'Display name', 100),
          _field(_jobTitle, 'Job title', 100),
          _field(_department, 'Department', 100),
          _field(_pronouns, 'Pronouns (e.g. she/her)', 30),
          _field(_phone, 'Phone', 30, keyboard: TextInputType.phone),
          _field(_bio, 'Bio', 300, maxLines: 3),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _savingProfile ? null : _saveProfile,
            icon: const Icon(Icons.save),
            label: Text(_savingProfile ? 'Saving…' : 'Save Profile'),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, int maxLen,
      {int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLength: maxLen,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          isDense: true,
        ),
      ),
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
          PasswordField(controller: _newPw, label: 'New password'),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(passwordHint,
                style: TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
          ),
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

  // ── Two-factor authentication ──

  Future<void> _start2FA() async {
    setState(() => _twoFaBusy = true);
    try {
      final res = await ApiService.setup2FA();
      setState(() => _twoFaSecret = res['secret']?.toString());
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _twoFaBusy = false);
    }
  }

  Future<void> _enable2FA() async {
    if (_twoFaCode.text.trim().length < 6) {
      _snack('Enter the 6-digit code from your authenticator app.');
      return;
    }
    setState(() => _twoFaBusy = true);
    try {
      await ApiService.enable2FA(_twoFaCode.text.trim());
      _twoFaSecret = null;
      _twoFaCode.clear();
      _snack('Two-factor authentication enabled.');
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _twoFaBusy = false);
    }
  }

  Future<void> _disable2FA() async {
    if (_twoFaPw.text.isEmpty) {
      _snack('Enter your password to disable 2FA.');
      return;
    }
    setState(() => _twoFaBusy = true);
    try {
      await ApiService.disable2FA(_twoFaPw.text);
      _twoFaPw.clear();
      _snack('Two-factor authentication disabled.');
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _twoFaBusy = false);
    }
  }

  Widget _twoFactorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Two-Factor Authentication',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _totpEnabled ? NHSTheme.riskLowBg : NHSTheme.riskHighBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_totpEnabled ? 'ENABLED' : 'DISABLED',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _totpEnabled
                          ? NHSTheme.riskLow
                          : NHSTheme.riskHigh)),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
              'Add a time-based one-time code from an authenticator app '
              '(Google Authenticator, Authy).',
              style: TextStyle(color: NHSTheme.darkGrey, fontSize: 13)),
          const SizedBox(height: 12),
          if (_totpEnabled) ...[
            PasswordField(controller: _twoFaPw, label: 'Password to disable'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: NHSTheme.riskHigh),
              onPressed: _twoFaBusy ? null : _disable2FA,
              icon: const Icon(Icons.lock_open),
              label: const Text('Disable 2FA'),
            ),
          ] else if (_twoFaSecret == null) ...[
            ElevatedButton.icon(
              onPressed: _twoFaBusy ? null : _start2FA,
              icon: const Icon(Icons.shield_outlined),
              label: Text(_twoFaBusy ? 'Please wait…' : 'Enable 2FA'),
            ),
          ] else ...[
            const Text('1. Add this secret to your authenticator app:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            SelectableText(_twoFaSecret!,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 12),
            const Text('2. Enter the 6-digit code to verify:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _twoFaCode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: '000000', counterText: ''),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _twoFaBusy ? null : _enable2FA,
              icon: const Icon(Icons.check),
              label: const Text('Verify & enable'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _privacyCard() {
    Widget item(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle,
                color: NHSTheme.riskLow, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(body,
                      style: const TextStyle(
                          color: NHSTheme.darkGrey, fontSize: 13)),
                ],
              ),
            ),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Privacy & Data Protection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          item('GDPR Article 5(1)(c) compliant',
              'Data minimisation — only essential fields collected.'),
          item('Session-scoped processing',
              'No patient data stored. Cleared on logout.'),
          item('Encrypted authentication',
              'Passwords hashed with bcrypt; sessions expire on inactivity.'),
          item('No third-party data sharing',
              'All processing local. No external analytics or tracking.'),
        ]),
      ),
    );
  }
}
