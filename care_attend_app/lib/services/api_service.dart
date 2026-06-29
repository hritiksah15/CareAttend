import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
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

  // Last patient assessed this session — lets the Nudge screen prefill from the
  // most recent Assessment (web mirrors the assessment form directly; the app
  // splits the forms, so we stash the raw inputs here).
  static Map<String, dynamic>? lastPatient;

  // True after a request fails for connectivity reasons (timeout / no route to
  // host), cleared the next time any request succeeds. Drives the global offline
  // banner. We key off real request outcomes rather than connectivity_plus
  // because the only thing that matters here is whether the backend is
  // reachable — on web navigator.onLine reports true even when it is not.
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  // Generic (non-localized) fallback for connectivity failures surfaced through
  // ApiException; the always-visible OfflineBanner carries the localized UX.
  static const String _offlineMessage =
      "Can't reach the server. Check your connection and try again.";

  static const Duration _timeout = Duration(seconds: 12);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static bool get isAuthenticated => _token != null;

  // Frontend RBAC mirror of the backend role_required gating.
  static bool _has(List<String> roles) => roles.contains(role);
  static bool get canDashboard => _has(['staff', 'admin']);
  static bool get canClinic => _has(['staff', 'admin']);
  static bool get canSlots => _has(['staff', 'admin']);
  static bool get canNudge => _has(['staff', 'admin']);
  static bool get canBias => _has(['admin']);
  static bool get canEthics => _has(['admin']);
  static bool get canAdmin => _has(['admin']);

  static void clearSession() {
    _token = null;
    role = 'user';
    avatar = null;
    riskHistory.clear();
  }

  // ── Central transport ──────────────────────────────────────────────
  // One injection point for timeout, connectivity detection, and retry.
  // GETs are idempotent → safe to auto-retry once. Mutations are NOT
  // auto-retried (a re-fired POST double-books appointments / re-submits
  // feedback); the user re-taps the action to retry instead.

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(
          queryParameters: (query == null || query.isEmpty) ? null : query);

  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call,
      {bool retryable = false}) async {
    for (var attempt = 0;; attempt++) {
      try {
        final res = await call().timeout(_timeout);
        offline.value = false; // a response (even a 4xx) means we are online
        return _handleResponse(res);
      } on ApiException {
        rethrow; // server replied with an error body — not a connectivity issue
      } catch (_) {
        // Connectivity failure: TimeoutException, or http.ClientException
        // (web) / SocketException (mobile, surfaced as a generic error here).
        if (retryable && attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue; // single retry for idempotent GETs
        }
        offline.value = true;
        throw ApiException(_offlineMessage);
      }
    }
  }

  static Future<Map<String, dynamic>> _get(String path,
          {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers),
          retryable: true);

  static Future<Map<String, dynamic>> _post(String path, {Object? body}) =>
      _send(() => http.post(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body)));

  static Future<Map<String, dynamic>> _put(String path, {Object? body}) =>
      _send(() => http.put(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body)));

  static Future<Map<String, dynamic>> _patch(String path, {Object? body}) =>
      _send(() => http.patch(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body)));

  static Future<Map<String, dynamic>> _delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  // ── Auth ──

  // Public self-registration always creates a 'user'; the backend ignores any
  // role in the body. Admins elevate accounts via /api/admin/users/<id>/role.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) =>
      _post('/auth/register',
          body: {'username': username, 'email': email, 'password': password});

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    bool remember = false,
  }) async {
    final data = await _post('/auth/login', body: {
      'username': username,
      'password': password,
      'remember': remember
    });
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

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      _post('/auth/forgot-password', body: {'email': email});

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _post('/auth/reset-password',
          body: {'email': email, 'code': code, 'newPassword': newPassword});

  static Future<Map<String, dynamic>> getProfile() => _get('/api/profile');

  static Future<Map<String, dynamic>> updateProfile(
          Map<String, dynamic> fields) =>
      _put('/api/profile', body: fields);

  // ── Two-factor authentication (TOTP) ──

  static Future<Map<String, dynamic>> setup2FA() =>
      _post('/api/profile/2fa/setup'); // {secret, uri}

  static Future<Map<String, dynamic>> enable2FA(String code) =>
      _post('/api/profile/2fa/enable', body: {'code': code});

  static Future<Map<String, dynamic>> disable2FA(String password) =>
      _post('/api/profile/2fa/disable', body: {'password': password});

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _post('/api/profile/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  static Future<void> logout() async {
    try {
      await _post('/auth/logout');
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
  }) =>
      _post('/api/predict', body: {
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
      });

  // Session risk-trajectory (client-side, mirrors the website).
  static const int riskHistoryLimit = 5;
  static final List<Map<String, dynamic>> riskHistory = [];

  static void recordRiskHistory(Map<String, dynamic> entry) {
    riskHistory.add(entry);
    if (riskHistory.length > riskHistoryLimit) {
      riskHistory.removeRange(0, riskHistory.length - riskHistoryLimit);
    }
  }

  // ── Batch CSV scoring ──

  static Future<String> batchPredict(List<int> bytes, String filename) async {
    try {
      final req = http.MultipartRequest('POST', _uri('/api/batch'));
      if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename.endsWith('.csv') ? filename : '$filename.csv'));
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      offline.value = false;
      if (res.statusCode >= 400) {
        String msg = 'Batch failed';
        try {
          msg = (jsonDecode(res.body) as Map)['error']?.toString() ?? msg;
        } catch (_) {}
        throw ApiException(msg);
      }
      return res.body; // CSV text
    } on ApiException {
      rethrow;
    } catch (_) {
      offline.value = true;
      throw ApiException(_offlineMessage);
    }
  }

  // ── Prediction feedback ──

  static Future<Map<String, dynamic>> submitFeedback(
          String predictionId, String outcome) =>
      _post('/api/feedback',
          body: {'prediction_id': predictionId, 'outcome': outcome});

  static Future<Map<String, dynamic>> feedbackSummary() =>
      _get('/api/feedback/summary');

  // ── Carer / family proxy ──

  static Future<Map<String, dynamic>> createCarerProxy(
          Map<String, dynamic> fields) =>
      _post('/api/carer-proxy', body: fields);

  // ── Rigorous evaluation (5-fold cross-validation + McNemar) ──

  static Future<Map<String, dynamic>> crossValidation() =>
      _post('/api/evaluation/cross-validation');

  // ── Bias Audit ──

  static Future<Map<String, dynamic>> biasAudit() => _get('/api/bias-audit');

  // ── Model Info ──

  static Future<Map<String, dynamic>> modelInfo() => _get('/api/model-info');

  // ── Practice Dashboard ──

  static Future<Map<String, dynamic>> dashboard() => _get('/api/dashboard');

  static Future<Map<String, dynamic>> operationalOutcomes(
      {String? from, String? to}) {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    return _get('/api/operational-outcomes', query: params);
  }

  // ── Appointment clinic list ──

  static Future<Map<String, dynamic>> createAppointments(
          Map<String, dynamic> payload) =>
      _post('/api/appointments', body: payload);

  static Future<Map<String, dynamic>> clinicList(String date) =>
      _get('/api/clinic-list', query: {'date': date});

  static Future<Map<String, dynamic>> updateAppointmentStatus(
          String appointmentId, String status) =>
      _patch('/api/appointments/$appointmentId/status',
          body: {'status': status});

  static Future<Map<String, dynamic>> scheduleNotification({
    required String patientId,
    required String riskTier,
    required String appointmentDate,
  }) =>
      _post('/api/notifications/schedule', body: {
        'patient_id': patientId,
        'risk_tier': riskTier,
        'appointment_date': appointmentDate,
      });

  static Future<Map<String, dynamic>> createOutreachAction(
          Map<String, dynamic> fields) =>
      _post('/api/actions', body: fields);

  // ── NHSX Ethics Framework ──

  static Future<Map<String, dynamic>> ethicsFramework() =>
      _get('/api/ethics-framework');

  // ── Slot Optimisation ──

  static Future<Map<String, dynamic>> slotOptimisation(
          List<Map<String, dynamic>> appointments) =>
      _post('/api/slot-optimisation', body: {'appointments': appointments});

  // ── Patient Nudge ──

  static Future<Map<String, dynamic>> patientNudge({
    required Map<String, dynamic> patient,
    String language = 'en',
    String patientName = '',
  }) =>
      _post('/api/patient-nudge', body: {
        'patient': patient,
        'language': language,
        if (patientName.isNotEmpty) 'patientName': patientName,
      });

  // ── Mock EHR ──

  static Future<Map<String, dynamic>> ehrLookup(String nhsNumber) =>
      _get('/api/ehr/lookup/$nhsNumber');

  // ── Admin: User Management (admin-only) ──

  static Future<Map<String, dynamic>> adminListUsers() =>
      _get('/api/admin/users');

  static Future<Map<String, dynamic>> auditLog() => _get('/api/audit-log');

  static Future<Map<String, dynamic>> adminSetRole(
          String userId, String newRole) =>
      _put('/api/admin/users/$userId/role', body: {'role': newRole});

  static Future<Map<String, dynamic>> adminDeleteUser(String userId) =>
      _delete('/api/admin/users/$userId');

  static Map<String, dynamic> _handleResponse(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      if (res.statusCode == 401) {
        clearSession();
        throw ApiException('Session expired. Please log in again.');
      }
      if (res.statusCode >= 400) {
        throw ApiException('Request failed (${res.statusCode}).');
      }
      throw ApiException('Invalid server response.');
    }
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
