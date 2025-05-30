import 'package:deportivov1/services/supabase_service.dart';

class AdminNotificationService {
  /// Enviar notificación cuando se acepta una inscripción
  static Future<bool> notifyInscriptionAccepted({
    required String userId,
    required String activityName,
    required String scheduleInfo,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': '✅ Inscripción Aceptada',
          'message':
              'Tu inscripción a "$activityName" ha sido aceptada. $scheduleInfo',
          'data': {
            'type': 'inscription_accepted',
            'activity_name': activityName,
            'schedule': scheduleInfo,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.status == 200) {
        print('✅ Notificación de inscripción enviada con Firebase');

        // También crear notificación en BD para historial
        await _createDatabaseNotification(
          userId: userId,
          title: '✅ Inscripción Aceptada',
          message: 'Tu inscripción a "$activityName" ha sido aceptada',
          type: 'inscription_accepted',
        );

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error enviando notificación de inscripción: $e');
      return false;
    }
  }

  /// Enviar notificación cuando se rechaza una inscripción
  static Future<bool> notifyInscriptionRejected({
    required String userId,
    required String activityName,
    required String reason,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': '❌ Inscripción Rechazada',
          'message':
              'Tu inscripción a "$activityName" ha sido rechazada. Motivo: $reason',
          'data': {
            'type': 'inscription_rejected',
            'activity_name': activityName,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.status == 200) {
        print('✅ Notificación de rechazo enviada con Firebase');

        await _createDatabaseNotification(
          userId: userId,
          title: '❌ Inscripción Rechazada',
          message: 'Tu inscripción a "$activityName" ha sido rechazada',
          type: 'inscription_rejected',
        );

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error enviando notificación de rechazo: $e');
      return false;
    }
  }

  /// Enviar notificación de nueva actividad disponible
  static Future<bool> notifyNewActivity({
    required String activityId,
    required String activityName,
    required String description,
    required DateTime startDate,
  }) async {
    try {
      // Enviar a todos los usuarios activos
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'title': '🆕 Nueva Actividad Disponible',
          'message': 'Se ha creado "$activityName". ¡Inscríbete ya!',
          'data': {
            'type': 'new_activity',
            'activity_id': activityId,
            'activity_name': activityName,
            'description': description,
            'start_date': startDate.toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
          },
          'send_to_all': true, // Flag para enviar a todos
        },
      );

      if (response.status == 200) {
        print('✅ Notificación de nueva actividad enviada a todos con Firebase');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error enviando notificación de nueva actividad: $e');
      return false;
    }
  }

  /// Enviar notificación de cambio de horario
  static Future<bool> notifyScheduleChange({
    required String userId,
    required String activityName,
    required String oldSchedule,
    required String newSchedule,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': '⏰ Cambio de Horario',
          'message':
              '"$activityName" cambió de horario: $oldSchedule → $newSchedule',
          'data': {
            'type': 'schedule_change',
            'activity_name': activityName,
            'old_schedule': oldSchedule,
            'new_schedule': newSchedule,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.status == 200) {
        print('✅ Notificación de cambio de horario enviada con Firebase');

        await _createDatabaseNotification(
          userId: userId,
          title: '⏰ Cambio de Horario',
          message: '"$activityName" cambió de horario',
          type: 'schedule_change',
        );

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error enviando notificación de cambio: $e');
      return false;
    }
  }

  /// Crear notificación en base de datos para historial
  static Future<void> _createDatabaseNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await SupabaseService.client.from('notificaciones').insert({
        'user_id': userId,
        'titulo': title,
        'mensaje': message,
        'tipo': type,
        'leida': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error creando notificación en BD: $e');
    }
  }

  /// Enviar notificación personalizada
  static Future<bool> sendCustomNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'message': message,
          'data': data ?? {},
        },
      );

      if (response.status == 200) {
        print('✅ Notificación personalizada enviada con Firebase');

        await _createDatabaseNotification(
          userId: userId,
          title: title,
          message: message,
          type: 'custom',
        );

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error enviando notificación personalizada: $e');
      return false;
    }
  }
}
