import 'package:deportivov1/services/optimized_activity_service.dart';
import 'package:deportivov1/services/cache_service.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/auth_service.dart';
import 'package:deportivov1/services/user_service.dart';
import 'package:deportivov1/services/reservation_service.dart';
import 'package:deportivov1/services/installation_service.dart';
import 'package:deportivov1/services/court_service.dart';
import 'package:deportivov1/services/news_service.dart';
import 'package:deportivov1/services/event_service.dart';
import 'package:deportivov1/interfaces/i_base_service.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:deportivov1/core/validation_service.dart';

/// Service Locator simplificado para gestión centralizada de dependencias
/// Implementa el patrón Singleton para acceso global a servicios
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};
  static bool _isInitialized = false;

  /// Inicializa todos los servicios y dependencias
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Servicios de infraestructura (sin dependencias)
      _registerInfrastructureServices();

      // 2. Servicios de datos (dependen de infraestructura)
      await _registerDataServices();

      // 3. Servicios de negocio (dependen de datos)
      _registerBusinessServices();

      _isInitialized = true;
      logger.info('ServiceLocator inicializado correctamente');
    } catch (e) {
      logger.error('Error al inicializar ServiceLocator: $e');
      rethrow;
    }
  }

  /// Registra servicios de infraestructura
  static void _registerInfrastructureServices() {
    // Logger (sin dependencias)
    _services[LoggerService] = LoggerService();

    // Validación (sin dependencias)
    _services[ValidationService] = ValidationService();

    // Caché (sin dependencias) - Nota: CacheService es estático
    _services[CacheService] = CacheService();
  }

  /// Registra servicios de datos
  static Future<void> _registerDataServices() async {
    // Supabase Service (requiere inicialización)
    await SupabaseService.initialize();
    _services[SupabaseService] = SupabaseService();

    // Auth Service (depende de Supabase)
    _services[AuthService] = AuthService();
  }

  /// Registra servicios de negocio
  static void _registerBusinessServices() {
    // User Service
    _services[UserService] = UserService();

    // Activity Service (optimizado)
    _services[OptimizedActivityService] = OptimizedActivityService();

    // Reservation Service
    _services[ReservationService] = ReservationService();

    // Installation Service
    _services[InstallationService] = InstallationService();

    // Court Service
    _services[CourtService] = CourtService();

    // News Service
    _services[NewsService] = NewsService();

    // Event Service
    _services[EventService] = EventService();
  }

  /// Obtiene una instancia de servicio por tipo
  static T get<T>() {
    if (!_services.containsKey(T)) {
      throw ServiceLocatorException('Servicio ${T.toString()} no registrado');
    }
    
    try {
      return _services[T] as T;
    } catch (e) {
      logger.error('Error al obtener servicio ${T.toString()}: $e');
      rethrow;
    }
  }

  /// Verifica si un servicio está registrado
  static bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Resetea el Service Locator (útil para testing)
  static Future<void> reset() async {
    _services.clear();
    _isInitialized = false;
    logger.info('ServiceLocator reseteado');
  }

  /// Registra un servicio manualmente (útil para testing)
  static void registerTestService<T>(T service) {
    _services[T] = service;
  }

  /// Obtiene el logger global
  static LoggerService get logger => get<LoggerService>();

  /// Obtiene el servicio de validación
  static ValidationService get validator => get<ValidationService>();

  /// Obtiene el servicio de caché
  static CacheService get cache => get<CacheService>();

  /// Obtiene el servicio de actividades optimizado
  static OptimizedActivityService get activities => get<OptimizedActivityService>();

  /// Obtiene el servicio de usuarios
  static UserService get users => get<UserService>();

  /// Obtiene el servicio de reservas
  static ReservationService get reservations => get<ReservationService>();

  /// Obtiene el servicio de instalaciones
  static InstallationService get installations => get<InstallationService>();

  /// Obtiene el servicio de pistas
  static CourtService get courts => get<CourtService>();

  /// Obtiene el servicio de noticias
  static NewsService get news => get<NewsService>();

  /// Obtiene el servicio de eventos
  static EventService get events => get<EventService>();

  /// Obtiene el servicio de autenticación
  static AuthService get auth => get<AuthService>();

  /// Verifica si el Service Locator está inicializado
  static bool get isInitialized => _isInitialized;

  /// Obtiene estadísticas de servicios registrados
  static ServiceLocatorStats getStats() {
    final registeredServices = _services.keys.map((type) => type.toString()).toList();
    
    // Lista de tipos de servicios esperados
    final expectedServices = [
      'LoggerService',
      'ValidationService', 
      'CacheService',
      'SupabaseService',
      'AuthService',
      'UserService',
      'OptimizedActivityService',
      'ReservationService',
      'InstallationService',
      'CourtService',
      'NewsService',
      'EventService',
    ];

    return ServiceLocatorStats(
      totalExpected: expectedServices.length,
      totalRegistered: registeredServices.length,
      registeredServices: registeredServices,
      isInitialized: _isInitialized,
    );
  }
}

/// Estadísticas del Service Locator
class ServiceLocatorStats {
  final int totalExpected;
  final int totalRegistered;
  final List<String> registeredServices;
  final bool isInitialized;

  ServiceLocatorStats({
    required this.totalExpected,
    required this.totalRegistered,
    required this.registeredServices,
    required this.isInitialized,
  });

  double get registrationRatio => 
      totalExpected > 0 ? totalRegistered / totalExpected : 0.0;

  @override
  String toString() {
    return 'ServiceLocatorStats('
        'initialized: $isInitialized, '
        'registered: $totalRegistered/$totalExpected, '
        'ratio: ${(registrationRatio * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// Excepción personalizada para errores del Service Locator
class ServiceLocatorException implements Exception {
  final String message;
  
  const ServiceLocatorException(this.message);
  
  @override
  String toString() => 'ServiceLocatorException: $message';
} 