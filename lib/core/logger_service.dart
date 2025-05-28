import 'dart:developer' as developer;
import 'dart:io';

/// Niveles de logging
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  const LogLevel(this.value, this.name);
  final int value;
  final String name;
}

/// Servicio de logging avanzado para monitoreo y debugging
class LoggerService {
  static LoggerService? _instance;
  static LogLevel _currentLevel = LogLevel.info;
  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;

  LoggerService._();

  factory LoggerService() {
    _instance ??= LoggerService._();
    return _instance!;
  }

  /// Configura el nivel mínimo de logging
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Log de debug (solo en modo desarrollo)
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log de información general
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log de advertencias
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log de errores
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log de errores críticos
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  /// Método interno para logging
  void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (level.value < _currentLevel.value) return;

    final timestamp = DateTime.now();
    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: timestamp,
      error: error,
      stackTrace: stackTrace,
    );

    // Añadir a la lista de logs
    _logs.add(logEntry);
    
    // Mantener solo los últimos logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Output a consola
    _outputToConsole(logEntry);

    // En modo debug, también usar developer.log
    if (level.value >= LogLevel.error.value) {
      developer.log(
        message,
        name: 'DeportivoApp',
        error: error,
        stackTrace: stackTrace,
        level: level.value * 300, // Convertir a nivel de dart:developer
      );
    }
  }

  /// Output formateado a consola
  void _outputToConsole(LogEntry entry) {
    final timestamp = _formatTimestamp(entry.timestamp);
    final levelStr = entry.level.name.padRight(8);
    
    String output = '[$timestamp] $levelStr: ${entry.message}';
    
    if (entry.error != null) {
      output += '\n  Error: ${entry.error}';
    }
    
    if (entry.stackTrace != null && entry.level.value >= LogLevel.error.value) {
      output += '\n  StackTrace: ${entry.stackTrace}';
    }

    // Usar colores en consola si es posible
    if (Platform.isAndroid || Platform.isIOS) {
      print(output);
    } else {
      print(_colorizeOutput(output, entry.level));
    }
  }

  /// Añade colores al output (para terminales que lo soporten)
  String _colorizeOutput(String output, LogLevel level) {
    const reset = '\x1B[0m';
    
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m$output$reset'; // Blanco
      case LogLevel.info:
        return '\x1B[36m$output$reset'; // Cian
      case LogLevel.warning:
        return '\x1B[33m$output$reset'; // Amarillo
      case LogLevel.error:
        return '\x1B[31m$output$reset'; // Rojo
      case LogLevel.critical:
        return '\x1B[35m$output$reset'; // Magenta
    }
  }

  /// Formatea timestamp
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Obtiene todos los logs
  List<LogEntry> getLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.from(_logs);
    
    return _logs.where((log) => log.level.value >= minLevel.value).toList();
  }

  /// Obtiene logs por nivel específico
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Obtiene estadísticas de logs
  LogStats getStats() {
    final stats = <LogLevel, int>{};
    
    for (final level in LogLevel.values) {
      stats[level] = _logs.where((log) => log.level == level).length;
    }

    return LogStats(
      totalLogs: _logs.length,
      logsByLevel: stats,
      oldestLog: _logs.isNotEmpty ? _logs.first.timestamp : null,
      newestLog: _logs.isNotEmpty ? _logs.last.timestamp : null,
    );
  }

  /// Limpia todos los logs
  void clearLogs() {
    _logs.clear();
    info('Logs limpiados');
  }

  /// Exporta logs como string
  String exportLogs({LogLevel? minLevel}) {
    final logsToExport = getLogs(minLevel: minLevel);
    final buffer = StringBuffer();
    
    buffer.writeln('=== DEPORTIVO APP LOGS ===');
    buffer.writeln('Exportado: ${DateTime.now()}');
    buffer.writeln('Total logs: ${logsToExport.length}');
    buffer.writeln('');

    for (final log in logsToExport) {
      buffer.writeln('${_formatTimestamp(log.timestamp)} [${log.level.name}] ${log.message}');
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  StackTrace: ${log.stackTrace}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Log específico para rendimiento
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    final metadataStr = metadata != null ? ' | Metadata: $metadata' : '';
    info('$message$metadataStr');
  }

  /// Log específico para caché
  void cache(String operation, bool hit, {String? key}) {
    final status = hit ? 'HIT' : 'MISS';
    final keyStr = key != null ? ' | Key: $key' : '';
    debug('Cache $status: $operation$keyStr');
  }

  /// Log específico para API calls
  void apiCall(String method, String endpoint, int statusCode, Duration duration) {
    final message = 'API $method $endpoint -> $statusCode (${duration.inMilliseconds}ms)';
    if (statusCode >= 200 && statusCode < 300) {
      info(message);
    } else if (statusCode >= 400) {
      warning(message);
    } else {
      debug(message);
    }
  }

  /// Log específico para errores de usuario
  void userError(String action, String error, {String? userId}) {
    final userStr = userId != null ? ' | User: $userId' : '';
    warning('User Error: $action failed - $error$userStr');
  }
}

/// Entrada individual de log
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${level.name}] $message';
  }
}

/// Estadísticas de logs
class LogStats {
  final int totalLogs;
  final Map<LogLevel, int> logsByLevel;
  final DateTime? oldestLog;
  final DateTime? newestLog;

  LogStats({
    required this.totalLogs,
    required this.logsByLevel,
    this.oldestLog,
    this.newestLog,
  });

  Duration? get timeSpan {
    if (oldestLog == null || newestLog == null) return null;
    return newestLog!.difference(oldestLog!);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('LogStats:');
    buffer.writeln('  Total: $totalLogs');
    
    for (final entry in logsByLevel.entries) {
      buffer.writeln('  ${entry.key.name}: ${entry.value}');
    }
    
    if (timeSpan != null) {
      buffer.writeln('  Timespan: ${timeSpan!.inMinutes} minutes');
    }
    
    return buffer.toString();
  }
} 