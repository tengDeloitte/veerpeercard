// lib/utils/logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  // 单例模式
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  // 私有构造函数
  AppLogger._internal() {
    _updateLogger(Level.info); // 默认日志级别
  }

  // Logger 实例
  late Logger _logger;

  // 初始化或更新 logger 实例
  void _updateLogger(Level level) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        // 修改: 使用 dateTimeFormat 替代 printTime
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: level,
    );
  }

  // 便捷方法
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // 设置日志级别的方法
  void setLogLevel(Level level) {
    _updateLogger(level); // 创建新的 Logger 实例来更改日志级别
  }
}

// 导出一个全局实例，方便直接使用
final logger = AppLogger();