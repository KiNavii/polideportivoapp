import 'package:deportivov1/core/service_locator.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:deportivov1/core/connection_pool.dart';
import 'package:deportivov1/services/cache_service.dart';

/// Configuración centralizada de la aplicación optimizada
class AppConfig {
  static bool _isInitialized = false;
  
  /// Configuración de caché
  static const Duration defaultCacheTTL = Duration(minutes: 5);
  static const Duration shortCacheTTL = Duration(minutes: 1);
  static const Duration longCacheTTL = Duration(hours: 1);
  static const int maxCacheSize = 1000;
  
  /// Configuración de pool de conexiones
  static const int maxConnections = 10;
  static const int minConnections = 2;
  static const Duration connectionTimeout = Duration(seconds: 30);
  
  /// Configuración de logging
  static const LogLevel defaultLogLevel = LogLevel.info;
  static const LogLevel productionLogLevel = LogLevel.warning;
  static const int maxLogEntries = 1000;
  
  /// Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  /// Configuración de timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  /// Inicializa toda la configuración de la aplicación
  static Future<void> initialize({
    bool isProduction = false,
    LogLevel? customLogLevel,
  }) async {
    if (_isInitialized) {
      LoggerService().warning('AppConfig ya está inicializado');
      return;
    }

    try {
      LoggerService().info('🚀 Inicializando configuración de la aplicación...');
      
      // 1. Configurar logging
      await _initializeLogging(isProduction, customLogLevel);
      
      // 2. Inicializar Service Locator
      await _initializeServiceLocator();
      
      // 3. Configurar caché
      await _initializeCache();
      
      // 4. Configurar pool de conexiones
      await _initializeConnectionPool();
      
      // 5. Configuraciones adicionales
      await _initializeAdditionalConfigs();
      
      _isInitialized = true;
      
      LoggerService().info('✅ Configuración de la aplicación completada');
      _logSystemStats();
      
    } catch (e) {
      LoggerService().critical('❌ Error al inicializar configuración', e);
      rethrow;
    }
  }

  /// Configura el sistema de logging
  static Future<void> _initializeLogging(bool isProduction, LogLevel? customLogLevel) async {
    final logLevel = customLogLevel ?? 
        (isProduction ? productionLogLevel : defaultLogLevel);
    
    LoggerService.setLevel(logLevel);
    LoggerService().info('📝 Sistema de logging configurado - Nivel: ${logLevel.name}');
  }

  /// Inicializa el Service Locator
  static Future<void> _initializeServiceLocator() async {
    await ServiceLocator.initialize();
    LoggerService().info('🔧 Service Locator inicializado');
  }

  /// Configura el sistema de caché
  static Future<void> _initializeCache() async {
    // El CacheService es estático, no necesita inicialización especial
    LoggerService().info('💾 Sistema de caché configurado');
  }

  /// Configura el pool de conexiones
  static Future<void> _initializeConnectionPool() async {
    final pool = ConnectionPool(
      maxConnections: maxConnections,
      minConnections: minConnections,
      connectionTimeout: connectionTimeout,
    );
    
    // Nota: En una implementación real, pasaríamos URL y key reales
    await pool.initialize('', '');
    
    LoggerService().info('🔗 Pool de conexiones configurado');
  }

  /// Configuraciones adicionales
  static Future<void> _initializeAdditionalConfigs() async {
    // Configuraciones específicas de la aplicación
    LoggerService().info('⚙️ Configuraciones adicionales aplicadas');
  }

  /// Registra estadísticas del sistema
  static void _logSystemStats() {
    final logger = LoggerService();
    
    logger.info('📊 === ESTADÍSTICAS DEL SISTEMA ===');
    
    // Estadísticas del Service Locator
    final locatorStats = ServiceLocator.getStats();
    logger.info('🔧 Service Locator: ${locatorStats.toString()}');
    
    // Estadísticas del caché
    final cacheStats = CacheService.getStats();
    logger.info('💾 Caché: ${cacheStats.toString()}');
    
    // Estadísticas del pool de conexiones
    try {
      final poolStats = ConnectionPool().getStats();
      logger.info('🔗 Pool: ${poolStats.toString()}');
    } catch (e) {
      logger.debug('Pool de conexiones no disponible aún');
    }
    
    logger.info('📊 ================================');
  }

  /// Obtiene la configuración actual del sistema
  static SystemConfiguration getCurrentConfig() {
    return SystemConfiguration(
      isInitialized: _isInitialized,
      cacheConfig: CacheConfiguration(
        defaultTTL: defaultCacheTTL,
        shortTTL: shortCacheTTL,
        longTTL: longCacheTTL,
        maxSize: maxCacheSize,
      ),
      connectionConfig: ConnectionConfiguration(
        maxConnections: maxConnections,
        minConnections: minConnections,
        timeout: connectionTimeout,
      ),
      loggingConfig: LoggingConfiguration(
        currentLevel: defaultLogLevel,
        maxEntries: maxLogEntries,
      ),
      paginationConfig: PaginationConfiguration(
        defaultPageSize: defaultPageSize,
        maxPageSize: maxPageSize,
      ),
    );
  }

