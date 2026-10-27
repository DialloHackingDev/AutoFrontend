import 'dart:convert';
import 'package:flutter/material.dart';

/// Affiche le QR Code d'une réservation.
///
/// Le backend renvoie `qrCode` sous forme de data URI PNG
/// (`data:image/png;base64,...`) : on décode l'image au lieu de
/// ré-encoder cette chaîne dans un nouveau QR.
class BookingQrImage extends StatelessWidget {
  final String qrCode;
  final double size;

  const BookingQrImage({super.key, required this.qrCode, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final commaIndex = qrCode.indexOf(',');
    if (!qrCode.startsWith('data:image') || commaIndex == -1) {
      return const Text('QR Code indisponible');
    }

    try {
      final bytes = base64Decode(qrCode.substring(commaIndex + 1));
      return Image.memory(
        bytes,
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const Text('QR Code illisible'),
      );
    } on FormatException {
      return const Text('QR Code illisible');
    }
  }
}
