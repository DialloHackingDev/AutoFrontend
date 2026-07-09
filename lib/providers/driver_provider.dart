import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class DriverProvider with ChangeNotifier {
  bool _isAvailable = false;
  bool _isLoading = false;
  final ApiService _apiService;

  DriverProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;

  void initAvailability(bool initial) {
    _isAvailable = initial;
  }

  Future<bool> setAvailability(bool available) async {
    _isLoading = true;
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
    } catch (e) {
      debugPrint('Set availability error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