  /// Reinicia toda la configuración (útil para testing)
  static Future<void> reset() async {
    LoggerService().info('🔄 Reiniciando configuración del sistema...');
    
    try {
      // Resetear Service Locator
      await ServiceLocator.reset();
      
      // Limpiar caché
      CacheService.clear();
      
      // Cerrar pool de conexiones
      try {
        await ConnectionPool().close();
      } catch (e) {
        LoggerService().debug('Error al cerrar pool: $e');
      }
      
      _isInitialized = false;
      
      LoggerService().info('✅ Sistema reiniciado correctamente');
    } catch (e) {
      LoggerService().error('❌ Error al reiniciar sistema', e);
      rethrow;
    }
  }

  /// Verifica el estado de salud del sistema
  static SystemHealthCheck performHealthCheck() {
    final issues = <String>[];
    final warnings = <String>[];

    // Verificar inicialización
    if (!_isInitialized) {
      issues.add('Sistema no inicializado');
    }

    // Verificar Service Locator
    if (!ServiceLocator.isInitialized) {
      issues.add('Service Locator no inicializado');
    }

    // Verificar estadísticas del caché
    final cacheStats = CacheService.getStats();
    if (cacheStats.hitRatio < 0.5) {
      warnings.add('Ratio de aciertos del caché bajo: ${(cacheStats.hitRatio * 100).toStringAsFixed(1)}%');
    }

    // Verificar pool de conexiones
    try {
      final poolStats = ConnectionPool().getStats();
      if (poolStats.utilizationRate > 0.8) {
        warnings.add('Alta utilización del pool: ${(poolStats.utilizationRate * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      warnings.add('Pool de conexiones no disponible');
    }

    final isHealthy = issues.isEmpty;
    final status = isHealthy 
        ? (warnings.isEmpty ? HealthStatus.excellent : HealthStatus.good)
        : HealthStatus.critical;

    return SystemHealthCheck(
      status: status,
      isHealthy: isHealthy,
      issues: issues,
      warnings: warnings,
      timestamp: DateTime.now(),
    );
  }

  /// Exporta configuración para debugging
  static Map<String, dynamic> exportConfigForDebugging() {
    return {
      'isInitialized': _isInitialized,
      'cache': {
        'defaultTTL': defaultCacheTTL.inMinutes,
        'maxSize': maxCacheSize,
        'stats': CacheService.getStats().toString(),
      },
      'connections': {
        'maxConnections': maxConnections,
        'minConnections': minConnections,
        'timeout': connectionTimeout.inSeconds,
      },
      'logging': {
        'level': defaultLogLevel.name,
        'maxEntries': maxLogEntries,
      },
      'pagination': {
        'defaultPageSize': defaultPageSize,
        'maxPageSize': maxPageSize,
      },
      'healthCheck': performHealthCheck().toJson(),
    };
  }

  /// Verifica si el sistema está inicializado
  static bool get isInitialized => _isInitialized;
}

/// Configuración del sistema
class SystemConfiguration {
  final bool isInitialized;
  final CacheConfiguration cacheConfig;
  final ConnectionConfiguration connectionConfig;
  final LoggingConfiguration loggingConfig;
  final PaginationConfiguration paginationConfig;

  SystemConfiguration({
    required this.isInitialized,
    required this.cacheConfig,
    required this.connectionConfig,
    required this.loggingConfig,
    required this.paginationConfig,
  });
}

/// Configuración del caché
class CacheConfiguration {
  final Duration defaultTTL;
  final Duration shortTTL;
  final Duration longTTL;
  final int maxSize;

  CacheConfiguration({
    required this.defaultTTL,
    required this.shortTTL,
    required this.longTTL,
    required this.maxSize,
  });
}

/// Configuración de conexiones
class ConnectionConfiguration {
  final int maxConnections;
  final int minConnections;
  final Duration timeout;

  ConnectionConfiguration({
    required this.maxConnections,
    required this.minConnections,
    required this.timeout,
  });
}

/// Configuración de logging
class LoggingConfiguration {
  final LogLevel currentLevel;
  final int maxEntries;

  LoggingConfiguration({
    required this.currentLevel,
    required this.maxEntries,
  });
}

/// Configuración de paginación
class PaginationConfiguration {
  final int defaultPageSize;
  final int maxPageSize;

  PaginationConfiguration({
    required this.defaultPageSize,
    required this.maxPageSize,
  });
}

/// Estado de salud del sistema
enum HealthStatus { excellent, good, warning, critical }

/// Verificación de salud del sistema
class SystemHealthCheck {
  final HealthStatus status;
  final bool isHealthy;
  final List<String> issues;
  final List<String> warnings;
  final DateTime timestamp;

  SystemHealthCheck({
    required this.status,
    required this.isHealthy,
    required this.issues,
    required this.warnings,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'isHealthy': isHealthy,
      'issues': issues,
      'warnings': warnings,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SystemHealthCheck(status: ${status.name}, healthy: $isHealthy, issues: ${issues.length}, warnings: ${warnings.length})';
  }
} 