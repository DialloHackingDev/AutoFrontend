import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../core/map_config.dart';
import '../../services/location_service.dart';
import '../trip_tracking_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/booking_model.dart';
import '../../providers/driver_provider.dart';
import '../../providers/vehicle_provider.dart';
import 'scan_qr_screen.dart';
import '../notifications_screen.dart';
import '../dispute_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchBookings();
      Provider.of<WalletProvider>(context, listen: false).fetchWalletData();
      Provider.of<VehicleProvider>(context, listen: false).fetchMyVehicles();
      Provider.of<DriverProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoConnect', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: [
        _DashboardView(
          onToggle: (val) async {
            final success = await driverProvider.setAvailability(val);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(driverProvider.errorMessage ?? 'Impossible de changer votre disponibilité.')),
              );
            }
          },
        ),
        const _DriverBookingsView(),
        const _WalletView(),
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1E3A8A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tableau de bord'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Réservations'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portefeuille'),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanQrScreen()),
                );
              },
              label: const Text('Scanner QR'),
              icon: const Icon(Icons.qr_code_scanner),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

/// Tableau de bord chauffeur : carte plein écran, statut en ligne/hors ligne,
/// passagers à prendre en charge et statistiques réelles.
class _DashboardView extends StatefulWidget {
  final Future<void> Function(bool) onToggle;

