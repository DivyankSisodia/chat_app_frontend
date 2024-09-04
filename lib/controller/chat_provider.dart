import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_app/model/chat_model.dart';

import '../services/chat_history_services.dart';

class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  ChatNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchChatHistory();
  }

  final ApiService _apiService;
  String? senderId;
  String? receiverId;

  Future<void> fetchChatHistory() async {
    if (senderId == null || receiverId == null) return;

    state = const AsyncValue.loading();
    try {
      final messages = await _apiService.fetchChatHistory(senderId!, receiverId!);
      state = AsyncValue.data(messages);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void addMessage(Message message) {
    state.whenData((messages) {
      state = AsyncValue.data([...messages, message]);
    });
  }

  void updateMessageStatus(Message updatedMessage) {
    state.whenData((messages) {
      state = AsyncValue.data(messages.map((message) =>
      message.id == updatedMessage.id ? updatedMessage : message
      ).toList());
    });
  }

  void setUserIds(String sender, String receiver) {
    senderId = sender;
    receiverId = receiver;
    fetchChatHistory();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<Message>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService);
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());