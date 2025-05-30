import 'package:deportivov1/interfaces/i_base_service.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:deportivov1/services/cache_service.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/automatic_notification_service.dart';
import 'package:deportivov1/utils/time_utils.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio principal para gestión de actividades
/// Implementa caché, paginación y mejores prácticas
class ActivityService implements IActivityService {
  static final SupabaseClient _client = SupabaseService.client;
  static final LoggerService _logger = LoggerService();

  // Claves de caché
  static const String _cachePrefix = 'activities';
  static const String _familiesCacheKey = 'activity_families_all';

  @override
  Future<List<Activity>> getAll({int limit = 20, int offset = 0}) async {
    final cacheKey = CacheService.generateKey(_cachePrefix, {
      'action': 'getAll',
      'limit': limit,
      'offset': offset,
    });

    // Intentar obtener del caché primero
    final cached = CacheService.getActivitiesList<Activity>(cacheKey);
    if (cached != null) {
      _logger.debug('Actividades obtenidas del caché: ${cached.length}');
      return cached;
    }

    try {
      _logger.info(
        'Obteniendo actividades de BD (limit: $limit, offset: $offset)',
      );

      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      final activities = await _processActivityList(response);

      // Guardar en caché
      CacheService.setActivitiesList(cacheKey, activities);

      _logger.info(
        '✅ Actividades obtenidas exitosamente: ${activities.length}',
      );
      return activities;
    } catch (e) {
      _logger.error('Error al obtener actividades', e);
      throw ActivityServiceException('Error al obtener actividades: $e');
    }
  }

