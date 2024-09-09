// socket_services.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    _initializeSocket();
  }

  //

  void _initializeSocket() {
    socket = IO.io('http://192.168.1.10:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event) {
    socket.off(event);
  }

  void sendMessage(Map<String, dynamic> message) {
    socket.emit('send_message', message);
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void emitTyping(String senderId, String receiverId) {
    socket.emit('typing', {
      'sender_id': senderId,
      'receiver_id': receiverId,
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
