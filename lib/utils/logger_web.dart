enum LogLevel { trace, debug, info, warn, error }

class Log {
  static LogLevel _level = LogLevel.info;
  static void init({LogLevel level = LogLevel.info, bool enableFile = false, String? filePath}) { _level = level; }
  static void setLevel(LogLevel level) { _level = level; }
  static void t(String msg, {String? tag}) => _log(LogLevel.trace, msg, tag: tag);
  static void d(String msg, {String? tag}) => _log(LogLevel.debug, msg, tag: tag);
  static void i(String msg, {String? tag}) => _log(LogLevel.info, msg, tag: tag);
  static void w(String msg, {String? tag, Object? error, StackTrace? stack}) => _log(LogLevel.warn, msg, tag: tag, error: error, stack: stack);
  static void e(String msg, {String? tag, Object? error, StackTrace? stack}) => _log(LogLevel.error, msg, tag: tag, error: error, stack: stack);

  static void _log(LogLevel level, String msg, {String? tag, Object? error, StackTrace? stack}) {
    if (level.index < _level.index) return;
    final ts = DateTime.now().toIso8601String();
    final name = _levelName(level);
    final t = tag != null ? '[$tag]' : '';
    final line = '$ts $name$t $msg';
    // 使用 print 以便浏览器控制台可捕获
    print(line);
    if (error != null) print('  error: $error');
    if (stack != null) print('  stack: $stack');
  }

  static String _levelName(LogLevel l) {
    switch (l) {
      case LogLevel.trace: return '[TRACE]';
      case LogLevel.debug: return '[DEBUG]';
      case LogLevel.info:  return '[INFO]';
      case LogLevel.warn:  return '[WARN]';
      case LogLevel.error: return '[ERROR]';
    }
  }

  static Future<void> close() async {}
}