  @override
  Future<Activity?> getById(String id) async {
    if (id.isEmpty) {
      throw ActivityServiceException('ID de actividad no puede estar vacío');
    }

    final cacheKey = '${_cachePrefix}_by_id_$id';

    // Verificar caché
    final cached = CacheService.get<Activity>(cacheKey);
    if (cached != null) {
      _logger.debug('Actividad obtenida del caché: $id');
      return cached;
    }

    try {
      _logger.debug('Obteniendo actividad por ID: $id');

      final response =
          await _client
              .from('actividades')
              .select('*, familia_actividades(*)')
              .eq('id', id)
              .single();

      final activity = Activity.fromJson(response);
      if (response['familia_actividades'] != null) {
        activity.familia = ActivityFamily.fromJson(
          response['familia_actividades'],
        );
      }

      // Guardar en caché
      CacheService.set(cacheKey, activity);

      _logger.debug('✅ Actividad obtenida exitosamente: ${activity.nombre}');
      return activity;
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        _logger.warning('Actividad no encontrada: $id');
        return null;
      }
      _logger.error('Error al obtener actividad por ID: $id', e);
      throw ActivityServiceException('Error al obtener actividad: $e');
    }
  }

  @override
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      // Validar datos requeridos
      _validateActivityData(data);

      _logger.info('Creando nueva actividad: ${data['nombre']}');

      // Normalizar datos de tiempo
      if (data['hora_inicio'] != null) {
        data['hora_inicio'] = TimeUtils.formatTimeString(data['hora_inicio']);
      }
      if (data['hora_fin'] != null) {
        data['hora_fin'] = TimeUtils.formatTimeString(data['hora_fin']);
      }

      // Agregar timestamp de creación
      data['created_at'] = DateTime.now().toIso8601String();

      final response =
          await _client
              .from('actividades')
              .insert(data)
              .select('id, nombre')
              .single();

      // Invalidar caché relacionado
      invalidateCache();

      _logger.info(
        '✅ Actividad creada exitosamente: ${response['nombre']} (ID: ${response['id']})',
      );

      // Notificar sobre nueva actividad
      try {
        await AutomaticNotificationService.notifyNewActivity(
          activityId: response['id'],
          activityName: response['nombre'],
          description: data['descripcion'] ?? '',
          startDate: DateTime.parse(data['fecha_inicio']),
        );
      } catch (e) {
        _logger.warning('Error al enviar notificación de nueva actividad', e);
        // No fallar la creación por error de notificación
      }

      return true;
    } catch (e) {
      _logger.error('Error al crear actividad', e);
      throw ActivityServiceException('Error al crear actividad: $e');
    }
  }

  @override
  Future<bool> update(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) {
      throw ActivityServiceException('ID de actividad no puede estar vacío');
    }

    try {
      _logger.info('Actualizando actividad: $id');

      // Normalizar datos de tiempo si están presentes
      if (data['hora_inicio'] != null) {
        data['hora_inicio'] = TimeUtils.formatTimeString(data['hora_inicio']);
      }
      if (data['hora_fin'] != null) {
        data['hora_fin'] = TimeUtils.formatTimeString(data['hora_fin']);
      }

      // Agregar timestamp de actualización
      data['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await _client
              .from('actividades')
              .update(data)
              .eq('id', id)
              .select('nombre')
              .single();

      // Invalidar caché relacionado
      invalidateCache();
      CacheService.remove('${_cachePrefix}_by_id_$id');

      _logger.info(
        '✅ Actividad actualizada exitosamente: ${response['nombre']}',
      );
      return true;
    } catch (e) {
      _logger.error('Error al actualizar actividad: $id', e);
      throw ActivityServiceException('Error al actualizar actividad: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    if (id.isEmpty) {
      throw ActivityServiceException('ID de actividad no puede estar vacío');
    }

    try {
      _logger.info('Eliminando actividad: $id');

      // Verificar si hay inscripciones
      final inscriptions = await _client
          .from('inscripciones_actividades')
          .select('id')
          .eq('actividad_id', id);

      if (inscriptions.isNotEmpty) {
        _logger.warning('Intento de eliminar actividad con inscripciones: $id');
        throw ActivityServiceException(
          'No se puede eliminar una actividad con inscripciones activas',
        );
      }

      await _client.from('actividades').delete().eq('id', id);

      // Invalidar caché
      invalidateCache();
      CacheService.remove('${_cachePrefix}_by_id_$id');

      _logger.info('✅ Actividad eliminada exitosamente: $id');
      return true;
    } catch (e) {
      _logger.error('Error al eliminar actividad: $id', e);
      throw ActivityServiceException('Error al eliminar actividad: $e');
    }
  }

  @override
  Future<List<Activity>> search(String term, {int limit = 20}) async {
    if (term.trim().isEmpty) {
      _logger.warning('Término de búsqueda vacío');
      return [];
    }

    final cacheKey = CacheService.generateKey(_cachePrefix, {
      'action': 'search',
      'term': term.trim(),
      'limit': limit,
    });

    final cached = CacheService.getActivitiesList<Activity>(cacheKey);
    if (cached != null) {
      _logger.debug('Búsqueda obtenida del caché: "$term"');
      return cached;
    }

    try {
      _logger.info('Buscando actividades: "$term"');

      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .or('nombre.ilike.%$term%,descripcion.ilike.%$term%')
          .limit(limit)
          .order('nombre', ascending: true);

      final activities = await _processActivityList(response);

      // Guardar en caché con TTL más corto para búsquedas
      CacheService.set(cacheKey, activities, ttl: const Duration(minutes: 2));

      _logger.info(
        '✅ Búsqueda completada: ${activities.length} resultados para "$term"',
      );
      return activities;
    } catch (e) {
      _logger.error('Error en búsqueda de actividades: "$term"', e);
      throw ActivityServiceException('Error en búsqueda de actividades: $e');
    }
  }

  @override
  Future<List<Activity>> searchByFilters(
    Map<String, dynamic> filters, {
    int limit = 20,
  }) async {
    final cacheKey = CacheService.generateKey(_cachePrefix, {
      'action': 'searchByFilters',
      'filters': filters,
      'limit': limit,
    });

    final cached = CacheService.getActivitiesList<Activity>(cacheKey);
    if (cached != null) {
      _logger.debug('Filtros obtenidos del caché');
      return cached;
    }

    try {
      _logger.info('Buscando actividades con filtros: $filters');

      var query = _client
          .from('actividades')
          .select('*, familia_actividades(*)');

      // Aplicar filtros
      if (filters['familia_id'] != null) {
        query = query.eq('familia_id', filters['familia_id']);
      }
      if (filters['instalacion_id'] != null) {
        query = query.eq('instalacion_id', filters['instalacion_id']);
      }
      if (filters['estado'] != null) {
        query = query.eq('estado', filters['estado']);
      }
      if (filters['nivel'] != null) {
        query = query.eq('nivel', filters['nivel']);
      }

      final response = await query
          .limit(limit)
          .order('fecha_inicio', ascending: true);

      final activities = await _processActivityList(response);

      CacheService.setActivitiesList(cacheKey, activities);

      _logger.info(
        '✅ Búsqueda con filtros completada: ${activities.length} resultados',
      );
      return activities;
    } catch (e) {
      _logger.error('Error en búsqueda con filtros', e);
      throw ActivityServiceException('Error en búsqueda con filtros: $e');
    }
  }

  // Métodos adicionales para compatibilidad

  /// Obtiene actividades con detalles de familia (método de compatibilidad)
  Future<List<Activity>> getActivitiesWithFamily({int limit = 20}) async {
    return getAll(limit: limit);
  }

  /// Obtiene actividades por familia
  Future<List<Activity>> getActivitiesByFamily(
    String familyId, {
    int limit = 20,
  }) async {
    return searchByFilters({'familia_id': familyId}, limit: limit);
  }

  /// Obtiene una actividad por ID (método de compatibilidad)
  Future<Activity?> getActivityById(String activityId) async {
    return getById(activityId);
  }

  @override
  Future<bool> enrollUser(String activityId, String userId) async {
    if (activityId.isEmpty || userId.isEmpty) {
      throw ActivityServiceException(
        'ID de actividad y usuario son requeridos',
      );
    }

    try {
      _logger.info('Inscribiendo usuario $userId en actividad $activityId');

      // Verificar si ya está inscrito
      final existingEnrollment = await _client
          .from('inscripciones_actividades')
          .select('id, estado')
          .eq('actividad_id', activityId)
          .eq('usuario_id', userId)
          .order('fecha_inscripcion', ascending: false)
          .limit(1);

      if (existingEnrollment.isNotEmpty) {
        final enrollment = existingEnrollment.first;
        if (enrollment['estado'] == 'activa') {
          _logger.warning(
            'Usuario ya inscrito en actividad: $userId -> $activityId',
          );
          throw ActivityServiceException(
            'El usuario ya está inscrito en esta actividad',
          );
        }
      }

      // Verificar capacidad de la actividad
      final activity = await getById(activityId);
      if (activity == null) {
        throw ActivityServiceException('Actividad no encontrada');
      }

      if (activity.plazasMax != null) {
        final currentEnrollments = await _client
            .from('inscripciones_actividades')
            .select('id')
            .eq('actividad_id', activityId)
            .eq('estado', 'activa');

        if (currentEnrollments.length >= activity.plazasMax!) {
          _logger.warning('Actividad llena: $activityId');
          throw ActivityServiceException(
            'La actividad ha alcanzado su capacidad máxima',
          );
        }
      }

      // Crear inscripción
      await _client.from('inscripciones_actividades').insert({
        'actividad_id': activityId,
        'usuario_id': userId,
        'fecha_inscripcion': DateTime.now().toIso8601String(),
        'estado': 'activa',
      });

      // Invalidar caché relacionado
      CacheService.invalidateUserCache(userId);
      CacheService.remove('${_cachePrefix}_by_id_$activityId');

      _logger.info('✅ Usuario inscrito exitosamente: $userId -> $activityId');
      return true;
    } catch (e) {
      _logger.error('Error al inscribir usuario: $userId -> $activityId', e);
      throw ActivityServiceException('Error al inscribir usuario: $e');
    }
  }

  @override
  Future<bool> unenrollUser(String activityId, String userId) async {
    if (activityId.isEmpty || userId.isEmpty) {
      throw ActivityServiceException(
        'ID de actividad y usuario son requeridos',
      );
    }

    try {
      _logger.info('Desinscribiendo usuario $userId de actividad $activityId');

      await _client
          .from('inscripciones_actividades')
          .delete()
          .eq('actividad_id', activityId)
          .eq('usuario_id', userId);

      // Invalidar caché relacionado
      CacheService.invalidateUserCache(userId);
      CacheService.remove('${_cachePrefix}_by_id_$activityId');

      _logger.info(
        '✅ Usuario desinscrito exitosamente: $userId -> $activityId',
      );
      return true;
    } catch (e) {
      _logger.error('Error al desinscribir usuario: $userId -> $activityId', e);
      throw ActivityServiceException('Error al desinscribir usuario: $e');
    }
  }

  /// Obtiene todas las familias de actividades con caché
  Future<List<ActivityFamily>> getAllFamilies({int limit = 50}) async {
    final cached = CacheService.get<List<ActivityFamily>>(_familiesCacheKey);
    if (cached != null) {
      _logger.debug('Familias obtenidas del caché');
      return cached;
    }

    try {
      _logger.info('Obteniendo familias de actividades');

      final response = await _client
          .from('familia_actividades')
          .select()
          .order('nombre', ascending: true)
          .limit(limit);

      final families =
          response
              .map<ActivityFamily>((data) => ActivityFamily.fromJson(data))
              .toList();

      // Guardar en caché con TTL largo (las familias cambian poco)
      CacheService.set(
        _familiesCacheKey,
        families,
        ttl: const Duration(hours: 2),
      );

      _logger.info('✅ Familias obtenidas exitosamente: ${families.length}');
      return families;
    } catch (e) {
      _logger.error('Error al obtener familias de actividades', e);
      throw ActivityServiceException(
        'Error al obtener familias de actividades: $e',
      );
    }
  }

  /// Obtiene actividades paginadas para el widget PaginatedListView
  Future<List<Activity>> getPaginated(int page, int limit) async {
    final offset = page * limit;
    return getAll(limit: limit, offset: offset);
  }

  /// Obtiene estadísticas de actividades
  Future<ActivityStats> getStats() async {
    const cacheKey = 'activity_stats';

    final cached = CacheService.get<ActivityStats>(cacheKey);
    if (cached != null) {
      _logger.debug('Estadísticas obtenidas del caché');
      return cached;
    }

    try {
      _logger.info('Obteniendo estadísticas de actividades');

      // Obtener conteos en paralelo
      final futures = await Future.wait([
        _client.from('actividades').select('id').count(),
        _client.from('actividades').select('id').eq('estado', 'activa').count(),
        _client
            .from('inscripciones_actividades')
            .select('id')
            .eq('estado', 'activa')
            .count(),
      ]);

      final stats = ActivityStats(
        totalActivities: futures[0].count,
        activeActivities: futures[1].count,
        totalEnrollments: futures[2].count,
      );

      CacheService.set(cacheKey, stats, ttl: const Duration(minutes: 10));

      _logger.info(
        '✅ Estadísticas obtenidas: ${stats.totalActivities} actividades',
      );
      return stats;
    } catch (e) {
      _logger.error('Error al obtener estadísticas', e);
      throw ActivityServiceException('Error al obtener estadísticas: $e');
    }
  }

  @override
  void invalidateCache() {
    _logger.debug('Invalidando caché de actividades');
    CacheService.invalidateActivitiesCache();
  }

  @override
  void cleanExpiredCache() {
    _logger.debug('Limpiando caché expirado');
    CacheService.cleanExpired();
  }

  /// Procesa una lista de actividades desde la respuesta de Supabase
  Future<List<Activity>> _processActivityList(List<dynamic> response) async {
    final activities = <Activity>[];

    for (final data in response) {
      try {
        final activity = Activity.fromJson(data);
        if (data['familia_actividades'] != null) {
          activity.familia = ActivityFamily.fromJson(
            data['familia_actividades'],
          );
        }
        activities.add(activity);
      } catch (e) {
        _logger.warning('Error al procesar actividad individual', e);
        // Continuar procesando otras actividades
      }
    }

    return activities;
  }

  /// Valida los datos requeridos para crear/actualizar una actividad
  void _validateActivityData(Map<String, dynamic> data) {
    final requiredFields = ['nombre', 'familia_id', 'instalacion_id'];

    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        throw ActivityServiceException('Campo requerido faltante: $field');
      }
    }

    // Validar formato de horas si están presentes
    if (data['hora_inicio'] != null) {
      try {
        TimeUtils.formatTimeString(data['hora_inicio']);
      } catch (e) {
        throw ActivityServiceException('Formato de hora_inicio inválido');
      }
    }

    if (data['hora_fin'] != null) {
      try {
        TimeUtils.formatTimeString(data['hora_fin']);
      } catch (e) {
        throw ActivityServiceException('Formato de hora_fin inválido');
      }
    }

    // Validar capacidad máxima
    if (data['plazas_max'] != null) {
      final capacity = int.tryParse(data['plazas_max'].toString());
      if (capacity == null || capacity <= 0) {
        throw ActivityServiceException(
          'Capacidad máxima debe ser un número positivo',
        );
      }
    }
  }

  // Métodos de compatibilidad para código existente

  /// Obtiene inscripciones de un usuario
  Future<List<Map<String, dynamic>>> getUserEnrollments(
    String userId, {
    int limit = 20,
  }) async {
    if (userId.isEmpty) {
      throw ActivityServiceException('ID de usuario no puede estar vacío');
    }

    try {
      _logger.debug('Obteniendo inscripciones del usuario: $userId');

      final response = await _client
          .from('inscripciones_actividades')
          .select('*, actividades(*)')
          .eq('usuario_id', userId)
          .eq('estado', 'activa')
          .order('fecha_inscripcion', ascending: false)
          .limit(limit);

      _logger.debug('✅ Inscripciones obtenidas: ${response.length}');
      return response;
    } catch (e) {
      _logger.error('Error al obtener inscripciones del usuario: $userId', e);
      throw ActivityServiceException('Error al obtener inscripciones: $e');
    }
  }

  /// Obtiene inscripciones por estado
  Future<List<Map<String, dynamic>>> getEnrollmentsByStatus(
    String status, {
    int limit = 20,
  }) async {
    try {
      _logger.debug('Obteniendo inscripciones por estado: $status');

      final response = await _client
          .from('inscripciones_actividades')
          .select('*, actividades(*), usuarios(*)')
          .eq('estado', status)
          .order('fecha_inscripcion', ascending: false)
          .limit(limit);

      _logger.debug('✅ Inscripciones por estado obtenidas: ${response.length}');
      return response;
    } catch (e) {
      _logger.error('Error al obtener inscripciones por estado: $status', e);
      throw ActivityServiceException(
        'Error al obtener inscripciones por estado: $e',
      );
    }
  }

  // Implementación de métodos de IStatefulService
  @override
  Future<List<Activity>> getByStatus(String status, {int limit = 20}) async {
    return searchByFilters({'estado': status}, limit: limit);
  }

  @override
  Future<bool> changeStatus(String id, String newStatus) async {
    return update(id, {'estado': newStatus});
  }

  // Implementación de método de IActivityService
  @override
  Future<List<Activity>> getByInstallation(
    String installationId, {
    int limit = 20,
  }) async {
    return searchByFilters({'instalacion_id': installationId}, limit: limit);
  }
}

