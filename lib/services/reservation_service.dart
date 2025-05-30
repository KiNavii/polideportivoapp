import 'package:deportivov1/models/reservation_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/automatic_notification_service.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationService {
  static final SupabaseClient _client = SupabaseService.client;
  static final LoggerService _logger = LoggerService();

  // =====================================================
  // MÉTODOS PRINCIPALES DE RESERVAS
  // =====================================================

  // Obtener reservas de un usuario específico
  static Future<List<Reservation>> getUserReservations(
    String userId, {
    int limit = 20,
  }) async {
    if (userId.isEmpty) {
      throw ReservationServiceException('ID de usuario no puede estar vacío');
    }

    try {
      _logger.info('Obteniendo reservas del usuario: $userId (limit: $limit)');

      final response = await _client
          .from('reservas')
          .select('''
            *, 
            instalaciones(nombre), 
            pistas(nombre, numero),
            usuarios(nombre, apellidos)
          ''')
          .eq('usuario_id', userId)
          .order('fecha', ascending: false)
          .limit(limit);

      List<Reservation> reservations = [];
      for (var data in response) {
        try {
          reservations.add(Reservation.fromJson(data));
        } catch (e) {
          _logger.warning(
            'Error al procesar reserva individual del usuario',
            e,
          );
          // Continuar con la siguiente reserva
        }
      }

      _logger.info('✅ Reservas del usuario obtenidas: ${reservations.length}');
      return reservations;
    } catch (e) {
      _logger.error('Error al obtener reservas del usuario: $userId', e);
      throw ReservationServiceException(
        'Error al obtener reservas del usuario: $e',
      );
    }
  }

  // Obtener reservas activas (confirmadas y futuras)
  static Future<List<Reservation>> getActiveReservations({
    int limit = 20,
  }) async {
    try {
      _logger.info('Obteniendo reservas activas (limit: $limit)');

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('reservas')
          .select('''
            *, 
            instalaciones(nombre), 
            pistas(nombre, numero),
            usuarios(nombre, apellidos)
          ''')
          .eq('estado', 'confirmada')
          .gte('fecha', today)
          .order('fecha', ascending: true)
          .limit(limit);

      List<Reservation> reservations = [];
      for (var data in response) {
        try {
          reservations.add(Reservation.fromJson(data));
        } catch (e) {
          _logger.warning('Error al procesar reserva activa individual', e);
          // Continuar con la siguiente reserva
        }
      }

      _logger.info('✅ Reservas activas obtenidas: ${reservations.length}');
      return reservations;
    } catch (e) {
      _logger.error('Error al obtener reservas activas', e);
      throw ReservationServiceException(
        'Error al obtener reservas activas: $e',
      );
    }
  }

  // Obtener reservas históricas (pasadas)
  static Future<List<Reservation>> getHistoricalReservations(
    String userId, {
    int limit = 20,
  }) async {
    if (userId.isEmpty) {
      throw ReservationServiceException('ID de usuario no puede estar vacío');
    }

    try {
      _logger.info(
        'Obteniendo reservas históricas del usuario: $userId (limit: $limit)',
      );

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('reservas')
          .select('''
            *, 
            instalaciones(nombre), 
            pistas(nombre, numero),
            usuarios(nombre, apellidos)
          ''')
          .eq('usuario_id', userId)
          .lt('fecha', today)
          .order('fecha', ascending: false)
          .limit(limit);

      List<Reservation> reservations = [];
      for (var data in response) {
        try {
          reservations.add(Reservation.fromJson(data));
        } catch (e) {
          _logger.warning('Error al procesar reserva histórica individual', e);
          // Continuar con la siguiente reserva
        }
      }

      _logger.info('✅ Reservas históricas obtenidas: ${reservations.length}');
      return reservations;
    } catch (e) {
      _logger.error(
        'Error al obtener reservas históricas del usuario: $userId',
        e,
      );
      throw ReservationServiceException(
        'Error al obtener reservas históricas: $e',
      );
    }
  }

  // Expose the client for direct use
  static SupabaseClient getClient() {
    return _client;
  }

  // Constantes para estado de reservas
  static const String ESTADO_PENDIENTE = 'pendiente';
  static const String ESTADO_CONFIRMADA = 'confirmada';
  static const String ESTADO_CANCELADA = 'cancelada';
  static const String ESTADO_COMPLETADA = 'completada';

  // Crear una nueva reserva
  static Future<bool> createReservation({
    required String userId,
    required String installationId,
    String? courtId, // Pista (opcional)
    required DateTime date,
    required String startTime,
    required String endTime,
    String? comment,
  }) async {
    try {
      // Verificar disponibilidad
      final isAvailable =
          courtId != null
              ? await isCourtAvailable(
                installationId: installationId,
                courtId: courtId,
                date: date,
                startTime: startTime,
                endTime: endTime,
              )
              : await checkAvailability(
                installationId: installationId,
                date: date,
                startTime: startTime,
                endTime: endTime,
              );

      if (!isAvailable) {
        print('La instalación o pista no está disponible en este horario');
        return false;
      }

      // Crear la reserva
      final reservation = {
        'usuario_id': userId,
        'instalacion_id': installationId,
        'fecha': date.toIso8601String().split('T')[0],
        'hora_inicio': startTime,
        'hora_fin': endTime,
        'estado': ESTADO_CONFIRMADA,
      };

      // Añadir la pista si se ha proporcionado
      if (courtId != null) {
        reservation['pista_id'] = courtId;
      }

      // Añadir comentario si se ha proporcionado
      if (comment != null) {
        reservation['notas'] = comment;
      }

      final response =
          await _client.from('reservas').insert(reservation).select();

      print('Reservation created successfully: $response');
      return true;
    } catch (e) {
      print('Error al crear reserva: $e');
      return false;
    }
  }

  // Cancelar una reserva
  static Future<bool> cancelReservation(String reservationId) async {
    try {
      await _client
          .from('reservas')
          .update({'estado': ESTADO_CANCELADA})
          .eq('id', reservationId);

      return true;
    } catch (e) {
      print('Error al cancelar reserva: $e');
      return false;
    }
  }

  // Comprobar disponibilidad de una instalación en una fecha y horario
  static Future<bool> checkAvailability({
    required String installationId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Buscar reservas que se solapen para esa instalación
      final reservations = await _client
          .from('reservas')
          .select()
          .eq('fecha', dateStr)
          .eq('instalacion_id', installationId)
          .eq('estado', ESTADO_CONFIRMADA); // Solo reservas confirmadas

      // Verificar si hay solapamiento de horarios
      for (var reservation in reservations) {
        String reservationStart = reservation['hora_inicio'];
        String reservationEnd = reservation['hora_fin'];

        bool overlap =
            !(_compareTimeStrings(startTime, reservationEnd) >= 0 ||
                _compareTimeStrings(endTime, reservationStart) <= 0);

        if (overlap) {
          return false; // No está disponible
        }
      }

      return true; // Está disponible
    } catch (e) {
      print('Error al comprobar disponibilidad: $e');
      return false;
    }
  }

  // Verificar si una pista específica está disponible
  static Future<bool> isCourtAvailable({
    required String installationId,
    required String courtId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Primero verificar si la instalación completa está disponible
      final installationAvailable = await checkAvailability(
        installationId: installationId,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );

      if (!installationAvailable) {
        return false; // La instalación completa está reservada
      }

      // Buscar reservas para esta pista específica
      final dateStr = date.toIso8601String().split('T')[0];
      final reservations = await _client
          .from('reservas')
          .select()
          .eq('fecha', dateStr)
          .eq('pista_id', courtId)
          .eq('estado', ESTADO_CONFIRMADA); // Solo reservas confirmadas

      // Verificar si hay solapamiento de horarios
      for (var reservation in reservations) {
        String reservationStart = reservation['hora_inicio'];
        String reservationEnd = reservation['hora_fin'];

        bool overlap =
            !(_compareTimeStrings(startTime, reservationEnd) >= 0 ||
                _compareTimeStrings(endTime, reservationStart) <= 0);

        if (overlap) {
          return false; // No está disponible
        }
      }

      return true; // Está disponible
    } catch (e) {
      print('Error al comprobar disponibilidad de pista: $e');
      return false;
    }
  }

  // Función auxiliar para comparar strings de hora (HH:MM)
  static int _compareTimeStrings(String time1, String time2) {
    // Convertir a horas y minutos
    List<int> parts1 = time1.split(':').map((e) => int.parse(e)).toList();
    List<int> parts2 = time2.split(':').map((e) => int.parse(e)).toList();

    // Comparar horas
    if (parts1[0] != parts2[0]) {
      return parts1[0].compareTo(parts2[0]);
    }

    // Si las horas son iguales, comparar minutos
    return parts1[1].compareTo(parts2[1]);
  }

  // Método para debug - Obtener estructura de la tabla reservas
  static Future<void> debugReservasTable() async {
    try {
      // Ejecutar una consulta simple para ver qué columnas están disponibles en la respuesta
      final response = await _client.from('reservas').select().limit(1);

      if (response.isNotEmpty) {
        print('Estructura de la tabla reservas:');
        print('Columnas disponibles: ${response[0].keys.toList()}');
        print('Muestra de datos: ${response[0]}');
      } else {
        print(
          'No hay registros en la tabla reservas para analizar su estructura',
        );

        // Intentar obtener la definición de la tabla
        final definition = await _client.rpc(
          'get_table_definition',
          params: {'table_name': 'reservas'},
        );
        print('Definición de tabla: $definition');
      }
    } catch (e) {
      print('Error al obtener estructura de tabla reservas: $e');
    }
  }

  // Obtener reservas por ID de pista y fecha
  static Future<List<Reservation>> getReservationsByCourtAndDate({
    required String courtId,
    required DateTime date,
  }) async {
    try {
      // Formatear la fecha para la consulta
      final String formattedDate = date.toIso8601String().split('T')[0];

      // Consultar reservas para esta pista en esta fecha usando Supabase
      final reservations = await _client
          .from('reservas')
          .select('*')
          .eq('pista_id', courtId)
          .eq('fecha', formattedDate)
          .or('estado.eq.confirmada,estado.eq.pendiente')
          .order('hora_inicio');

      // Convertir resultados a objetos Reservation
      List<Reservation> result = [];
      for (var data in reservations) {
        try {
          // Parsear la fecha
          DateTime fecha = DateTime.parse(data['fecha']);

          // Determinar el estado de la reserva
          ReservationStatus estado;
          String estadoString = data['estado'] ?? 'pendiente';

          switch (estadoString) {
            case 'confirmada':
              estado = ReservationStatus.confirmada;
              break;
            case 'completada':
              estado = ReservationStatus.completada;
              break;
            case 'cancelada':
              estado = ReservationStatus.cancelada;
              break;
            default:
              estado = ReservationStatus.pendiente;
          }

          result.add(
            Reservation(
              id: data['id'],
              usuarioId: data['usuario_id'] ?? '',
              instalacionId: data['instalacion_id'] ?? '',
              pistaId: data['pista_id'] ?? '',
              fecha: fecha,
              horaInicio: data['hora_inicio'] ?? '',
              horaFin: data['hora_fin'] ?? '',
              estado: estado,
            ),
          );
        } catch (e) {
          print('Error al procesar reserva individual: $e');
        }
      }

      return result;
    } catch (e) {
      print('Error al obtener reservas por pista y fecha: $e');
      return [];
    }
  }

  // Método para actualizar el estado de las reservas completadas
  static Future<void> updateCompletedReservations() async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Actualizar reservas que ya han pasado
      await _client
          .from('reservas')
          .update({'estado': ESTADO_COMPLETADA})
          .eq('estado', ESTADO_CONFIRMADA)
          .or('fecha.lt.$today,fecha.eq.$today,hora_fin.lt.$currentTime');

      print('Reservas completadas actualizadas correctamente');
    } catch (e) {
      print('Error al actualizar reservas completadas: $e');
    }
  }

  // Método para limpiar reservas antiguas
  static Future<void> cleanOldReservations() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final dateLimit = thirtyDaysAgo.toIso8601String().split('T')[0];

      // Eliminar reservas antiguas (más de 30 días) que no estén activas
      await _client
          .from('reservas')
          .delete()
          .lt('fecha', dateLimit)
          .neq('estado', ESTADO_CONFIRMADA);

      print('Reservas antiguas limpiadas correctamente');
    } catch (e) {
      print('Error al limpiar reservas antiguas: $e');
    }
  }
}

/// Excepción personalizada para errores del servicio de reservas
class ReservationServiceException implements Exception {
  final String message;

  const ReservationServiceException(this.message);

  @override
  String toString() => 'ReservationServiceException: $message';
}
