import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/models/reservation_model.dart';
import 'package:deportivov1/models/activity_model.dart';

/// Servicio para manejar todas las notificaciones automáticas de la aplicación
class AutomaticNotificationService {
  static final _client = SupabaseService.client;

  // =====================================================
  // NOTIFICACIONES DE NOTICIAS (A TODOS LOS USUARIOS)
  // =====================================================

  /// Envía notificación push a todos los usuarios cuando se crea una noticia
  static Future<bool> notifyNewNews({
    required String newsId,
    required String title,
    required String content,
    required NewsCategory category,
    bool isHighlighted = false,
  }) async {
    try {
      print('📰 Enviando notificación de nueva noticia a todos los usuarios no administradores...');

      // Obtener todos los usuarios activos que NO sean administradores
      final usuariosActivos = await _client
          .from('usuarios')
          .select('id, email, nombre, apellidos, tipo_usuario')
          .eq('esta_activo', true)
          .eq('tipo_usuario', 'socio'); // Solo usuarios normales, no administradores

      if (usuariosActivos.isEmpty) {
        print('⚠️ No hay usuarios activos no administradores para notificar');
        return false;
      }

      print('👥 Usuarios activos no administradores encontrados: ${usuariosActivos.length}');

      // Preparar datos de la notificación
      final notificationTitle = isHighlighted 
          ? '🔥 Noticia Destacada: $title'
          : '📰 Nueva Noticia: $title';
      
      final notificationMessage = _truncateMessage(content, 100);
      
      final categoryEmoji = _getCategoryEmoji(category);
      final finalMessage = '$categoryEmoji $notificationMessage';

      // Crear notificaciones en BD para todos los usuarios
      // Como usuarios.id = auth.users.id, podemos usar directamente usuarios.id
      final notifications = usuariosActivos.map((usuario) => {
        'usuario_id': usuario['id'], // usuarios.id = auth.users.id
        'titulo': notificationTitle,
        'mensaje': finalMessage,
        'tipo': 'news',
        'data': {
          'news_id': newsId,
          'category': category.name,
          'is_highlighted': isHighlighted,
          'action': 'view_news',
        },
        'leida': false,
      }).toList();

      // Intentar insertar notificaciones con manejo de errores mejorado
      try {
        await _client.from('notificaciones').insert(notifications);
        print('✅ Notificaciones creadas en BD: ${notifications.length}');
      } catch (e) {
        print('❌ Error insertando notificaciones en BD: $e');
        print('🔍 Primer usuario de ejemplo: ${usuariosActivos.first}');
        // Continuar con el envío de push notifications aunque falle la BD
      }

      // Enviar notificaciones push a todos los usuarios
      int successCount = 0;
      for (final usuario in usuariosActivos) {
        final success = await _sendPushToUser(
          userId: usuario['id'], // usuarios.id = auth.users.id
          title: notificationTitle,
          message: finalMessage,
          data: {
            'type': 'news',
            'news_id': newsId,
            'category': category.name,
            'action': 'view_news',
          },
        );
        if (success) successCount++;
      }

      print('🚀 Notificaciones push enviadas: $successCount/${usuariosActivos.length}');
      print('📊 Resumen: ${usuariosActivos.length} usuarios no administradores notificados');
      return true;

    } catch (e) {
      print('❌ Error enviando notificación de noticia: $e');
      return false;
    }
  }

  // =====================================================
  // RECORDATORIOS DE RESERVAS
  // =====================================================

  /// Envía recordatorio de reserva próxima (llamar desde cron job)
  static Future<bool> sendReservationReminders() async {
    try {
      print('⏰ Buscando reservas para recordatorios...');

      // Buscar reservas confirmadas para mañana
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().split('T')[0];

      final reservations = await _client
          .from('reservas')
          .select('''
            id, usuario_id, fecha, hora_inicio, hora_fin, comentario,
            instalaciones(nombre),
            pistas(nombre, numero),
            usuarios(nombre, apellidos, email)
          ''')
          .eq('estado', 'confirmada')
          .eq('fecha', tomorrowStr);

      if (reservations.isEmpty) {
        print('📅 No hay reservas para mañana');
        return true;
      }

      print('📋 Reservas encontradas: ${reservations.length}');

      int successCount = 0;
      for (final reservation in reservations) {
        final success = await _sendReservationReminder(reservation);
        if (success) successCount++;
      }

      print('✅ Recordatorios enviados: $successCount/${reservations.length}');
      return true;

    } catch (e) {
      print('❌ Error enviando recordatorios de reservas: $e');
      return false;
    }
  }

