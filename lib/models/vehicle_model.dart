enum VehicleStatus { ACTIF, INACTIF, MAINTENANCE }

class Vehicle {
  final String id;
  final String marque;
  final String modele;
  final String immatriculation;
  final int capacite;
  final int placesDisponibles;
  final VehicleStatus statut;
  final String? driverName;
  final String? driverPhone;
  final double driverNote;

  Vehicle({
    required this.id,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.capacite,
    required this.placesDisponibles,
    required this.statut,
    this.driverName,
    this.driverPhone,
    this.driverNote = 5.0,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final user = driver?['user'] as Map<String, dynamic>?;

    return Vehicle(
      id: json['id'],
      marque: json['marque'],
      modele: json['modele'],
      immatriculation: json['immatriculation'],
      capacite: json['capacite'],
      placesDisponibles: json['placesDisponibles'] ?? 0,
      statut: VehicleStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['statut'],
        orElse: () => VehicleStatus.ACTIF,
      ),
      driverName: user?['nom']?.toString(),
      driverPhone: user?['telephone']?.toString(),
      driverNote: (driver?['note'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
