import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veerpeercard/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 发送消息
  Future<void> sendMessage(String receiverId, String content) async {
    final senderId = _auth.currentUser!.uid;
    final messageId = _firestore.collection('messages').doc().id;
    final timestamp = Timestamp.now(); // 改用 Timestamp

    // 创建消息文档
    final message = ChatMessage(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp.toDate(),
      isRead: false,
    );

    // 保存到发送方聊天记录
    await _firestore
        .collection('messages')
        .doc(messageId)
        .set(message.toMap()); // 使用 toMap 方法

    // 更新最近聊天
    await _updateRecentChat(senderId, receiverId, content, timestamp);
  }

  // 更新最近聊天
  Future<void> _updateRecentChat(
      String senderId,
      String receiverId,
      String lastMessage,
      Timestamp timestamp,
      ) async {
    // 更新发送方的最近聊天
    await _firestore
        .collection('users')
        .doc(senderId)
        .collection('recentChats')
        .doc(receiverId)
        .set({
      'userId': receiverId,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': 0,
    }, SetOptions(merge: true));

    // 更新接收方的最近聊天和未读计数
    DocumentSnapshot recentChat = await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('recentChats')
        .doc(senderId)
        .get();

    int unreadCount = 0;
    if (recentChat.exists) {
      final data = recentChat.data() as Map<String, dynamic>;
      unreadCount = (data['unreadCount'] ?? 0) + 1;
    } else {
      unreadCount = 1;
    }

    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('recentChats')
        .doc(senderId)
        .set({
      'userId': senderId,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
    }, SetOptions(merge: true));
  }

  // 标记消息为已读
  Future<void> markMessageAsRead(String messageId) async {
    await _firestore
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // 获取聊天消息流
  Stream<List<ChatMessage>> getMessages(String otherUserId) {
    final userId = _auth.currentUser!.uid;

    return _firestore
        .collection('messages')
        .where('participants', arrayContains: userId) // 使用数组包含查询
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data())) // 使用 fromMap 方法
          .where((message) =>
      (message.senderId == userId && message.receiverId == otherUserId) ||
          (message.senderId == otherUserId && message.receiverId == userId))
          .toList();
    });
  }

  // 获取最近聊天列表
  Stream<List<Map<String, dynamic>>> getRecentChats() {
    final userId = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recentChats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      List<Map<String, dynamic>> chats = [];

      for (var doc in chatSnapshot.docs) {
        final chatData = doc.data();
        final otherUserId = chatData['userId'];

        try {
          // 获取用户资料
          final userDoc = await _firestore
              .collection('users')
              .doc(otherUserId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            chats.add({
              ...chatData,
              'name': userData['name'] ?? 'Unknown',
              'photoUrl': userData['photoUrl'] ?? 'https://via.placeholder.com/50',
              'isOnline': userData['isOnline'] ?? false,
              'lastSeen': userData['lastSeen'] ?? Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      return chats;
    });
  }
}