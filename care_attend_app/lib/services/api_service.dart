import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Backend host differs per platform:
  //   - Web / iOS simulator / desktop: localhost
  //   - Android emulator: 10.0.2.2 maps to the host's localhost
  // Override at build time with --dart-define=API_BASE=http://<ip>:5000.
  static const String _envBase =
      String.fromEnvironment('API_BASE', defaultValue: '');
  static final String baseUrl = _envBase.isNotEmpty
      ? _envBase
      : (kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000');
  static String? _token;
  static String role = 'user';
  static String? avatar; // base64 data-URL of the logged-in user's photo

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static bool get isAuthenticated => _token != null;

  // Frontend RBAC mirror of the backend role_required gating.
  static bool _has(List<String> roles) => roles.contains(role);
  static bool get canDashboard => _has(['staff', 'admin']);
  static bool get canSlots => _has(['staff', 'admin']);
  static bool get canNudge => _has(['staff', 'admin']);
  static bool get canBias => _has(['admin']);
  static bool get canEthics => _has(['admin']);
  static bool get canAdmin => _has(['admin']);

  static void clearSession() {
    _token = null;
    role = 'user';
    avatar = null;
  }

  // ── Auth ──

  // Public self-registration always creates a 'user'; the backend ignores any
  // role in the body. Admins elevate accounts via /api/admin/users/<id>/role.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    bool remember = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'remember': remember,
      }),
    );
    final data = _handleResponse(res);
    if (data.containsKey('token')) {
      _token = data['token'];
      // Pull the real role so the UI can gate features to match the backend.
      try {
        final profile = await getProfile();
        role = (profile['role'] ?? 'user').toString();
        avatar = profile['avatar'] as String?;
      } catch (_) {
        role = 'user';
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> fields) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
      body: jsonEncode(fields),
    );
    return _handleResponse(res);
  }

  // ── Two-factor authentication (TOTP) ──

  static Future<Map<String, dynamic>> setup2FA() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/profile/2fa/setup'),
      headers: _headers,
    );
    return _handleResponse(res); // {secret, uri}
  }

  static Future<Map<String, dynamic>> enable2FA(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/profile/2fa/enable'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> disable2FA(String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/profile/2fa/disable'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/profile/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return _handleResponse(res);
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );
    } catch (_) {}
    clearSession();
  }

  // ── Predict ──

  static Future<Map<String, dynamic>> predict({
    required int age,
    required int gender,
    required int leadTimeDays,
    required int smsReceived,
    required int priorDNACount,
    required int hypertension,
    required int diabetes,
    required int alcoholism,
    required int disability,
    required int imdDecile,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/predict'),
      headers: _headers,
      body: jsonEncode({
        'Age': age,
        'Gender': gender,
        'AppointmentLeadTimeDays': leadTimeDays,
        'SMSReceived': smsReceived,
        'PriorDNACount': priorDNACount,
        'Hypertension': hypertension,
        'Diabetes': diabetes,
        'Alcoholism': alcoholism,
        'Disability': disability,
        'IMDDecile': imdDecile,
      }),
    );
    return _handleResponse(res);
  }

  // ── Bias Audit ──

  static Future<Map<String, dynamic>> biasAudit() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/bias-audit'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ── Model Info ──

  static Future<Map<String, dynamic>> modelInfo() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/model-info'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ── Practice Dashboard ──

  static Future<Map<String, dynamic>> dashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/dashboard'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ── NHSX Ethics Framework ──

  static Future<Map<String, dynamic>> ethicsFramework() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/ethics-framework'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ── Slot Optimisation ──

  static Future<Map<String, dynamic>> slotOptimisation(
      List<Map<String, dynamic>> appointments) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/slot-optimisation'),
      headers: _headers,
      body: jsonEncode({'appointments': appointments}),
    );
    return _handleResponse(res);
  }

  // ── Patient Nudge ──

  static Future<Map<String, dynamic>> patientNudge({
    required Map<String, dynamic> patient,
    String language = 'en',
    String patientName = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/patient-nudge'),
      headers: _headers,
      body: jsonEncode({
        'patient': patient,
        'language': language,
        if (patientName.isNotEmpty) 'patientName': patientName,
      }),
    );
    return _handleResponse(res);
  }

  // ── Mock EHR ──

  static Future<Map<String, dynamic>> ehrLookup(String nhsNumber) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/ehr/lookup/$nhsNumber'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ── Admin: User Management (admin-only) ──

  static Future<Map<String, dynamic>> adminListUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> adminSetRole(
      String userId, String newRole) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': newRole}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> adminDeleteUser(String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  static Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401) {
      clearSession();
      throw ApiException('Session expired. Please log in again.');
    }
    if (res.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Request failed');
    }
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
