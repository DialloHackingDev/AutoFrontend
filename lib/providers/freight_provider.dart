import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/freight_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class FreightProvider with ChangeNotifier {
  List<Freight> _freights = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Freight> get freights => _freights;
  bool get isLoading => _isLoading;

  Future<void> fetchFreights() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.freight);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _freights = data.map((json) => Freight.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetch freights error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createFreight({
    required double poids,
    required String destination,
    String? type,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.freight, {
        'poids': poids,
        'destination': destination,
        'type': type,
        'description': description,
      });
      if (response.statusCode == 201) {
        await fetchFreights();
        return true;
      }
    } catch (e) {
      debugPrint('Create freight error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
