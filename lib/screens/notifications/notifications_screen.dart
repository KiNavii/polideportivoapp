import 'package:flutter/material.dart';
import 'package:deportivov1/models/notification_model.dart';
import 'package:deportivov1/services/notification_service.dart';
import 'package:deportivov1/widgets/notification_widget.dart';
import 'package:deportivov1/core/service_locator.dart';

/// Pantalla principal de notificaciones
class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _allNotifications = [];
  List<AppNotification> _unreadNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize(widget.userId);
    } catch (e) {
      ServiceLocator.logger.error('Error al inicializar notificaciones', e);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      
      final notifications = await _notificationService.getUserNotifications(limit: 50);
      
      setState(() {
        _allNotifications = notifications;
        _unreadNotifications = notifications.where((n) => !n.leida).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar notificaciones: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      _showSuccessSnackBar('Todas las notificaciones marcadas como leídas');
    } catch (e) {
      _showErrorSnackBar('Error al marcar como leídas: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onNotificationTap(AppNotification notification) {
    // Navegar según el tipo de notificación
    switch (notification.tipo) {
      case NotificationType.reservation:
        _navigateToReservation(notification);
        break;
      case NotificationType.activity:
        _navigateToActivity(notification);
        break;
      case NotificationType.news:
        _navigateToNews(notification);
        break;
      case NotificationType.event:
        _navigateToEvent(notification);
        break;
      default:
        // Mostrar detalles de la notificación
        _showNotificationDetails(notification);
        break;
    }
  }

  void _navigateToReservation(AppNotification notification) {
    final reservationId = notification.data?['reservation_id'];
    if (reservationId != null) {
      // Navigator.pushNamed(context, '/reservation-details', arguments: reservationId);
      _showNotificationDetails(notification);
    }
  }

  void _navigateToActivity(AppNotification notification) {
    final activityId = notification.data?['activity_id'];
    if (activityId != null) {
      // Navigator.pushNamed(context, '/activity-details', arguments: activityId);
      _showNotificationDetails(notification);
    }
  }

  void _navigateToNews(AppNotification notification) {
    final newsId = notification.data?['news_id'];
    if (newsId != null) {
      // Navigator.pushNamed(context, '/news-details', arguments: newsId);
      _showNotificationDetails(notification);
    }
  }

  void _navigateToEvent(AppNotification notification) {
    final eventId = notification.data?['event_id'];
    if (eventId != null) {
      // Navigator.pushNamed(context, '/event-details', arguments: eventId);
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => NotificationDetailsDialog(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Todas',
              icon: Badge(
                label: Text(_allNotifications.length.toString()),
                child: const Icon(Icons.notifications),
              ),
            ),
            Tab(
              text: 'No leídas',
              icon: Badge(
                label: Text(_unreadNotifications.length.toString()),
                child: const Icon(Icons.notifications_active),
              ),
            ),
            Tab(
              text: 'Configuración',
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
            ),
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Todas las notificaciones
          _buildAllNotificationsTab(),
          
          // Tab 2: No leídas
          _buildUnreadNotificationsTab(),
          
          // Tab 3: Configuración
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _allNotifications.length,
        itemBuilder: (context, index) {
          final notification = _allNotifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onDismiss: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }

  Widget _buildUnreadNotificationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unreadNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes notificaciones sin leer',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '¡Estás al día!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _unreadNotifications.length,
        itemBuilder: (context, index) {
          final notification = _unreadNotifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onDismiss: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    return FutureBuilder<NotificationSettings>(
      future: _loadNotificationSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final settings = snapshot.data ?? NotificationSettings(
          id: 'default-${widget.userId}',
          userId: widget.userId,
          fechaActualizacion: DateTime.now(),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: NotificationSettingsWidget(
            settings: settings,
            onSettingsChanged: _saveNotificationSettings,
          ),
        );
      },
    );
  }

  Future<NotificationSettings> _loadNotificationSettings() async {
    try {
      // Aquí cargarías las configuraciones desde Supabase
      // Por ahora retornamos configuraciones por defecto
      return NotificationSettings(
        id: 'default-${widget.userId}',
        userId: widget.userId,
        fechaActualizacion: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error al cargar configuraciones: $e');
    }
  }

  Future<void> _saveNotificationSettings(NotificationSettings settings) async {
    try {
      // Aquí guardarías las configuraciones en Supabase
      ServiceLocator.logger.info('Configuraciones guardadas: ${settings.toJson()}');
      _showSuccessSnackBar('Configuración guardada');
    } catch (e) {
      _showErrorSnackBar('Error al guardar configuración: $e');
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      await _loadNotifications();
      _showSuccessSnackBar('Notificación eliminada');
    } catch (e) {
      _showErrorSnackBar('Error al eliminar notificación: $e');
    }
  }
}

/// Dialog para mostrar detalles de una notificación
class NotificationDetailsDialog extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsDialog({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notification.titulo,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.mensaje,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getTypeDisplayName(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (notification.data != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Datos adicionales:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification.data.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        if (!notification.leida)
          ElevatedButton(
            onPressed: () {
              NotificationService().markAsRead(notification.id);
              Navigator.of(context).pop();
            },
            child: const Text('Marcar como leída'),
          ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (notification.tipo) {
      case NotificationType.reservation:
        return Icons.calendar_today;
      case NotificationType.activity:
        return Icons.sports;
      case NotificationType.news:
        return Icons.article;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.general:
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor() {
    switch (notification.tipo) {
      case NotificationType.reservation:
        return Colors.blue;
      case NotificationType.activity:
        return Colors.green;
      case NotificationType.news:
        return Colors.orange;
      case NotificationType.event:
        return Colors.purple;
      case NotificationType.system:
        return Colors.blueGrey;
      case NotificationType.reminder:
        return Colors.red;
      case NotificationType.general:
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplayName() {
    switch (notification.tipo) {
      case NotificationType.reservation:
        return 'Reserva';
      case NotificationType.activity:
        return 'Actividad';
      case NotificationType.news:
        return 'Noticia';
      case NotificationType.event:
        return 'Evento';
      case NotificationType.system:
        return 'Sistema';
      case NotificationType.reminder:
        return 'Recordatorio';
      case NotificationType.general:
      default:
        return 'General';
    }
  }
} 