class Wallet {
  final String? id;
  final double balance;
  final double pendingBalance;
  final double withdrawableBalance;
  final double totalWithdrawalsRequested;
  final double totalCommissionPaid;

  Wallet({
    this.id,
    required this.balance,
    required this.pendingBalance,
    required this.withdrawableBalance,
    this.totalWithdrawalsRequested = 0,
    this.totalCommissionPaid = 0,
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
      isCredit: json['isCredit'] ?? json['bookingId'] != null || json['montant'] != null,
    );
  }
}
