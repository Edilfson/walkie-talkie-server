import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';
import '../widgets/talk_button.dart';
import 'message_input_bar.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoomProvider>(context, listen: false).listenTextMessages();
      Provider.of<RoomProvider>(context, listen: false)
          .listenKickedEvent(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF1A0F08)],
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
                  // Header ve katılımcı listesi
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
                  // Katılımcı listesi
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
                                  if (participant.id == room.createdBy)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                    ),
                                ],
                              ),
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
                  const SizedBox(height: 10),
                  // TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.amber,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(icon: Icon(Icons.mic), text: 'Telsiz'),
                        Tab(icon: Icon(Icons.chat), text: 'Mesajlaşma'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Telsiz Tab: Only audio messages and talk button
                        _AudioTab(),
                        // Mesajlaşma Tab: Only text messages and input
                        _TextTab(),
                      ],
                    ),
                  ),
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

// --- Audio Tab ---
class _AudioTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<RoomProvider>(
            builder: (context, roomProvider, child) {
              final audioMessages = roomProvider.messages;
              if (audioMessages.isEmpty) {
                return const Center(
                  child: Text('Henüz sesli mesaj yok',
                      style: TextStyle(color: Colors.white54)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: audioMessages.length,
                itemBuilder: (context, index) {
                  final msg = audioMessages[index];
                  final isOwn = msg.senderId == roomProvider.currentUser?.id;
                  return Align(
                    alignment:
                        isOwn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOwn
                            ? Colors.amber
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.play_arrow,
                                color: isOwn ? Colors.black : Colors.white),
                            onPressed: () {
                              // Play audio logic (handled by AudioProvider)
                              final audioProvider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false);
                              if (audioProvider.isPlaying) {
                                audioProvider.stopPlaying();
                              } else {
                                audioProvider.playAudio(msg.audioPath);
                              }
                            },
                          ),
                          Text(isOwn ? 'Sen' : msg.senderName,
                              style: TextStyle(
                                  color: isOwn ? Colors.black : Colors.white,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(_formatTime(msg.sentAt),
                              style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isOwn ? Colors.black54 : Colors.white54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Push-to-talk button
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(height: 90, child: Center(child: TalkButton())),
        ),
      ],
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

// --- Text Tab ---
class _TextTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<RoomProvider>(
            builder: (context, roomProvider, child) {
              final textMessages = roomProvider.textMessages;
              if (textMessages.isEmpty) {
                return const Center(
                  child: Text('Henüz yazılı mesaj yok',
                      style: TextStyle(color: Colors.white54)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: textMessages.length,
                itemBuilder: (context, index) {
                  final msg = textMessages[index];
                  final isOwn = msg.senderId == roomProvider.currentUser?.id;
                  return Align(
                    alignment:
                        isOwn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOwn
                            ? Colors.amber
                            : Colors.white.withOpacity(0.1),
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
                                  color:
                                      isOwn ? Colors.black54 : Colors.white54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Text input bar
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MessageInputBar(),
        ),
      ],
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
