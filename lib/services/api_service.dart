import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    return _sendRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> get(String url) async {
    return _sendRequest(() async {
      final headers = await _getHeaders();
      return http.get(Uri.parse(url), headers: headers);
    });
  }

  Future<http.Response> patch(String url, Map<String, dynamic> body) async {
    return _sendRequest(() async {
      final headers = await _getHeaders();
      return http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() request, {bool isRetry = false}) async {
    try {
      final response = await request().timeout(_timeout);
      
      if (response.statusCode == 401 && !isRetry) {
        final success = await _refreshToken();
        if (success) {
          final retryResponse = await request().timeout(_timeout);
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(0, 'Le backend ne répond pas. Réessayez dans quelques instants.');
    } on ApiException {
      rethrow;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') || 
          errorString.contains('connection') ||
          errorString.contains('refused') ||
          errorString.contains('failed')) {
        throw const ApiException(0, 'Impossible de joindre le backend. Vérifiez votre connexion.');
      }
      throw ApiException(0, 'Une erreur inattendue est survenue: ${e.runtimeType}');
    }
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken == null) return false;

    try {
      // On utilise le endpoint /auth/refresh
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['accessToken'] != null) {
          await prefs.setString('jwt_token', data['accessToken']);
          if (data['refreshToken'] != null) {
            await prefs.setString('refresh_token', data['refreshToken']);
          }
          if (data['user'] != null) {
            await prefs.setString('user_data', jsonEncode(data['user']));
          }
          return true;
        }
      }
    } catch (_) {}
    
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    return false;
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final decoded = _decodeBody(response.body);
    final message = decoded?['message'] ?? decoded?['error'] ?? 'La requête a échoué.';
    throw ApiException(response.statusCode, message.toString());
  }

  Map<String, dynamic>? _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'message': decoded.toString()};
    } catch (_) {
      return {'message': body};
    }
  }
}
