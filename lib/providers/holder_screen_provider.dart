// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // holder expanding state provider
// final providerHolderState = StateNotifierProvider<NotifierHolderState, int?>((ref) {
//   return NotifierHolderState();
// });
//
// class NotifierHolderState extends StateNotifier<int?> {
//   NotifierHolderState() : super(null) {
//     _loadState(); // 初始化时加载状态
//   }
//
//   bool showBack = false; // 是否显示卡片背面
//
//   Future<void> _loadState() async {
//     final prefs = await SharedPreferences.getInstance();
//     state = prefs.getInt('expandedCardIndex');
//     showBack = prefs.getBool('showBack') ?? false;
//   }
//
//   Future<void> saveState(int? index, bool back) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('expandedCardIndex', index ?? -1);
//     await prefs.setBool('showBack', back);
//     state = index;
//     showBack = back;
//   }
//
//   Future<void> resetState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('expandedCardIndex');
//     await prefs.remove('showBack');
//     state = null;
//     showBack = false;
//   }
// }

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// holder expanding state provider
final providerHolderState = StateNotifierProvider<NotifierHolderState, int?>((ref) {
  return NotifierHolderState();
});

class NotifierHolderState extends StateNotifier<int?> {
  NotifierHolderState() : super(null) {
    _loadState(); // 初始化时加载状态
  }

  bool showBack = false; // 是否显示卡片背面

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('expandedCardIndex');
    showBack = prefs.getBool('showBack') ?? false;
  }

  Future<void> saveState(int? index, bool back) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('expandedCardIndex', index ?? -1);
    await prefs.setBool('showBack', back);
    state = index;
    showBack = back;
  }

  // 新增：只翻转卡片而不改变选中状态
  Future<void> toggleCardFace() async {
    final prefs = await SharedPreferences.getInstance();
    showBack = !showBack;
    await prefs.setBool('showBack', showBack);
    // 通知监听器状态变化
    state = state;
  }

  Future<void> resetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('expandedCardIndex');
    await prefs.remove('showBack');
    state = null;
    showBack = false;
  }
}