class Station {
  final String id;
  final String nom;
  final String ville;
  final String adresse;
  final double? latitude;
  final double? longitude;

  Station({
    required this.id,
    required this.nom,
    required this.ville,
    required this.adresse,
    this.latitude,
    this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      nom: json['nom'],
      ville: json['ville'],
      adresse: json['adresse'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}
