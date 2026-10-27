import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

/// Récupère la position GPS de l'appareil en gérant le service et les permissions.
/// Utilisé par le passager (confirmation d'embarquement, partage de position)
/// et le chauffeur (démarrage du trajet, suivi en temps réel).
class LocationService {
  /// Vérifie que le GPS est actif et que l'app a la permission, sinon lève une [LocationException].
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Le service de localisation est désactivé.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Permissions de localisation refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('Permissions de localisation définitivement refusées.');
    }
  }

  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition();
  }

  /// Positions successives, émises à chaque déplacement d'au moins [distanceFilter] mètres.
  /// Appeler [ensurePermission] avant d'écouter ce flux.
  Stream<Position> positionStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Distance en mètres entre deux points GPS.
  static double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
