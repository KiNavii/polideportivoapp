import 'package:deportivov1/models/event_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  static final SupabaseClient _client = SupabaseService.client;

  // Obtener todos los eventos
  static Future<List<Event>> getAllEvents({int limit = 10}) async {
    try {
      final response = await _client
          .from('eventos')
          .select()
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Event> eventList = [];
      for (var data in response) {
        try {
          eventList.add(Event.fromJson(data));
        } catch (e) {
          print('Error al procesar evento individual: $e');
          // Continuar con el siguiente evento
        }
      }
      return eventList;
    } catch (e) {
      print('Error al obtener eventos: $e');
      // Devolver lista vacía en caso de error para evitar bloqueos
      return [];
    }
  }

  // Obtener eventos destacados
  static Future<List<Event>> getFeaturedEvents({int limit = 5}) async {
    try {
      // Ya no filtramos por destacado, simplemente devolvemos los eventos más recientes
      final response = await _client
          .from('eventos')
          .select()
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Event> eventList = [];
      for (var data in response) {
        try {
          eventList.add(Event.fromJson(data));
        } catch (e) {
          print('Error al procesar evento individual: $e');
          // Continuar con el siguiente evento
        }
      }
      return eventList;
    } catch (e) {
      print('Error al obtener eventos destacados: $e');
      // Devolver lista vacía en caso de error para evitar bloqueos
      return [];
    }
  }

  // Obtener eventos próximos
  static Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('eventos')
          .select()
          .gt('fecha_inicio', now)
          .not('estado', 'eq', 'cancelado')
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Event> eventList = [];
      for (var data in response) {
        try {
          eventList.add(Event.fromJson(data));
        } catch (e) {
          print('Error al procesar evento individual: $e');
          // Continuar con el siguiente evento
        }
      }
      return eventList;
    } catch (e) {
      print('Error al obtener eventos próximos: $e');
      return [];
    }
  }

  // Obtener evento por ID
  static Future<Event?> getEventById(String eventId) async {
    try {
      final response =
          await _client.from('eventos').select().eq('id', eventId).single();

      return Event.fromJson(response);
    } catch (e) {
      print('Error al obtener evento por ID: $e');
      return null;
    }
  }

  // Buscar eventos
  static Future<List<Event>> searchEvents(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('eventos')
          .select()
          .or(
            'nombre.ilike.%$query%,descripcion.ilike.%$query%,lugar.ilike.%$query%',
          )
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      List<Event> eventList = [];
      for (var data in response) {
        try {
          eventList.add(Event.fromJson(data));
        } catch (e) {
          print('Error al procesar evento individual: $e');
          // Continuar con el siguiente evento
        }
      }
      return eventList;
    } catch (e) {
      print('Error al buscar eventos: $e');
      return [];
    }
  }

  // Crear un nuevo evento
  static Future<bool> createEvent({
    String? titulo,
    String? nombre,
    required String descripcion,
    DateTime? fechaEvento,
    DateTime? fechaInicio,
    DateTime? fechaFinEvento,
    DateTime? fechaFin,
    required String lugar,
    String? imagenUrl,
    bool destacado = false,
    int? capacidadMaxima,
  }) async {
    try {
      // Crear un mapa tipado correctamente
      final Map<String, dynamic> data = {
        'nombre': nombre ?? titulo ?? 'Evento sin título',
        'descripcion': descripcion,
        'fecha_inicio': (fechaInicio ?? fechaEvento)!.toIso8601String(),
        'lugar': lugar,
      };

      // Agregar campos opcionales si están presentes
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        data['imagen_url'] = imagenUrl;
      }

      if (fechaFin != null || fechaFinEvento != null) {
        data['fecha_fin'] = (fechaFin ?? fechaFinEvento)!.toIso8601String();
      }

      if (capacidadMaxima != null) {
        data['capacidad_maxima'] = capacidadMaxima;
      }

      // Imprimir los datos que vamos a enviar para debug
      print('Intento crear evento con datos: $data');

      try {
        await _client.from('eventos').insert(data);
        print('Evento creado exitosamente');
        return true;
      } catch (e) {
        print('Error detallado al crear evento: $e');

        // Si el primer intento falló, probamos con un payload mínimo
        if (e.toString().contains('column')) {
          print('Reintentando con payload mínimo absoluto');
          final minimalData = {
            'nombre': nombre ?? titulo ?? 'Evento sin título',
            'descripcion': descripcion,
            'fecha_inicio': (fechaInicio ?? fechaEvento)!.toIso8601String(),
            'lugar': lugar,
          };

          await _client.from('eventos').insert(minimalData);
          print('Evento creado con datos mínimos');
          return true;
        }

        throw e; // Re-lanzar el error si no pudimos manejarlo
      }
    } catch (e) {
      print('Error al crear evento: $e');
      return false;
    }
  }

  // Actualizar un evento existente
  static Future<bool> updateEvent({
    required String id,
    String? titulo,
    String? nombre,
    String? descripcion,
    DateTime? fechaEvento,
    DateTime? fechaInicio,
    DateTime? fechaFinEvento,
    DateTime? fechaFin,
    String? lugar,
    String? imagenUrl,
    bool? destacado,
    int? capacidadMaxima,
    int? participantesActuales,
    String? estado,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (nombre != null || titulo != null) data['nombre'] = nombre ?? titulo;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (fechaInicio != null || fechaEvento != null)
        data['fecha_inicio'] = (fechaInicio ?? fechaEvento)!.toIso8601String();
      if (fechaFin != null || fechaFinEvento != null)
        data['fecha_fin'] = (fechaFin ?? fechaFinEvento)!.toIso8601String();
      if (lugar != null) data['lugar'] = lugar;
      if (imagenUrl != null) data['imagen_url'] = imagenUrl;
      if (capacidadMaxima != null) data['capacidad_maxima'] = capacidadMaxima;
      if (participantesActuales != null)
        data['participantes'] = participantesActuales;
      if (estado != null) data['estado_evento'] = estado;

      if (data.isEmpty) return true; // No hay cambios que guardar

      await _client.from('eventos').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Error al actualizar evento: $e');
      return false;
    }
  }

  // Eliminar un evento
  static Future<bool> deleteEvent(String id) async {
    try {
      await _client.from('eventos').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar evento: $e');
      return false;
    }
  }

  // Inscribirse a un evento
  static Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      // Primero verificamos si hay cupo disponible
      final event = await getEventById(eventId);
      if (event == null) return false;

      if (event.capacidadMaxima != null &&
          event.participantesActuales != null &&
          event.participantesActuales! >= event.capacidadMaxima!) {
        return false; // No hay cupo disponible
      }

      // Verificar si ya está inscrito
      final existingRegistration = await _client
          .from('inscripciones_eventos')
          .select()
          .eq('evento_id', eventId)
          .eq('usuario_id', userId)
          .limit(1);

      if (existingRegistration.isNotEmpty) return true; // Ya está inscrito

      // Añadir inscripción
      await _client.from('inscripciones_eventos').insert({
        'evento_id': eventId,
        'usuario_id': userId,
        'fecha_inscripcion': DateTime.now().toIso8601String(),
      });

      // Incrementar contador de participantes
      if (event.participantesActuales != null) {
        await updateEvent(
          id: eventId,
          participantesActuales: event.participantesActuales! + 1,
        );
      }

      return true;
    } catch (e) {
      print('Error al inscribirse al evento: $e');
      return false;
    }
  }

  // Cancelar inscripción a un evento
  static Future<bool> cancelEventRegistration(
    String eventId,
    String userId,
  ) async {
    try {
      // Eliminar inscripción
      await _client
          .from('inscripciones_eventos')
          .delete()
          .eq('evento_id', eventId)
          .eq('usuario_id', userId);

      // Actualizar contador de participantes
      final event = await getEventById(eventId);
      if (event != null &&
          event.participantesActuales != null &&
          event.participantesActuales! > 0) {
        await updateEvent(
          id: eventId,
          participantesActuales: event.participantesActuales! - 1,
        );
      }

      return true;
    } catch (e) {
      print('Error al cancelar inscripción: $e');
      return false;
    }
  }

  // Verificar si un usuario está inscrito en un evento
  static Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final response = await _client
          .from('inscripciones_eventos')
          .select()
          .eq('evento_id', eventId)
          .eq('usuario_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error al verificar inscripción: $e');
      return false;
    }
  }

  // Obtener todos los eventos como Map
  static Future<List<Map<String, dynamic>>> getAllEventsAsMap({
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('eventos')
          .select()
          .order('fecha_inicio', ascending: true)
          .limit(limit);

      // Convertir directamente la respuesta que ya es List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener eventos como Map: $e');
      // Devolver lista vacía en caso de error
      return [];
    }
  }
}
