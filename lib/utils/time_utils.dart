import 'package:intl/intl.dart';

/// Utilidades centralizadas para manejo de tiempo y fechas
class TimeUtils {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Compara dos strings de tiempo en formato HH:mm
  /// Retorna: -1 si time1 < time2, 0 si son iguales, 1 si time1 > time2
  static int compareTimeStrings(String time1, String time2) {
    try {
      final t1 = _parseTimeString(time1);
      final t2 = _parseTimeString(time2);
      return t1.compareTo(t2);
    } catch (e) {
      throw TimeUtilsException('Error al comparar tiempos: $time1, $time2 - $e');
    }
  }

  /// Formatea un string de tiempo al formato HH:mm
  static String formatTimeString(String time) {
    try {
      if (time.isEmpty) return '';
      
      // Si ya está en formato correcto, devolverlo
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
        return time;
      }
      
      // Si tiene segundos, eliminarlos
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]).toString().padLeft(2, '0');
          final minute = int.parse(parts[1]).toString().padLeft(2, '0');
          return '$hour:$minute';
        }
      }
      
      // Si es solo números, asumir formato HHMM
      if (RegExp(r'^\d{3,4}$').hasMatch(time)) {
        final timeStr = time.padLeft(4, '0');
        final hour = timeStr.substring(0, 2);
        final minute = timeStr.substring(2, 4);
        return '$hour:$minute';
      }
      
      throw TimeUtilsException('Formato de tiempo no reconocido: $time');
    } catch (e) {
      throw TimeUtilsException('Error al formatear tiempo: $time - $e');
    }
  }

  /// Verifica si dos rangos de tiempo se superponen
  static bool timeRangesOverlap(
    String start1, String end1,
    String start2, String end2,
  ) {
    try {
      final s1 = _parseTimeString(start1);
      final e1 = _parseTimeString(end1);
      final s2 = _parseTimeString(start2);
      final e2 = _parseTimeString(end2);

      return s1.isBefore(e2) && s2.isBefore(e1);
    } catch (e) {
      throw TimeUtilsException('Error al verificar superposición de rangos: $e');
    }
  }

  /// Convierte string de tiempo a DateTime (usando fecha actual)
  static DateTime timeStringToDateTime(String time) {
    try {
      final formattedTime = formatTimeString(time);
      final now = DateTime.now();
      final parts = formattedTime.split(':');
      
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      throw TimeUtilsException('Error al convertir tiempo a DateTime: $time - $e');
    }
  }

  /// Calcula la duración entre dos tiempos en minutos
  static int calculateDurationMinutes(String startTime, String endTime) {
    try {
      final start = timeStringToDateTime(startTime);
      final end = timeStringToDateTime(endTime);
      
      // Si el tiempo final es menor, asumir que es del día siguiente
      if (end.isBefore(start)) {
        final nextDayEnd = end.add(const Duration(days: 1));
        return nextDayEnd.difference(start).inMinutes;
      }
      
      return end.difference(start).inMinutes;
    } catch (e) {
      throw TimeUtilsException('Error al calcular duración: $startTime - $endTime - $e');
    }
  }

  /// Formatea una fecha al formato español
  static String formatDateSpanish(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (e) {
      throw TimeUtilsException('Error al formatear fecha: $date - $e');
    }
  }

  /// Formatea fecha y hora al formato español
  static String formatDateTimeSpanish(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (e) {
      throw TimeUtilsException('Error al formatear fecha y hora: $dateTime - $e');
    }
  }

  /// Convierte fecha a formato ISO (yyyy-MM-dd)
  static String dateToIsoString(DateTime date) {
    try {
      return _isoFormat.format(date);
    } catch (e) {
      throw TimeUtilsException('Error al convertir fecha a ISO: $date - $e');
    }
  }

  /// Obtiene el nombre del día de la semana en español
  static String getDayNameSpanish(DateTime date) {
    const dayNames = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 
      'Viernes', 'Sábado', 'Domingo'
    ];
    return dayNames[date.weekday - 1];
  }

  /// Obtiene el nombre del mes en español
  static String getMonthNameSpanish(DateTime date) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return monthNames[date.month - 1];
  }

  /// Verifica si una fecha está en el rango especificado
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
           date.isBefore(end.add(const Duration(days: 1)));
  }

  /// Obtiene el inicio del día para una fecha
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtiene el final del día para una fecha
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica si una fecha es mañana
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  /// Obtiene un string relativo para mostrar fechas (Hoy, Mañana, etc.)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) return 'Hoy';
    if (isTomorrow(date)) return 'Mañana';
    
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == -1) return 'Ayer';
    if (difference > 0 && difference <= 7) {
      return getDayNameSpanish(date);
    }
    
    return formatDateSpanish(date);
  }

  /// Método privado para parsear string de tiempo
  static DateTime _parseTimeString(String time) {
    final formattedTime = formatTimeString(time);
    final now = DateTime.now();
    final parts = formattedTime.split(':');
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Valida si un string de tiempo es válido
  static bool isValidTimeString(String time) {
    try {
      formatTimeString(time);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Añade minutos a un tiempo
  static String addMinutesToTime(String time, int minutes) {
    try {
      final dateTime = timeStringToDateTime(time);
      final newDateTime = dateTime.add(Duration(minutes: minutes));
      return _timeFormat.format(newDateTime);
    } catch (e) {
      throw TimeUtilsException('Error al añadir minutos: $time + $minutes - $e');
    }
  }

  /// Resta minutos a un tiempo
  static String subtractMinutesFromTime(String time, int minutes) {
    return addMinutesToTime(time, -minutes);
  }
}

/// Excepción personalizada para errores de utilidades de tiempo
class TimeUtilsException implements Exception {
  final String message;
  
  const TimeUtilsException(this.message);
  
  @override
  String toString() => 'TimeUtilsException: $message';
} 