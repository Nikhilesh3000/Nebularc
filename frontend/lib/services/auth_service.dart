import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true; // True while restoring session on app start

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;
  bool get isLoading => _isLoading;

  String get baseUrl => AppConfig.backendUrl;

  // ---------------------------------------------------------------------------
  // Init — called on app startup to restore session
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');

      if (savedToken == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Verify token with backend
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $savedToken'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        _token = savedToken;
      } else {
        // Token expired/invalid — clear it
        await prefs.remove('auth_token');
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------
  Future<String?> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], data['user']);
        return null; // null = success
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Network error. Is the backend running?';
    }
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], data['user']);
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Login failed';
      }
    } catch (e) {
      return 'Network error. Is the backend running?';
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _user = null;
    _token = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------
  Future<void> _saveSession(String token, Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _user = User.fromJson(userJson);
    notifyListeners();
  }
}
