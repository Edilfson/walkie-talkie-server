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
    DateTime sentAt;
    if (json['sentAt'] is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(json['sentAt']);
    } else if (json['sentAt'] is String) {
      sentAt = DateTime.tryParse(json['sentAt']) ?? DateTime.now();
    } else {
      sentAt = DateTime.now();
    }
    return TextMessage(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      text: json['text'],
      sentAt: sentAt,
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
