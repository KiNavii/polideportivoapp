import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  static final SupabaseClient _client = SupabaseService.client;

  // Métodos para actividades

  // Obtener todas las actividades
  static Future<List<Activity>> getAllActivities({int limit = 10}) async {
    try {
      final response = await _client
          .from('actividades')
          .select()
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Activity> activities = [];
      for (var data in response) {
        try {
          activities.add(Activity.fromJson(data));
        } catch (e) {
          print('Error al procesar actividad individual: $e');
          // Continuar con la siguiente actividad
        }
      }
      return activities;
    } catch (e) {
      print('Error al obtener actividades: $e');
      return [];
    }
  }

  // Obtener actividades por familia
  static Future<List<Activity>> getActivitiesByFamily(
    String familyId, {
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('actividades')
          .select()
          .eq('familia_id', familyId)
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Activity> activities = [];
      for (var data in response) {
        try {
          activities.add(Activity.fromJson(data));
        } catch (e) {
          print('Error al procesar actividad individual: $e');
          // Continuar con la siguiente actividad
        }
      }
      return activities;
    } catch (e) {
      print('Error al obtener actividades por familia: $e');
      return [];
    }
  }

  // Obtener actividades con detalles de familia
  static Future<List<Activity>> getActivitiesWithFamily({
    int limit = 10,
  }) async {
    try {
      print('Obteniendo actividades con límite: $limit');

      // Consulta simple sin filtros para obtener todas las actividades
      final response = await _client
          .from('actividades')
          .select('*, familia_actividades(*)')
          .limit(limit);

      print('Actividades obtenidas de DB: ${response.length}');

      if (response.isEmpty) {
        print('No se encontraron actividades en la base de datos');
        return [];
      }

      print('Ejemplos de actividades en BD:');
      for (int i = 0; i < response.length && i < 3; i++) {
        print(
          'Actividad #$i: ${response[i]['nombre']} (ID: ${response[i]['id']})',
        );
      }

      List<Activity> activities = [];
      for (var data in response) {
        try {
          Activity activity = Activity.fromJson(data);
          if (data['familia_actividades'] != null) {
            activity.familia = ActivityFamily.fromJson(
              data['familia_actividades'],
            );
          }
          activities.add(activity);
        } catch (e) {
          print('Error al procesar actividad individual: $e');
          print('Datos de la actividad con error: $data');
          // Continuar con la siguiente actividad
        }
      }

      print('Actividades procesadas: ${activities.length}');
      return activities;
    } catch (e) {
      print('Error al obtener actividades con familia: $e');
      print('Stacktrace: ${e is Error ? e.stackTrace : "No disponible"}');
      // Devolver lista vacía en caso de error para evitar bloqueos
      return [];
    }
  }

  // Obtener una actividad por ID
  static Future<Activity?> getActivityById(String activityId) async {
    try {
      final response =
          await _client
              .from('actividades')
              .select('*, familia_actividades(*)')
              .eq('id', activityId)
              .single();

      Activity activity = Activity.fromJson(response);
      if (response['familia_actividades'] != null) {
        activity.familia = ActivityFamily.fromJson(
          response['familia_actividades'],
        );
      }

      return activity;
    } catch (e) {
      print('Error al obtener actividad por ID: $e');
      return null;
    }
  }

  // Métodos para familias de actividades

  // Obtener todas las familias de actividades
  static Future<List<ActivityFamily>> getAllActivityFamilies({
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('familia_actividades')
          .select()
          .order('nombre', ascending: true)
          .limit(limit);

      List<ActivityFamily> families = [];
      for (var data in response) {
        try {
          families.add(ActivityFamily.fromJson(data));
        } catch (e) {
          print('Error al procesar familia de actividad: $e');
          // Continuar con la siguiente familia
        }
      }
      return families;
    } catch (e) {
      print('Error al obtener familias de actividades: $e');
      return [];
    }
  }

  // Obtener una familia de actividades por ID
  static Future<ActivityFamily?> getActivityFamilyById(String familyId) async {
    try {
      final response =
          await _client
              .from('familia_actividades')
              .select()
              .eq('id', familyId)
              .single();

      return ActivityFamily.fromJson(response);
    } catch (e) {
      print('Error al obtener familia por ID: $e');
      return null;
    }
  }

  // Inscribirse a una actividad
  static Future<bool> enrollActivity(String activityId, String userId) async {
    try {
      // Verificar primero si el usuario ya está inscrito en esta actividad
      // Ordenamos por fecha de inscripción descendente para obtener la más reciente primero
      final existingEnrollments = await _client
          .from('inscripciones_actividades')
          .select()
          .eq('actividad_id', activityId)
          .eq('usuario_id', userId)
          .order('fecha_inscripcion', ascending: false);

      // Si ya existe una inscripción
      if (existingEnrollments.isNotEmpty) {
        // Verificar si alguna inscripción está activa (pendiente o confirmada)
        final activeEnrollment =
            existingEnrollments
                .where(
                  (e) =>
                      e['estado'] == 'pendiente' || e['estado'] == 'confirmada',
                )
                .toList();

        if (activeEnrollment.isNotEmpty) {
          // Ya existe una inscripción activa
          return false;
        }

        // Si todas las inscripciones anteriores están canceladas, actualizar la más reciente
        // en lugar de crear una nueva para evitar violar la restricción de unicidad
        final mostRecentEnrollment = existingEnrollments[0];
        final enrollmentId = mostRecentEnrollment['id'];

        await _client
            .from('inscripciones_actividades')
            .update({
              'estado': 'pendiente',
              'fecha_inscripcion': DateTime.now().toIso8601String(),
              'fecha_cancelacion': null,
            })
            .eq('id', enrollmentId);

        return true;
      }

      // Crear nueva inscripción si no existía ninguna previa
      await _client.from('inscripciones_actividades').insert({
        'actividad_id': activityId,
        'usuario_id': userId,
        'estado': 'pendiente', // Las inscripciones se crean como pendientes
        'fecha_inscripcion': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error al inscribirse en actividad: $e');
      return false;
    }
  }

  // Cancelar inscripción
  static Future<bool> cancelEnrollment(String enrollmentId) async {
    try {
      final response =
          await _client
              .from('inscripciones_actividades')
              .select('actividad_id')
              .eq('id', enrollmentId)
              .single();

      String activityId = response['actividad_id'].toString();

      await _client
          .from('inscripciones_actividades')
          .update({
            'estado': 'cancelada',
            'fecha_cancelacion': DateTime.now().toIso8601String(),
          })
          .eq('id', enrollmentId);

      return true;
    } catch (e) {
      print('Error al cancelar inscripción: $e');
      return false;
    }
  }

  // Obtener inscripciones del usuario
  static Future<List<Map<String, dynamic>>> getUserEnrollments(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('inscripciones_actividades')
          .select('*, actividades(*)')
          .eq('usuario_id', userId)
          .order('fecha_inscripcion', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('Error al obtener inscripciones del usuario: $e');
      return [];
    }
  }

  // Métodos para administradores

  // Obtener inscripciones por estado
  static Future<List<Map<String, dynamic>>> getEnrollmentsByStatus(
    String status, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('inscripciones_actividades')
          .select('*, actividades(*), usuarios(*)')
          .eq('estado', status)
          .order('fecha_inscripcion', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('Error al obtener inscripciones por estado: $e');
      return [];
    }
  }

  // Actualizar estado de una inscripción
  static Future<bool> updateEnrollmentStatus(
    String enrollmentId,
    String newStatus,
  ) async {
    try {
      // Solo actualizar el estado, sin campos de fecha adicionales
      final updateData = {'estado': newStatus};

      // Si es cancelación, guardar fecha (este campo sí existe)
      if (newStatus == 'cancelada') {
        updateData['fecha_cancelacion'] = DateTime.now().toIso8601String();
      }

      // Eliminar el intento de guardar fecha_confirmacion que no existe en la tabla
      // No añadir updateData['fecha_confirmacion']

      await _client
          .from('inscripciones_actividades')
          .update(updateData)
          .eq('id', enrollmentId);

      return true;
    } catch (e) {
      print('Error al actualizar estado de inscripción: $e');
      return false;
    }
  }

  // Crear una nueva actividad
  static Future<bool> createActivity(Map<String, dynamic> activityData) async {
    try {
      // Verificar que tenga los campos requeridos
      if (activityData['nombre'] == null ||
          activityData['familia_id'] == null ||
          activityData['instalacion_id'] == null) {
        print('Error al crear actividad: Faltan campos requeridos');
        print('Datos recibidos: $activityData');
        return false;
      }

      await _client.from('actividades').insert(activityData);
      return true;
    } catch (e) {
      print('Error al crear actividad: $e');
      // Si es PostgrestException, mostrar más detalles
      if (e.toString().contains('PostgrestException')) {
        print('Detalles de error: $e');
        print('Datos de la actividad: $activityData');
      }
      return false;
    }
  }

  // Actualizar una actividad
  static Future<bool> updateActivity(
    String activityId,
    Map<String, dynamic> activityData,
  ) async {
    try {
      // Verificar que tenga un ID válido
      if (activityId.isEmpty) {
        print('Error al actualizar actividad: ID no válido');
        return false;
      }

      await _client
          .from('actividades')
          .update(activityData)
          .eq('id', activityId);
      return true;
    } catch (e) {
      print('Error al actualizar actividad: $e');
      // Si es PostgrestException, mostrar más detalles
      if (e.toString().contains('PostgrestException')) {
        print('Detalles de error: $e');
        print('ID: $activityId');
        print('Datos de la actividad: $activityData');
      }
      return false;
    }
  }

  // Eliminar una actividad
  static Future<bool> deleteActivity(String activityId) async {
    try {
      // Primero verificar si hay inscripciones
      final inscripciones = await _client
          .from('inscripciones_actividades')
          .select('id')
          .eq('actividad_id', activityId);

      if (inscripciones.isNotEmpty) {
        throw Exception('No se puede eliminar una actividad con inscripciones');
      }

      await _client.from('actividades').delete().eq('id', activityId);
      return true;
    } catch (e) {
      print('Error al eliminar actividad: $e');
      return false;
    }
  }
}
