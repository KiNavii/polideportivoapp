import 'package:flutter/material.dart';
import 'package:deportivov1/models/notification_model.dart';
import 'package:deportivov1/services/notification_service.dart';
import 'package:deportivov1/core/service_locator.dart';

/// Widget para mostrar una notificación individual
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: notification.leida ? 1 : 3,
        child: ListTile(
          leading: _buildLeadingIcon(),
          title: Text(
            notification.titulo,
            style: TextStyle(
              fontWeight: notification.leida ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.mensaje,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: notification.leida
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getTypeColor(),
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            if (!notification.leida) {
              NotificationService().markAsRead(notification.id);
            }
            onTap?.call();
          },
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 20,
      ),
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
}

/// Widget para mostrar el contador de notificaciones no leídas
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;

  const NotificationBadge({
    Key? key,
    required this.child,
    required this.count,
    this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget para mostrar lista de notificaciones con pull-to-refresh
class NotificationsList extends StatefulWidget {
  final String userId;
  final Function(AppNotification)? onNotificationTap;

  const NotificationsList({
    Key? key,
    required this.userId,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final notifications = await _notificationService.getUserNotifications();
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  void _deleteNotification(AppNotification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar notificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las notificaciones aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => widget.onNotificationTap?.call(notification),
            onDismiss: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }
}

/// Widget para el botón de notificaciones con badge
class NotificationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? iconColor;
  final double iconSize;

  const NotificationButton({
    Key? key,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().unreadCountStream,
      initialData: NotificationService().unreadCount,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return NotificationBadge(
          count: unreadCount,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              Icons.notifications,
              color: iconColor ?? Theme.of(context).iconTheme.color,
              size: iconSize,
            ),
          ),
        );
      },
    );
  }
}

/// Widget para configuración de notificaciones
class NotificationSettingsWidget extends StatefulWidget {
  final NotificationSettings settings;
  final Function(NotificationSettings) onSettingsChanged;

  const NotificationSettingsWidget({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSetting(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuración de Notificaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Notificaciones Push
        SwitchListTile(
          title: const Text('Notificaciones Push'),
          subtitle: const Text('Recibir notificaciones en el dispositivo'),
          value: _settings.pushEnabled,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(pushEnabled: value));
          },
        ),
        
        // Notificaciones por Email
        SwitchListTile(
          title: const Text('Notificaciones por Email'),
          subtitle: const Text('Recibir notificaciones por correo electrónico'),
          value: _settings.emailEnabled,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(emailEnabled: value));
          },
        ),
        
        const Divider(),
        
        const Text(
          'Tipos de Notificaciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Reservas
        SwitchListTile(
          title: const Text('Reservas'),
          subtitle: const Text('Cambios en el estado de tus reservas'),
          value: _settings.reservationNotifications,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(reservationNotifications: value));
          },
        ),
        
        // Actividades
        SwitchListTile(
          title: const Text('Actividades'),
          subtitle: const Text('Nuevas actividades y cambios'),
          value: _settings.activityNotifications,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(activityNotifications: value));
          },
        ),
        
        // Noticias
        SwitchListTile(
          title: const Text('Noticias'),
          subtitle: const Text('Nuevas noticias del polideportivo'),
          value: _settings.newsNotifications,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(newsNotifications: value));
          },
        ),
        
        // Eventos
        SwitchListTile(
          title: const Text('Eventos'),
          subtitle: const Text('Nuevos eventos y recordatorios'),
          value: _settings.eventNotifications,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(eventNotifications: value));
          },
        ),
        
        // Sistema
        SwitchListTile(
          title: const Text('Sistema'),
          subtitle: const Text('Notificaciones importantes del sistema'),
          value: _settings.systemNotifications,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(systemNotifications: value));
          },
        ),
        
        const Divider(),
        
        // Horario silencioso
        ListTile(
          title: const Text('Horario Silencioso'),
          subtitle: Text('${_settings.quietHoursStart} - ${_settings.quietHoursEnd}'),
          trailing: const Icon(Icons.access_time),
          onTap: () {
            // Aquí puedes implementar un selector de tiempo
            _showTimeRangePicker();
          },
        ),
      ],
    );
  }

  void _showTimeRangePicker() {
    // Implementación del selector de rango de tiempo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horario Silencioso'),
        content: const Text('Funcionalidad de selector de tiempo pendiente de implementar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Widget para probar notificaciones (solo para desarrollo)
/// Agregar temporalmente a cualquier pantalla para probar el sistema
class NotificationTestWidget extends StatelessWidget {
  final String? userId;

  const NotificationTestWidget({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Panel de Pruebas de Notificaciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Botón para obtener token FCM
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final token = await NotificationService().getCurrentFCMToken();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(token != null 
                          ? 'Token FCM obtenido (ver consola)' 
                          : 'Error al obtener token FCM'),
                        backgroundColor: token != null ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.token),
              label: const Text('Obtener Token FCM'),
            ),
            
            const SizedBox(height: 8),
            
            // Botón para enviar notificación de prueba
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService().sendTestNotification(
                    userId: userId,
                    title: 'Prueba ${DateTime.now().hour}:${DateTime.now().minute}',
                    message: 'Notificación de prueba enviada correctamente',
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación de prueba enviada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al enviar notificación: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Enviar Notificación de Prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón para verificar tokens en base de datos
            ElevatedButton.icon(
              onPressed: () {
                _showTokenInstructions(context);
              },
              icon: const Icon(Icons.info),
              label: const Text('Ver Instrucciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Instrucciones de Prueba'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Verificar Token en Base de Datos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('SELECT * FROM user_fcm_tokens WHERE user_id = \'TU-UUID\';'),
              SizedBox(height: 12),
              
              Text(
                '2. Verificar Notificaciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('SELECT * FROM notificaciones WHERE usuario_id = \'TU-UUID\' ORDER BY created_at DESC;'),
              SizedBox(height: 12),
              
              Text(
                '3. Obtener JWT Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Supabase.instance.client.currentSession?.accessToken'),
              SizedBox(height: 12),
              
              Text(
                '4. Probar Edge Function:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('POST /functions/v1/send-push-notification\n'
                   'Authorization: Bearer JWT_TOKEN\n'
                   'Content-Type: application/json\n\n'
                   '{\n'
                   '  "user_id": "UUID",\n'
                   '  "title": "Prueba",\n'
                   '  "message": "Mensaje de prueba"\n'
                   '}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
} 