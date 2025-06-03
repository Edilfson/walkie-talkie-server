import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/audio_message.dart';
import '../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomProvider extends ChangeNotifier {
  SocketService? _socketService;
  String _serverUrl = '';
  Room? _currentRoom;
  User? _currentUser;
  List<Room> _availableRooms = [];
  List<User> _roomParticipants = [];
  List<AudioMessage> _messages = [];
  bool _isConnected = false;

  Room? get currentRoom => _currentRoom;
  User? get currentUser => _currentUser;
  List<Room> get availableRooms => _availableRooms;
  List<User> get roomParticipants => _roomParticipants;
  List<AudioMessage> get messages => _messages;
  bool get isConnected => _isConnected;

  Future<void> initialize(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl') ??
        'https://walkie-talkie-server-0j4t.onrender.com';
    _currentUser = User(
      id: const Uuid().v4(),
      name: userName,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _isConnected = true;
    notifyListeners();
    // Demo odaları kaldır, sadece bir oda olsun
    _availableRooms = [
      Room(
        id: 'room1',
        name: 'Genel Sohbet',
        participants: [],
        createdBy: _currentUser!.id,
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  void connectToRoom(String roomId) {
    if (_socketService != null) {
      _socketService!.disconnect();
    }
    _socketService = SocketService(_serverUrl);
    _socketService!.connect(roomId);
    _socketService!.onAudio((data) {
      // Sunucudan gelen sesli mesajı ekle
      final msg = AudioMessage(
        id: const Uuid().v4(),
        roomId: roomId,
        senderId: data['sender'] ?? 'unknown',
        senderName: data['sender'] ?? 'unknown',
        audioPath: data['audioBlob'],
        duration: const Duration(seconds: 3),
        sentAt: DateTime.now(),
      );
      _messages.add(msg);
      notifyListeners();
    });
  }

  Future<void> joinRoom(String roomId) async {
    if (_currentUser == null) return;
    final room = _availableRooms.firstWhere((r) => r.id == roomId);
    _currentRoom = room;
    connectToRoom(roomId);
    _roomParticipants = [_currentUser!];
    _messages.clear();
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    _currentRoom = null;
    _roomParticipants.clear();
    _messages.clear();
    _socketService?.disconnect();
    notifyListeners();
  }

  Future<void> sendAudioMessage(String audioPath) async {
    if (_currentRoom == null || _currentUser == null) return;
    // Mesajı önce kendi listene ekle
    final message = AudioMessage(
      id: const Uuid().v4(),
      roomId: _currentRoom!.id,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      audioPath: audioPath,
      duration: const Duration(seconds: 3),
      sentAt: DateTime.now(),
    );
    _messages.add(message);
    notifyListeners();
    // Sunucuya gönder
    _socketService?.sendAudio(_currentRoom!.id, audioPath, _currentUser!.name);
  }

  Future<void> createRoom(String roomName) async {
    final newRoom = Room(
      id: const Uuid().v4(),
      name: roomName,
      participants: [],
      createdBy: _currentUser?.id ?? '',
      createdAt: DateTime.now(),
    );
    _availableRooms.add(newRoom);
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService?.disconnect();
    super.dispose();
  }
}
