/// Mouvement du portefeuille AutoConnect du passager.
class WalletTransactionModel {
  final String id;

  /// TOPUP (recharge), PAYMENT (paiement d'un trajet), REFUND (remboursement)
  final String type;
  final double montant;

  /// PENDING, PROCESSING, COMPLETED, FAILED
  final String statut;
  final String? methode;
  final String description;
  final String? paymentUrl;
  final String? failReason;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.montant,
    required this.statut,
    required this.description,
    required this.createdAt,
    this.methode,
    this.paymentUrl,
    this.failReason,
  });

  bool get isCredit => type == 'TOPUP' || type == 'REFUND';
  bool get isPending => statut == 'PENDING' || statut == 'PROCESSING';
  bool get isFailed => statut == 'FAILED';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'TOPUP',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      statut: json['statut']?.toString() ?? 'PENDING',
      methode: json['methode']?.toString(),
      description: json['description']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString(),
      failReason: json['failReason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}

class PassengerWallet {
  final double balance;
  final List<WalletTransactionModel> transactions;

  /// Mode de chaque opérateur côté serveur : live, simulation ou unavailable
  final Map<String, String> operators;

  PassengerWallet({required this.balance, required this.transactions, required this.operators});

  bool get isSimulation => operators.values.any((mode) => mode == 'simulation');
  bool isAvailable(String methode) => operators[methode] != 'unavailable';

  factory PassengerWallet.fromJson(Map<String, dynamic> json) {
    final operators = <String, String>{};
    final raw = json['operators'];
    if (raw is Map) {
      raw.forEach((key, value) => operators[key.toString()] = value.toString());
    }
    return PassengerWallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      transactions: (json['transactions'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionModel.fromJson)
          .toList(),
      operators: operators,
    );
  }
}
