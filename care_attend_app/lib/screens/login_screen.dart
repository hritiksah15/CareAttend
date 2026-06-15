import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../widgets/password_field.dart';
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

  // Register controllers
  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  String _regRole = 'staff';

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
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(username: _loginUsername.text.trim()),
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
    if (_regPassword.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
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
        role: _regRole,
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // NHS Blue Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [NHSTheme.blue, NHSTheme.darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
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
                  const SizedBox(height: 16),
                  const Text('Care Attend',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('NHS Predictive Risk Assessment',
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
                child: const Column(
                  children: [
                    Text('Data Protection Notice',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NHSTheme.riskLow)),
                    SizedBox(height: 6),
                    Text('No patient data is stored on this device.',
                        style:
                            TextStyle(fontSize: 13, color: NHSTheme.darkGrey)),
                    Text('All session data is cleared on close.',
                        style:
                            TextStyle(fontSize: 13, color: NHSTheme.darkGrey)),
                    Text('GDPR Article 5(1)(c) compliant.',
                        style:
                            TextStyle(fontSize: 13, color: NHSTheme.darkGrey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const Text('Welcome Back',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Sign in to access your practice dashboard',
            style: TextStyle(fontSize: 14, color: NHSTheme.darkGrey)),
        const SizedBox(height: 24),
        TextField(
          controller: _loginUsername,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'staff@nhspractice.nhs.uk',
          ),
        ),
        const SizedBox(height: 16),
        PasswordField(controller: _loginPassword, label: 'Password'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: const Text('Forgot password?'),
          ),
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
              : const Text('LOG IN'),
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
          child: const Text('CREATE NEW ACCOUNT',
              style: TextStyle(
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
        const Text('Register for practice access',
            style: TextStyle(fontSize: 14, color: NHSTheme.darkGrey)),
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
        PasswordField(controller: _regPassword, label: 'Password (min 8)'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _regRole,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (v) => setState(() => _regRole = v ?? 'staff'),
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
          child: const Text('BACK TO LOGIN',
              style: TextStyle(
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
            child: Text('OR',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
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
