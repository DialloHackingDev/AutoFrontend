import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/passenger_wallet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/passenger_wallet_provider.dart';
import '../../widgets/mobile_money_wait_dialog.dart';
import '../../widgets/payment_method_tile.dart';

/// Portefeuille AutoConnect du passager : solde, recharge, historique des mouvements.
class PassengerWalletScreen extends StatefulWidget {
  const PassengerWalletScreen({super.key});

  @override
  State<PassengerWalletScreen> createState() => _PassengerWalletScreenState();
}

class _PassengerWalletScreenState extends State<PassengerWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PassengerWalletProvider>().fetchWallet());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PassengerWalletProvider>();
    final wallet = provider.wallet;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon portefeuille')),
      body: RefreshIndicator(
        onRefresh: provider.fetchWallet,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BalanceCard(
              balance: provider.balance,
              loading: provider.isLoading && wallet == null,
              onTopUp: () => showTopUpSheet(context),
            ),
            if (wallet?.isSimulation ?? false) ...[
              const SizedBox(height: 12),
              const _InfoBanner(
                icon: Icons.science_outlined,
                text: 'Mode test : les paiements Mobile Money sont simulés, aucun argent réel n’est débité.',
              ),
            ],
            const SizedBox(height: 24),
            const Text('Historique', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            if (provider.errorMessage != null && wallet == null)
              _InfoBanner(icon: Icons.error_outline, text: provider.errorMessage!)
            else if (wallet == null)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (wallet.transactions.isEmpty)
              const _EmptyHistory()
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < wallet.transactions.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 72),
                      _TransactionTile(transaction: wallet.transactions[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final bool loading;
  final VoidCallback onTopUp;

  const _BalanceCard({required this.balance, required this.loading, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('Solde disponible', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          loading
              ? const SizedBox(height: 40, child: Center(child: LinearProgressIndicator(color: Colors.white)))
              : Text(
                  formatGnf(balance),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                ),
          const SizedBox(height: 4),
          const Text(
            'Payez vos trajets en un geste. Les remboursements sont crédités ici.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add),
              label: const Text('Recharger'),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final (icon, color) = switch (t.type) {
      'TOPUP' => (Icons.add_circle_outline, AppColors.success),
      'REFUND' => (Icons.replay, AppColors.success),
      _ => (Icons.directions_car_outlined, AppColors.primary),
    };
    final amountColor = t.isFailed
        ? AppColors.inkMuted
        : t.isCredit
            ? AppColors.successDark
            : AppColors.ink;

    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
      title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        t.isPending
            ? 'En attente de validation · ${formatDateTime(t.createdAt)}'
            : t.isFailed
                ? 'Échouée${t.failReason != null ? ' — ${t.failReason}' : ''}'
                : formatDateTime(t.createdAt),
        style: TextStyle(color: t.isFailed ? AppColors.danger : AppColors.inkMuted, fontSize: 13),
      ),
      trailing: Text(
        '${t.isCredit ? '+' : '−'} ${formatGnf(t.montant)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: amountColor,
          decoration: t.isFailed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.inkMuted),
          SizedBox(height: 8),
          Text('Aucun mouvement pour le moment', style: TextStyle(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Recharge
// ─────────────────────────────────────────────────

/// Feuille de recharge du portefeuille. Retourne true si la recharge a été confirmée.
Future<bool> showTopUpSheet(BuildContext context, {int? suggestedAmount}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TopUpSheet(suggestedAmount: suggestedAmount),
  );
  return result ?? false;
}

class _TopUpSheet extends StatefulWidget {
  final int? suggestedAmount;

  const _TopUpSheet({this.suggestedAmount});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _presets = [10000, 25000, 50000, 100000];

  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;
  String _methode = PaymentMethods.orange;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '${widget.suggestedAmount ?? 25000}');
    final phone = context.read<AuthProvider>().user?.telephone ?? '';
    _phoneController = TextEditingController(text: phone.replaceFirst('+224', ''));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _submit() async {
    if (_amount < 1000) {
      setState(() => _error = 'Le montant minimum est de 1 000 GNF.');
      return;
    }
    if (_phoneController.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _error = 'Entrez le numéro Mobile Money à débiter.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final provider = context.read<PassengerWalletProvider>();
    final transaction = await provider.topUp(
      montant: _amount,
      methode: _methode,
      telephone: AuthProvider.normalizePhone(_phoneController.text),
    );
    if (!mounted) return;
    if (transaction == null) {
      setState(() {
        _submitting = false;
        _error = provider.errorMessage;
      });
      return;
    }

    final outcome = await showMobileMoneyWaitDialog(
      context,
      methode: _methode,
      montant: transaction.montant,
      paymentUrl: transaction.paymentUrl,
      check: () async => (await provider.checkTransaction(transaction.id))?.statut,
    );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, outcome == MobileMoneyOutcome.success);
    messenger.showSnackBar(SnackBar(
      content: Text(switch (outcome) {
        MobileMoneyOutcome.success => 'Portefeuille rechargé de ${formatGnf(transaction.montant)}.',
        MobileMoneyOutcome.failure => 'La recharge n’a pas abouti. Aucun montant n’a été débité.',
        MobileMoneyOutcome.stillPending => 'Recharge en attente de validation. Vous serez notifié du résultat.',
      }),
    ));
    provider.fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<PassengerWalletProvider>().wallet;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Recharger mon portefeuille',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _presets)
                  ChoiceChip(
                    label: Text(formatGnf(preset)),
                    selected: _amount == preset,
                    selectedColor: AppColors.primarySoft,
                    onSelected: (_) => setState(() => _amountController.text = '$preset'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Montant', suffixText: 'GNF', prefixIcon: Icon(Icons.payments_outlined)),
            ),
            const SizedBox(height: 16),
            const Text('Payer avec', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            for (final methode in [PaymentMethods.orange, PaymentMethods.mtn]) ...[
              PaymentMethodTile(
                methode: methode,
                selected: _methode == methode,
                enabled: wallet?.isAvailable(methode) ?? true,
                subtitle: (wallet?.isAvailable(methode) ?? true) ? null : 'Momentanément indisponible',
                onTap: () => setState(() => _methode = methode),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro à débiter',
                prefixText: '+224 ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Recharger ${_amount > 0 ? formatGnf(_amount) : ''}'),
            ),
          ],
        ),
      ),
    );
  }
}
