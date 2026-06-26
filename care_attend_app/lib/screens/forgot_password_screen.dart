import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPw = TextEditingController();

  bool _sent = false;
  bool _busy = false;
  String? _info;
  String? _error;

  Future<void> _sendCode() async {
    final t = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = t.fpEnterEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await ApiService.forgotPassword(email);
      setState(() {
        _sent = true;
        _info = res['dev_code'] != null
            ? t.fpDevCode('${res['dev_code']}')
            : t.fpCodeSent;
        if (res['dev_code'] != null) _code.text = '${res['dev_code']}';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final t = AppLocalizations.of(context);
    if (_code.text.trim().isEmpty) {
      setState(() => _error = t.fpEnterCode);
      return;
    }
    final pwErr = passwordError(_newPw.text);
    if (pwErr != null) {
      setState(() => _error = pwErr);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.resetPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _newPw.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fpResetDone)),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.fpTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.fpSubtitle,
              style: const TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_sent,
            decoration: InputDecoration(labelText: t.emailAddress),
          ),
          const SizedBox(height: 12),
          if (!_sent)
            ElevatedButton(
              onPressed: _busy ? null : _sendCode,
              child: Text(_busy ? t.fpSending : t.fpSendCode),
            ),
          if (_sent) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: t.fpCodeField),
            ),
            const SizedBox(height: 8),
            PasswordField(controller: _newPw, label: t.profileNewPw),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(passwordHint,
                  style: TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _busy ? null : _reset,
              child: Text(_busy ? t.fpResetting : t.fpResetBtn),
            ),
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: Text(t.fpResend),
            ),
          ],
          const SizedBox(height: 12),
          if (_info != null)
            Text(_info!, style: const TextStyle(color: NHSTheme.riskLow)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)),
        ],
      ),
    );
  }
}
