import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/models/chat_message.dart';

// 管理员 Provider -> 告诉 编辑员 Notifier 来编辑
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  // 初始化状态是空 []
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void markAsRead(String messageId) {
    state = [
      for (final message in state)
        if (message.id == messageId)
          ChatMessage(
            id: message.id,
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            timestamp: message.timestamp,
            isRead: true,
          )
        else
          message,
    ];
  }
}