class AudioMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String audioPath;
  final Duration duration;
  final DateTime sentAt;
  bool isFavorite;

  AudioMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.audioPath,
    required this.duration,
    required this.sentAt,
    this.isFavorite = false,
  });

  factory AudioMessage.fromJson(Map<String, dynamic> json) {
    return AudioMessage(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      audioPath: json['audioPath'],
      duration: Duration(milliseconds: json['duration']),
      sentAt: DateTime.parse(json['sentAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'audioPath': audioPath,
      'duration': duration.inMilliseconds,
      'sentAt': sentAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }
}

// Kısa yazılı mesaj modeli
class TextMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  TextMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory TextMessage.fromJson(Map<String, dynamic> json) {
    return TextMessage(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      text: json['text'],
      sentAt: DateTime.parse(json['sentAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
