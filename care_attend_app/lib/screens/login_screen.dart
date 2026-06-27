import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../widgets/password_field.dart';
import '../widgets/language_button.dart';
import '../widgets/offline_banner.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showRegister = false;
  bool _loading = false;
  String? _error;
  String? _success;

  // Login controllers
  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();

  bool _remember = false;

  // Register controllers
  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();

  Future<void> _handleLogin() async {
    if (_loginUsername.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.login(
        username: _loginUsername.text.trim(),
        password: _loginPassword.text,
        remember: _remember,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            username: _loginUsername.text.trim(),
            remember: _remember,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connection error. Is the server running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_regUsername.text.trim().isEmpty ||
        _regEmail.text.trim().isEmpty ||
        _regPassword.text.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    final pwErr = passwordError(_regPassword.text);
    if (pwErr != null) {
      setState(() => _error = pwErr);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await ApiService.register(
        username: _regUsername.text.trim(),
        email: _regEmail.text.trim(),
        password: _regPassword.text,
      );
      setState(() {
        _success = 'Account created. You can now log in.';
        _error = null;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showRegister = false);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connection error. Is the server running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
        child: Column(
          children: [
            // NHS Blue Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [NHSTheme.blue, NHSTheme.darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LanguageButton(color: Colors.white),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('+',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(t.appTitle,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(t.appSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),

            // Form area
            Padding(
              padding: const EdgeInsets.all(24),
              child: _showRegister ? _buildRegisterForm() : _buildLoginForm(),
            ),

            // Data Protection Notice (GDPR NFR-01)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NHSTheme.riskLowBg,
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(t.dataProtection,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NHSTheme.riskLow)),
                    const SizedBox(height: 6),
                    Text(t.noDataStored,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(t.sessionCleared,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(t.gdprCompliant,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
            ),
          ],
        ),
    );
  }

  Widget _buildLoginForm() {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        Text(t.welcomeBack,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(t.signInDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        TextField(
          controller: _loginUsername,
          decoration: InputDecoration(
            labelText: t.emailAddress,
            hintText: 'staff@nhspractice.nhs.uk',
          ),
        ),
        const SizedBox(height: 16),
        PasswordField(controller: _loginPassword, label: t.password),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: MergeSemantics(
                child: InkWell(
                  onTap: () => setState(() => _remember = !_remember),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: (v) =>
                            setState(() => _remember = v ?? false),
                      ),
                      Flexible(
                        child: Text(t.rememberMe,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: Text(t.forgotPassword),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null) _buildError(_error!),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _handleLogin,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(t.login),
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => setState(() {
            _showRegister = true;
            _error = null;
          }),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: NHSTheme.blue, width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(t.createAccount,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        const Text('Create Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Register for practice access',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        TextField(
          controller: _regUsername,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'e.g. asha.patel',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _regEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'staff@nhspractice.nhs.uk',
          ),
        ),
        const SizedBox(height: 16),
        PasswordField(controller: _regPassword, label: 'Password'),
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(passwordHint,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) _buildError(_error!),
        if (_success != null) _buildSuccess(_success!),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _handleRegister,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('CREATE ACCOUNT'),
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => setState(() {
            _showRegister = false;
            _error = null;
            _success = null;
          }),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: NHSTheme.blue, width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(AppLocalizations.of(context).backToLogin,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildError(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NHSTheme.riskHighBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(msg,
            style: const TextStyle(color: NHSTheme.riskHigh, fontSize: 14)),
      );

  Widget _buildSuccess(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NHSTheme.riskLowBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(msg,
            style: const TextStyle(color: NHSTheme.riskLow, fontSize: 14)),
      );

  Widget _buildDivider() => Row(
        children: [
          const Expanded(child: Divider(color: NHSTheme.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(AppLocalizations.of(context).orText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          const Expanded(child: Divider(color: NHSTheme.grey)),
        ],
      );

  @override
  void dispose() {
    _loginUsername.dispose();
    _loginPassword.dispose();
    _regUsername.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    super.dispose();
  }
}
