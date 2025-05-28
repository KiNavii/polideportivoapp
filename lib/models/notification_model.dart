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

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
  defaultPriority,
}

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

  // Getter para compatibilidad con código existente
  Map<String, dynamic>? get data => datos;

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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: _parseNotificationType(json['tipo']),
      prioridad: _parseNotificationPriority(json['prioridad']),
      datos: json['datos'] as Map<String, dynamic>?,
      leida: json['leida'] ?? false,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toIso8601String()),
      fechaLeida: json['fecha_leida'] != null ? DateTime.parse(json['fecha_leida']) : null,
      imagenUrl: json['imagen_url'],
      accionUrl: json['accion_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.toString().split('.').last,
      'prioridad': prioridad.toString().split('.').last,
      'datos': datos,
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_leida': fechaLeida?.toIso8601String(),
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
    switch (tipo) {
      case 'reservationConfirmed':
        return NotificationType.reservationConfirmed;
      case 'reservationCancelled':
        return NotificationType.reservationCancelled;
      case 'reservationReminder':
        return NotificationType.reservationReminder;
      case 'activityRegistered':
        return NotificationType.activityRegistered;
      case 'activityCancelled':
        return NotificationType.activityCancelled;
      case 'activityReminder':
        return NotificationType.activityReminder;
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventUpdated':
        return NotificationType.eventUpdated;
      case 'eventCancelled':
        return NotificationType.eventCancelled;
      case 'newsPublished':
        return NotificationType.newsPublished;
      case 'maintenanceScheduled':
        return NotificationType.maintenanceScheduled;
      case 'systemUpdate':
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
    switch (prioridad) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      case 'defaultPriority':
        return NotificationPriority.defaultPriority;
      default:
        return NotificationPriority.normal;
    }
  }
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
      quietHoursStart: json['quiet_hours_start'] != null 
          ? DateTime.parse(json['quiet_hours_start']) 
          : null,
      quietHoursEnd: json['quiet_hours_end'] != null 
          ? DateTime.parse(json['quiet_hours_end']) 
          : null,
      fechaActualizacion: DateTime.parse(
        json['fecha_actualizacion'] ?? DateTime.now().toIso8601String()
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
      reservationNotifications: reservationNotifications ?? this.reservationNotifications,
      activityNotifications: activityNotifications ?? this.activityNotifications,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      newsNotifications: newsNotifications ?? this.newsNotifications,
      maintenanceNotifications: maintenanceNotifications ?? this.maintenanceNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      pushNotifications: pushEnabled ?? pushNotifications ?? this.pushNotifications,
      emailNotifications: emailEnabled ?? emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
} 