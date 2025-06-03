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

// TextMessage modeli kaldırıldı, artık text_message.dart içinde
