import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';
import '../providers/room_provider.dart';

class TalkButton extends StatefulWidget {
  const TalkButton({super.key});

  @override
  State<TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends State<TalkButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioProvider, RoomProvider>(
      builder: (context, audioProvider, roomProvider, child) {
        final isRecording = audioProvider.isRecording;

        return Center(
          child: GestureDetector(
            onTapDown: (_) => _startTalking(audioProvider),
            onTapUp: (_) => _stopTalking(audioProvider, roomProvider),
            onTapCancel: () => _stopTalking(audioProvider, roomProvider),
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isRecording
                            ? [
                                Colors.red.withOpacity(0.8),
                                Colors.red.withOpacity(0.4),
                                Colors.red.withOpacity(0.1),
                              ]
                            : [
                                Colors.amber.withOpacity(0.8),
                                Colors.amber.withOpacity(0.4),
                                Colors.amber.withOpacity(0.1),
                              ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red : Colors.amber)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: isRecording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? Colors.red : Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording ? Icons.mic : Icons.mic_none,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _startTalking(AudioProvider audioProvider) async {
    if (_isPressed) return;

    setState(() {
      _isPressed = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Scale animation
    _scaleController.forward();

    // Start recording
    await audioProvider.startRecording();
  }

  void _stopTalking(
      AudioProvider audioProvider, RoomProvider roomProvider) async {
    if (!_isPressed) return;

    setState(() {
      _isPressed = false;
    });

    // Scale animation
    _scaleController.reverse();

    // Stop recording and send message
    final audioPath = await audioProvider.stopRecording();

    if (audioPath != null) {
      await roomProvider.sendAudioMessage(audioPath);

      // Success haptic feedback
      HapticFeedback.lightImpact();
    }
  }
}
