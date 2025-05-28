import 'package:flutter/foundation.dart';
import 'package:deportivov1/services/notification_service.dart';
import 'package:deportivov1/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;
  String? _currentUserId;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de notificaciones para un usuario
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _currentUserId = userId;
      
      // Inicializar el servicio
      await _notificationService.initialize(userId);
      
      // Escuchar notificaciones en tiempo real
      _notificationService.notificationStream.listen((notification) {
        _notifications.insert(0, notification);
        notifyListeners();
      });
      
      // Escuchar cambios en el contador
      _notificationService.unreadCountStream.listen((count) {
        _unreadCount = count;
        notifyListeners();
      });
      
      // Cargar notificaciones existentes
      await loadNotifications();
      
      _isInitialized = true;
      notifyListeners();
      
      print('🔔 NotificationProvider inicializado para usuario: $userId');
    } catch (e) {
      print('❌ Error al inicializar NotificationProvider: $e');
    }
  }

  /// Carga las notificaciones del usuario
  Future<void> loadNotifications() async {
    try {
      _notifications = await _notificationService.getUserNotifications();
      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar notificaciones: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Actualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(leida: true);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error al marcar como leída: $e');
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Actualizar localmente
      _notifications = _notifications.map((n) => n.copyWith(leida: true)).toList();
      notifyListeners();
    } catch (e) {
      print('❌ Error al marcar todas como leídas: $e');
    }
  }

  /// Envía una notificación de prueba
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification(
        title: '🧪 Notificación de Prueba',
        message: 'Esta es una prueba del sistema de notificaciones push',
        data: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('📧 Notificación de prueba enviada');
    } catch (e) {
      print('❌ Error al enviar notificación de prueba: $e');
    }
  }

  /// Obtiene el token FCM actual
  Future<String?> getCurrentFCMToken() async {
    try {
      return await _notificationService.getCurrentFCMToken();
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Limpia el estado cuando el usuario se desconecta
  void dispose() {
    _notificationService.dispose();
    _notifications.clear();
    _unreadCount = 0;
    _isInitialized = false;
    _currentUserId = null;
    super.dispose();
  }
} 