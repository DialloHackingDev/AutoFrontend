import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dispute_provider.dart';
import '../core/app_theme.dart';

class DisputeScreen extends StatefulWidget {
  final String? bookingId;

  const DisputeScreen({super.key, this.bookingId});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bookingId == null) {
        context.read<DisputeProvider>().fetchDisputes();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitDispute() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez décrire le problème.')));
      return;
    }

    final success = await context.read<DisputeProvider>().createDispute(
      bookingId: widget.bookingId!,
      description: description,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Litige soumis avec succès.')));
      Navigator.pop(context);
    } else {
      final errorMessage = context.read<DisputeProvider>().errorMessage ?? 'Erreur lors de la soumission.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisputeProvider>();

    if (widget.bookingId != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Signaler un problème')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Décrivez le problème que vous avez rencontré :', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Le chauffeur ne s\'est pas présenté...',
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: provider.isLoading ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Soumettre le litige', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes litiges')),
      body: provider.isLoading && provider.disputes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.disputes.isEmpty
              ? const Center(child: Text('Aucun litige signalé.'))
              : RefreshIndicator(
                  onRefresh: provider.fetchDisputes,
                  child: ListView.builder(
                    itemCount: provider.disputes.length,
                    itemBuilder: (context, index) {
                      final dispute = provider.disputes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text('Réservation : ${dispute.bookingId}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dispute.description),
                              const SizedBox(height: 4),
                              Text('Statut : ${dispute.statut}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Date : ${DateFormat('dd/MM/yyyy HH:mm').format(dispute.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
