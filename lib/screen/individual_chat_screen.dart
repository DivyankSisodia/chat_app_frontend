import 'dart:async';
import 'dart:convert';
import 'package:chat_app/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/socket_services.dart';

// Provider for managing messages
final messagesProvider = StateNotifierProvider<MessagesNotifier, List<Message>>((ref) {
  return MessagesNotifier();
});

final typingProvider = StateProvider<String?>((ref) => null);

class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super([]);

  void addMessage(Message message) {
    state = [...state, message];
  }

  void setMessages(List<Message> messages) {
    state = messages;
  }

  void deleteMessage(Message message) {
    state = state.where((msg) => msg.id != message.id).toList();
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String username;
  final bool onlineStatus;
  final String senderId;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.username,
    required this.onlineStatus,
    required this.senderId,
    required this.receiverId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late SocketService socketService;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    socketService = SocketService();
    _initializeSocketListeners();
    _fetchChatHistory();
  }

  void _initializeSocketListeners() {
    socketService.on('receive_message', (data) {
      final newMessage = Message.fromJson(data);
      ref.read(messagesProvider.notifier).addMessage(newMessage);
    });

    socketService.on('typing', (data) {
      final senderId = data['sender_id'];
      if (senderId != widget.senderId) {
        ref.read(typingProvider.notifier).state = widget.username;
        _resetTypingIndicator();
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text;
    if (content.isNotEmpty) {
      final newMessage = Message(
        sender_id: widget.senderId,
        receiver_id: widget.receiverId,
        message: content,
      );

      socketService.emit('send_message', {
        ...newMessage.toJson(),
        'targetId': widget.receiverId,
      });

      ref.read(messagesProvider.notifier).addMessage(newMessage);
      _messageController.clear();
      ref.read(typingProvider.notifier).state = null;
    }
  }

  void _onMessageChanged() {
    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    socketService.emitTyping(widget.senderId, widget.receiverId);

    _typingTimer = Timer(const Duration(seconds: 1), () {
      ref.read(typingProvider.notifier).state = null;
    });
  }

  void _resetTypingIndicator() {
    Timer(const Duration(seconds: 2), () {
      ref.read(typingProvider.notifier).state = null;
    });
  }

  Future<void> _fetchChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('https://chat-app-95gd.onrender.com/chat/history/${widget.senderId}/${widget.receiverId}'),
      );

      if (response.statusCode == 200) {
        final List<Message> messages = parseMessages(response.body);
        ref.read(messagesProvider.notifier).setMessages(messages);
      } else {
        print('Failed to load messages. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error fetching chat history: $error');
    }
  }

  List<Message> parseMessages(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Message>((json) => Message.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final typingUser = ref.watch(typingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.username}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isCurrentUser = message.sender_id == widget.senderId;

                return Align(
                  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isCurrentUser ? 'You' : widget.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (typingUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$typingUser is typing...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                    onChanged: (text) => _onMessageChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socketService.off('receive_message');
    socketService.off('typing');
    _messageController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}
