import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// theme provider
final providerTheme = StateNotifierProvider<NotifierTheme, ThemeMode>(
  (ref) => NotifierTheme(),
);

// 这个是封装所有主题相关的业务逻辑
class NotifierTheme extends StateNotifier<ThemeMode> {
  NotifierTheme() : super(ThemeMode.system);

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 如果能从 SharedPreferences 中读取到 'themeMode' 的值，就使用该值
    // 如果读不到（比如首次安装 app，还没有保存过主题设置），就使用 0 作为默认值
    // 因为 ThemeMode.values[0] 对应的是 ThemeMode.system，所以这样设计可以确保首次安装时使用系统主题。
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeIndex];
  }
  // 使用不到
  // Future<void> setThemeMode(ThemeMode mode) async {
  //   state = mode;
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setInt('themeMode', mode.index);
  // }

  Future<void> toggleTheme() async {
    // 如果当前是系统主题，直接切换到light
    if (state == ThemeMode.system) {
      state = ThemeMode.light;
    } 
    // 在light和dark之间切换
    else {
      state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', state.index);
  }
}