  const _DashboardView({required this.onToggle});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  MapLibreMapController? _map;
  bool _hasLocationPermission = false;
  LatLng? _myPosition;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      final position = await LocationService().getCurrentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _hasLocationPermission = true;
        _myPosition = point;
      });
      _map?.animateCamera(CameraUpdate.newLatLngZoom(point, MapConfig.streetZoom));
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>();
    final bookings = context.watch<BookingProvider>().bookings;
    final wallet = context.watch<WalletProvider>().wallet;
    final money = NumberFormat.decimalPattern('fr');

    final activeTrips = bookings.where((b) => b.isTrackable).toList();
    final completedTrips = bookings
        .where((b) => b.statut == BookingStatus.COMPLETED || b.statut == BookingStatus.FUNDS_RELEASED)
        .length;

    return Stack(
      children: [
        // ── Carte plein écran ──
        Positioned.fill(
          child: MapLibreMap(
            styleString: MapConfig.styleUrl,
            initialCameraPosition: const CameraPosition(
              target: MapConfig.defaultCenter,
              zoom: MapConfig.defaultZoom,
            ),
            myLocationEnabled: _hasLocationPermission,
            compassEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            onMapCreated: (controller) => _map = controller,
            onStyleLoadedCallback: () {
              final me = _myPosition;
              if (me != null) _map?.moveCamera(CameraUpdate.newLatLngZoom(me, MapConfig.streetZoom));
            },
          ),
        ),

        // ── Statut en ligne / hors ligne ──
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _StatusPill(
            isAvailable: driver.isAvailable,
            isVerified: driver.isVerified,
            profileLoaded: driver.profileLoaded,
          ),
        ),

        // ── Panneau de commande ──
        DraggableScrollableSheet(
          initialChildSize: 0.36,
          minChildSize: 0.22,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Material(
            elevation: 12,
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                _AvailabilityButton(
                  isAvailable: driver.isAvailable,
                  isVerified: driver.isVerified,
                  profileLoaded: driver.profileLoaded,
                  isLoading: driver.isLoading,
                  onToggle: widget.onToggle,
                ),
                if (activeTrips.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Passagers à prendre en charge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final booking in activeTrips)
                    Card(
                      color: const Color(0xFFF0FDF4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFDCFCE7),
                          child: Icon(Icons.person_pin_circle, color: Color(0xFF15803D)),
                        ),
                        title: Text(booking.passengerName ?? 'Passager'),
                        subtitle: Text('${booking.departure} → ${booking.destination}'),
                        trailing: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TripTrackingScreen(booking: booking, asDriver: true)),
                          ),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Localiser'),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatTile(icon: Icons.route, label: 'Trajets terminés', value: '$completedTrips'),
                    const SizedBox(width: 8),
                    _StatTile(
                      icon: Icons.account_balance_wallet,
                      label: 'Disponible',
                      value: wallet == null ? '—' : '${money.format(wallet.withdrawableBalance)} GNF',
                    ),
                    const SizedBox(width: 8),
                    _StatTile(
                      icon: Icons.hourglass_bottom,
                      label: 'En attente',
                      value: wallet == null ? '—' : '${money.format(wallet.pendingBalance)} GNF',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _MyVehiclesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isAvailable;
  final bool isVerified;
  final bool profileLoaded;

  const _StatusPill({required this.isAvailable, required this.isVerified, required this.profileLoaded});

  @override
  Widget build(BuildContext context) {
    final pending = profileLoaded && !isVerified;
    final color = pending ? Colors.amber[700]! : (isAvailable ? Colors.green[600]! : Colors.grey[600]!);
    final title = pending ? 'Vérification en cours' : (isAvailable ? 'En ligne' : 'Hors ligne');
    final subtitle = pending
        ? 'Un administrateur doit valider votre compte'
        : (isAvailable ? 'Vous recevez des réservations' : 'Passez en ligne pour recevoir des passagers');

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 2)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityButton extends StatelessWidget {
  final bool isAvailable;
  final bool isVerified;
  final bool profileLoaded;
  final bool isLoading;
  final Future<void> Function(bool) onToggle;

  const _AvailabilityButton({
    required this.isAvailable,
    required this.isVerified,
    required this.profileLoaded,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (profileLoaded && !isVerified) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFFB45309)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Votre compte est en attente de vérification. Vous pourrez passer en ligne dès qu’un administrateur aura validé votre permis.',
              ),
            ),
          ],
        ),
      );
    }

    final child = isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(
            isAvailable ? 'Passer hors ligne' : 'Passer en ligne',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          );

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : () => onToggle(!isAvailable),
        icon: Icon(isAvailable ? Icons.pause_circle_outline : Icons.power_settings_new),
        label: child,
        style: FilledButton.styleFrom(
          backgroundColor: isAvailable ? const Color(0xFF374151) : const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

class _MyVehiclesSection extends StatelessWidget {
  const _MyVehiclesSection();

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.myVehicles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Mes véhicules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              onPressed: () => _showAddVehicleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (vehicleProvider.isLoading && vehicles.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (vehicles.isEmpty)
          const Text('Ajoutez un véhicule pour recevoir des réservations.')
        else
          ...vehicles.map(
            (vehicle) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text('${vehicle.marque} ${vehicle.modele}'),
                subtitle: Text('${vehicle.immatriculation} • ${vehicle.placesDisponibles}/${vehicle.capacite} places'),
                trailing: Text(vehicle.statut.name),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddVehicleDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final marqueController = TextEditingController();
    final modeleController = TextEditingController();
    final immatController = TextEditingController();
    final capaciteController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un véhicule'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: marqueController,
                  decoration: const InputDecoration(labelText: 'Marque (ex: Toyota)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: modeleController,
                  decoration: const InputDecoration(labelText: 'Modèle (ex: Corolla)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: immatController,
                  decoration: const InputDecoration(labelText: 'Immatriculation'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: capaciteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre de places'),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Au moins 1 place' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await dialogContext.read<VehicleProvider>().addVehicle(
                marqueController.text.trim(),
                modeleController.text.trim(),
                immatController.text.trim(),
                int.parse(capaciteController.text.trim()),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext, success);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (added == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Véhicule ajouté.'
              : context.read<VehicleProvider>().errorMessage ?? 'Impossible d’ajouter le véhicule.',
        ),
      ),
    );
  }
}

class _DriverBookingsView extends StatelessWidget {
  const _DriverBookingsView();

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    if (bookingProvider.isLoading) return const Center(child: CircularProgressIndicator());
    if (bookingProvider.bookings.isEmpty) return const Center(child: Text('Aucune réservation reçue'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookingProvider.bookings.length,
      itemBuilder: (context, index) {
        final booking = bookingProvider.bookings[index];
        final actionLabel = _actionLabel(booking.statut);

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(booking.passengerName ?? 'Passager #${booking.id.substring(0, 5)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${booking.departure} → ${booking.destination}'),
                Text(
                  'Statut : ${_statusLabel(booking.statut)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (booking.statut == BookingStatus.CONFIRMED)
                  const Text('En attente du paiement du passager', style: TextStyle(color: Colors.orange)),
                if (booking.statut == BookingStatus.PAID)
                  const Text('Payée — en attente de la confirmation du passager', style: TextStyle(color: Colors.orange)),
                if (booking.isTrackable)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TripTrackingScreen(booking: booking, asDriver: true)),
                      ),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Localiser le passager'),
                    ),
                  ),
              ],
            ),
            trailing: actionLabel == null
                ? null
                : SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => _handleBookingAction(context, bookingProvider, booking),
                      child: Text(actionLabel),
                    ),
                  ),
            onTap: actionLabel == null
                ? null
                : () => _handleBookingAction(context, bookingProvider, booking),
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DisputeScreen(bookingId: booking.id)),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleBookingAction(
    BuildContext context,
    BookingProvider bookingProvider,
    Booking booking,
  ) async {
    if (booking.statut == BookingStatus.PENDING) {
      final success = await bookingProvider.confirmBooking(booking.id);
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation confirmée.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bookingProvider.errorMessage ?? 'La confirmation a échoué.')),
        );
      }
      return;
    }

    // Embarquement : le passager a confirmé sa présence, le chauffeur scanne son QR / saisit l'OTP
    if (booking.statut == BookingStatus.BOARDING) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanQrScreen(bookingId: booking.id)),
      );
      if (context.mounted) {
        bookingProvider.fetchBookings();
      }
      return;
    }

    if (booking.statut == BookingStatus.IN_PROGRESS) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Terminer le trajet'),
          content: Text('Confirmez-vous l’arrivée à ${booking.destination} ? Les fonds seront libérés dans votre portefeuille.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminer')),
          ],
        ),
      );
      if (confirmed != true) return;

      final success = await bookingProvider.completeTrip(booking.id);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Trajet terminé. Les fonds ont été libérés dans votre portefeuille.'
                : bookingProvider.errorMessage ?? 'Impossible de terminer le trajet.',
          ),
        ),
      );
      if (success) {
        context.read<WalletProvider>().fetchWalletData();
      }
    }
  }

  /// Action disponible pour le chauffeur selon le statut, ou null si aucune.
  String? _actionLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return 'Confirmer';
      case BookingStatus.BOARDING:
        return 'Embarquer';
      case BookingStatus.IN_PROGRESS:
        return 'Terminer';
      default:
        return null;
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

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF1E3A8A),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    walletProvider.isLoading || walletProvider.wallet == null
                        ? 'Chargement…'
                        : '${walletProvider.wallet!.withdrawableBalance.toInt()} GNF',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    walletProvider.wallet == null
                        ? 'Solde en attente : —'
                        : 'En attente : ${walletProvider.wallet!.pendingBalance.toInt()} GNF',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: walletProvider.wallet == null || walletProvider.wallet!.withdrawableBalance <= 0
                ? null
                : () {},
            icon: const Icon(Icons.file_upload),
            label: const Text('Demander un retrait'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 24),
          const Text('Dernières transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: walletProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : walletProvider.transactions.isEmpty
                    ? const Center(child: Text('Aucun mouvement enregistré'))
                    : ListView.builder(
                        itemCount: walletProvider.transactions.length,
                        itemBuilder: (context, index) {
                          final tx = walletProvider.transactions[index];
                          return ListTile(
                            leading: Icon(
                              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: tx.isCredit ? Colors.green : Colors.orange,
                            ),
                            title: Text(tx.description),
                            subtitle: Text('${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}'),
                            trailing: Text('${tx.montant.toInt()} GNF'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
