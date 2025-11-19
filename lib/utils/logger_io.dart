import 'dart:io';

enum LogLevel { trace, debug, info, warn, error }

class Log {
  static LogLevel _level = LogLevel.info;
  static IOSink? _sink;
  static String? _filePath;

  static void init({LogLevel level = LogLevel.info, bool enableFile = false, String? filePath}) {
    _level = level;
    if (enableFile) {
      final base = filePath ?? '${Directory.systemTemp.path}/classaware.log';
      _filePath = base;
      _rotateIfNeeded(base);
      _sink = File(base).openWrite(mode: FileMode.append);
    }
  }

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
    stdout.writeln(line);
    if (error != null) {
      stdout.writeln('  error: $error');
    }
    if (stack != null) {
      stdout.writeln('  stack: $stack');
    }
    final s = _sink;
    if (s != null) {
      s.writeln(line);
      if (error != null) s.writeln('  error: $error');
      if (stack != null) s.writeln('  stack: $stack');
    }
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

  static void _rotateIfNeeded(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        final size = f.lengthSync();
        if (size > 2 * 1024 * 1024) {
          final bak = File('$path.1');
          if (bak.existsSync()) bak.deleteSync();
          f.renameSync('$path.1');
        }
      }
    } catch (_) {}
  }

  static Future<void> close() async { await _sink?.flush(); await _sink?.close(); _sink = null; }
}