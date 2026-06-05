import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your Flask backend URL
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator -> localhost
  static String? _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static bool get isAuthenticated => _token != null;

  static void clearSession() {
    _token = null;
  }

  // ── Auth ──

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String role = 'staff',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = _handleResponse(res);
    if (data.containsKey('token')) {
      _token = data['token'];
    }
    return data;
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
