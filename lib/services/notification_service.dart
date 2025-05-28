import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/cache_service.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:deportivov1/core/service_locator.dart';
import 'package:deportivov1/models/notification_model.dart';

/// Servicio completo de notificaciones para la aplicación
/// Integra Supabase Realtime, Firebase Push y notificaciones locales
class NotificationService {
  static NotificationService? _instance;
  static final LoggerService _logger = LoggerService();
  static final SupabaseClient _client = SupabaseService.client;
  
  // Plugins de notificaciones
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Streams para notificaciones en tiempo real
  final StreamController<AppNotification> _notificationController = 
      StreamController<AppNotification>.broadcast();
  final StreamController<int> _unreadCountController = 
      StreamController<int>.broadcast();
  
  // Suscripciones de Supabase
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _reservationsChannel;
  RealtimeChannel? _activitiesChannel;
  
  // Estado
  bool _isInitialized = false;
  String? _currentUserId;
  int _unreadCount = 0;

  NotificationService._();

  factory NotificationService() {
    _instance ??= NotificationService._();
    return _instance!;
  }

  /// Stream de notificaciones en tiempo real
  Stream<AppNotification> get notificationStream => _notificationController.stream;
  
  /// Stream del contador de notificaciones no leídas
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  
  /// Contador actual de notificaciones no leídas
  int get unreadCount => _unreadCount;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _logger.info('🔔 Inicializando servicio de notificaciones...');
      _currentUserId = userId;

      // 1. Configurar notificaciones locales
      await _initializeLocalNotifications();

      // 2. Configurar Firebase Push Notifications
      await _initializeFirebaseMessaging();

      // 3. Configurar Supabase Realtime
      await _initializeSupabaseRealtime();

      // 4. Cargar contador de no leídas
      await _loadUnreadCount();

      // 5. Registrar token FCM en Supabase
      await _registerFCMToken();

