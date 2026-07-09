class DisputeModel {
  final String id;
  final String bookingId;
  final String description;
  final String statut;
  final DateTime createdAt;

  DisputeModel({
    required this.id,
    required this.bookingId,
    required this.description,
    required this.statut,
    required this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'],
      bookingId: json['bookingId'],
      description: json['description'],
      statut: json['statut'] ?? 'OUVERT',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
