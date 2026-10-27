import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/passenger_wallet_provider.dart';
import '../notifications_screen.dart';
import 'passenger_wallet_screen.dart';
import 'trip_history_screen.dart';

/// Langues de l'assistant vocal (cahier des charges : français, pular, soussou, malinké)
const _languages = {
  'FRANCAIS': 'Français',
  'PULAR': 'Pular',
  'SOUSSOU': 'Soussou',
  'MALINKE': 'Malinké',
};

/// Onglet « Profil » du passager.
class PassengerProfileView extends StatefulWidget {
  const PassengerProfileView({super.key});

  @override
  State<PassengerProfileView> createState() => _PassengerProfileViewState();
}

class _PassengerProfileViewState extends State<PassengerProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PassengerWalletProvider>().fetchWallet();
      context.read<AuthProvider>().syncProfile();
    });
  }

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bookings = context.watch<BookingProvider>().bookings;
    final wallet = context.watch<PassengerWalletProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;

    final doneTrips = bookings
        .where((b) => b.statut == BookingStatus.COMPLETED || b.statut == BookingStatus.FUNDS_RELEASED)
        .length;
    final spent = bookings.where((b) => b.paymentStatus == 'COMPLETED').fold<double>(0, (s, b) => s + b.prix);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<PassengerWalletProvider>().fetchWallet(),
          context.read<BookingProvider>().fetchBookings(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileHeader(name: user?.nom ?? 'Passager', phone: user?.telephone ?? ''),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '$doneTrips', label: 'Trajets\neffectués'),
              const SizedBox(width: 10),
              _Stat(value: formatGnf(spent), label: 'Total\npayé'),
              const SizedBox(width: 10),
              _Stat(value: formatGnf(wallet.balance), label: 'Solde\nportefeuille', highlight: true),
            ],
          ),
          const SizedBox(height: 16),
          _WalletShortcut(
            balance: wallet.balance,
            onOpen: () => _open(const PassengerWalletScreen()),
            onTopUp: () => showTopUpSheet(context),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Mon activité'),
          _MenuCard(children: [
            _MenuItem(
              icon: Icons.history,
              title: 'Historique des trajets',
              subtitle: bookings.isEmpty ? 'Aucun trajet pour le moment' : '${bookings.length} réservation(s) · reçus de paiement',
              onTap: () => _open(const TripHistoryScreen()),
            ),
            _MenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Mon portefeuille',
              subtitle: 'Solde : ${formatGnf(wallet.balance)}',
              onTap: () => _open(const PassengerWalletScreen()),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: unread > 0 ? '$unread non lue(s)' : 'Tout est lu',
              onTap: () => _open(const NotificationsScreen()),
            ),
          ]),
          const SizedBox(height: 20),
          const _SectionTitle('Mon compte'),
          _MenuCard(children: [
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Mes informations',
              subtitle: user?.nom ?? '',
              onTap: () => _editName(context, user?.nom ?? ''),
            ),
            _MenuItem(
              icon: Icons.record_voice_over_outlined,
              title: 'Langue de l’assistant vocal',
              subtitle: _languages[user?.langue] ?? 'Français',
              onTap: () => _chooseLanguage(context, user?.langue ?? 'FRANCAIS'),
            ),
            _MenuItem(
              icon: Icons.lock_outline,
              title: 'Mot de passe',
              subtitle: 'Modifier mon mot de passe',
              onTap: () => _changePassword(context),
            ),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Se déconnecter', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.dangerSoft, width: 1.5)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('AutoConnect · Le transport intelligent en Guinée',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetForm(
        title: 'Mes informations',
        fields: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
          ),
        ],
        onSubmit: () async {
          final name = controller.text.trim();
          if (name.length < 2) return 'Entrez votre nom complet.';
          return auth.updateProfile(nom: name);
        },
      ),
    );
    if (saved == true) messenger.showSnackBar(const SnackBar(content: Text('Informations enregistrées.')));
  }

  Future<void> _chooseLanguage(BuildContext context, String current) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Langue de l’assistant vocal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final entry in _languages.entries)
              ListTile(
                leading: Icon(
                  entry.key == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: entry.key == current ? AppColors.primary : AppColors.inkMuted,
                ),
                title: Text(entry.value),
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || selected == current) return;
    final error = await auth.updateProfile(langue: selected);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Langue : ${_languages[selected]}.')));
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SheetForm(
        title: 'Changer le mot de passe',
        fields: [
          TextField(
            controller: current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: next,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              helperText: 'Au moins 6 caractères',
              prefixIcon: Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe', prefixIcon: Icon(Icons.check)),
          ),
        ],
        onSubmit: () async {
          if (next.text.length < 6) return 'Le nouveau mot de passe doit contenir au moins 6 caractères.';
          if (next.text != confirm.text) return 'Les deux mots de passe ne correspondent pas.';
          return auth.changePassword(current.text, next.text);
        },
      ),
    );
    if (saved == true) messenger.showSnackBar(const SnackBar(content: Text('Mot de passe modifié.')));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau votre numéro et votre mot de passe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (ok == true) await auth.logout();
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;

  const _ProfileHeader({required this.name, required this.phone});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Anneau aux couleurs du logo
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.surface,
              child: CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.primarySoft,
                child: Text(_initials,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(phone, style: const TextStyle(color: AppColors.inkMuted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, size: 14, color: AppColors.successDark),
                      SizedBox(width: 4),
                      Text('Passager',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;

  const _Stat({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? AppColors.primarySoft : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: highlight ? AppColors.primary : AppColors.ink,
                  )),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _WalletShortcut extends StatelessWidget {
  final double balance;
  final VoidCallback onOpen;
  final VoidCallback onTopUp;

  const _WalletShortcut({required this.balance, required this.onOpen, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Portefeuille AutoConnect', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(formatGnf(balance),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onTopUp,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Recharger'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.inkMuted)),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
      onTap: onTap,
    );
  }
}

/// Formulaire en feuille modale : affiche l'erreur renvoyée par [onSubmit] ou se ferme en cas de succès.
class _SheetForm extends StatefulWidget {
  final String title;
  final List<Widget> fields;
  final Future<String?> Function() onSubmit;

  const _SheetForm({required this.title, required this.fields, required this.onSubmit});

  @override
  State<_SheetForm> createState() => _SheetFormState();
}

class _SheetFormState extends State<_SheetForm> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...widget.fields,
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    final error = await widget.onSubmit();
                    if (!context.mounted) return;
                    if (error == null) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _saving = false;
                        _error = error;
                      });
                    }
                  },
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
