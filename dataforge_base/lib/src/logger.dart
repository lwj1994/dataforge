// @author luwenjie on 2026/01/23 16:00:00
// Logging utility for Dataforge

/// Log levels for categorizing messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Simple logging utility for Dataforge code generation
///
/// Provides structured logging with different severity levels
/// instead of using print() statements directly.
class DataforgeLogger {
  static bool debugEnabled = false;

  /// Logs a debug message (only shown when debugEnabled = true)
  static void debug(String message) {
    if (debugEnabled) {
      _log(LogLevel.debug, message);
    }
  }

  /// Logs an informational message
  static void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Logs a warning message
  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// Logs an error message
  static void error(String message, [Object? exception, StackTrace? stackTrace]) {
    _log(LogLevel.error, message);
    if (exception != null) {
      _log(LogLevel.error, 'Exception: $exception');
    }
    if (stackTrace != null) {
      _log(LogLevel.error, 'Stack trace:\n$stackTrace');
    }
  }

  static void _log(LogLevel level, String message) {
    final prefix = _getPrefix(level);
    print('$prefix$message');
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG] ';
      case LogLevel.info:
        return '';
      case LogLevel.warning:
        return '⚠️  ';
      case LogLevel.error:
        return '❌ ';
    }
  }
}
