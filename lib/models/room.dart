class Room {
  final String id;
  final String name;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      participants: List<String>.from(json['participants']),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
