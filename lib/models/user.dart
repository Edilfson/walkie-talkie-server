class User {
  final String id;
  final String name;
  final bool isOnline;
  final DateTime lastSeen;
  final String? avatarUrl; // Profil fotoğrafı (opsiyonel)
  final String? status; // Durum mesajı (opsiyonel)

  User({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.lastSeen,
    this.avatarUrl,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      isOnline: json['isOnline'],
      lastSeen: DateTime.parse(json['lastSeen']),
      avatarUrl: json['avatarUrl'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'avatarUrl': avatarUrl,
      'status': status,
    };
  }
}
