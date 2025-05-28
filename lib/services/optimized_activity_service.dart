import 'package:deportivov1/interfaces/i_base_service.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:deportivov1/services/cache_service.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/utils/time_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio optimizado para gestión de actividades
/// Implementa caché, paginación y mejores prácticas
class OptimizedActivityService implements IActivityService {
  static final SupabaseClient _client = SupabaseService.client;
  
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
      return cached;
    }

    try {
      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      final activities = await _processActivityList(response);
      
      // Guardar en caché
      CacheService.setActivitiesList(cacheKey, activities);
      
      return activities;
    } catch (e) {
      throw ActivityServiceException('Error al obtener actividades: $e');
    }
  }

  @override
  Future<Activity?> getById(String id) async {
    final cacheKey = '${_cachePrefix}_by_id_$id';
    
    // Verificar caché
    final cached = CacheService.get<Activity>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .eq('id', id)
          .single();

      final activity = Activity.fromJson(response);
      if (response['familia_actividades'] != null) {
        activity.familia = ActivityFamily.fromJson(response['familia_actividades']);
      }

      // Guardar en caché
      CacheService.set(cacheKey, activity);
      
      return activity;
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw ActivityServiceException('Error al obtener actividad: $e');
    }
  }

  @override
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      // Validar datos requeridos
      _validateActivityData(data);
      
      // Normalizar datos de tiempo
      if (data['hora_inicio'] != null) {
        data['hora_inicio'] = TimeUtils.formatTimeString(data['hora_inicio']);
      }
      if (data['hora_fin'] != null) {
        data['hora_fin'] = TimeUtils.formatTimeString(data['hora_fin']);
      }

      await _client.from('actividades').insert(data);
      
      // Invalidar caché relacionado
      invalidateCache();
      
      return true;
    } catch (e) {
      throw ActivityServiceException('Error al crear actividad: $e');
    }
  }

  @override
  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      // Normalizar datos de tiempo si están presentes
      if (data['hora_inicio'] != null) {
        data['hora_inicio'] = TimeUtils.formatTimeString(data['hora_inicio']);
      }
      if (data['hora_fin'] != null) {
        data['hora_fin'] = TimeUtils.formatTimeString(data['hora_fin']);
      }

      await _client
          .from('actividades')
          .update(data)
          .eq('id', id);
      
      // Invalidar caché relacionado
      invalidateCache();
      CacheService.remove('${_cachePrefix}_by_id_$id');
      
      return true;
    } catch (e) {
      throw ActivityServiceException('Error al actualizar actividad: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      // Verificar si hay inscripciones
      final inscriptions = await _client
          .from('inscripciones_actividades')
          .select('id')
          .eq('actividad_id', id);

      if (inscriptions.isNotEmpty) {
        throw ActivityServiceException(
          'No se puede eliminar una actividad con inscripciones activas'
        );
      }

      await _client.from('actividades').delete().eq('id', id);
      
      // Invalidar caché
      invalidateCache();
      CacheService.remove('${_cachePrefix}_by_id_$id');
      
      return true;
    } catch (e) {
      throw ActivityServiceException('Error al eliminar actividad: $e');
    }
  }

  @override
  Future<List<Activity>> search(String term, {int limit = 20}) async {
    final cacheKey = CacheService.generateKey(_cachePrefix, {
      'action': 'search',
      'term': term,
      'limit': limit,
    });

    final cached = CacheService.getActivitiesList<Activity>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .or('nombre.ilike.%$term%,descripcion.ilike.%$term%')
          .limit(limit)
          .order('nombre', ascending: true);

      final activities = await _processActivityList(response);
      
      // Guardar en caché con TTL más corto para búsquedas
      CacheService.set(cacheKey, activities, ttl: const Duration(minutes: 2));
      
      return activities;
    } catch (e) {
      throw ActivityServiceException('Error en búsqueda de actividades: $e');
    }
  }

  @override
  Future<List<Activity>> searchByFilters(
    Map<String, dynamic> filters, 
    {int limit = 20}
  ) async {
    final cacheKey = CacheService.generateKey(_cachePrefix, {
      'action': 'searchByFilters',
      'filters': filters,
      'limit': limit,
    });

    final cached = CacheService.getActivitiesList<Activity>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
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
      
      return activities;
    } catch (e) {
      throw ActivityServiceException('Error al filtrar actividades: $e');
    }
  }

  @override
  Future<List<Activity>> getByStatus(String status, {int limit = 20}) async {
    return searchByFilters({'estado': status}, limit: limit);
  }

  @override
  Future<bool> changeStatus(String id, String newStatus) async {
    return update(id, {'estado': newStatus});
  }

  @override
  Future<List<Activity>> getActivitiesWithFamily({int limit = 20}) async {
    return getAll(limit: limit);
  }

  @override
  Future<List<Activity>> getByInstallation(
    String installationId, 
    {int limit = 20}
  ) async {
    return searchByFilters({'instalacion_id': installationId}, limit: limit);
  }

  @override
  Future<bool> enrollUser(String activityId, String userId) async {
    try {
      // Verificar si ya está inscrito
      final existing = await _client
          .from('inscripciones_actividades')
          .select('id')
          .eq('actividad_id', activityId)
          .eq('usuario_id', userId);

      if (existing.isNotEmpty) {
        throw ActivityServiceException('El usuario ya está inscrito en esta actividad');
      }

      // Verificar capacidad disponible
      final activity = await getById(activityId);
      if (activity == null) {
        throw ActivityServiceException('Actividad no encontrada');
      }

      final currentEnrollments = await _client
          .from('inscripciones_actividades')
          .select('id')
          .eq('actividad_id', activityId)
          .eq('estado', 'activa');

      if (currentEnrollments.length >= activity.plazasMax) {
        throw ActivityServiceException('No hay plazas disponibles');
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

      return true;
    } catch (e) {
      throw ActivityServiceException('Error al inscribir usuario: $e');
    }
  }

  @override
  Future<bool> unenrollUser(String activityId, String userId) async {
    try {
      await _client
          .from('inscripciones_actividades')
          .delete()
          .eq('actividad_id', activityId)
          .eq('usuario_id', userId);

      // Invalidar caché relacionado
      CacheService.invalidateUserCache(userId);
      CacheService.remove('${_cachePrefix}_by_id_$activityId');

      return true;
    } catch (e) {
      throw ActivityServiceException('Error al desinscribir usuario: $e');
    }
  }

  /// Obtiene todas las familias de actividades con caché
  Future<List<ActivityFamily>> getAllFamilies({int limit = 50}) async {
    final cached = CacheService.get<List<ActivityFamily>>(_familiesCacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client
          .from('familia_actividades')
          .select()
          .order('nombre', ascending: true)
          .limit(limit);

      final families = response
          .map<ActivityFamily>((data) => ActivityFamily.fromJson(data))
          .toList();

      // Guardar en caché con TTL largo (las familias cambian poco)
      CacheService.set(_familiesCacheKey, families, ttl: const Duration(hours: 2));

      return families;
    } catch (e) {
      throw ActivityServiceException('Error al obtener familias de actividades: $e');
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
      return cached;
    }

    try {
      // Obtener conteos en paralelo
      final futures = await Future.wait([
        _client.from('actividades').select('id').count(),
        _client.from('actividades').select('id').eq('estado', 'activa').count(),
        _client.from('inscripciones_actividades').select('id').eq('estado', 'activa').count(),
      ]);

      final stats = ActivityStats(
        totalActivities: futures[0].count,
        activeActivities: futures[1].count,
        totalEnrollments: futures[2].count,
      );

      CacheService.set(cacheKey, stats, ttl: const Duration(minutes: 10));
      
      return stats;
    } catch (e) {
      throw ActivityServiceException('Error al obtener estadísticas: $e');
    }
  }

  @override
  void invalidateCache() {
    CacheService.invalidateActivitiesCache();
  }

  @override
  void cleanExpiredCache() {
    CacheService.cleanExpired();
  }

  /// Procesa una lista de actividades desde la respuesta de Supabase
  Future<List<Activity>> _processActivityList(List<dynamic> response) async {
    final activities = <Activity>[];
    
    for (final data in response) {
      try {
        final activity = Activity.fromJson(data);
        if (data['familia_actividades'] != null) {
          activity.familia = ActivityFamily.fromJson(data['familia_actividades']);
        }
        activities.add(activity);
      } catch (e) {
        // Log error pero continúa procesando otras actividades
        print('Error al procesar actividad individual: $e');
      }
    }
    
    return activities;
  }

  /// Valida los datos requeridos para crear/actualizar una actividad
  void _validateActivityData(Map<String, dynamic> data) {
    final requiredFields = ['nombre', 'familia_id', 'instalacion_id'];
    
    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().isEmpty) {
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