import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../widgets/talk_button.dart';
import '../widgets/message_list.dart';
import '../widgets/text_chat_tab.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Kısa yazılı mesajlar için dinleyici başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomProvider>(context, listen: false).listenTextMessages();
      Provider.of<RoomProvider>(context, listen: false)
          .listenKickedEvent(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF1A0F08),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<RoomProvider>(
            builder: (context, roomProvider, child) {
              final room = roomProvider.currentRoom;
              if (room == null) {
                return const Center(
                  child: Text(
                    'Oda bulunamadı',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _leaveRoom(roomProvider),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${roomProvider.roomParticipants.length} kişi aktif',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'CANLI',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Participants
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: roomProvider.roomParticipants.length,
                      itemBuilder: (context, index) {
                        final participant =
                            roomProvider.roomParticipants[index];
                        final isCurrentUser =
                            participant.id == roomProvider.currentUser?.id;

                        return Container(
                          margin: const EdgeInsets.only(right: 15),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: isCurrentUser
                                        ? Colors.amber
                                        : Colors.white.withOpacity(0.2),
                                    child: Icon(
                                      Icons.person,
                                      color: isCurrentUser
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                  if (participant.isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF1A0F08),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Yönetici rozeti
                                  if (participant.id == room.createdBy)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                    ),
                                ],
                              ),
                              // Katılımcı atma butonu (sadece yönetici ve kendisi değilse)
                              if (roomProvider.currentUser?.id ==
                                      room.createdBy &&
                                  participant.id != room.createdBy)
                                TextButton(
                                  onPressed: () {
                                    roomProvider
                                        .kickParticipant(participant.id);
                                  },
                                  child: const Text('At',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 10)),
                                ),
                              const SizedBox(height: 5),
                              Text(
                                isCurrentUser
                                    ? 'Sen'
                                    : participant.name.split(' ').first,
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.amber
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Messages
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Favori mesajlar ve kısa yazılı mesaj sekmesi
                          DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(
                                        icon: Icon(Icons.chat_bubble_outline),
                                        text: 'Sesli'),
                                    Tab(
                                        icon: Icon(Icons.star),
                                        text: 'Favoriler'),
                                    Tab(
                                        icon: Icon(Icons.message),
                                        text: 'Yazılı'),
                                  ],
                                ),
                                SizedBox(
                                  height: 350, // Mesaj listesi yüksekliği
                                  child: TabBarView(
                                    children: [
                                      const MessageList(),
                                      const MessageList(
                                          showOnlyFavorites: true),
                                      TextChatTab(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Talk Button
                  const TalkButton(),

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _leaveRoom(RoomProvider roomProvider) async {
    await roomProvider.leaveRoom();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _TextChatTab extends StatefulWidget {
  @override
  State<_TextChatTab> createState() => _TextChatTabState();
}

class _TextChatTabState extends State<_TextChatTab> {
  final TextEditingController _controller = TextEditingController();

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
