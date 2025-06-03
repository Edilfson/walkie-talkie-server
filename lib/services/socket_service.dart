import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  String serverUrl;

  SocketService(this.serverUrl);

  void connect(String room) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) {
      socket.emit('join', room);
    });
  }

  void sendAudio(String room, dynamic audioBlob, String sender) {
    socket.emit(
        'audio', {'room': room, 'audioBlob': audioBlob, 'sender': sender});
  }

  void onAudio(void Function(dynamic data) callback) {
    socket.on('audio', callback);
  }

  void disconnect() {
    socket.disconnect();
  }
}
