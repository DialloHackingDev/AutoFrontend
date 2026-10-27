enum BookingStatus {
  PENDING,
  CONFIRMED,
  PAID,
  BOARDING,
  IN_PROGRESS,
  COMPLETED,
  FUNDS_RELEASED,
  CANCELLED,
  DISPUTE,
  INCIDENT
}

class Booking {
  final String id;
  final String departure;
  final String destination;
  final int places;
  final double prix;
  final BookingStatus statut;
  final String? qrCode;
  final String? otpCode;
  final DateTime createdAt;
  final String? paymentId;
  final String? paymentStatus;
  final String? paymentMethod;
  final bool escrowHeld;
  final bool escrowReleased;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? passengerName;
  final String? passengerPhone;

  Booking({
    required this.id,
    required this.departure,
    required this.destination,
    required this.places,
    required this.prix,
    required this.statut,
    this.qrCode,
    this.otpCode,
    required this.createdAt,
    this.paymentId,
    this.paymentStatus,
    this.paymentMethod,
    this.escrowHeld = false,
    this.escrowReleased = false,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.passengerName,
    this.passengerPhone,
  });

  /// Réservation en cours de prise en charge : le passager partage sa position
  /// et chacun peut suivre l'autre sur la carte.
  bool get isTrackable =>
      statut == BookingStatus.PAID || statut == BookingStatus.BOARDING || statut == BookingStatus.IN_PROGRESS;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final paymentJson = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : null;
    final escrowJson = paymentJson?['escrow'] is Map<String, dynamic>
        ? paymentJson!['escrow'] as Map<String, dynamic>
        : null;
    final driverUser = (json['driver'] as Map<String, dynamic>?)?['user'] as Map<String, dynamic>?;
    final passengerUser = (json['passenger'] as Map<String, dynamic>?)?['user'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'].toString(),
      departure: json['departure'].toString(),
      destination: json['destination'].toString(),
      places: (json['places'] as num).toInt(),
      prix: (json['prix'] as num).toDouble(),
      statut: BookingStatus.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => BookingStatus.PENDING,
      ),
      qrCode: json['qrCode']?.toString(),
      otpCode: json['otpCode']?.toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      paymentId: paymentJson?['id']?.toString(),
      paymentStatus: paymentJson?['statut']?.toString(),
      paymentMethod: paymentJson?['methode']?.toString(),
      escrowHeld: escrowJson?['isHeld'] ?? false,
      escrowReleased: escrowJson?['isReleased'] ?? false,
      driverId: json['driverId']?.toString(),
      driverName: driverUser?['nom']?.toString(),
      driverPhone: driverUser?['telephone']?.toString(),
      passengerName: passengerUser?['nom']?.toString(),
      passengerPhone: passengerUser?['telephone']?.toString(),
    );
  }
}
