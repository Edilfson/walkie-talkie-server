import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  String serverUrl;

  SocketService(this.serverUrl);

  void connect([String? room]) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    if (room != null && room.isNotEmpty) {
      socket.onConnect((_) {
        socket.emit('join', room);
      });
    }
  }

  void sendAudio(String room, dynamic audioBlob, String sender) {
    // Web'de base64 string gönderiliyor, mobilde path
    socket.emit(
        'audio', {'room': room, 'audioBlob': audioBlob, 'sender': sender});
  }

  void onAudio(void Function(dynamic data) callback) {
    socket.on('audio', callback);
  }

  void disconnect() {
    socket.disconnect();
  }

  void joinRoom(String roomId, Map<String, dynamic> user,
      {String? password, String? inviteCode}) {
    final joinData = {'roomId': roomId, 'user': user};
    if (password != null) joinData['password'] = password;
    if (inviteCode != null) joinData['inviteCode'] = inviteCode;
    socket.emit('join', joinData);
  }

  void leaveRoom(String roomId, String userId) {
    socket.emit('leave', {'roomId': roomId, 'userId': userId});
  }

  void createRoom(Map<String, dynamic> room) {
    socket.emit('createRoom', room);
  }

  void onRooms(void Function(dynamic data) callback) {
    socket.on('rooms', callback);
  }

  void onParticipants(void Function(dynamic data) callback) {
    socket.on('participants', callback);
  }

  void sendTextMessage(dynamic msg) {
    socket.emit('textMessage', msg.toJson());
  }

  void onTextMessage(void Function(dynamic data) callback) {
    socket.on('textMessage', callback);
  }

  void kickParticipant(String roomId, String targetUserId, String byUserId) {
    socket.emit('kickParticipant', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'byUserId': byUserId,
    });
  }
}
