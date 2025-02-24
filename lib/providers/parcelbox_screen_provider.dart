import 'package:flutter_riverpod/flutter_riverpod.dart';

// parcelbox screen
// 定义 StateNotifier 管理附近消息和申请状态
class NotifierParcelboxState extends StateNotifier<Map<String, bool>> {
  NotifierParcelboxState()
      : super({
    'hasNearbyCard': true, // 初始值为没有附近卡片
    'hasPendingApplication': false, // 初始值为没有申请
  });

  // 更新附近消息状态
  void setHasNearbyCard(bool value) {
    state = {...state, 'hasNearbyCard': value};
  }

  // 更新申请状态
  void setHasPendingApplication(bool value) {
    state = {...state, 'hasPendingApplication': value};
  }
}

// 定义全局 Provider
final providerParcelboxState =
StateNotifierProvider<NotifierParcelboxState, Map<String, bool>>((ref) {
  return NotifierParcelboxState();
});
