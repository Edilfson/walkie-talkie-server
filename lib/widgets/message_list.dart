import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';
import '../models/audio_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageList extends StatelessWidget {
  final bool showOnlyFavorites;
  const MessageList({super.key, this.showOnlyFavorites = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final messages = showOnlyFavorites
            ? roomProvider.messages.where((m) => m.isFavorite).toList()
            : roomProvider.messages;

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white24,
                ),
                SizedBox(height: 15),
                Text(
                  'Henüz mesaj yok',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Konuşmak için butona basın ve basılı tutun',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isOwnMessage =
                message.senderId == roomProvider.currentUser?.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: isOwnMessage
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isOwnMessage) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: AudioMessageBubble(
                      message: message,
                      isOwnMessage: isOwnMessage,
                    ),
                  ),
                  if (isOwnMessage) ...[
                    const SizedBox(width: 10),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.amber,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AudioMessageBubble extends StatefulWidget {
  final AudioMessage message;
  final bool isOwnMessage;

  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  AudioProvider? _audioProvider;

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

    // AudioProvider durumunu dinle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _audioProvider = Provider.of<AudioProvider>(context, listen: false);
        _audioProvider?.addListener(_onAudioStateChanged);
      }
      // Favori durumu localden yükle
      _loadFavorite();
    });
  }

  void _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favKey = 'favorite_${widget.message.id}';
    final isFav = prefs.getBool(favKey) ?? false;
    if (mounted && widget.message.isFavorite != isFav) {
      setState(() {
        widget.message.isFavorite = isFav;
      });
    }
  }

  void _onAudioStateChanged() {
    if (!mounted) return;
    if (_audioProvider?.isPlaying == true) {
      _waveController.repeat(reverse: true);
    } else {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _audioProvider?.removeListener(_onAudioStateChanged);
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isPlayingThisMessage = audioProvider.isPlaying;

        return Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isOwnMessage
                ? Colors.amber.withOpacity(0.9)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: widget.isOwnMessage
                ? null
                : Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isOwnMessage)
                Text(
                  widget.message.senderName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (!widget.isOwnMessage) const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _togglePlayback(audioProvider),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isOwnMessage
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlayingThisMessage ? Icons.pause : Icons.play_arrow,
                        color:
                            widget.isOwnMessage ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Favori butonu
                  IconButton(
                    icon: Icon(
                      widget.message.isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: widget.message.isFavorite
                          ? Colors.amber
                          : Colors.white38,
                      size: 22,
                    ),
                    onPressed: () async {
                      setState(() {
                        widget.message.isFavorite = !widget.message.isFavorite;
                      });
                      // Favori durumu localde saklanacak
                      final prefs = await SharedPreferences.getInstance();
                      final favKey = 'favorite_${widget.message.id}';
                      if (widget.message.isFavorite) {
                        prefs.setBool(favKey, true);
                      } else {
                        prefs.remove(favKey);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(20, (index) {
                            final height = isPlayingThisMessage
                                ? (20 + (index % 3) * 10) * _waveAnimation.value
                                : 8.0;
                            return Container(
                              width: 2,
                              height: height,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: widget.isOwnMessage
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _formatTime(widget.message.sentAt),
                style: TextStyle(
                  color: widget.isOwnMessage
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _togglePlayback(AudioProvider audioProvider) async {
    if (audioProvider.isPlaying) {
      await audioProvider.stopPlaying();
    } else {
      await audioProvider.playAudio(widget.message.audioPath);
    }
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
