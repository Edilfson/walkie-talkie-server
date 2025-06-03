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
  final List<AudioMessage> _messages = [];
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
    _socketService = SocketService(_serverUrl);
    _socketService!.connect();
    // Oda ve katılımcı listesi eventlerini dinle
    _socketService!.onRooms((data) {
      _availableRooms = (data as List)
          .map((room) => Room(
                id: room['id'],
                name: room['name'],
                participants: room['participants'] ?? [],
                createdBy: room['createdBy'] ?? '',
                createdAt: DateTime.tryParse(room['createdAt'] ?? '') ??
                    DateTime.now(),
              ))
          .toList();
      notifyListeners();
    });
    _socketService!.onParticipants((data) {
      _roomParticipants = (data as List)
          .map((u) => User(
                id: u['id'],
                name: u['name'],
                isOnline: u['isOnline'] ?? true,
                lastSeen: DateTime.now(),
              ))
          .toList();
      notifyListeners();
    });
    notifyListeners();
  }

  void connectToRoom(String roomId) {
    if (_socketService != null) {
      _socketService!.disconnect();
    }
    // Oda ve katılımcı yönetimi merkezi sunucuda, burada sadece sesli mesaj eventini dinle
    _socketService = SocketService(_serverUrl);
    _socketService!.connect();
    _socketService!.onAudio((data) {
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
    _currentRoom = _availableRooms.firstWhere((r) => r.id == roomId,
        orElse: () => Room(
            id: roomId,
            name: '',
            participants: [],
            createdBy: '',
            createdAt: DateTime.now()));
    _socketService?.joinRoom(roomId, _currentUser!.toJson());
    _messages.clear();
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (_currentRoom == null || _currentUser == null) return;
    _socketService?.leaveRoom(_currentRoom!.id, _currentUser!.id);
    _currentRoom = null;
    _roomParticipants.clear();
    _messages.clear();
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

  Future<String?> createRoom(String roomName) async {
    if (_currentUser == null) return null;
    final newRoom = Room(
      id: const Uuid().v4(),
      name: roomName,
      participants: [],
      createdBy: _currentUser!.id,
      createdAt: DateTime.now(),
    );
    _socketService?.createRoom({
      'roomId': newRoom.id,
      'name': newRoom.name,
      'createdBy': newRoom.createdBy,
      'createdAt': newRoom.createdAt.toIso8601String(),
    });
    await joinRoom(newRoom.id);
    notifyListeners();
    return newRoom.id;
  }

  int get totalOnlineUsers {
    // Tüm odalardaki katılımcıların unique id'lerini topla
    final ids = <String>{};
    for (final room in _availableRooms) {
      for (final user in room.participants) {
        if (user is Map && user['id'] != null)
          ids.add(user['id']);
        else if (user is String) ids.add(user);
      }
    }
    return ids.length;
  }

  @override
  void dispose() {
    _socketService?.disconnect();
    super.dispose();
  }
}
