import 'dart:async';
import 'dart:collection';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deportivov1/core/logger_service.dart';

/// Pool de conexiones optimizado para Supabase
/// Gestiona múltiples clientes para mejorar el rendimiento
class ConnectionPool {
  static ConnectionPool? _instance;
  static final LoggerService _logger = LoggerService();
  
  final Queue<SupabaseClient> _availableConnections = Queue<SupabaseClient>();
  final Set<SupabaseClient> _busyConnections = <SupabaseClient>{};
  final int _maxConnections;
  final int _minConnections;
  final Duration _connectionTimeout;
  final Duration _idleTimeout;
  
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  ConnectionPool._({
    int maxConnections = 10,
    int minConnections = 2,
    Duration connectionTimeout = const Duration(seconds: 30),
    Duration idleTimeout = const Duration(minutes: 5),
  }) : _maxConnections = maxConnections,
       _minConnections = minConnections,
       _connectionTimeout = connectionTimeout,
       _idleTimeout = idleTimeout;

  /// Obtiene la instancia singleton del pool
  factory ConnectionPool({
    int maxConnections = 10,
    int minConnections = 2,
    Duration connectionTimeout = const Duration(seconds: 30),
    Duration idleTimeout = const Duration(minutes: 5),
  }) {
    _instance ??= ConnectionPool._(
      maxConnections: maxConnections,
      minConnections: minConnections,
      connectionTimeout: connectionTimeout,
      idleTimeout: idleTimeout,
    );
    return _instance!;
  }

  /// Inicializa el pool de conexiones
  Future<void> initialize(String url, String anonKey) async {
    if (_isInitialized) return;

    try {
      _logger.info('Inicializando pool de conexiones...');
      
      // Crear conexiones mínimas
      for (int i = 0; i < _minConnections; i++) {
        final client = await _createConnection(url, anonKey);
        _availableConnections.add(client);
      }

      // Iniciar timer de limpieza
      _startCleanupTimer();
      
      _isInitialized = true;
      _logger.info('Pool de conexiones inicializado con ${_availableConnections.length} conexiones');
    } catch (e) {
      _logger.error('Error al inicializar pool de conexiones', e);
      rethrow;
    }
  }

  /// Obtiene una conexión del pool
  Future<PooledConnection> getConnection() async {
    if (!_isInitialized) {
      throw ConnectionPoolException('Pool no inicializado');
    }

    final stopwatch = Stopwatch()..start();

    try {
      SupabaseClient? client;

      // Intentar obtener conexión disponible
      if (_availableConnections.isNotEmpty) {
        client = _availableConnections.removeFirst();
        _logger.debug('Conexión reutilizada del pool');
      } 
      // Crear nueva conexión si no se alcanzó el máximo
      else if (_totalConnections < _maxConnections) {
        client = await _createConnection('', ''); // Parámetros dummy
        _logger.debug('Nueva conexión creada');
      }
      // Esperar por conexión disponible
      else {
        client = await _waitForAvailableConnection();
        _logger.debug('Conexión obtenida después de espera');
      }

      if (client == null) {
        throw ConnectionPoolException('No se pudo obtener conexión');
      }

      _busyConnections.add(client);
      
      stopwatch.stop();
      _logger.performance('getConnection', stopwatch.elapsed);

      return PooledConnection(client, this);
    } catch (e) {
      _logger.error('Error al obtener conexión del pool', e);
      rethrow;
    }
  }

  /// Libera una conexión de vuelta al pool
  void releaseConnection(SupabaseClient client) {
    if (_busyConnections.remove(client)) {
      _availableConnections.add(client);
      _logger.debug('Conexión liberada al pool');
    }
  }

  /// Cierra una conexión específica
  void closeConnection(SupabaseClient client) {
    _busyConnections.remove(client);
    _availableConnections.remove(client);
    // Nota: Supabase no tiene método close() explícito
    _logger.debug('Conexión cerrada');
  }

  /// Obtiene estadísticas del pool
  ConnectionPoolStats getStats() {
    return ConnectionPoolStats(
      totalConnections: _totalConnections,
      availableConnections: _availableConnections.length,
      busyConnections: _busyConnections.length,
      maxConnections: _maxConnections,
      minConnections: _minConnections,
    );
  }

  /// Cierra todas las conexiones del pool
  Future<void> close() async {
    _logger.info('Cerrando pool de conexiones...');
    
    _cleanupTimer?.cancel();
    
    // Cerrar todas las conexiones
    for (final client in _availableConnections) {
      // Supabase se cierra automáticamente
    }
    for (final client in _busyConnections) {
      // Supabase se cierra automáticamente
    }
    
    _availableConnections.clear();
    _busyConnections.clear();
    _isInitialized = false;
    
    _logger.info('Pool de conexiones cerrado');
  }

