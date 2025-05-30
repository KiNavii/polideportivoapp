enum NotificationType {
  reservationConfirmed,
  reservationCancelled,
  reservationReminder,
  activityRegistered,
  activityCancelled,
  activityReminder,
  eventCreated,
  eventUpdated,
  eventCancelled,
  newsPublished,
  maintenanceScheduled,
  systemUpdate,
  general,
  reservation,
  activity,
  news,
  event,
  system,
  reminder,
}

enum NotificationPriority { low, normal, high, urgent, defaultPriority }

class AppNotification {
  final String id;
  final String userId;
  final String titulo;
  final String mensaje;
  final NotificationType tipo;
  final NotificationPriority prioridad;
  final Map<String, dynamic>? datos;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaLeida;
  final String? imagenUrl;
  final String? accionUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.prioridad = NotificationPriority.normal,
    this.datos,
    this.leida = false,
    required this.fechaCreacion,
    this.fechaLeida,
    this.imagenUrl,
    this.accionUrl,
  });

  // Getters para compatibilidad con diferentes estructuras de BD
  Map<String, dynamic>? get data => datos;
  String get usuarioId => userId;
  DateTime get createdAt => fechaCreacion;
  DateTime? get readAt => fechaLeida;

  // Getter para mostrar tiempo transcurrido
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(fechaCreacion);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace un momento';
    }
  }

  // Getter para icono según tipo
  String get iconData {
    switch (tipo) {
      case NotificationType.reservationConfirmed:
      case NotificationType.reservation:
        return '📅';
      case NotificationType.reservationCancelled:
        return '❌';
      case NotificationType.reservationReminder:
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.activityRegistered:
      case NotificationType.activity:
        return '🏃';
      case NotificationType.activityCancelled:
        return '🚫';
      case NotificationType.activityReminder:
        return '🔔';
      case NotificationType.eventCreated:
      case NotificationType.event:
        return '🎪';
      case NotificationType.eventUpdated:
        return '📝';
      case NotificationType.eventCancelled:
        return '🚫';
      case NotificationType.newsPublished:
      case NotificationType.news:
        return '📰';
      case NotificationType.maintenanceScheduled:
        return '🔧';
      case NotificationType.systemUpdate:
      case NotificationType.system:
        return '⚙️';
      default:
        return 'ℹ️';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    try {
      return AppNotification(
        id: json['id']?.toString() ?? '',
        userId:
            json['user_id']?.toString() ?? json['usuario_id']?.toString() ?? '',
        titulo: json['titulo']?.toString() ?? '',
        mensaje: json['mensaje']?.toString() ?? '',
        tipo: _parseNotificationType(json['tipo']?.toString()),
        prioridad: _parseNotificationPriority(json['prioridad']?.toString()),
        datos:
            json['datos'] as Map<String, dynamic>? ??
            json['data'] as Map<String, dynamic>?,
        leida: json['leida'] == true || json['leida'] == 1,
        fechaCreacion: _parseDateTime(
          json['fecha_creacion'] ?? json['created_at'],
        ),
        fechaLeida: _parseDateTime(json['fecha_leida'] ?? json['read_at']),
        imagenUrl: json['imagen_url']?.toString(),
        accionUrl: json['accion_url']?.toString(),
      );
    } catch (e) {
      throw NotificationParseException('Error al parsear notificación: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'usuario_id': userId, // Compatibilidad
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.toString().split('.').last,
      'prioridad': prioridad.toString().split('.').last,
      'datos': datos,
      'data': datos, // Compatibilidad
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'created_at': fechaCreacion.toIso8601String(), // Compatibilidad
      'fecha_leida': fechaLeida?.toIso8601String(),
      'read_at': fechaLeida?.toIso8601String(), // Compatibilidad
      'imagen_url': imagenUrl,
      'accion_url': accionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? mensaje,
    NotificationType? tipo,
    NotificationPriority? prioridad,
    Map<String, dynamic>? datos,
    bool? leida,
    DateTime? fechaCreacion,
    DateTime? fechaLeida,
    String? imagenUrl,
    String? accionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      prioridad: prioridad ?? this.prioridad,
      datos: datos ?? this.datos,
      leida: leida ?? this.leida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaLeida: fechaLeida ?? this.fechaLeida,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      accionUrl: accionUrl ?? this.accionUrl,
    );
  }

  static NotificationType _parseNotificationType(String? tipo) {
    if (tipo == null) return NotificationType.general;

    switch (tipo.toLowerCase()) {
      case 'reservationconfirmed':
      case 'reservation_confirmed':
        return NotificationType.reservationConfirmed;
      case 'reservationcancelled':
      case 'reservation_cancelled':
        return NotificationType.reservationCancelled;
      case 'reservationreminder':
      case 'reservation_reminder':
        return NotificationType.reservationReminder;
      case 'activityregistered':
      case 'activity_registered':
        return NotificationType.activityRegistered;
      case 'activitycancelled':
      case 'activity_cancelled':
        return NotificationType.activityCancelled;
      case 'activityreminder':
      case 'activity_reminder':
        return NotificationType.activityReminder;
      case 'eventcreated':
      case 'event_created':
        return NotificationType.eventCreated;
      case 'eventupdated':
      case 'event_updated':
        return NotificationType.eventUpdated;
      case 'eventcancelled':
      case 'event_cancelled':
        return NotificationType.eventCancelled;
      case 'newspublished':
      case 'news_published':
        return NotificationType.newsPublished;
      case 'maintenancescheduled':
      case 'maintenance_scheduled':
        return NotificationType.maintenanceScheduled;
      case 'systemupdate':
      case 'system_update':
        return NotificationType.systemUpdate;
      case 'reservation':
        return NotificationType.reservation;
      case 'activity':
        return NotificationType.activity;
      case 'news':
        return NotificationType.news;
      case 'event':
        return NotificationType.event;
      case 'system':
        return NotificationType.system;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.general;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? prioridad) {
    if (prioridad == null) return NotificationPriority.normal;

    switch (prioridad.toLowerCase()) {
      case 'low':
      case 'baja':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
      case 'alta':
        return NotificationPriority.high;
      case 'urgent':
      case 'urgente':
        return NotificationPriority.urgent;
      case 'defaultpriority':
      case 'default_priority':
        return NotificationPriority.defaultPriority;
      default:
        return NotificationPriority.normal;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is DateTime) return dateValue;

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppNotification{id: $id, titulo: $titulo, tipo: $tipo, leida: $leida}';
  }
}

/// Excepción para errores de parseo de notificaciones
class NotificationParseException implements Exception {
  final String message;

  const NotificationParseException(this.message);

  @override
  String toString() => 'NotificationParseException: $message';
}

class NotificationSettings {
  final String id;
  final String userId;
  final bool reservationNotifications;
  final bool activityNotifications;
  final bool eventNotifications;
  final bool newsNotifications;
  final bool maintenanceNotifications;
  final bool systemNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final DateTime fechaActualizacion;

  NotificationSettings({
    required this.id,
    required this.userId,
    this.reservationNotifications = true,
    this.activityNotifications = true,
    this.eventNotifications = true,
    this.newsNotifications = true,
    this.maintenanceNotifications = true,
    this.systemNotifications = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.fechaActualizacion,
  });

  // Getters para compatibilidad con código existente
  bool get pushEnabled => pushNotifications;
  bool get emailEnabled => emailNotifications;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      reservationNotifications: json['reservation_notifications'] ?? true,
      activityNotifications: json['activity_notifications'] ?? true,
      eventNotifications: json['event_notifications'] ?? true,
      newsNotifications: json['news_notifications'] ?? true,
      maintenanceNotifications: json['maintenance_notifications'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? false,
      smsNotifications: json['sms_notifications'] ?? false,
      quietHoursStart:
          json['quiet_hours_start'] != null
              ? DateTime.parse(json['quiet_hours_start'])
              : null,
      quietHoursEnd:
          json['quiet_hours_end'] != null
              ? DateTime.parse(json['quiet_hours_end'])
              : null,
      fechaActualizacion: DateTime.parse(
        json['fecha_actualizacion'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reservation_notifications': reservationNotifications,
      'activity_notifications': activityNotifications,
      'event_notifications': eventNotifications,
      'news_notifications': newsNotifications,
      'maintenance_notifications': maintenanceNotifications,
      'system_notifications': systemNotifications,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'quiet_hours_start': quietHoursStart?.toIso8601String(),
      'quiet_hours_end': quietHoursEnd?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  NotificationSettings copyWith({
    String? id,
    String? userId,
    bool? reservationNotifications,
    bool? activityNotifications,
    bool? eventNotifications,
    bool? newsNotifications,
    bool? maintenanceNotifications,
    bool? systemNotifications,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    DateTime? fechaActualizacion,
    // Parámetros adicionales para compatibilidad
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reservationNotifications:
          reservationNotifications ?? this.reservationNotifications,
      activityNotifications:
          activityNotifications ?? this.activityNotifications,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      newsNotifications: newsNotifications ?? this.newsNotifications,
      maintenanceNotifications:
          maintenanceNotifications ?? this.maintenanceNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      pushNotifications:
          pushEnabled ?? pushNotifications ?? this.pushNotifications,
      emailNotifications:
          emailEnabled ?? emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
