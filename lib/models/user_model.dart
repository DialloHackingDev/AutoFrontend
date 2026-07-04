enum UserRole { PASSAGER, CHAUFFEUR, AGENT_GARE, ADMIN }

class User {
  final String id;
  final String nom;
  final String telephone;
  final UserRole role;
  final String? token;

  User({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'],
      telephone: json['telephone'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'role': role.toString().split('.').last,
    };
  }
}
