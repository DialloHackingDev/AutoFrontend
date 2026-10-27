class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? bookingId;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      titre: json['titre']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INFO',
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      bookingId: json['bookingId']?.toString(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      titre: titre,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      bookingId: bookingId,
    );
  }
}
