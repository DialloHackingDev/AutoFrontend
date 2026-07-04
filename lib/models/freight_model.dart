enum FreightStatus { EN_ATTENTE, EN_TRANSIT, LIVRE }

class Freight {
  final String id;
  final double poids;
  final String? type;
  final String destination;
  final double tarif;
  final String? description;
  final String ticketCode;
  final FreightStatus statut;
  final DateTime createdAt;

  Freight({
    required this.id,
    required this.poids,
    this.type,
    required this.destination,
    required this.tarif,
    this.description,
    required this.ticketCode,
    required this.statut,
    required this.createdAt,
  });

  factory Freight.fromJson(Map<String, dynamic> json) {
    return Freight(
      id: json['id'],
      poids: (json['poids'] as num).toDouble(),
      type: json['type'],
      destination: json['destination'],
      tarif: (json['tarif'] as num).toDouble(),
      description: json['description'],
      ticketCode: json['ticketCode'],
      statut: FreightStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['statut'],
        orElse: () => FreightStatus.EN_ATTENTE,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
