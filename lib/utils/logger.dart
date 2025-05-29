import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class Logger {
  static const String _appName = 'PolideportivoApp';

  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.error, message, tag, error, stackTrace);
  }

  static void critical(
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.critical, message, tag, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode && level == LogLevel.debug) {
      return; // Don't log debug messages in release mode
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag]' : '';
    final prefix = '[$_appName] $timestamp $levelStr $tagStr';

    // Print main message
    print('$prefix $message');

    // Print error details if provided
    if (error != null) {
      print('$prefix Error Details: $error');
    }

    // Print stack trace for errors and critical issues
    if (stackTrace != null &&
        (level == LogLevel.error || level == LogLevel.critical)) {
      print('$prefix Stack Trace:');
      print(stackTrace.toString());
    }
  }

  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.critical:
        return '[CRITICAL]';
    }
  }

  // Convenience methods for common scenarios
  static void apiCall(String endpoint, [Map<String, dynamic>? params]) {
    info(
      'API Call: $endpoint${params != null ? ' with params: $params' : ''}',
      'API',
    );
  }

  static void apiResponse(String endpoint, int statusCode, [dynamic response]) {
    if (statusCode >= 200 && statusCode < 300) {
      info('API Success: $endpoint (${statusCode})', 'API');
    } else {
      error('API Error: $endpoint (${statusCode})', 'API', response);
    }
  }

  static void userAction(String action, [Map<String, dynamic>? context]) {
    info('User Action: $action${context != null ? ' - $context' : ''}', 'USER');
  }

  static void navigation(String from, String to) {
    info('Navigation: $from -> $to', 'NAV');
  }

  static void performance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms > 1000) {
      warning('Slow Operation: $operation took ${ms}ms', 'PERF');
    } else {
      debug('Performance: $operation took ${ms}ms', 'PERF');
    }
  }
}
