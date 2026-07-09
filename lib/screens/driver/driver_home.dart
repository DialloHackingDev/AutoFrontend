import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/booking_model.dart';
import '../../providers/driver_provider.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoConnect Chauffeur', style: TextStyle(fontWeight: FontWeight.bold)),
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
          isAvailable: driverProvider.isAvailable, 
          onToggle: (val) async {
            final success = await driverProvider.setAvailability(val);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur: Vous devez être vérifié pour vous mettre en ligne.')),
              );
            }
          }
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

class _DashboardView extends StatelessWidget {
  final bool isAvailable;
  final Function(bool) onToggle;

  const _DashboardView({required this.isAvailable, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: isAvailable ? Colors.green[50] : Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.pause_circle_filled,
                    color: isAvailable ? Colors.green : Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAvailable ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isAvailable ? 'Prêt à recevoir des réservations' : 'Activez pour recevoir des passagers',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: isAvailable, onChanged: onToggle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Statistiques du jour', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(title: 'Trajets', value: '12', icon: Icons.map, color: Colors.blue),
              _StatCard(title: 'Revenus', value: '450k', icon: Icons.payments, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
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
        final isPending = booking.statut == BookingStatus.PENDING;
        final isReadyToValidate = booking.statut == BookingStatus.CONFIRMED || booking.statut == BookingStatus.PAID;

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Passager #${booking.id.substring(0, 5)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${booking.departure} → ${booking.destination}'),
                Text(
                  'Statut : ${_statusLabel(booking.statut)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: isPending || isReadyToValidate
                    ? () => _handleBookingAction(context, bookingProvider, booking)
                    : null,
                child: Text(
                  isPending ? 'Confirmer' : 'Valider',
                ),
              ),
            ),
            onTap: isPending || isReadyToValidate
                ? () => _handleBookingAction(context, bookingProvider, booking)
                : null,
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

    if (booking.statut == BookingStatus.CONFIRMED) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanQrScreen(bookingId: booking.id)),
      );
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
