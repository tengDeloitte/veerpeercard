import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// bottom tabs provider
final providerCurrentTabIndex =
    StateNotifierProvider<NotifierCurrentTabIndex, int>(
      (ref) => NotifierCurrentTabIndex(),
    );

// 这个是封装所有业务逻辑
class NotifierCurrentTabIndex extends StateNotifier<int> {
  NotifierCurrentTabIndex() : super(2);

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('lastSelectedTab') ?? 2; // 加载持久化数据
  }

  Future<void> setTabIndex(int index) async {
    state = index; // 更新状态
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastSelectedTab', index); // 保存到持久化存储
  }
}
