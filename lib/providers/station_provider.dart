import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class StationProvider with ChangeNotifier {
  List<Station> _stations = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Station> get stations => _stations;
  bool get isLoading => _isLoading;

  Future<void> fetchStations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.stations);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _stations = data.map((json) => Station.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetch stations error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
