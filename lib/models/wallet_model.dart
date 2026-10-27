class Wallet {
  final String? id;
  final double balance;
  final double pendingBalance;
  final double withdrawableBalance;
  final double totalWithdrawalsRequested;
  final double totalCommissionPaid;

  /// Commission plateforme prélevée sur chaque retrait (ex. 0.10 = 10 %)
  final double commissionRate;

  Wallet({
    this.id,
    required this.balance,
    required this.pendingBalance,
    required this.withdrawableBalance,
    this.totalWithdrawalsRequested = 0,
    this.totalCommissionPaid = 0,
    this.commissionRate = 0.1,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final payload = json['wallet'] is Map<String, dynamic>
        ? json['wallet'] as Map<String, dynamic>
        : json;

    return Wallet(
      id: payload['id']?.toString(),
      balance: _toDouble(payload['balance']),
      pendingBalance: _toDouble(payload['pendingBalance']),
      withdrawableBalance: _toDouble(payload['withdrawableBalance']),
      totalWithdrawalsRequested: _toDouble(payload['totalWithdrawalsRequested']),
      totalCommissionPaid: _toDouble(payload['totalCommissionPaid']),
      commissionRate: payload['commissionRate'] == null ? 0.1 : _toDouble(payload['commissionRate']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class Transaction {
  final String id;
  final double montant;
  final String description;
  final DateTime createdAt;
  final bool isCredit;

  Transaction({
    required this.id,
    required this.montant,
    required this.description,
    required this.createdAt,
    required this.isCredit,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amount = json['montant'] ?? json['amount'] ?? json['montantNet'] ?? 0;
    final dateValue = json['createdAt'] ?? json['date'] ?? DateTime.now().toIso8601String();
    final description = json['description'] ??
        json['reference'] ??
        (json['bookingId'] != null ? 'Paiement de trajet' : 'Transaction');

    return Transaction(
      id: json['id']?.toString() ?? json['bookingId']?.toString() ?? DateTime.now().toIso8601String(),
      montant: Wallet._toDouble(amount),
      description: description.toString(),
      createdAt: dateValue is DateTime ? dateValue : DateTime.parse(dateValue.toString()),
      // Gain = lié à une réservation ; un retrait n'a pas de bookingId
      isCredit: json['isCredit'] ?? json['bookingId'] != null,
    );
  }
}
