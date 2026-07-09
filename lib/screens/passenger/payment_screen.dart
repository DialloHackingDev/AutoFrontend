import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;

  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'ORANGE_MONEY';
  bool _isLoading = false;

  void _processPayment() async {
    setState(() => _isLoading = true);

    final bookingProvider = context.read<BookingProvider>();
    final result = await bookingProvider.initiatePayment(
      bookingId: widget.bookingId,
      montant: widget.amount,
      methode: _selectedMethod,
      telephone: '620000000', // Téléphone par défaut pour le MVP
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement réussi. Le trajet est prêt à démarrer.')),
      );
      Navigator.pop(context, true); // Return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingProvider.errorMessage ?? 'Le paiement a échoué.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Montant à payer : ${widget.amount.toStringAsFixed(0)} GNF', 
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Choisissez votre méthode de paiement :', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Orange Money'),
              value: 'ORANGE_MONEY',
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            RadioListTile<String>(
              title: const Text('MTN Mobile Money'),
              value: 'MTN_MONEY',
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            RadioListTile<String>(
              title: const Text('Portefeuille AutoConnect'),
              value: 'WALLET',
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmer le paiement', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
