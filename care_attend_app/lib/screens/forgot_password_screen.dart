import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
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
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address.');
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
            ? 'Email not configured — your test code is ${res['dev_code']}'
            : 'If that email is registered, a 6-digit code has been sent.';
        if (res['dev_code'] != null) _code.text = '${res['dev_code']}';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().isEmpty || _newPw.text.length < 8) {
      setState(() => _error = 'Enter the code and a new password (min 8).');
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
        const SnackBar(content: Text('Password reset! Please log in.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('We will email you a 6-digit code to reset your password.',
              style: TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_sent,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 12),
          if (!_sent)
            ElevatedButton(
              onPressed: _busy ? null : _sendCode,
              child: Text(_busy ? 'Sending…' : 'Send reset code'),
            ),
          if (_sent) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
            const SizedBox(height: 8),
            PasswordField(controller: _newPw, label: 'New password (min 8)'),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _busy ? null : _reset,
              child: Text(_busy ? 'Resetting…' : 'Reset password'),
            ),
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: const Text('Resend code'),
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
