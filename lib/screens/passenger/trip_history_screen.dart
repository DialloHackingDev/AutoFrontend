import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/payment_method_tile.dart';

enum _TripFilter { all, upcoming, done, cancelled }

/// Historique des trajets du passager, avec reçu de paiement pour chaque trajet payé.
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  _TripFilter _filter = _TripFilter.all;

  static const _done = {BookingStatus.COMPLETED, BookingStatus.FUNDS_RELEASED};
  static const _closed = {BookingStatus.CANCELLED};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BookingProvider>().fetchBookings());
  }

  bool _matches(Booking b) => switch (_filter) {
        _TripFilter.all => true,
        _TripFilter.done => _done.contains(b.statut),
        _TripFilter.cancelled => _closed.contains(b.statut),
        _TripFilter.upcoming => !_done.contains(b.statut) && !_closed.contains(b.statut),
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final bookings = provider.bookings;
    final trips = bookings.where(_matches).toList();
    final doneTrips = bookings.where((b) => _done.contains(b.statut)).toList();
    final spent = bookings
        .where((b) => b.paymentStatus == 'COMPLETED')
        .fold<double>(0, (sum, b) => sum + b.prix);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des trajets')),
      body: RefreshIndicator(
        onRefresh: provider.fetchBookings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _Summary(label: 'Trajets effectués', value: '${doneTrips.length}', icon: Icons.route),
                const SizedBox(width: 12),
                _Summary(label: 'Total payé', value: formatGnf(spent), icon: Icons.payments_outlined),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (filter, label) in [
                    (_TripFilter.all, 'Tous'),
                    (_TripFilter.upcoming, 'À venir'),
                    (_TripFilter.done, 'Terminés'),
                    (_TripFilter.cancelled, 'Annulés'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == filter,
                        selectedColor: AppColors.primarySoft,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && bookings.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (trips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_outlined, size: 48, color: AppColors.inkMuted),
                    SizedBox(height: 8),
                    Text('Aucun trajet dans cette catégorie', style: TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              )
            else
              for (final booking in trips) _TripCard(booking: booking),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Summary({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// Libellé et couleur d'un statut de réservation
(String, Color) bookingStatusStyle(BookingStatus status) => switch (status) {
      BookingStatus.PENDING => ('En attente', AppColors.warning),
      BookingStatus.CONFIRMED => ('Confirmée', AppColors.warning),
      BookingStatus.PAID => ('Payée', AppColors.success),
      BookingStatus.BOARDING => ('Embarquement', AppColors.success),
      BookingStatus.IN_PROGRESS => ('En cours', AppColors.primary),
      BookingStatus.COMPLETED || BookingStatus.FUNDS_RELEASED => ('Terminé', AppColors.successDark),
      BookingStatus.CANCELLED => ('Annulée', AppColors.inkMuted),
      BookingStatus.DISPUTE => ('Litige', AppColors.danger),
      BookingStatus.INCIDENT => ('Incident', AppColors.danger),
    };

class _TripCard extends StatelessWidget {
  final Booking booking;

  const _TripCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = bookingStatusStyle(booking.statut);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReceipt(context, booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.trip_origin, size: 14, color: AppColors.success),
                  Container(width: 2, height: 22, color: AppColors.border),
                  const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.departure, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(booking.destination, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(booking.createdAt)} · ${booking.places} place${booking.places > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatGnf(booking.prix), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceipt(BuildContext context, Booking booking) {
    final (label, color) = bookingStatusStyle(booking.statut);
    final paid = booking.paymentStatus == 'COMPLETED' || booking.paymentStatus == 'REFUNDED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(paid ? 'Reçu de paiement' : 'Détail du trajet',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Text('${booking.departure} → ${booking.destination}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const Divider(height: 28),
            _ReceiptLine('Réservé le', formatDateTime(booking.createdAt)),
            if (booking.completedAt != null) _ReceiptLine('Arrivé le', formatDateTime(booking.completedAt!)),
            _ReceiptLine('Places', '${booking.places}'),
            if (booking.paymentMethod != null) _ReceiptLine('Moyen de paiement', PaymentMethods.label(booking.paymentMethod!)),
            if (booking.paymentDate != null && paid) _ReceiptLine('Payé le', formatDateTime(booking.paymentDate!)),
            if (booking.paymentStatus == 'REFUNDED') const _ReceiptLine('Statut', 'Remboursé sur le portefeuille'),
            if (booking.paymentReference != null && paid)
              _ReceiptLine('Référence', booking.paymentReference!.substring(0, 8).toUpperCase()),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(formatGnf(booking.prix),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            if (paid) ...[
              const SizedBox(height: 12),
              const Text(
                'Paiement sécurisé par AutoConnect : les fonds sont conservés jusqu’à la fin du trajet.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkMuted)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