      _isInitialized = true;
      _logger.info('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      _logger.error('❌ Error al inicializar notificaciones', e);
      rethrow;
    }
  }

  /// Configura las notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _logger.info('📱 Notificaciones locales configuradas');
  }

  /// Configura Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Solicitar permisos
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.info('🔥 Permisos de Firebase concedidos');
    } else {
      _logger.warning('⚠️ Permisos de Firebase denegados');
    }

    // Configurar handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    _logger.info('🔥 Firebase Messaging configurado');
  }

  /// Configura Supabase Realtime para notificaciones
  Future<void> _initializeSupabaseRealtime() async {
    // Canal para notificaciones directas
    _notificationsChannel = _client
        .channel('notifications:$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'usuario_id',
            value: _currentUserId,
          ),
          callback: _handleRealtimeNotification,
        )
        .subscribe();

    // Canal para cambios en reservas (notificaciones automáticas)
    _reservationsChannel = _client
        .channel('reservations:$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'reservas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'usuario_id',
            value: _currentUserId,
          ),
          callback: _handleReservationChange,
        )
        .subscribe();

    // Canal para nuevas actividades
    _activitiesChannel = _client
        .channel('activities:all')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'actividades',
          callback: _handleNewActivity,
        )
        .subscribe();

    _logger.info('⚡ Supabase Realtime configurado');
  }

  /// Registra el token FCM en Supabase
  Future<void> _registerFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Debug: Mostrar token en consola
        print('TOKEN FCM REGISTRADO: $token');
        
        await _client
            .from('user_fcm_tokens')
            .upsert({
              'user_id': _currentUserId,
              'fcm_token': token,
              'platform': 'flutter',
              'is_active': true, // Asegurar que está activo
              // No incluir updated_at - se actualiza automáticamente con el trigger
            });
        
        _logger.info('📝 Token FCM registrado en Supabase');
      }
    } catch (e) {
      _logger.error('Error al registrar token FCM', e);
    }
  }

  /// Carga el contador de notificaciones no leídas
  Future<void> _loadUnreadCount() async {
    try {
      final response = await _client
          .from('notificaciones')
          .select('id')
          .eq('usuario_id', _currentUserId!)
          .eq('leida', false);

      _unreadCount = response.length;
      _unreadCountController.add(_unreadCount);
      
      _logger.debug('📊 Contador no leídas cargado: $_unreadCount');
    } catch (e) {
      _logger.error('Error al cargar contador no leídas', e);
    }
  }

  /// Envía una notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'deportivo_channel',
      'Deportivo Notifications',
      channelDescription: 'Notificaciones de la aplicación Deportivo',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    _logger.info('📱 Notificación local mostrada: $title');
  }

  /// Crea una notificación en la base de datos
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    try {
      final notificationData = {
        'usuario_id': userId,
        'titulo': title,
        'mensaje': message,
        'tipo': type.name,
        'data': data != null ? jsonEncode(data) : null,
        'leida': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('notificaciones')
          .insert(notificationData)
          .select()
          .single();

      final notification = AppNotification.fromJson(response);

      // Enviar push notification si está habilitado
      if (sendPush) {
        await _sendPushNotification(userId, title, message, data);
      }

      _logger.info('📝 Notificación creada: $title');
      return notification;
    } catch (e) {
      _logger.error('Error al crear notificación', e);
      rethrow;
    }
  }

  /// Envía notificación push a un usuario específico
  Future<void> _sendPushNotification(
    String userId,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Llamar a la función Edge de Firebase (ya configurada con credenciales)
      final response = await _client.functions.invoke('send-push-notification', body: {
        'user_id': userId,
        'title': title,
        'message': message,
        'data': data,
      });

      if (response.status == 200) {
        _logger.info('🚀 Push notification enviada con Firebase');
      } else {
        _logger.warning('⚠️ Push notification falló: ${response.status}');
      }
    } catch (e) {
      _logger.error('Error al enviar push notification', e);
      // Fallback: mostrar notificación local
      await showLocalNotification(
        title: title,
        body: message,
        payload: jsonEncode(data),
      );
    }
  }

  /// Método público para enviar notificación de prueba
  /// Útil para testing y debugging del sistema de notificaciones
  Future<void> sendTestNotification({
    String? userId,
    String title = 'Notificación de Prueba',
    String message = 'Esta es una notificación de prueba del sistema',
    Map<String, dynamic>? data,
  }) async {
    try {
      final targetUserId = userId ?? _currentUserId;
      if (targetUserId == null) {
        throw Exception('No hay usuario activo para enviar notificación');
      }

      // Crear notificación en la base de datos
      await createNotification(
        userId: targetUserId,
        title: title,
        message: message,
        type: NotificationType.system,
        data: data ?? {'test': true, 'timestamp': DateTime.now().toIso8601String()},
        sendPush: true,
      );

      _logger.info('📧 Notificación de prueba enviada a usuario: $targetUserId');
    } catch (e) {
      _logger.error('Error al enviar notificación de prueba', e);
      rethrow;
    }
  }

  /// Obtiene el token FCM actual del dispositivo
  /// Útil para debugging y verificación
  Future<String?> getCurrentFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('TOKEN FCM ACTUAL: $token');
        _logger.info('📱 Token FCM obtenido: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      _logger.error('Error al obtener token FCM', e);
      return null;
    }
  }

  /// Obtiene todas las notificaciones del usuario
  Future<List<AppNotification>> getUserNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final cacheKey = CacheService.generateKey('notifications', {
      'userId': _currentUserId,
      'limit': limit,
      'offset': offset,
    });

    final cached = CacheService.get<List<AppNotification>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client
          .from('notificaciones')
          .select()
          .eq('usuario_id', _currentUserId!)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final notifications = response
          .map((json) => AppNotification.fromJson(json))
          .toList();

      CacheService.set(cacheKey, notifications, ttl: const Duration(minutes: 2));
      
      return notifications;
    } catch (e) {
      _logger.error('Error al obtener notificaciones', e);
      throw NotificationServiceException('Error al obtener notificaciones: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificationId);

      // Actualizar contador
      if (_unreadCount > 0) {
        _unreadCount--;
        _unreadCountController.add(_unreadCount);
      }

      // Invalidar caché
      CacheService.removePattern('notifications');
      
      _logger.debug('✅ Notificación marcada como leída');
    } catch (e) {
      _logger.error('Error al marcar notificación como leída', e);
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      await _client
          .from('notificaciones')
          .update({'leida': true})
          .eq('usuario_id', _currentUserId!)
          .eq('leida', false);

      _unreadCount = 0;
      _unreadCountController.add(_unreadCount);

      // Invalidar caché
      CacheService.removePattern('notifications');
      
      _logger.info('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      _logger.error('Error al marcar todas como leídas', e);
    }
  }

  /// Elimina una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client
          .from('notificaciones')
          .delete()
          .eq('id', notificationId);

      // Invalidar caché
      CacheService.removePattern('notifications');
      
      _logger.info('🗑️ Notificación eliminada');
    } catch (e) {
      _logger.error('Error al eliminar notificación', e);
    }
  }

  /// Handlers para eventos de notificaciones

  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('👆 Notificación local tocada: ${response.payload}');
    // Aquí puedes navegar a pantallas específicas según el payload
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _logger.info('📱 Mensaje en primer plano: ${message.notification?.title}');
    
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Deportivo',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _logger.info('👆 Notificación push tocada: ${message.notification?.title}');
    // Navegar según los datos del mensaje
  }

  void _handleRealtimeNotification(PostgresChangePayload payload) {
    try {
      final notification = AppNotification.fromJson(payload.newRecord);
      
      // Emitir al stream
      _notificationController.add(notification);
      
      // Actualizar contador
      _unreadCount++;
      _unreadCountController.add(_unreadCount);
      
      // Mostrar notificación local
      showLocalNotification(
        title: notification.titulo,
        body: notification.mensaje,
        payload: notification.id,
      );
      
      _logger.info('⚡ Notificación en tiempo real recibida');
    } catch (e) {
      _logger.error('Error al procesar notificación en tiempo real', e);
    }
  }

  void _handleReservationChange(PostgresChangePayload payload) {
    try {
      final oldRecord = payload.oldRecord;
      final newRecord = payload.newRecord;
      
      if (oldRecord['estado'] != newRecord['estado']) {
        final newStatus = newRecord['estado'];
        String message = '';
        
        switch (newStatus) {
          case 'confirmada':
            message = 'Tu reserva ha sido confirmada';
            break;
          case 'cancelada':
            message = 'Tu reserva ha sido cancelada';
            break;
          case 'completada':
            message = 'Tu reserva ha sido completada';
            break;
        }
        
        if (message.isNotEmpty) {
          createNotification(
            userId: newRecord['usuario_id'],
            title: 'Estado de Reserva',
            message: message,
            type: NotificationType.reservation,
            data: {'reservation_id': newRecord['id']},
          );
        }
      }
    } catch (e) {
      _logger.error('Error al procesar cambio de reserva', e);
    }
  }

  void _handleNewActivity(PostgresChangePayload payload) {
    try {
      final activity = payload.newRecord;
      
      // Notificar a todos los usuarios sobre nueva actividad
      createNotification(
        userId: 'all', // Se manejará en el backend
        title: 'Nueva Actividad',
        message: 'Nueva actividad disponible: ${activity['nombre']}',
        type: NotificationType.activity,
        data: {'activity_id': activity['id']},
      );
    } catch (e) {
      _logger.error('Error al procesar nueva actividad', e);
    }
  }

  /// Limpia recursos y cierra conexiones
  Future<void> dispose() async {
    await _notificationsChannel?.unsubscribe();
    await _reservationsChannel?.unsubscribe();
    await _activitiesChannel?.unsubscribe();
    
    await _notificationController.close();
    await _unreadCountController.close();
    
    _isInitialized = false;
    _logger.info('🔔 Servicio de notificaciones cerrado');
  }
}

/// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  final logger = LoggerService();
  logger.info('📱 Mensaje en background: ${message.notification?.title}');
}

/// Excepción personalizada para errores del servicio de notificaciones
class NotificationServiceException implements Exception {
  final String message;
  
  const NotificationServiceException(this.message);
  
  @override
  String toString() => 'NotificationServiceException: $message';
} 