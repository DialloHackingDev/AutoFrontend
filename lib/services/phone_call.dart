import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre l'application Téléphone avec le numéro pré-composé (l'utilisateur valide l'appel).
/// Affiche un message si l'appareil ne peut pas passer d'appel.
Future<void> callPhone(BuildContext context, String? phone) async {
  final messenger = ScaffoldMessenger.of(context);
  final number = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  if (number.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Numéro de téléphone indisponible.')));
    return;
  }

  final uri = Uri(scheme: 'tel', path: number);
  final opened = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text('Impossible d’ouvrir l’application d’appel. Numéro : $number')));
  }
}