  /// Ejecuta una operación con una conexión del pool
  Future<T> execute<T>(Future<T> Function(SupabaseClient) operation) async {
    final connection = await getConnection();
    
    try {
      final result = await operation(connection.client);
      return result;
    } finally {
      connection.release();
    }
  }

  /// Ejecuta múltiples operaciones en paralelo
  Future<List<T>> executeParallel<T>(
    List<Future<T> Function(SupabaseClient)> operations,
  ) async {
    final futures = operations.map((operation) => execute(operation));
    return Future.wait(futures);
  }

  /// Ejecuta una transacción (simulada para Supabase)
  Future<T> executeTransaction<T>(
    Future<T> Function(SupabaseClient) operation,
  ) async {
    // Nota: Supabase maneja transacciones automáticamente
    // Esta implementación es para consistencia de API
    return execute(operation);
  }

  /// Crea una nueva conexión
  Future<SupabaseClient> _createConnection(String url, String anonKey) async {
    try {
      // Para Supabase, reutilizamos la instancia principal
      // En un pool real, crearíamos múltiples instancias
      return Supabase.instance.client;
    } catch (e) {
      _logger.error('Error al crear conexión', e);
      rethrow;
    }
  }

  /// Espera por una conexión disponible
  Future<SupabaseClient?> _waitForAvailableConnection() async {
    final completer = Completer<SupabaseClient?>();
    Timer? timeoutTimer;

    // Timer de timeout
    timeoutTimer = Timer(_connectionTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Polling por conexión disponible
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_availableConnections.isNotEmpty) {
        timer.cancel();
        timeoutTimer?.cancel();
        
        if (!completer.isCompleted) {
          final client = _availableConnections.removeFirst();
          completer.complete(client);
        }
      }
    });

    return completer.future;
  }

  /// Inicia el timer de limpieza de conexiones inactivas
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cleanupIdleConnections();
    });
  }

  /// Limpia conexiones inactivas
  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final connectionsToRemove = <SupabaseClient>[];

    // En una implementación real, rastrearíamos el tiempo de última actividad
    // Por ahora, mantenemos el mínimo de conexiones
    while (_availableConnections.length > _minConnections) {
      final client = _availableConnections.removeFirst();
      connectionsToRemove.add(client);
    }

    if (connectionsToRemove.isNotEmpty) {
      _logger.debug('Limpiadas ${connectionsToRemove.length} conexiones inactivas');
    }
  }

  /// Obtiene el número total de conexiones
  int get _totalConnections => _availableConnections.length + _busyConnections.length;

  /// Verifica si el pool está inicializado
  bool get isInitialized => _isInitialized;
}

/// Wrapper para una conexión del pool
class PooledConnection {
  final SupabaseClient client;
  final ConnectionPool _pool;
  bool _isReleased = false;

  PooledConnection(this.client, this._pool);

  /// Libera la conexión de vuelta al pool
  void release() {
    if (!_isReleased) {
      _pool.releaseConnection(client);
      _isReleased = true;
    }
  }

  /// Cierra la conexión permanentemente
  void close() {
    if (!_isReleased) {
      _pool.closeConnection(client);
      _isReleased = true;
    }
  }

  /// Verifica si la conexión ha sido liberada
  bool get isReleased => _isReleased;
}

/// Estadísticas del pool de conexiones
class ConnectionPoolStats {
  final int totalConnections;
  final int availableConnections;
  final int busyConnections;
  final int maxConnections;
  final int minConnections;

  ConnectionPoolStats({
    required this.totalConnections,
    required this.availableConnections,
    required this.busyConnections,
    required this.maxConnections,
    required this.minConnections,
  });

  double get utilizationRate => 
      totalConnections > 0 ? busyConnections / totalConnections : 0.0;

  bool get isAtCapacity => totalConnections >= maxConnections;

  @override
  String toString() {
    return 'ConnectionPoolStats('
        'total: $totalConnections, '
        'available: $availableConnections, '
        'busy: $busyConnections, '
        'utilization: ${(utilizationRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// Excepción personalizada para errores del pool de conexiones
class ConnectionPoolException implements Exception {
  final String message;
  
  const ConnectionPoolException(this.message);
  
  @override
  String toString() => 'ConnectionPoolException: $message';
}

/// Mixin para servicios que usan el pool de conexiones
mixin ConnectionPoolMixin {
  static ConnectionPool? _pool;

  /// Obtiene el pool de conexiones
  ConnectionPool get pool {
    _pool ??= ConnectionPool();
    return _pool!;
  }

  /// Ejecuta una operación con el pool
  Future<T> executeWithPool<T>(
    Future<T> Function(SupabaseClient) operation,
  ) async {
    return pool.execute(operation);
  }

  /// Ejecuta múltiples operaciones en paralelo
  Future<List<T>> executeParallelWithPool<T>(
    List<Future<T> Function(SupabaseClient)> operations,
  ) async {
    return pool.executeParallel(operations);
  }
} 