import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import 'payment_method_tile.dart';

/// Statut final d'une opération Mobile Money vue par l'application.
enum MobileMoneyOutcome { success, failure, stillPending }

/// Attend que le client valide un paiement Mobile Money.
///
/// - MTN : une invite s'affiche sur le téléphone du client (code secret MoMo).
/// - Orange : la page de paiement Orange s'ouvre dans le navigateur.
/// Le statut est revérifié toutes les 3 secondes par le serveur auprès de l'opérateur.
/// [check] retourne le statut serveur (COMPLETED, FAILED, PENDING, PROCESSING…).
Future<MobileMoneyOutcome> showMobileMoneyWaitDialog(
  BuildContext context, {
  required String methode,
  required double montant,
  required Future<String?> Function() check,
  String? paymentUrl,
}) async {
  if (paymentUrl != null && paymentUrl.isNotEmpty) {
    await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
  }
  if (!context.mounted) return MobileMoneyOutcome.stillPending;
  final result = await showDialog<MobileMoneyOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MobileMoneyWaitDialog(
      methode: methode,
      montant: montant,
      check: check,
      paymentUrl: paymentUrl,
    ),
  );
  return result ?? MobileMoneyOutcome.stillPending;
}

class _MobileMoneyWaitDialog extends StatefulWidget {
  final String methode;
  final double montant;
  final Future<String?> Function() check;
  final String? paymentUrl;

  const _MobileMoneyWaitDialog({
    required this.methode,
    required this.montant,
    required this.check,
    this.paymentUrl,
  });

  @override
  State<_MobileMoneyWaitDialog> createState() => _MobileMoneyWaitDialogState();
}

class _MobileMoneyWaitDialogState extends State<_MobileMoneyWaitDialog> {
  static const _interval = Duration(seconds: 3);
  static const _timeout = Duration(minutes: 3);

  Timer? _timer;
  final _startedAt = DateTime.now();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_checking || !mounted) return;
    _checking = true;
    final status = await widget.check();
    _checking = false;
    if (!mounted) return;

    if (status == 'COMPLETED') {
      _close(MobileMoneyOutcome.success);
    } else if (status == 'FAILED' || status == 'REFUNDED') {
      _close(MobileMoneyOutcome.failure);
    } else if (DateTime.now().difference(_startedAt) > _timeout) {
      _close(MobileMoneyOutcome.stillPending);
    }
  }

  void _close(MobileMoneyOutcome outcome) {
    _timer?.cancel();
    Navigator.of(context).pop(outcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOrange = widget.methode == PaymentMethods.orange;
    return AlertDialog(
      title: Text('Validez sur ${PaymentMethods.label(widget.methode)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3.5)),
          const SizedBox(height: 20),
          Text(
            formatGnf(widget.montant),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            isOrange
                ? 'Confirmez le paiement sur la page Orange Money qui vient de s’ouvrir, avec le code demandé.'
                : 'Une demande de paiement va s’afficher sur votre téléphone : saisissez votre code secret MTN MoMo pour valider.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette fenêtre se ferme automatiquement dès la confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
      actions: [
        if (isOrange && widget.paymentUrl != null)
          TextButton(
            onPressed: () => launchUrl(Uri.parse(widget.paymentUrl!), mode: LaunchMode.externalApplication),
            child: const Text('Rouvrir la page'),
          ),
        TextButton(
          onPressed: () => _close(MobileMoneyOutcome.stillPending),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