  /// Envía recordatorio individual de reserva
  static Future<bool> _sendReservationReminder(Map<String, dynamic> reservation) async {
    try {
      final userId = reservation['usuario_id'];
      final fecha = reservation['fecha'];
      final horaInicio = reservation['hora_inicio'];
      final horaFin = reservation['hora_fin'];
      final instalacion = reservation['instalaciones']?['nombre'] ?? 'Instalación';
      final pista = reservation['pistas']?['nombre'] ?? 
                   (reservation['pistas']?['numero'] != null 
                    ? 'Pista ${reservation['pistas']['numero']}' 
                    : null);

      final title = '⏰ Recordatorio de Reserva';
      final message = pista != null
          ? 'Mañana tienes reservado $instalacion - $pista de $horaInicio a $horaFin'
          : 'Mañana tienes reservado $instalacion de $horaInicio a $horaFin';

      // Crear notificación en BD
      await _client.from('notificaciones').insert({
        'usuario_id': userId,
        'titulo': title,
        'mensaje': message,
        'tipo': 'reminder',
        'data': {
          'reservation_id': reservation['id'],
          'date': fecha,
          'start_time': horaInicio,
          'end_time': horaFin,
          'installation': instalacion,
          'court': pista,
          'action': 'view_reservation',
        },
        'leida': false,
      });

      // Enviar push
      final pushSuccess = await _sendPushToUser(
        userId: userId,
        title: title,
        message: message,
        data: {
          'type': 'reminder',
          'reservation_id': reservation['id'],
          'action': 'view_reservation',
        },
      );

      return pushSuccess;

    } catch (e) {
      print('❌ Error enviando recordatorio individual: $e');
      return false;
    }
  }

  // =====================================================
  // NOTIFICACIONES DE INSCRIPCIONES ACEPTADAS
  // =====================================================

  /// Notifica cuando se acepta una inscripción a actividad
  static Future<bool> notifyInscriptionAccepted({
    required String inscriptionId,
    required String userId,
    required String activityName,
    String? startDate,
    String? schedule,
  }) async {
    try {
      print('✅ Notificando inscripción aceptada...');

      final title = '🎉 ¡Inscripción Aceptada!';
      final message = schedule != null
          ? 'Tu inscripción a "$activityName" ha sido aceptada. Horario: $schedule'
          : 'Tu inscripción a "$activityName" ha sido aceptada. ¡Ya puedes participar!';

      // Crear notificación en BD
      await _client.from('notificaciones').insert({
        'usuario_id': userId,
        'titulo': title,
        'mensaje': message,
        'tipo': 'activity',
        'data': {
          'inscription_id': inscriptionId,
          'activity_name': activityName,
          'status': 'accepted',
          'start_date': startDate,
          'schedule': schedule,
          'action': 'view_activity',
        },
        'leida': false,
      });

      // Enviar push
      final pushSuccess = await _sendPushToUser(
        userId: userId,
        title: title,
        message: message,
        data: {
          'type': 'activity',
          'inscription_id': inscriptionId,
          'status': 'accepted',
          'action': 'view_activity',
        },
      );

      print(pushSuccess ? '✅ Notificación enviada' : '❌ Error enviando push');
      return pushSuccess;

    } catch (e) {
      print('❌ Error notificando inscripción aceptada: $e');
      return false;
    }
  }

  /// Notifica cuando se rechaza una inscripción a actividad
  static Future<bool> notifyInscriptionRejected({
    required String inscriptionId,
    required String userId,
    required String activityName,
    String? reason,
  }) async {
    try {
      print('❌ Notificando inscripción rechazada...');

      final title = '😔 Inscripción No Aceptada';
      final message = reason != null
          ? 'Tu inscripción a "$activityName" no fue aceptada. Motivo: $reason'
          : 'Tu inscripción a "$activityName" no fue aceptada. Puedes intentar con otras actividades.';

      // Crear notificación en BD
      await _client.from('notificaciones').insert({
        'usuario_id': userId,
        'titulo': title,
        'mensaje': message,
        'tipo': 'activity',
        'data': {
          'inscription_id': inscriptionId,
          'activity_name': activityName,
          'status': 'rejected',
          'reason': reason,
          'action': 'view_activities',
        },
        'leida': false,
      });

      // Enviar push
      final pushSuccess = await _sendPushToUser(
        userId: userId,
        title: title,
        message: message,
        data: {
          'type': 'activity',
          'inscription_id': inscriptionId,
          'status': 'rejected',
          'action': 'view_activities',
        },
      );

      print(pushSuccess ? '✅ Notificación enviada' : '❌ Error enviando push');
      return pushSuccess;

    } catch (e) {
      print('❌ Error notificando inscripción rechazada: $e');
      return false;
    }
  }

  // =====================================================
  // NOTIFICACIONES DE NUEVAS ACTIVIDADES
  // =====================================================

