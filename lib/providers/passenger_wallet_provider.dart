import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/passenger_wallet_model.dart';
import '../services/api_service.dart';

/// Portefeuille AutoConnect du passager : solde, historique, recharge Mobile Money.
class PassengerWalletProvider with ChangeNotifier {
  final ApiService _apiService;
  PassengerWallet? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  PassengerWalletProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  PassengerWallet? get wallet => _wallet;
  double get balance => _wallet?.balance ?? 0;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWallet() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.passengerWallet);
      _wallet = PassengerWallet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de charger le portefeuille.';
      debugPrint('Fetch wallet error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Lance une recharge. Retourne la transaction créée (à suivre avec [checkTransaction]).
  Future<WalletTransactionModel?> topUp({
    required int montant,
    required String methode,
    required String telephone,
  }) async {
    _errorMessage = null;
    try {
      final response = await _apiService.post(ApiConstants.passengerWalletTopUp, {
        'montant': montant,
        'methode': methode,
        'telephone': telephone,
      });
      return WalletTransactionModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'La recharge n’a pas pu être lancée.';
      debugPrint('Top-up error: $e');
    }
    notifyListeners();
    return null;
  }

  /// Statut de la recharge, vérifié par le serveur auprès de l'opérateur.
  Future<WalletTransactionModel?> checkTransaction(String id) async {
    try {
      final response = await _apiService.get(ApiConstants.passengerWalletTransaction(id));
      final transaction = WalletTransactionModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      if (!transaction.isPending) {
        await fetchWallet();
      }
      return transaction;
    } catch (e) {
      debugPrint('Check transaction error: $e');
      return null;
    }
  }
}
