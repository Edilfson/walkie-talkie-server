import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/audio_message.dart';
import '../models/text_message.dart';
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
  final List<TextMessage> _textMessages = [];
  bool _isConnected = false;

  Room? get currentRoom => _currentRoom;
  User? get currentUser => _currentUser;
  List<Room> get availableRooms => _availableRooms;
  List<User> get roomParticipants => _roomParticipants;
  List<AudioMessage> get messages => _messages;
  List<TextMessage> get textMessages => _textMessages;
  bool get isConnected => _isConnected;

  // Sesli ve yazılı mesajları zaman sırasına göre birleştir
  List<dynamic> get allMessages {
    final all = <dynamic>[];
    all.addAll(_messages);
    all.addAll(_textMessages);
    all.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return all;
  }

  Future<void> initialize(String userName,
      {String? avatarUrl, String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl') ??
        'https://walkie-talkie-server-0j4t.onrender.com';
    _currentUser = User(
      id: const Uuid().v4(),
      name: userName,
      isOnline: true,
      lastSeen: DateTime.now(),
      avatarUrl: avatarUrl,
      status: status,
    );
    _isConnected = true;
    _socketService = SocketService(_serverUrl);
    _socketService!.connect();
    // Oda ve katılımcı listesi eventlerini dinle
    _socketService!.onRooms((data) {
      final List<Room> parsedRooms = [];
      for (final room in (data as List)) {
        // Eksik alanlar için varsayılan değerler ata
        parsedRooms.add(Room(
          id: room['id'] ?? '',
          name: room['name'] ?? '',
          participants: room['participants'] ?? [],
          createdBy: room['createdBy'] ?? '',
          createdAt: room['createdAt'] != null && room['createdAt'] != ''
              ? DateTime.tryParse(room['createdAt']) ?? DateTime.now()
              : DateTime.now(),
          password: room.containsKey('password') &&
                  room['password'] != null &&
                  room['password'] != false
              ? room['password'].toString()
              : null,
          inviteCode: room.containsKey('inviteCode') &&
                  room['inviteCode'] != null &&
                  room['inviteCode'] != false
              ? room['inviteCode'].toString()
              : null,
        ));
      }
      // Eğer genel oda yoksa elle ekle (sunucu hatası ihtimaline karşı)
      final hasGenel = parsedRooms.any((r) => r.id == 'genel');
      if (!hasGenel) {
        parsedRooms.insert(
            0,
            Room(
              id: 'genel',
              name: 'Genel Sohbet',
              participants: [],
              createdBy: 'system',
              createdAt: DateTime.now(),
            ));
      }
      _availableRooms = parsedRooms;
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
    // Tüm odalarda sesli mesaj eventini dinle
    _socketService!.onAudio((data) {
      final msg = AudioMessage(
        id: const Uuid().v4(),
        roomId: data['room'] ?? '',
        senderId: data['sender'] ?? 'unknown',
        senderName: data['sender'] ?? 'unknown',
        audioPath: data['audioBlob'],
        duration: const Duration(seconds: 3),
        sentAt: DateTime.now(),
      );
      // Sadece aktif odadaysa mesajı ekle
      if (_currentRoom != null && _currentRoom!.id == data['room']) {
        _messages.add(msg);
        notifyListeners();
      }
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

  Future<void> joinRoom(String roomId,
      {String? password, String? inviteCode}) async {
    if (_currentUser == null) return;
    _currentRoom = _availableRooms.firstWhere((r) => r.id == roomId,
        orElse: () => Room(
            id: roomId,
            name: '',
            participants: [],
            createdBy: '',
            createdAt: DateTime.now()));
    _socketService?.joinRoom(
      roomId,
      _currentUser!.toJson(),
      password: password,
      inviteCode: inviteCode,
    );
    _messages.clear();
    // Sunucudan geçmiş mesajları dinle
    _socketService?.socket.on('history', (data) {
      if (data is List) {
        _messages.clear();
        for (final msg in data) {
          _messages.add(AudioMessage(
            id: msg['id'] ?? '',
            roomId: msg['room'] ?? '',
            senderId: msg['sender'] ?? 'unknown',
            senderName: msg['sender'] ?? 'unknown',
            audioPath: msg['audioBlob'],
            duration: const Duration(seconds: 3),
            sentAt: DateTime.fromMillisecondsSinceEpoch(msg['sentAt'] ?? 0),
          ));
        }
        notifyListeners();
      }
    });
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
    // Sadece sunucuya gönder, local olarak ekleme
    _socketService?.sendAudio(_currentRoom!.id, audioPath, _currentUser!.name);
  }

  Future<String?> createRoom(String roomName,
      {String? password, String? inviteCode}) async {
    if (_currentUser == null) return null;
    final newRoom = Room(
      id: const Uuid().v4(),
      name: roomName,
      participants: [],
      createdBy: _currentUser!.id,
      createdAt: DateTime.now(),
      password: password,
      inviteCode: inviteCode,
    );
    _socketService?.createRoom({
      'roomId': newRoom.id,
      'name': newRoom.name,
      'createdBy': newRoom.createdBy,
      'createdAt': newRoom.createdAt.toIso8601String(),
      'password': password,
      'inviteCode': inviteCode,
    });
    await joinRoom(newRoom.id);
    notifyListeners();
    return newRoom.id;
  }

  void addTextMessage(TextMessage msg) {
    _textMessages.add(msg);
    notifyListeners();
  }

  void clearTextMessages() {
    _textMessages.clear();
    notifyListeners();
  }

  void sendTextMessage(String text) {
    if (_currentRoom == null || _currentUser == null) return;
    final msg = TextMessage(
      id: const Uuid().v4(),
      roomId: _currentRoom!.id,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      text: text,
      sentAt: DateTime.now(),
    );
    _socketService?.sendTextMessage(msg);
    // addTextMessage(msg); // ÇİFT MESAJ OLMASIN DİYE KALDIRILDI
  }

  void listenTextMessages() {
    // Önce eski listener'ı kaldır
    _socketService?.socket.off('textMessage');
    _socketService?.onTextMessage((data) {
      final msg = TextMessage.fromJson(data);
      addTextMessage(msg);
    });
  }

  void listenAudioMessages() {
    // Önce eski listener'ı kaldır
    _socketService?.socket.off('audio');
    _socketService?.onAudio((data) {
      final msg = AudioMessage(
        id: const Uuid().v4(),
        roomId: data['room'] ?? '',
        senderId: data['sender'] ?? 'unknown',
        senderName: data['sender'] ?? 'unknown',
        audioPath: data['audioBlob'],
        duration: const Duration(seconds: 3),
        sentAt: DateTime.now(),
      );
      if (_currentRoom != null && _currentRoom!.id == data['room']) {
        _messages.add(msg);
        notifyListeners();
      }
    });
  }

  void kickParticipant(String userId) {
    if (_currentRoom == null || _currentUser == null) return;
    _socketService?.kickParticipant(_currentRoom!.id, userId, _currentUser!.id);
  }

  void listenKickedEvent(BuildContext context) {
    _socketService?.socket.on('kicked', (data) {
      if (data is Map && data['roomId'] == _currentRoom?.id) {
        leaveRoom();
        // Uyarı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oda yöneticisi tarafından atıldınız.')),
        );
      }
    });
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