/// Estadísticas de actividades
class ActivityStats {
  final int totalActivities;
  final int activeActivities;
  final int totalEnrollments;

  ActivityStats({
    required this.totalActivities,
    required this.activeActivities,
    required this.totalEnrollments,
  });

  double get enrollmentRate =>
      totalActivities > 0 ? totalEnrollments / totalActivities : 0.0;
}

/// Excepción personalizada para errores del servicio de actividades
class ActivityServiceException implements Exception {
  final String message;

  const ActivityServiceException(this.message);

  @override
  String toString() => 'ActivityServiceException: $message';
}

/// Clase con métodos estáticos para compatibilidad con código existente
class ActivityServiceStatic {
  static final SupabaseClient _client = SupabaseService.client;
  static final LoggerService _logger = LoggerService();

  static Future<List<Activity>> getActivitiesWithFamily({
    int limit = 20,
  }) async {
    final service = ActivityService();
    return service.getAll(limit: limit);
  }

  static Future<List<ActivityFamily>> getAllActivityFamilies({
    int limit = 50,
  }) async {
    final service = ActivityService();
    return service.getAllFamilies(limit: limit);
  }

  static Future<bool> deleteActivity(String activityId) async {
    final service = ActivityService();
    return service.delete(activityId);
  }

  static Future<bool> createActivity(Map<String, dynamic> data) async {
    final service = ActivityService();
    return service.create(data);
  }

