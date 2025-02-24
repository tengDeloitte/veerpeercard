import 'package:flutter_riverpod/flutter_riverpod.dart';
// 聊天界面状态管理提供器
final providerMessageState = StateNotifierProvider<NotifierMessageState, Map<String, String>>(
      (ref) => NotifierMessageState(),
);

// 聊天界面状态管理器
class NotifierMessageState extends StateNotifier<Map<String, String>> {
  NotifierMessageState()
      : super({
    "showChatScreen": "false",
    "selectedUser": "",
  });

  // 保存聊天状态
  void saveState(String selectedUser, bool showChatScreen) {
    state = {
      "selectedUser": selectedUser,
      "showChatScreen": showChatScreen.toString(),
    };
  }
}