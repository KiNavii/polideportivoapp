// MODELO ADAPTADO A TU ESTRUCTURA EXISTENTE
enum NotificationType {
  // Valores existentes del código
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
  // Valores adicionales para compatibilidad
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
  final String usuarioId; // Adaptado a tu estructura
  final String titulo;
  final String mensaje;
  final NotificationType tipo;
  final NotificationPriority prioridad;
  final Map<String, dynamic>? data; // Tu estructura usa 'data'
  final bool leida;
  final DateTime createdAt; // Tu estructura usa 'created_at'
  final DateTime? readAt; // Tu estructura usa 'read_at'

  AppNotification({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.prioridad = NotificationPriority.normal,
    this.data,
    this.leida = false,
    required this.createdAt,
    this.readAt,
  });

  // Getters para compatibilidad con código existente
  String get userId => usuarioId;
  Map<String, dynamic>? get datos => data;
  DateTime get fechaCreacion => createdAt;
  DateTime? get fechaLeida => readAt;

  // Getter para mostrar tiempo transcurrido
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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
      usuarioId: json['usuario_id'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: _parseNotificationType(json['tipo']),
      prioridad: _parseNotificationPriority(json['prioridad']),
      data: json['data'] as Map<String, dynamic>?,
      leida: json['leida'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.toString().split('.').last,
      'prioridad': prioridad?.toString().split('.').last ?? 'normal',
      'data': data,
      'leida': leida,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? mensaje,
    NotificationType? tipo,
    NotificationPriority? prioridad,
    Map<String, dynamic>? data,
    bool? leida,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      prioridad: prioridad ?? this.prioridad,
      data: data ?? this.data,
      leida: leida ?? this.leida,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
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

// Modelo para configuraciones (adaptado a tu estructura)
class NotificationSettings {
  final String id;
  final String usuarioId; // Adaptado a tu estructura
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
    required this.usuarioId,
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

  // Getters para compatibilidad
  String get userId => usuarioId;
  bool get pushEnabled => pushNotifications;
  bool get emailEnabled => emailNotifications;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
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
      'usuario_id': usuarioId,
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
    String? usuarioId,
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
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
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