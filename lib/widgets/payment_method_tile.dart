import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Moyens de paiement proposés dans l'application.
class PaymentMethods {
  static const wallet = 'WALLET';
  static const orange = 'ORANGE_MONEY';
  static const mtn = 'MTN_MONEY';

  static String label(String methode) => switch (methode) {
        wallet => 'Portefeuille AutoConnect',
        orange => 'Orange Money',
        mtn => 'MTN Mobile Money',
        _ => methode,
      };

  /// Couleurs officielles des opérateurs, pour qu'ils soient reconnus d'un coup d'œil
  static Color color(String methode) => switch (methode) {
        orange => const Color(0xFFFF7900),
        mtn => const Color(0xFFFFCB05),
        _ => AppColors.primary,
      };
}

/// Tuile de choix d'un moyen de paiement : grande zone tactile, état sélectionné bien visible.
class PaymentMethodTile extends StatelessWidget {
  final String methode;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.methode,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = PaymentMethods.color(methode);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    methode == PaymentMethods.wallet ? Icons.account_balance_wallet : Icons.phone_android,
                    color: methode == PaymentMethods.mtn ? AppColors.ink : Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PaymentMethods.label(methode),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                      if (subtitle != null)
                        Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
