import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';

class TextChatTab extends StatefulWidget {
  const TextChatTab({super.key});

  @override
  State<TextChatTab> createState() => _TextChatTabState();
}

class _TextChatTabState extends State<TextChatTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomProvider>(context, listen: false).listenTextMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: roomProvider.textMessages.length,
            itemBuilder: (context, index) {
              final msg = roomProvider.textMessages[index];
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
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Mesaj yaz...'),
                onSubmitted: (_) => _sendMessage(roomProvider),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.amber),
              onPressed: () => _sendMessage(roomProvider),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage(RoomProvider roomProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    roomProvider.sendTextMessage(text);
    _controller.clear();
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
