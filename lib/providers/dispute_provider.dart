import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/dispute_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class DisputeProvider with ChangeNotifier {
  List<DisputeModel> _disputes = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  List<DisputeModel> get disputes => _disputes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDisputes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.disputes);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _disputes = data.map((json) => DisputeModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = 'Impossible de charger les litiges.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createDispute({required String bookingId, required String description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.disputes, {
        'bookingId': bookingId,
        'description': description,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDisputes();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Impossible de soumettre le litige.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
