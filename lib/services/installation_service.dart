import 'package:deportivov1/models/installation_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallationService {
  static final SupabaseClient _client = SupabaseService.client;

  // Constante para el estado de reservas
  static const String ESTADO_CONFIRMADA = 'confirmada';

  // Obtener todas las instalaciones
  static Future<List<Installation>> getAllInstallations({
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('instalaciones')
          .select()
          .order('nombre', ascending: true)
          .limit(limit);

      List<Installation> installations = [];
      for (var data in response) {
        try {
          installations.add(Installation.fromJson(data));
        } catch (e) {
          print('Error al procesar instalación individual: $e');
          // Continuar con la siguiente instalación
        }
      }
      return installations;
    } catch (e) {
      print('Error al obtener instalaciones: $e');
      return [];
    }
  }

  // Obtener todas las instalaciones como Map (para administración)
  static Future<List<Map<String, dynamic>>> getAllInstallationsAsMap({
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('instalaciones')
          .select()
          .order('nombre', ascending: true)
          .limit(limit);

      return response;
    } catch (e) {
      print('Error al obtener instalaciones: $e');
      return [];
    }
  }

  // Crear una nueva instalación
  static Future<bool> createInstallation({
    required String nombre,
    String? descripcion,
    String? imagenUrl, // Will be mapped to foto_url
    required String tipo,
    required bool disponible,
    int? capacidadMax,
    String? ubicacion,
    // Las siguientes propiedades se almacenarán en caracteristicas_json
    int? duracionMinReserva,
    int? duracionMaxReserva,
    String? horaApertura,
    String? horaCierre,
    List<String>? diasDisponibles,
    bool? tienePistas,
  }) async {
    try {
      print('Creando instalación: $nombre');

      // Crear el JSON de características
      Map<String, dynamic>? caracteristicasJson;
      if (duracionMinReserva != null ||
          duracionMaxReserva != null ||
          horaApertura != null ||
          horaCierre != null ||
          diasDisponibles != null ||
          tienePistas != null) {
        caracteristicasJson = Installation.createCaracteristicasJson(
          duracionMinReserva: duracionMinReserva,
          duracionMaxReserva: duracionMaxReserva,
          horaApertura: horaApertura,
          horaCierre: horaCierre,
          diasDisponibles: diasDisponibles,
          tienePistas: tienePistas,
        );
      }

      final data = {
        'nombre': nombre,
        'descripcion': descripcion,
        'foto_url': imagenUrl, // Map imagenUrl to foto_url
        'tipo': tipo,
        'ubicacion': ubicacion,
        'disponible': disponible,
        'capacidad_max': capacidadMax,
        'caracteristicas_json': caracteristicasJson,
      };

      print('Datos de instalación a insertar: $data');
      await _client.from('instalaciones').insert(data);
      print('Instalación creada exitosamente');
      return true;
    } catch (e) {
      print('Error al crear instalación: $e');
      return false;
    }
  }

  // Actualizar una instalación existente
  static Future<bool> updateInstallation({
    required String id,
    String? nombre,
    String? descripcion,
    String? imagenUrl, // Will be mapped to foto_url
    String? tipo,
    String? ubicacion,
    bool? disponible,
    int? capacidadMax,
    // Las siguientes propiedades se almacenarán en caracteristicas_json
    int? duracionMinReserva,
    int? duracionMaxReserva,
    String? horaApertura,
    String? horaCierre,
    List<String>? diasDisponibles,
    bool? tienePistas,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (nombre != null) data['nombre'] = nombre;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (imagenUrl != null) data['foto_url'] = imagenUrl;
      if (ubicacion != null) data['ubicacion'] = ubicacion;
      if (tipo != null) data['tipo'] = tipo;
      if (disponible != null) data['disponible'] = disponible;
      if (capacidadMax != null) data['capacidad_max'] = capacidadMax;

      // Si hay alguna propiedad para caracteristicas_json, primero obtener los valores actuales
      if (duracionMinReserva != null ||
          duracionMaxReserva != null ||
          horaApertura != null ||
          horaCierre != null ||
          diasDisponibles != null ||
          tienePistas != null) {
        // Obtener la instalación actual para extraer caracteristicas_json
        final currentInstallation = await getInstallationById(id);
        Map<String, dynamic> currentCaracteristicas =
            currentInstallation?.caracteristicasJson ?? {};

        // Actualizar con los nuevos valores
        if (duracionMinReserva != null)
          currentCaracteristicas['duracion_min_reserva'] = duracionMinReserva;
        if (duracionMaxReserva != null)
          currentCaracteristicas['duracion_max_reserva'] = duracionMaxReserva;
        if (horaApertura != null)
          currentCaracteristicas['hora_apertura'] = horaApertura;
        if (horaCierre != null)
          currentCaracteristicas['hora_cierre'] = horaCierre;
        if (diasDisponibles != null)
          currentCaracteristicas['dias_disponibles'] = diasDisponibles;
        if (tienePistas != null)
          currentCaracteristicas['tiene_pistas'] = tienePistas;

        data['caracteristicas_json'] = currentCaracteristicas;
      }

      if (data.isEmpty) return true; // No hay cambios que guardar

      print('Actualizando instalación ID $id con datos: $data');
      await _client.from('instalaciones').update(data).eq('id', id);
      print('Instalación actualizada exitosamente');
      return true;
    } catch (e) {
      print('Error al actualizar instalación: $e');
      return false;
    }
  }

  // Eliminar una instalación
  static Future<bool> deleteInstallation(String id) async {
    try {
      await _client.from('instalaciones').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar instalación: $e');
      return false;
    }
  }

  // Obtener instalaciones por tipo
  static Future<List<Installation>> getInstallationsByType(
    String type, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('instalaciones')
          .select()
          .eq('tipo', type)
          .order('nombre', ascending: true)
          .limit(limit);

      List<Installation> installations = [];
      for (var data in response) {
        try {
          installations.add(Installation.fromJson(data));
        } catch (e) {
          print('Error al procesar instalación individual: $e');
          // Continuar con la siguiente instalación
        }
      }
      return installations;
    } catch (e) {
      print('Error al obtener instalaciones por tipo: $e');
      return [];
    }
  }

  // Obtener instalaciones disponibles (que no estén reservadas) en una fecha y horario específico
  static Future<List<Installation>> getAvailableInstallations(
    DateTime date,
    String startTime,
    String endTime, {
    int limit = 20,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Obtener todas las instalaciones
      final installations = await getAllInstallations(limit: limit);

      // Obtener reservas para la fecha seleccionada
      final reservations = await _client
          .from('reservas')
          .select()
          .eq('fecha', dateStr)
          .eq('estado', ESTADO_CONFIRMADA) // Solo reservas confirmadas
          .order('hora_inicio', ascending: true);

      // Filtrar instalaciones que están disponibles (no tienen reservas que se solapan)
      List<Installation> availableInstallations = [];

      for (var installation in installations) {
        // Buscar si la instalación tiene alguna reserva que se solape
        bool hasOverlap = reservations.any((reservation) {
          if (reservation['instalacion_id'].toString() != installation.id) {
            return false;
          }

          // Verificar si hay solapamiento de horarios (comparación de strings con formato HH:MM)
          String reservationStart = reservation['hora_inicio'];
          String reservationEnd = reservation['hora_fin'];

          // Comparar horas como strings en formato HH:MM
          bool newStartsAfterExistingEnds =
              _compareTimeStrings(startTime, reservationEnd) >= 0;
          bool newEndsBeforeExistingStarts =
              _compareTimeStrings(endTime, reservationStart) <= 0;

          return !(newStartsAfterExistingEnds || newEndsBeforeExistingStarts);
        });

        if (!hasOverlap && installation.disponible) {
          availableInstallations.add(installation);
        }
      }

      return availableInstallations;
    } catch (e) {
      print('Error al obtener instalaciones disponibles: $e');
      return [];
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

  // Obtener una instalación por ID
  static Future<Installation?> getInstallationById(
    String installationId,
  ) async {
    try {
      final response =
          await _client
              .from('instalaciones')
              .select()
              .eq('id', installationId)
              .single();

      return Installation.fromJson(response);
    } catch (e) {
      print('Error al obtener instalación por ID: $e');
      return null;
    }
  }
}
