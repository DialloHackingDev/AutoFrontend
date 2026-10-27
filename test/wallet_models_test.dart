import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/passenger_wallet_model.dart';
import 'package:frontend/models/wallet_model.dart';

void main() {
  group('PassengerWallet', () {
    test('parses balance, transactions and operator modes', () {
      final wallet = PassengerWallet.fromJson({
        'balance': 150000,
        'operators': {'ORANGE_MONEY': 'live', 'MTN_MONEY': 'unavailable'},
        'transactions': [
          {'id': '1', 'type': 'TOPUP', 'montant': 50000, 'statut': 'COMPLETED', 'description': 'Recharge', 'createdAt': '2026-10-27T10:00:00Z'},
          {'id': '2', 'type': 'PAYMENT', 'montant': 100000, 'statut': 'COMPLETED', 'description': 'Trajet', 'createdAt': '2026-10-27T11:00:00Z'},
          {'id': '3', 'type': 'REFUND', 'montant': 100000, 'statut': 'COMPLETED', 'description': 'Remboursement', 'createdAt': '2026-10-27T12:00:00Z'},
          {'id': '4', 'type': 'TOPUP', 'montant': 20000, 'statut': 'PROCESSING', 'description': 'Recharge', 'createdAt': '2026-10-27T13:00:00Z'},
        ],
      });

      expect(wallet.balance, 150000);
      expect(wallet.isAvailable('ORANGE_MONEY'), isTrue);
      expect(wallet.isAvailable('MTN_MONEY'), isFalse);
      expect(wallet.isSimulation, isFalse);
      expect(wallet.transactions.map((t) => t.isCredit), [true, false, true, true]);
      expect(wallet.transactions.last.isPending, isTrue);
    });

    test('flags the simulation mode', () {
      final wallet = PassengerWallet.fromJson({
        'balance': 0,
        'operators': {'ORANGE_MONEY': 'simulation', 'MTN_MONEY': 'simulation'},
        'transactions': [],
      });
      expect(wallet.isSimulation, isTrue);
    });
  });

  group('Driver wallet', () {
    test('a withdrawal is a debit, a trip earning is a credit', () {
      final withdrawal = Transaction.fromJson({'id': 'w', 'montant': 50000, 'reference': 'ref', 'createdAt': '2026-10-27T10:00:00Z'});
      final earning = Transaction.fromJson({'bookingId': 'b', 'amount': 100000, 'date': '2026-10-27T10:00:00Z'});
      expect(withdrawal.isCredit, isFalse);
      expect(earning.isCredit, isTrue);
    });

    test('reads the commission rate, 10 % by default', () {
      expect(Wallet.fromJson({'balance': 0, 'commissionRate': 0.15}).commissionRate, 0.15);
      expect(Wallet.fromJson({'balance': 0}).commissionRate, 0.1);
    });
  });
}