  static Future<bool> updateActivity(
    String id,
    Map<String, dynamic> data,
  ) async {
    final service = ActivityService();
    return service.update(id, data);
  }

  static Future<List<Map<String, dynamic>>> getUserEnrollments(
    String userId, {
    int limit = 20,
  }) async {
    final service = ActivityService();
    return service.getUserEnrollments(userId, limit: limit);
  }

  static Future<List<Map<String, dynamic>>> getEnrollmentsByStatus(
    String status, {
    int limit = 20,
  }) async {
    final service = ActivityService();
    return service.getEnrollmentsByStatus(status, limit: limit);
  }

  static Future<bool> enrollActivity(String activityId, String userId) async {
    final service = ActivityService();
    return service.enrollUser(activityId, userId);
  }

  static Future<bool> cancelEnrollment(String enrollmentId) async {
    try {
      await _client
          .from('inscripciones_actividades')
          .delete()
          .eq('id', enrollmentId);
      return true;
    } catch (e) {
      _logger.error('Error al cancelar inscripción: $enrollmentId', e);
      return false;
    }
  }

  static Future<bool> updateEnrollmentStatus(
    String enrollmentId,
    String newStatus,
  ) async {
    try {
      await _client
          .from('inscripciones_actividades')
          .update({'estado': newStatus})
          .eq('id', enrollmentId);
      return true;
    } catch (e) {
      _logger.error(
        'Error al actualizar estado de inscripción: $enrollmentId',
        e,
      );
      return false;
    }
  }
}
