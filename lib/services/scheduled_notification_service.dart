import 'dart:async';
import 'package:deportivov1/services/automatic_notification_service.dart';

/// Servicio para manejar notificaciones programadas y recordatorios
class ScheduledNotificationService {
  static Timer? _reminderTimer;
  static bool _isRunning = false;

  /// Inicia el servicio de recordatorios automáticos
  static void startReminderService() {
    if (_isRunning) {
      print('⚠️ Servicio de recordatorios ya está ejecutándose');
      return;
    }

    print('🚀 Iniciando servicio de recordatorios automáticos...');
    _isRunning = true;

    // Ejecutar inmediatamente una vez
    _checkAndSendReminders();

    // Programar ejecución cada 6 horas
    _reminderTimer = Timer.periodic(
      const Duration(hours: 6),
      (timer) => _checkAndSendReminders(),
    );

    print('✅ Servicio de recordatorios iniciado (cada 6 horas)');
  }

  /// Detiene el servicio de recordatorios
  static void stopReminderService() {
    if (_reminderTimer != null) {
      _reminderTimer!.cancel();
      _reminderTimer = null;
    }
    _isRunning = false;
    print('🛑 Servicio de recordatorios detenido');
  }

  /// Verifica y envía recordatorios si es necesario
  static Future<void> _checkAndSendReminders() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;

      // Solo enviar recordatorios en horarios apropiados (9 AM - 9 PM)
      if (hour < 9 || hour > 21) {
        print('⏰ Fuera del horario de recordatorios (${hour}h)');
        return;
      }

      print('🔔 Verificando recordatorios de reservas...');
      
      final success = await AutomaticNotificationService.sendReservationReminders();
      
      if (success) {
        print('✅ Verificación de recordatorios completada');
      } else {
        print('❌ Error en verificación de recordatorios');
      }

    } catch (e) {
      print('❌ Error en servicio de recordatorios: $e');
    }
  }

  /// Envía recordatorio manual (para testing)
  static Future<void> sendManualReminder() async {
    print('🔔 Enviando recordatorio manual...');
    await _checkAndSendReminders();
  }

  /// Verifica si el servicio está ejecutándose
  static bool get isRunning => _isRunning;

  /// Programa un recordatorio específico para una reserva
  static void scheduleReservationReminder({
    required String reservationId,
    required DateTime reservationDateTime,
    required Duration reminderAdvance,
  }) {
    final reminderTime = reservationDateTime.subtract(reminderAdvance);
    final now = DateTime.now();

    if (reminderTime.isBefore(now)) {
      print('⚠️ Tiempo de recordatorio ya pasó para reserva $reservationId');
      return;
    }

    final delay = reminderTime.difference(now);
    
    print('⏰ Programando recordatorio para reserva $reservationId en ${delay.inHours}h ${delay.inMinutes % 60}m');

    Timer(delay, () async {
      print('🔔 Enviando recordatorio programado para reserva $reservationId');
      await AutomaticNotificationService.sendReservationReminders();
    });
  }

  /// Programa recordatorios para múltiples reservas
  static void scheduleMultipleReminders(List<Map<String, dynamic>> reservations) {
    for (final reservation in reservations) {
      try {
        final fecha = DateTime.parse(reservation['fecha']);
        final horaInicio = reservation['hora_inicio'] as String;
        
        // Parsear hora (formato HH:mm)
        final timeParts = horaInicio.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final reservationDateTime = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hour,
          minute,
        );

        // Programar recordatorio 24 horas antes
        scheduleReservationReminder(
          reservationId: reservation['id'].toString(),
          reservationDateTime: reservationDateTime,
          reminderAdvance: const Duration(hours: 24),
        );

      } catch (e) {
        print('❌ Error programando recordatorio para reserva ${reservation['id']}: $e');
      }
    }
  }
} 