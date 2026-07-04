import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/freight_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/voice_service.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _selectedIndex = 0;
  final _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoConnect Passager', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Écouter les instructions',
            icon: const Icon(Icons.volume_up),
            onPressed: () => _voiceService.speak('Bienvenue sur AutoConnect. Recherchez un trajet ou gérez vos réservations.'),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: [
        const _SearchTripView(),
        const _MyBookingsView(),
        const _ProfileView(),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1E3A8A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Mes trajets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _SearchTripView extends StatefulWidget {
  const _SearchTripView();

  @override
  State<_SearchTripView> createState() => _SearchTripViewState();
}

class _SearchTripViewState extends State<_SearchTripView> {
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _placesController = TextEditingController(text: '1');

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _placesController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicles() async {
    final departure = _departureController.text.trim();
    final destination = _destinationController.text.trim();

    if (departure.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le départ et la destination.')),
      );
      return;
    }

    await context.read<VehicleProvider>().fetchAvailableVehicles(
      departure: departure,
      destination: destination,
    );
  }

  void _showBookingDialog(Vehicle vehicle) {
    final placesController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${vehicle.marque} ${vehicle.modele}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conducteur : ${vehicle.driverName ?? "Non renseigné"}'),
              const SizedBox(height: 8),
              Text('Places disponibles : ${vehicle.placesDisponibles}'),
              const SizedBox(height: 16),
              TextField(
                controller: placesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final places = int.tryParse(placesController.text) ?? 1;
                if (places < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nombre de places doit être supérieur à 0.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                final success = await context.read<BookingProvider>().createBooking(
                  vehicleId: vehicle.id,
                  departure: _departureController.text.trim(),
                  destination: _destinationController.text.trim(),
                  places: places,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Réservation envoyée au conducteur.'
                            : context.read<BookingProvider>().errorMessage ?? 'La réservation n’a pas pu être créée.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Réserver'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Où allez-vous ?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _departureController,
                    decoration: InputDecoration(
                      hintText: 'Départ (ex: Conakry)',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.swap_vert, color: Colors.grey),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: 'Destination (ex: Labé)',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _placesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de places',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: vehicleProvider.isLoading ? null : _searchVehicles,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    child: vehicleProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Rechercher des véhicules'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (vehicleProvider.errorMessage != null)
            Text(vehicleProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
          if (!vehicleProvider.isLoading && vehicleProvider.availableVehicles.isEmpty)
            const Text('Aucun véhicule disponible pour l’instant. Réessayez plus tard.'),
          const SizedBox(height: 24),
          const Text('Service fret', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _FreightQuickAction(),
          if (vehicleProvider.availableVehicles.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: vehicleProvider.availableVehicles.length,
                itemBuilder: (_, index) {
                  final vehicle = vehicleProvider.availableVehicles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${vehicle.marque} ${vehicle.modele}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conducteur : ${vehicle.driverName ?? "À confirmer"}'),
                          Text('Places restantes : ${vehicle.placesDisponibles}'),
                          Text('Note : ${vehicle.driverNote.toStringAsFixed(1)} / 5'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showBookingDialog(vehicle),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingProvider.bookings.isEmpty) {
      return const Center(child: Text('Aucune réservation en cours'));
    }

    return RefreshIndicator(
      onRefresh: bookingProvider.fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookingProvider.bookings.length,
        itemBuilder: (context, index) {
          final booking = bookingProvider.bookings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${booking.departure} → ${booking.destination}'),
              subtitle: Text(
                '${_statusLabel(booking.statut)} • ${DateFormat('dd/MM/yyyy').format(booking.createdAt)}',
                style: TextStyle(color: _getStatusColor(booking.statut)),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBookingDetails(context, booking),
            ),
          );
        },
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${booking.departure} → ${booking.destination}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Statut : ${_statusLabel(booking.statut)}'),
              Text('Places : ${booking.places}'),
              Text('Prix : ${booking.prix.toStringAsFixed(0)} GNF'),
              const SizedBox(height: 12),
              const Text('Validation embarquement', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                booking.qrCode != null || booking.otpCode != null
                    ? 'QR/OTP prêt pour la validation.'
                    : 'Le QR/OTP sera affiché dès que la réservation sera payée et validée.',
              ),
              const SizedBox(height: 20),
              if (booking.statut != BookingStatus.CANCELLED &&
                  booking.statut != BookingStatus.COMPLETED &&
                  booking.statut != BookingStatus.IN_PROGRESS)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await context.read<BookingProvider>().cancelBooking(booking.id);
                      if (context.mounted) {
                        Navigator.pop(sheetContext);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Réservation annulée.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler la réservation'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.PAID:
        return Colors.green;
      case BookingStatus.PENDING:
      case BookingStatus.CONFIRMED:
        return Colors.orange;
      case BookingStatus.CANCELLED:
        return Colors.red;
      case BookingStatus.IN_PROGRESS:
      case BookingStatus.COMPLETED:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return 'En attente';
      case BookingStatus.CONFIRMED:
        return 'Confirmée';
      case BookingStatus.PAID:
        return 'Payée';
      case BookingStatus.BOARDING:
        return 'Embarquement';
      case BookingStatus.IN_PROGRESS:
        return 'En cours';
      case BookingStatus.COMPLETED:
        return 'Terminée';
      case BookingStatus.FUNDS_RELEASED:
        return 'Fonds libérés';
      case BookingStatus.CANCELLED:
        return 'Annulée';
      case BookingStatus.DISPUTE:
        return 'Litige';
      case BookingStatus.INCIDENT:
        return 'Incident';
    }
  }
}

class _FreightQuickAction extends StatefulWidget {
  const _FreightQuickAction();

  @override
  State<_FreightQuickAction> createState() => _FreightQuickActionState();
}

class _FreightQuickActionState extends State<_FreightQuickAction> {
  final _poidsController = TextEditingController(text: '10');
  final _destinationController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _poidsController.dispose();
    _destinationController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFreight(BuildContext context) async {
    final poids = double.tryParse(_poidsController.text.trim()) ?? 0;
    final destination = _destinationController.text.trim();
    if (poids <= 0 || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le poids et la destination sont requis pour créer un fret.')),
      );
      return;
    }

    final success = await context.read<FreightProvider>().createFreight(
      poids: poids,
      destination: destination,
      type: _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Demande de fret enregistrée.' : 'Impossible d’enregistrer le fret.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Envoyez un colis ou du fret de manière sécurisée.'),
            const SizedBox(height: 12),
            TextField(
              controller: _poidsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type de marchandise', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitFreight(context),
                child: const Text('Créer une demande de fret'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(user?.nom ?? 'Utilisateur', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.telephone ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des trajets'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.wallet),
            title: const Text('Mon Portefeuille'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