  /// Notifica a todos los usuarios cuando se crea una nueva actividad
  static Future<bool> notifyNewActivity({
    required String activityId,
    required String activityName,
    required String description,
    required DateTime startDate,
    String? schedule,
    int? maxPlaces,
  }) async {
    try {
      print('🏃‍♂️ Notificando nueva actividad a todos los usuarios...');

      // Obtener todos los usuarios activos
      final users = await _client
          .from('usuarios')
          .select('id, email, nombre')
          .eq('esta_activo', true);

      if (users.isEmpty) {
        print('⚠️ No hay usuarios activos para notificar');
        return false;
      }

      final title = '🆕 Nueva Actividad Disponible';
      final message = maxPlaces != null
          ? '$activityName - $maxPlaces plazas disponibles. ¡Inscríbete ya!'
          : '$activityName - ¡Nueva actividad disponible para inscribirse!';

      // Crear notificaciones en BD para todos los usuarios
      final notifications = users.map((user) => {
        'usuario_id': user['id'], // Usar el id de la tabla usuarios
        'titulo': title,
        'mensaje': message,
        'tipo': 'activity',
        'data': {
          'activity_id': activityId,
          'activity_name': activityName,
          'description': description,
          'start_date': startDate.toIso8601String(),
          'schedule': schedule,
          'max_places': maxPlaces,
          'action': 'view_activity',
        },
        'leida': false,
      }).toList();

      await _client.from('notificaciones').insert(notifications);
      print('✅ Notificaciones creadas en BD: ${notifications.length}');

      // Enviar notificaciones push
      int successCount = 0;
      for (final user in users) {
        final success = await _sendPushToUser(
          userId: user['id'], // Usar el id de la tabla usuarios
          title: title,
          message: message,
          data: {
            'type': 'activity',
            'activity_id': activityId,
            'action': 'view_activity',
          },
        );
        if (success) successCount++;
      }

      print('🚀 Notificaciones push enviadas: $successCount/${users.length}');
      return true;

    } catch (e) {
      print('❌ Error notificando nueva actividad: $e');
      return false;
    }
  }

  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================

  /// Envía notificación push a un usuario específico
  static Future<bool> _sendPushToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'message': message,
          'data': data ?? {},
        },
      );

      return response.status == 200;
    } catch (e) {
      print('❌ Error enviando push a usuario $userId: $e');
      return false;
    }
  }

  /// Obtiene emoji según categoría de noticia
  static String _getCategoryEmoji(NewsCategory category) {
    switch (category) {
      case NewsCategory.evento:
        return '🎪';
      case NewsCategory.noticia:
        return '📰';
      case NewsCategory.mantenimiento:
        return '🔧';
      case NewsCategory.promocion:
        return '🎁';
      case NewsCategory.aviso:
        return '⚠️';
      case NewsCategory.informativa:
        return 'ℹ️';
      default:
        return '📰';
    }
  }

  /// Trunca mensaje a longitud específica
  static String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  /// Formatea fecha para mostrar
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Formatea rango de fechas
  static String _formatDateRange(DateTime start, DateTime end) {
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  // =====================================================
  // NOTIFICACIONES DE MANTENIMIENTO/CIERRE
  // =====================================================

  /// Notifica sobre cierres o mantenimiento de instalaciones
  static Future<bool> notifyMaintenanceOrClosure({
    required String title,
    required String message,
    required DateTime startDate,
    DateTime? endDate,
    List<String>? affectedInstallations,
  }) async {
    try {
      print('🔧 Notificando mantenimiento/cierre...');

      // Obtener todos los usuarios activos que NO sean administradores
      final users = await _client
          .from('usuarios')
          .select('id, email, nombre, tipo_usuario')
          .eq('esta_activo', true)
          .eq('tipo_usuario', 'socio'); // Solo usuarios normales, no administradores

      if (users.isEmpty) {
        print('⚠️ No hay usuarios activos para notificar');
        return false;
      }

      final notificationTitle = '⚠️ $title';
      final notificationMessage = endDate != null
          ? '$message (${_formatDateRange(startDate, endDate)})'
          : '$message (desde ${_formatDate(startDate)})';

      // Crear notificaciones en BD
      final notifications = users.map((user) => {
        'usuario_id': user['id'], // usuarios.id = auth.users.id
        'titulo': notificationTitle,
        'mensaje': notificationMessage,
        'tipo': 'system',
        'data': {
          'maintenance_title': title,
          'maintenance_message': message,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'affected_installations': affectedInstallations,
          'action': 'view_info',
        },
        'leida': false,
      }).toList();

      await _client.from('notificaciones').insert(notifications);

      // Enviar push notifications
      int successCount = 0;
      for (final user in users) {
        final success = await _sendPushToUser(
          userId: user['id'], // usuarios.id = auth.users.id
          title: notificationTitle,
          message: notificationMessage,
          data: {
            'type': 'system',
            'action': 'view_info',
          },
        );
        if (success) successCount++;
      }

      print('🚀 Notificaciones de mantenimiento enviadas: $successCount/${users.length}');
      return true;

    } catch (e) {
      print('❌ Error notificando mantenimiento: $e');
      return false;
    }
  }
} 