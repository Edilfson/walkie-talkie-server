import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';

class _MessageInputBar extends StatefulWidget {
  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Sesli mesaj butonu
          GestureDetector(
            onLongPressStart: (_) async {
              setState(() => _isRecording = true);
              await audioProvider.startRecording();
            },
            onLongPressEnd: (_) async {
              setState(() => _isRecording = false);
              final path = await audioProvider.stopRecording();
              if (path != null && path.isNotEmpty) {
                await roomProvider.sendAudioMessage(path);
              }
            },
            child: CircleAvatar(
              backgroundColor: _isRecording ? Colors.red : Colors.amber,
              child: Icon(_isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
          // Yazılı mesaj inputu
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Mesaj yaz veya ses kaydet...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendText(roomProvider),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.amber),
            onPressed: () => _sendText(roomProvider),
          ),
        ],
      ),
    );
  }

  void _sendText(RoomProvider roomProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    roomProvider.sendTextMessage(text);
    _controller.clear();
  }
}
