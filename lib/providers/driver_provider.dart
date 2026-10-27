import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class DriverProvider with ChangeNotifier {
  bool _isAvailable = false;
  bool _isVerified = false;
  bool _profileLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService;

  DriverProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  bool get isAvailable => _isAvailable;

  /// Un chauffeur doit être vérifié par l'administrateur avant de pouvoir se mettre en ligne
  bool get isVerified => _isVerified;
  bool get profileLoaded => _profileLoaded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initAvailability(bool initial) {
    _isAvailable = initial;
  }

  /// Charge le statut réel du chauffeur (disponibilité, vérification) depuis le profil.
  Future<void> loadProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.authMe);
      final data = jsonDecode(response.body);
      final driver = data is Map<String, dynamic> ? data['driver'] : null;
      if (driver is Map<String, dynamic>) {
        _isAvailable = driver['isAvailable'] == true;
        _isVerified = driver['isVerified'] == true;
      }
      _profileLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Load driver profile error: $e');
    }
  }

  Future<bool> setAvailability(bool available) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(ApiConstants.driverAvailability, {
        'isAvailable': available,
      });

      if (response.statusCode == 200) {
        _isAvailable = available;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de changer votre disponibilité. Vérifiez votre connexion.';
      debugPrint('Set availability error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
