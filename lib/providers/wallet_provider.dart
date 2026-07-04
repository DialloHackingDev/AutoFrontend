import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class WalletProvider with ChangeNotifier {
  Wallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Wallet? get wallet => _wallet;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final balanceRes = await _apiService.get(ApiConstants.wallet);
      if (balanceRes.statusCode == 200) {
        final decodedBalance = jsonDecode(balanceRes.body);
        _wallet = Wallet.fromJson(decodedBalance is Map<String, dynamic>
            ? decodedBalance
            : {'balance': decodedBalance});
      }

      final historyRes = await _apiService.get(ApiConstants.walletHistory);
      if (historyRes.statusCode == 200) {
        final decodedHistory = jsonDecode(historyRes.body);
        if (decodedHistory is Map<String, dynamic>) {
          final historyPayload = decodedHistory['history'];
          final withdrawals = historyPayload is Map<String, dynamic>
              ? historyPayload['withdrawals']
              : null;
          final earnings = historyPayload is Map<String, dynamic>
              ? historyPayload['earnings']
              : null;

          final combined = <Map<String, dynamic>>[];
          if (withdrawals is List) {
            combined.addAll(withdrawals.whereType<Map<String, dynamic>>().toList());
          }
          if (earnings is List) {
            combined.addAll(earnings.whereType<Map<String, dynamic>>().toList());
          }

          _transactions = combined.map((json) => Transaction.fromJson(json)).toList();
        } else if (decodedHistory is List) {
          _transactions = decodedHistory.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Fetch wallet data error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> requestWithdrawal(double amount, String operateur, String telephone) async {
    try {
      final response = await _apiService.post(ApiConstants.withdrawals, {
        'montant': amount,
        'operateur': operateur,
        'telephone': telephone,
      });
      if (response.statusCode == 201) {
        await fetchWalletData();
        return true;
      }
    } catch (e) {
      debugPrint('Withdrawal error: $e');
    }
    return false;
  }
}
