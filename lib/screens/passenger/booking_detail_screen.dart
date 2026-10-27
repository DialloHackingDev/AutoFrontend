import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_qr_image.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _phoneController = TextEditingController();
  String _selectedMethod = 'ORANGE_MONEY';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(title: const Text('Détails du Trajet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Votre Ticket de Voyage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoCol('Départ', booking.departure),
                        const Icon(Icons.arrow_forward, color: Color(0xFF1E3A8A)),
                        _infoCol('Destination', booking.destination),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (booking.statut == BookingStatus.PAID || booking.statut == BookingStatus.BOARDING) ...[
                      if (booking.qrCode != null)
                        BookingQrImage(qrCode: booking.qrCode!),
                      const SizedBox(height: 16),
                      Text(
                        'CODE OTP : ${booking.otpCode ?? "---"}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                      ),
                      const SizedBox(height: 8),
                      const Text('Montrez ce code ou le QR au chauffeur', style: TextStyle(color: Colors.grey)),
                    ] else ...[
                      const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text('Statut : ${booking.statut.name}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paiement et sécurité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Statut du paiement : ${booking.paymentStatus ?? 'Aucun paiement initié'}'),
                    Text('Moyen : ${booking.paymentMethod ?? '—'}'),
                    const SizedBox(height: 8),
                    if (booking.paymentStatus == 'COMPLETED')
                      const Text('Le montant est actuellement sous séquestre jusqu’à la validation du trajet.')
                    else if (booking.paymentStatus == 'REFUNDED')
                      const Text('Le montant a été remboursé selon la politique de remboursement du système.')
                    else
                      const Text('Le paiement Mobile Money sera sécurisé dans l’escrow jusqu’à la fin du trajet.'),
                    const SizedBox(height: 8),
                    if (booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'REFUNDED')
                      Text(
                        booking.escrowReleased
                            ? 'Escrow : libéré'
                            : 'Escrow : bloqué jusqu’à la validation du trajet',
                      ),
                    const SizedBox(height: 8),
                    const Text('En cas d’annulation, le remboursement est traité automatiquement selon les règles d’escrow du cahier de charge.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (booking.statut == BookingStatus.PENDING || booking.statut == BookingStatus.CONFIRMED)
              ElevatedButton(
                onPressed: () => _showPaymentDialog(context, booking),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Procéder au paiement'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, Booking booking) async {
    final bookingProvider = context.read<BookingProvider>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Paiement Mobile Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                items: const [
                  DropdownMenuItem(value: 'ORANGE_MONEY', child: Text('Orange Money')),
                  DropdownMenuItem(value: 'MTN_MONEY', child: Text('MTN Money')),
                ],
                onChanged: (value) => setState(() => _selectedMethod = value ?? 'ORANGE_MONEY'),
                decoration: const InputDecoration(labelText: 'Opérateur'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Numéro Mobile Money'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final response = await bookingProvider.initiatePayment(
                  bookingId: booking.id,
                  montant: booking.prix,
                  methode: _selectedMethod,
                  telephone: _phoneController.text.trim(),
                );

                if (!context.mounted) return;
                Navigator.pop(dialogContext);

                if (response != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message']?.toString() ?? 'Paiement initialisé.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(bookingProvider.errorMessage ?? 'Le paiement n’a pas pu être lancé.')),
                  );
                }
              },
              child: const Text('Payer'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
