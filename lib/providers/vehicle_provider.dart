import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _myVehicles = [];
  List<Vehicle> _availableVehicles = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService;

  VehicleProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  List<Vehicle> get myVehicles => _myVehicles;
  List<Vehicle> get availableVehicles => _availableVehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyVehicles() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.myVehicles);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myVehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetch vehicles error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAvailableVehicles({String? departure, String? destination}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = ApiConstants.vehiclesNearby;
      if (departure != null && destination != null) {
        url += '?departure=$departure&destination=$destination';
      }
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _availableVehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        _errorMessage = 'Aucun véhicule disponible pour ce trajet pour le moment.';
      }
    } catch (e) {
      _errorMessage = 'Impossible de charger les véhicules disponibles.';
      debugPrint('Fetch available vehicles error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addVehicle(String marque, String modele, String immat, int capacite) async {
    _errorMessage = null;
    try {
      final response = await _apiService.post(ApiConstants.vehicles, {
        'marque': marque,
        'modele': modele,
        'immatriculation': immat,
        'capacite': capacite,
      });
      if (response.statusCode == 201) {
        await fetchMyVehicles();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible d’ajouter le véhicule.';
      debugPrint('Add vehicle error: $e');
    }
    notifyListeners();
    return false;
  }
}
