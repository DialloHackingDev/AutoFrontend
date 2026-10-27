import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/passenger_wallet_provider.dart';
import '../../widgets/mobile_money_wait_dialog.dart';
import '../../widgets/payment_method_tile.dart';
import 'passenger_wallet_screen.dart';

/// Paiement d'une réservation : portefeuille AutoConnect, Orange Money ou MTN Mobile Money.
/// Retourne true (Navigator.pop) quand le paiement est confirmé.
class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;

  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _methode = PaymentMethods.wallet;
  late final TextEditingController _phoneController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final phone = context.read<AuthProvider>().user?.telephone ?? '';
    _phoneController = TextEditingController(text: phone.replaceFirst('+224', ''));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wallet = context.read<PassengerWalletProvider>();
      await wallet.fetchWallet();
      // Portefeuille proposé par défaut seulement s'il couvre le trajet
      if (mounted && wallet.balance < widget.amount) {
        setState(() => _methode = PaymentMethods.orange);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isMobileMoney => _methode != PaymentMethods.wallet;

  Future<void> _pay() async {
    if (_isMobileMoney && _phoneController.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _error = 'Entrez le numéro Mobile Money à débiter.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final bookings = context.read<BookingProvider>();
    final payment = await bookings.initiatePayment(
      bookingId: widget.bookingId,
      montant: widget.amount,
      methode: _methode,
      telephone: _isMobileMoney ? AuthProvider.normalizePhone(_phoneController.text) : null,
    );
    if (!mounted) return;
    if (payment == null) {
      setState(() {
        _submitting = false;
        _error = bookings.errorMessage;
      });
      return;
    }

    var outcome = payment['statut'] == 'COMPLETED' ? MobileMoneyOutcome.success : MobileMoneyOutcome.stillPending;
    if (outcome != MobileMoneyOutcome.success) {
      outcome = await showMobileMoneyWaitDialog(
        context,
        methode: _methode,
        montant: widget.amount,
        paymentUrl: payment['paymentUrl']?.toString(),
        check: () => bookings.checkPayment(payment['id'].toString()),
      );
    }
    if (!mounted) return;
    context.read<PassengerWalletProvider>().fetchWallet();

    switch (outcome) {
      case MobileMoneyOutcome.success:
        await _showSuccess();
        if (mounted) Navigator.pop(context, true);
      case MobileMoneyOutcome.failure:
        setState(() {
          _submitting = false;
          _error = 'Le paiement n’a pas abouti. Aucun montant n’a été débité : vous pouvez réessayer.';
        });
      case MobileMoneyOutcome.stillPending:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paiement en attente de validation. Vous serez notifié dès sa confirmation.'),
        ));
        Navigator.pop(context, false);
    }
  }

  Future<void> _showSuccess() {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        title: const Text('Paiement confirmé'),
        content: Text(
          '${formatGnf(widget.amount)} payés. Votre QR Code et votre code OTP sont disponibles dans « Mes trajets ».',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Voir mon trajet')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<PassengerWalletProvider>();
    final wallet = walletProvider.wallet;
    final balance = walletProvider.balance;
    final walletCovers = balance >= widget.amount;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text('Montant à payer', style: TextStyle(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  Text(formatGnf(widget.amount),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text('Montant conservé par AutoConnect jusqu’à la fin du trajet',
                            style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Moyen de paiement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 10),
            PaymentMethodTile(
              methode: PaymentMethods.wallet,
              selected: _methode == PaymentMethods.wallet,
              enabled: walletCovers,
              subtitle: wallet == null
                  ? 'Chargement du solde…'
                  : walletCovers
                      ? 'Solde : ${formatGnf(balance)}'
                      : 'Solde insuffisant (${formatGnf(balance)})',
              onTap: () => setState(() => _methode = PaymentMethods.wallet),
            ),
            if (wallet != null && !walletCovers)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final missing = (widget.amount - balance).ceil();
                    final ok = await showTopUpSheet(context, suggestedAmount: missing < 1000 ? 1000 : missing);
                    if (ok && context.mounted && context.read<PassengerWalletProvider>().balance >= widget.amount) {
                      setState(() => _methode = PaymentMethods.wallet);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Recharger mon portefeuille'),
                ),
              ),
            const SizedBox(height: 8),
            for (final methode in [PaymentMethods.orange, PaymentMethods.mtn]) ...[
              PaymentMethodTile(
                methode: methode,
                selected: _methode == methode,
                enabled: wallet?.isAvailable(methode) ?? true,
                subtitle: (wallet?.isAvailable(methode) ?? true) ? 'Validation sur votre téléphone' : 'Momentanément indisponible',
                onTap: () => setState(() => _methode = methode),
              ),
              const SizedBox(height: 8),
            ],
            if (_isMobileMoney) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro ${PaymentMethods.label(_methode)}',
                  prefixText: '+224 ',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ],
            if (wallet?.isSimulation ?? false) ...[
              const SizedBox(height: 12),
              const Text(
                'Mode test : les paiements Mobile Money sont simulés.',
                style: TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting || (_methode == PaymentMethods.wallet && !walletCovers) ? null : _pay,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Payer ${formatGnf(widget.amount)}'),
            ),
          ],
        ),
      ),
    );
  }
}
