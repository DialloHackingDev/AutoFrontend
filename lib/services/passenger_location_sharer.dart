import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/booking_model.dart';
import 'location_service.dart';
import 'realtime_service.dart';

/// Partage automatiquement la position du passager pendant ses réservations actives
/// (payée, embarquement, en cours), pour que le chauffeur puisse venir le chercher.
/// S'arrête dès qu'il n'y a plus de réservation active.
class PassengerLocationSharer {
  final _locationService = LocationService();
  RealtimeService? _realtime;
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeat;
  Position? _last;
  Set<String> _bookingIds = {};

  bool get isSharing => _positionSub != null;

  Future<void> syncWith(List<Booking> bookings) async {
    final ids = bookings.where((b) => b.isTrackable).map((b) => b.id).toSet();
    // Rien à faire si les réservations n'ont pas changé et que le partage tourne déjà
    if (setEquals(ids, _bookingIds) && (ids.isEmpty || isSharing)) return;
    _bookingIds = ids;

    if (ids.isEmpty) {
      stop();
      return;
    }

    try {
      await _locationService.ensurePermission();
    } on LocationException catch (e) {
      // Sera retenté au prochain rafraîchissement des réservations
      debugPrint('Partage de position impossible : ${e.message}');
      return;
    }

    _realtime ??= RealtimeService();
    await _realtime!.connect();

    _positionSub ??= _locationService.positionStream(distanceFilter: 15).listen(_publish);
    // Renvoie la dernière position régulièrement : un passager immobile chez lui
    // reste visible pour un chauffeur qui ouvre la carte plus tard.
    _heartbeat ??= Timer.periodic(const Duration(seconds: 20), (_) {
      if (_last != null) _publish(_last!);
    });

    try {
      _publish(await _locationService.getCurrentPosition());
    } on LocationException catch (_) {}
  }

  void _publish(Position position) {
    _last = position;
    for (final bookingId in _bookingIds) {
      _realtime?.sendPassengerLocation(bookingId, position.latitude, position.longitude);
    }
  }

  void stop() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _positionSub?.cancel();
    _positionSub = null;
    _realtime?.dispose();
    _realtime = null;
    _last = null;
  }
}
