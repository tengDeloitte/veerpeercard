import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veerpeercard/models/chat_message.dart';
import 'package:veerpeercard/providers/auth_provider.dart';
import 'package:veerpeercard/providers/chat_service_provider.dart';
import 'package:veerpeercard/providers/message_screen_provider.dart';
import 'package:veerpeercard/widgets/chat/message_bubble.dart';
import 'package:veerpeercard/widgets/chat/chat_input_field.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }
        return _buildMainScreen(context, ref, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading auth state')),
    );
  }

  Widget _buildMainScreen(BuildContext context, WidgetRef ref, User user) {
    final chatState = ref.watch(providerMessageState);
    final chatNotifier = ref.read(providerMessageState.notifier);
    final chatService = ref.watch(chatServiceProvider);

    final bool showChatScreen = chatState["showChatScreen"] == "true";
    final String selectedUser = chatState["selectedUser"] ?? "";

    return Scaffold(
      appBar: AppBar(
        // title: Text(showChatScreen ? selectedUser : 'Direct Messages'),
        leading: showChatScreen
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            chatNotifier.saveState("", false);
          },
        )
            : null,
        actions: [
          if (showChatScreen)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // 显示聊天信息
              },
            ),
        ],
      ),
      body: showChatScreen
          ? _buildChatScreen(context, ref, selectedUser, user.uid)
          : _buildContactsList(context, ref, chatNotifier, user.uid),
    );
  }

  Widget _buildContactsList(
      BuildContext context,
      WidgetRef ref,
      NotifierMessageState chatNotifier,
      String currentUserId,
      ) {
    final chatService = ref.watch(chatServiceProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getRecentChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!;

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final bool isOnline = chat['isOnline'] ?? false;
            final int unreadCount = chat['unreadCount'] ?? 0;

            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(chat["photoUrl"] ?? 'https://via.placeholder.com/50'),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(chat["name"] ?? 'Unknown'),
              subtitle: Text(
                chat["lastMessage"] ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.black : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(
                      (chat["timestamp"] as Timestamp).toDate(),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0 ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () {
                chatNotifier.saveState(chat["name"], true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatScreen(BuildContext context, WidgetRef ref, String selectedUser, String currentUserId) {
    final chatService = ref.watch(chatServiceProvider);

    return StreamBuilder<List<ChatMessage>>(
      stream: chatService.getMessages(selectedUser),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;

        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyChatView()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isSentByMe = message.senderId == currentUserId;

                  if (!message.isRead && !isSentByMe) {
                    chatService.markMessageAsRead(message.id);
                  }

                  return MessageBubble(
                    message: message,
                    isSentByMe: isSentByMe,
                  );
                },
              ),
            ),
            ChatInputField(
              onSendMessage: (String content) {
                chatService.sendMessage(selectedUser, content);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start chatting',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (time.day == now.day - 1) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[time.weekday - 1];
    } else {
      return '${time.month}/${time.day}';
    }
  }
}