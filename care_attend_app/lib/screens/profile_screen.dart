import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';
import '../widgets/ui.dart';
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
    final t = AppLocalizations.of(context);
    final hasPhoto = _avatarProvider != null;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto)
              ListTile(
                leading: Icon(Icons.visibility,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(t.profileViewPhoto),
                onTap: () {
                  Navigator.pop(context);
                  _viewAvatar();
                },
              ),
            ListTile(
              leading: Icon(Icons.photo_camera,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(hasPhoto ? t.profileChangePhoto : t.profileAddPhoto),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            if (hasPhoto)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: NHSTheme.riskHigh),
                title: Text(t.profileRemovePhoto),
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
    final t = AppLocalizations.of(context);
    try {
      final updated = await ApiService.updateProfile({'avatar': ''});
      ApiService.avatar = null;
      setState(() {
        _profile = updated;
        _avatarProvider = null;
      });
      _snack(t.profilePhotoRemoved);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _pickAvatar() async {
    final t = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final raw = await file.readAsBytes();
      // image_picker ignores maxWidth/quality on web, so resize ourselves —
      // any source image becomes a small 256px square JPEG (keeps payload tiny).
      final decoded = img.decodeImage(raw);
      if (decoded == null) {
        _snack(t.profileUnsupportedImage);
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
      _snack(t.profilePhotoUpdated);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _saveProfile() async {
    final t = AppLocalizations.of(context);
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
      _snack(t.profileSaved);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final t = AppLocalizations.of(context);
    final pwErr = passwordError(_newPw.text);
    if (pwErr != null) {
      _snack(pwErr);
      return;
    }
    if (_newPw.text == _current.text) {
      _snack(t.profilePwDifferent);
      return;
    }
    if (_newPw.text != _confirm.text) {
      _snack(t.profilePwMismatch);
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
      _snack(t.profilePwChanged);
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
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(t.personalAccount,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
        if (_error != null)
          AppCard(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: NHSTheme.riskHigh))),
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
          label: Text(t.profileLogoutClear),
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
    final d =
        DateTime.fromMillisecondsSinceEpoch((epoch as num).round() * 1000);
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _accountInfoCard() {
    final t = AppLocalizations.of(context);
    final p = _profile!;
    Widget row(IconData ic, String label, String value) => ListTile(
          dense: true,
          leading: Icon(ic,
              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          title: Text(label),
          trailing:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        row(Icons.person_outline, t.profileUsername, '${p['username'] ?? '—'}'),
        const Divider(height: 1),
        row(Icons.badge_outlined, t.profileRole,
            '${p['role'] ?? '—'}'.toUpperCase()),
        const Divider(height: 1),
        row(Icons.event_outlined, t.profileMemberSince,
            _fmtDate(p['createdAt'])),
        const Divider(height: 1),
        row(
            Icons.lock_clock_outlined,
            t.profilePasswordChanged,
            p['lastPasswordChange'] == null
                ? t.profileNever
                : _fmtDate(p['lastPasswordChange'])),
      ]),
    );
  }

  Widget _headerCard() {
    final t = AppLocalizations.of(context);
    final p = _profile!;
    final sub = [p['jobTitle'], p['department']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: t.profilePhotoA11y,
            child: GestureDetector(
              onTap: _avatarOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: NHSTheme.blue,
                    backgroundImage: _avatarProvider,
                    child: _avatarProvider == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 30)
                        : null,
                  ),
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: NHSTheme.blue,
                      child:
                          Icon(Icons.camera_alt, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
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
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ],
                ),
                Text('${p['email'] ?? ''}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
    );
  }

  Widget _editCard() {
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.profileEdit,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field(_displayName, t.profileDisplayName, 100),
        _field(_jobTitle, t.profileJobTitle, 100),
        _field(_department, t.profileDepartment, 100),
        _field(_pronouns, t.profilePronouns, 30),
        _field(_phone, t.profilePhone, 30, keyboard: TextInputType.phone),
        _field(_bio, t.profileBio, 300, maxLines: 3),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _savingProfile ? null : _saveProfile,
          icon: const Icon(Icons.save),
          label: Text(_savingProfile ? t.profileSaving : t.profileSaveBtn),
        ),
      ]),
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
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.profileChangePassword,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        PasswordField(controller: _current, label: t.profileCurrentPw),
        const SizedBox(height: 10),
        PasswordField(controller: _newPw, label: t.profileNewPw),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(passwordHint,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 10),
        PasswordField(controller: _confirm, label: t.profileConfirmPw),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _saving ? null : _changePassword,
          icon: const Icon(Icons.lock_reset),
          label: Text(_saving ? t.profileSaving : t.profileUpdatePw),
        ),
      ]),
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
    final t = AppLocalizations.of(context);
    if (_twoFaCode.text.trim().length < 6) {
      _snack(t.profile2faEnterCode);
      return;
    }
    setState(() => _twoFaBusy = true);
    try {
      await ApiService.enable2FA(_twoFaCode.text.trim());
      _twoFaSecret = null;
      _twoFaCode.clear();
      _snack(t.profile2faEnabled);
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _twoFaBusy = false);
    }
  }

  Future<void> _disable2FA() async {
    final t = AppLocalizations.of(context);
    if (_twoFaPw.text.isEmpty) {
      _snack(t.profile2faEnterPw);
      return;
    }
    setState(() => _twoFaBusy = true);
    try {
      await ApiService.disable2FA(_twoFaPw.text);
      _twoFaPw.clear();
      _snack(t.profile2faDisabled);
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _twoFaBusy = false);
    }
  }

  Widget _twoFactorCard() {
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(t.profile2faTitle,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _totpEnabled ? NHSTheme.riskLowBg : NHSTheme.riskHighBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
                _totpEnabled
                    ? t.profile2faEnabledBadge
                    : t.profile2faDisabledBadge,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        _totpEnabled ? NHSTheme.riskLow : NHSTheme.riskHigh)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(t.profile2faDesc,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 12),
        if (_totpEnabled) ...[
          PasswordField(controller: _twoFaPw, label: t.profile2faPwDisable),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: NHSTheme.riskHigh),
            onPressed: _twoFaBusy ? null : _disable2FA,
            icon: const Icon(Icons.lock_open),
            label: Text(t.profile2faDisableBtn),
          ),
        ] else if (_twoFaSecret == null) ...[
          ElevatedButton.icon(
            onPressed: _twoFaBusy ? null : _start2FA,
            icon: const Icon(Icons.shield_outlined),
            label: Text(_twoFaBusy ? t.profile2faWait : t.profile2faEnableBtn),
          ),
        ] else ...[
          Text(t.profile2faStep1, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          SelectableText(_twoFaSecret!,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Text(t.profile2faStep2, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _twoFaCode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration:
                const InputDecoration(labelText: '000000', counterText: ''),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _twoFaBusy ? null : _enable2FA,
            icon: const Icon(Icons.check),
            label: Text(t.profile2faVerify),
          ),
        ],
      ]),
    );
  }

  Widget _privacyCard() {
    Widget item(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, color: NHSTheme.riskLow, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(body,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            ),
          ]),
        );
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.profilePrivacy,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        item(t.profilePrivGdprT, t.profilePrivGdprB),
        item(t.profilePrivSessionT, t.profilePrivSessionB),
        item(t.profilePrivEncT, t.profilePrivEncB),
        item(t.profilePrivShareT, t.profilePrivShareB),
      ]),
    );
  }
}
