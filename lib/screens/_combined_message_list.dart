import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../models/audio_message.dart';
import '../models/text_message.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';

class _CombinedMessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final messages =
            roomProvider.allMessages; // Tüm mesajlar (sesli + yazılı)
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Henüz mesaj yok',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            if (msg is AudioMessage) {
              return _AudioMessageBubble(
                  message: msg,
                  isOwn: msg.senderId == roomProvider.currentUser?.id);
            } else if (msg is TextMessage) {
              final isOwn = msg.senderId == roomProvider.currentUser?.id;
              return Align(
                alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOwn ? Colors.amber : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isOwn)
                        Text(msg.senderName,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      Text(msg.text,
                          style: TextStyle(
                              color: isOwn ? Colors.black : Colors.white)),
                      Text(_formatTime(msg.sentAt),
                          style: TextStyle(
                              fontSize: 10,
                              color: isOwn ? Colors.black54 : Colors.white54)),
                    ],
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}s önce';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _AudioMessageBubble extends StatelessWidget {
  final AudioMessage message;
  final bool isOwn;
  const _AudioMessageBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOwn ? Colors.amber : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  audioProvider.isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isOwn ? Colors.black : Colors.white),
              onPressed: () async {
                if (audioProvider.isPlaying) {
                  await audioProvider.stopPlaying();
                } else {
                  await audioProvider.playAudio(message.audioPath);
                }
              },
            ),
            Text(
              isOwn ? 'Sen' : message.senderName,
              style: TextStyle(
                  color: isOwn ? Colors.black : Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(_formatTime(message.sentAt),
                style: TextStyle(
                    fontSize: 10,
                    color: isOwn ? Colors.black54 : Colors.white54)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}s önce';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
