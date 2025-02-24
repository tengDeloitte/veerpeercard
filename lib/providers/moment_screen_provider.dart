import 'package:flutter_riverpod/flutter_riverpod.dart';

// moments screen
// 定义好友数据
class NotifierMomentsState extends StateNotifier<Map<String, dynamic>> {
  NotifierMomentsState()
      : super({
    'friends': [
      {'name': 'Cassie Condon', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Lindsss 🦋', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Robin Resnik', 'image': 'https://via.placeholder.com/150'},
      {'name': 'Wreckomended Custom', 'image': 'https://via.placeholder.com/150'},
    ],
    'discover': [
      {'title': 'Kaitlyn Krems', 'image': 'https://via.placeholder.com/150'},
      {'title': 'She Caught Us!', 'image': 'https://via.placeholder.com/150'},
      {'title': 'Nina Riddle', 'image': 'https://via.placeholder.com/150'},
      {'title': 'NFL Audible', 'image': 'https://via.placeholder.com/150'},
    ],
  });

  // 添加好友
  void addFriend(Map<String, String> friend) {
    state = {
      ...state,
      'friends': [...state['friends'], friend],
    };
  }

  // 添加发现内容
  void addDiscoverItem(Map<String, String> item) {
    state = {
      ...state,
      'discover': [...state['discover'], item],
    };
  }
}

// 创建全局 Provider
final providerMoments = StateNotifierProvider<NotifierMomentsState, Map<String, dynamic>>((ref) {
  return NotifierMomentsState();
});