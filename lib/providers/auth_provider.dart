import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  String? _refreshToken;
  String? _errorMessage;
  bool _isLoading = false;
  final ApiService _apiService;

  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userJson = prefs.getString('user_data');

    if (token == null || userJson == null) {
      await _clearSession();
      return;
    }

    _token = token;
    _refreshToken = prefs.getString('refresh_token');
    _user = User.fromJson(jsonDecode(userJson));
    notifyListeners();
  }

  Future<bool> login(String telephone, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(ApiConstants.authLogin, {
        'telephone': normalizePhone(telephone),
        'motDePasse': password,
      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw const ApiException(0, 'La réponse du backend est incomplète.');
      }

      final user = User.fromJson(userData);
      await _persistSession(token: token, refreshToken: refreshToken, user: user);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de se connecter. Veuillez réessayer.';
      debugPrint('Login error: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> register({
    required String nom,
    required String telephone,
    required String password,
    required String role,
    String? numeroPermis,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post(ApiConstants.authRegister, {
        'nom': nom,
        'telephone': normalizePhone(telephone),
        'motDePasse': password,
        'role': role,
        if (numeroPermis != null) 'numeroPermis': numeroPermis,
      });

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw const ApiException(0, 'La réponse du backend est incomplète.');
      }

      final user = User.fromJson(userData);
      await _persistSession(token: token, refreshToken: refreshToken, user: user);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de créer le compte. Vérifiez vos informations.';
      debugPrint('Register error: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _apiService.post(ApiConstants.authLogout, {});
      } catch (_) {
        // Ensure local logout still succeeds even if the backend rejects the logout call.
      }
    }

    await _clearSession();
  }

  Future<bool> syncProfile() async {
    if (_token == null) {
      return false;
    }

    try {
      final response = await _apiService.get(ApiConstants.authMe);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(data);
      await _persistSession(token: _token, refreshToken: _refreshToken, user: user);
      return true;
    } catch (e) {
      debugPrint('Sync profile error: $e');
      return false;
    }
  }

  Future<void> _persistSession({
    required String? token,
    required String? refreshToken,
    required User? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (token != null) {
      await prefs.setString('jwt_token', token);
    } else {
      await prefs.remove('jwt_token');
    }

    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    } else {
      await prefs.remove('refresh_token');
    }

    if (user != null) {
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } else {
      await prefs.remove('user_data');
    }

    _token = token;
    _refreshToken = refreshToken;
    _user = user;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    _token = null;
    _refreshToken = null;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Le backend attend un numéro international (+224…).
  /// Accepte aussi les saisies locales : "620 00 00 00", "00224…", "224…".
  static String normalizePhone(String input) {
    var phone = input.replaceAll(RegExp(r'[\s.-]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('00')) return '+${phone.substring(2)}';
    if (phone.startsWith('224') && phone.length > 9) return '+$phone';
    return '+224$phone';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
