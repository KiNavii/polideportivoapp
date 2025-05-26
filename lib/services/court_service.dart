import 'package:deportivov1/models/court_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class CourtService {
  static final SupabaseClient _client = SupabaseService.client;

  // Constantes para estado de pistas
  static const String ESTADO_DISPONIBLE = 'disponible';
  static const String ESTADO_OCUPADA = 'ocupada';
  static const String ESTADO_MANTENIMIENTO = 'mantenimiento';
  static const String ESTADO_CERRADA = 'cerrada';

  // Expose the client for direct use
  static SupabaseClient getClient() {
    return _client;
  }

  // Obtener todas las pistas
  static Future<List<Court>> getAllCourts() async {
    try {
      final response = await _client
          .from('pistas')
          .select('*, instalaciones(*)')
          .order('nombre', ascending: true);

      List<Court> courts = [];
      for (var data in response) {
        try {
          courts.add(Court.fromJson(data));
        } catch (e) {
          print('Error al procesar pista individual: $e');
          // Continuar con la siguiente pista
        }
      }
      return courts;
    } catch (e) {
      print('Error al obtener todas las pistas: $e');
      return [];
    }
  }

  // Obtener pistas por ID de instalación
  static Future<List<Court>> getCourtsByInstallationId(String installationId) async {
    try {
      final response = await _client
          .from('pistas')
          .select('*')
          .eq('instalacion_id', installationId)
          .order('nombre', ascending: true);

      List<Court> courts = [];
      for (var data in response) {
        try {
          courts.add(Court.fromJson(data));
        } catch (e) {
          print('Error al procesar pista individual: $e');
          // Continuar con la siguiente pista
        }
      }
      return courts;
    } catch (e) {
      print('Error al obtener pistas por instalación: $e');
      return [];
    }
  }

  // Obtener pista por ID
  static Future<Court?> getCourtById(String courtId) async {
    try {
      final response = await _client
          .from('pistas')
          .select('*, instalaciones(*)')
          .eq('id', courtId)
          .single();

      return Court.fromJson(response);
    } catch (e) {
      print('Error al obtener pista por ID: $e');
      return null;
    }
  }

  // Obtener pistas por instalación
  static Future<List<Court>> getCourtsByInstallation(
    String installationId,
  ) async {
    try {
      print('🔍🔴 Consultando pistas para instalación: $installationId');
      
      final response = await _client
          .from('pistas')
          .select('*, instalaciones!inner(nombre)')
          .eq('instalacion_id', installationId)
          .order('numero');

      print('🔍🔴 Respuesta recibida: ${response.runtimeType}');
      print('🔍🔴 Datos completos: $response');
      
      if (response is! List) {
        print('🔍🔴 Respuesta no es una lista: ${response.runtimeType}');
        return [];
      }
      
      if (response.isEmpty) {
        print('🔍🔴 No se encontraron pistas para la instalación: $installationId');
        
        // Verificar si existen instalaciones
        final installationsResponse = await _client
            .from('instalaciones')
            .select('id, nombre')
            .eq('id', installationId)
            .single();
            
        print('🔍🔴 Instalación encontrada: ${installationsResponse['nombre']}');
        
        // Verificar la tabla de pistas
        try {
          final allPistas = await _client
              .from('pistas')
              .select('id');
              
          print('🔍🔴 Total de pistas en la BD: ${allPistas.length}');
        } catch (e) {
          print('🔍🔴 Error al contar pistas: $e');
        }
        
        return [];
      }

      print('🔍🔴 Procesando ${response.length} pistas encontradas');
      
      final courts = <Court>[];
      
      for (var data in response) {
        try {
          print('🔍🔴 Procesando pista: ${data['nombre']} (ID: ${data['id']})');
          
        final mapped = {
          ...data as Map<String, dynamic>,
          'instalacion_nombre': data['instalaciones']['nombre'],
        };
          
          final court = Court.fromJson(mapped);
          courts.add(court);
          
        } catch (e) {
          print('🔍🔴 Error al procesar pista individual: $e');
          print('🔍🔴 Datos de pista con error: $data');
        }
      }
      
      print('🔍🔴 Se procesaron correctamente ${courts.length} pistas');
      for (var court in courts) {
        print('🔍🔴 Pista lista: ${court.nombre} (ID: ${court.id}, Número: ${court.numero}, Estado: ${court.estado})');
      }
      
      return courts;
    } catch (e) {
      print('🔍🔴 Error grave al obtener pistas de la instalación: $e');
      print('🔍🔴 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Obtener una pista específica
  static Future<Court?> getCourt(String courtId) async {
    try {
      final response =
          await _client
              .from('pistas')
              .select('*, instalaciones!inner(nombre)')
              .eq('id', courtId)
              .single();

      // Ajustar el formato para adaptarse a nuestro modelo
      final mapped = {
        ...response,
        'instalacion_nombre': response['instalaciones']['nombre'],
      };

      return Court.fromJson(mapped);
    } catch (e) {
      print('Error al obtener pista: $e');
      return null;
    }
  }

  // Crear una nueva pista
  static Future<Court?> createCourt({
    required String instalacionId,
    required String nombre,
    required int numero,
    String? descripcion,
    String? fotoUrl,
    String estado = 'disponible',
    Map<String, dynamic>? caracteristicasJson,
  }) async {
    try {
      print('📝 Creando pista: $nombre (Instalación: $instalacionId)');
      print('📝 Características: $caracteristicasJson');
      
      // Preparar datos
      final data = {
                'instalacion_id': instalacionId,
                'nombre': nombre,
                'numero': numero,
                'descripcion': descripcion,
                'foto_url': fotoUrl,
                'estado': estado,
      };
      
      // Añadir características si existen
      if (caracteristicasJson != null) {
        data['caracteristicas_json'] = caracteristicasJson;
      }
      
      final response = await _client
          .from('pistas')
          .insert(data)
              .select('*, instalaciones!inner(nombre)')
              .single();

      print('📝 Pista creada con éxito: ${response['id']}');

      // Ajustar el formato para adaptarse a nuestro modelo
      final mapped = {
        ...response,
        'instalacion_nombre': response['instalaciones']['nombre'],
      };

      return Court.fromJson(mapped);
    } catch (e) {
      print('📝 Error al crear pista: $e');
      return null;
    }
  }

  // Actualizar una pista existente
  static Future<bool> updateCourt({
    required String id,
    String? nombre,
    String? descripcion,
    String? fotoUrl,
    int? numero,
    String? estado,
    Map<String, dynamic>? caracteristicasJson,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;
      if (fotoUrl != null) updates['foto_url'] = fotoUrl;
      if (numero != null) updates['numero'] = numero;
      if (estado != null) updates['estado'] = estado;
      if (caracteristicasJson != null)
        updates['caracteristicas_json'] = caracteristicasJson;

      await _client.from('pistas').update(updates).eq('id', id);

      return true;
    } catch (e) {
      print('Error al actualizar pista: $e');
      return false;
    }
  }

  // Eliminar una pista
  static Future<bool> deleteCourt(String courtId) async {
    try {
      await _client.from('pistas').delete().eq('id', courtId);
      return true;
    } catch (e) {
      print('Error al eliminar pista: $e');
      return false;
    }
  }

  // Obtener pistas disponibles para una fecha y horario
  static Future<List<Court>> getAvailableCourts({
    required String installationId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Obtener todas las pistas de la instalación
      final allCourts = await getCourtsByInstallation(installationId);

      if (allCourts.isEmpty) {
        return [];
      }

      // Obtener reservas existentes para esa fecha
      final reservations = await _client
          .from('reservas')
          .select('pista_id, hora_inicio, hora_fin')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('instalacion_id', installationId)
          .not('pista_id', 'is', 'null') // Solo reservas con pista asignada
          .eq('estado', 'confirmada'); // Solo reservas confirmadas

      // Filtrar pistas que tienen reservas en ese horario
      final reservedCourtIds = <String>{};

      for (var reservation in reservations) {
        final String courtId = reservation['pista_id'];
        final String resStartTime = reservation['hora_inicio'];
        final String resEndTime = reservation['hora_fin'];

        // Comprobar si hay solapamiento
        final bool overlap =
            !(_compareTimeStrings(startTime, resEndTime) >= 0 ||
                _compareTimeStrings(endTime, resStartTime) <= 0);

        if (overlap) {
          reservedCourtIds.add(courtId);
        }
      }

      // Devolver solo las pistas que están disponibles
      return allCourts
          .where(
            (court) =>
                court.estado == CourtStatus.disponible &&
                !reservedCourtIds.contains(court.id),
          )
          .toList();
    } catch (e) {
      print('Error al obtener pistas disponibles: $e');
      return [];
    }
  }

  // Obtener todas las pistas con información de disponibilidad
  static Future<List<Map<String, dynamic>>> getAllCourtsWithAvailability({
    required String installationId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      print('📌 Iniciando búsqueda de pistas con disponibilidad');
      print('📌 ID Instalación: $installationId');
      print('📌 Fecha: ${date.toIso8601String().split('T')[0]}');
      print('📌 Horario: $startTime - $endTime');

      // Obtener todas las pistas de la instalación
      final allCourts = await getCourtsByInstallation(installationId);
      print('📌 Pistas totales en la instalación: ${allCourts.length}');

      if (allCourts.isEmpty) {
        print('📌 No se encontraron pistas para la instalación');
        return [];
      }

      for (var court in allCourts) {
        print('📌 Pista encontrada: ${court.nombre} (ID: ${court.id})');
      }

      // Obtener reservas existentes para esa fecha
      final dateString = date.toIso8601String().split('T')[0];
      print('📌 Buscando reservas para la fecha: $dateString');

      final reservations = await _client
          .from('reservas')
          .select('pista_id, hora_inicio, hora_fin')
          .eq('fecha', dateString)
          .eq('instalacion_id', installationId)
          .not('pista_id', 'is', 'null') // Solo reservas con pista asignada
          .eq('estado', 'confirmada'); // Solo reservas confirmadas

      print('📌 Reservas encontradas: ${reservations.length}');

      // Identificar pistas reservadas en ese horario
      final reservedCourtIds = <String>{};

      for (var reservation in reservations) {
        final String courtId = reservation['pista_id'];
        final String resStartTime = reservation['hora_inicio'];
        final String resEndTime = reservation['hora_fin'];

        print('📌 Revisando reserva: Pista $courtId, Horario: $resStartTime - $resEndTime');

        // Comprobar si hay solapamiento
        final bool overlap =
            !(_compareTimeStrings(startTime, resEndTime) >= 0 ||
                _compareTimeStrings(endTime, resStartTime) <= 0);

        if (overlap) {
          print('📌 Solapamiento encontrado para la pista: $courtId');
          reservedCourtIds.add(courtId);
        }
      }

      // Crear lista con todas las pistas y su disponibilidad
      final result = allCourts.map((court) {
        final bool isAvailable = 
            court.estado == CourtStatus.disponible && 
            !reservedCourtIds.contains(court.id);
        
        final reason = _getUnavailabilityReason(court, reservedCourtIds.contains(court.id));
        
        print('📌 Resultado: Pista ${court.nombre} - Disponible: $isAvailable ${reason != null ? "- Razón: $reason" : ""}');
        
        return {
          'court': court,
          'isAvailable': isAvailable,
          'reason': reason
        };
      }).toList();

      print('📌 Total de pistas procesadas: ${result.length}');
      return result;
    } catch (e) {
      print('📌 Error al obtener pistas con disponibilidad: $e');
      rethrow;
    }
  }

  // Obtener razón por la que una pista no está disponible
  static String? _getUnavailabilityReason(Court court, bool isReserved) {
    if (isReserved) {
      return 'Reservada para este horario';
    } else if (court.estado == CourtStatus.mantenimiento) {
      return 'En mantenimiento';
    } else if (court.estado == CourtStatus.cerrada) {
      return 'Cerrada';
    } else if (court.estado == CourtStatus.ocupada) {
      return 'Ocupada';
    }
    return null;
  }

  // Método helper para comparar strings de tiempo
  static int _compareTimeStrings(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');

    final hours1 = int.parse(parts1[0]);
    final minutes1 = int.parse(parts1[1]);

    final hours2 = int.parse(parts2[0]);
    final minutes2 = int.parse(parts2[1]);

    if (hours1 != hours2) {
      return hours1.compareTo(hours2);
    }

    return minutes1.compareTo(minutes2);
  }

  // Crear pistas de demostración para una instalación
  static Future<bool> createDemoCourts(String installationId) async {
    try {
      print('🎾 Creando pistas de demostración para instalación: $installationId');
      
      // Verificar si ya existen pistas para esta instalación
      final existingCourts = await _client
          .from('pistas')
          .select('id')
          .eq('instalacion_id', installationId);
          
      if (existingCourts.isNotEmpty) {
        print('🎾 Ya existen ${existingCourts.length} pistas para esta instalación');
        return true;
      }
      
      // Definir pistas de demostración
      final demoNames = ['Pista Central', 'Pista Secundaria', 'Pista Cubierta', 'Pista Principal'];
      final demoSurface = ['Tierra batida', 'Hierba', 'Dura', 'Moqueta'];
      
      // Crear pistas
      for (int i = 0; i < 4; i++) {
        final caracteristicas = {
          'superficie': demoSurface[i % demoSurface.length],
          'tiene_marcador': i < 2, // Solo las primeras dos tienen marcador
          'tiene_iluminacion': true, // Todas tienen iluminación
          'dimensiones': {
            'largo': 23.77,
            'ancho': 10.97,
            'unidad': 'metros'
          },
          'equipamiento': ['Red', 'Bancos', 'Sillas de juez'],
        };
        
        await _client
            .from('pistas')
            .insert({
              'instalacion_id': installationId,
              'nombre': demoNames[i],
              'numero': i + 1,
              'descripcion': 'Pista de tenis ${demoSurface[i % demoSurface.length]}',
              'estado': ESTADO_DISPONIBLE,
              'caracteristicas_json': caracteristicas,
            });
      }
      
      print('🎾 Se crearon 4 pistas de demostración correctamente');
      return true;
    } catch (e) {
      print('🎾 Error al crear pistas de demostración: $e');
      return false;
    }
  }

  // Verificar y actualizar la configuración de una instalación para tener pistas
  static Future<bool> verifyAndFixInstallationConfig(String installationId) async {
    try {
      print('🔧 Verificando configuración de instalación: $installationId');
      
      // Obtener la instalación
      final installationData = await _client
          .from('instalaciones')
          .select('*, caracteristicas_json')
          .eq('id', installationId)
          .single();
      
      print('🔧 Instalación encontrada: ${installationData['nombre']}');
      
      // Verificar si tiene la propiedad tiene_pistas
      Map<String, dynamic> caracteristicas = {};
      
      if (installationData['caracteristicas_json'] != null) {
        if (installationData['caracteristicas_json'] is String) {
          try {
            caracteristicas = jsonDecode(installationData['caracteristicas_json']);
          } catch (e) {
            print('🔧 Error al decodificar JSON: $e');
            caracteristicas = {};
          }
        } else if (installationData['caracteristicas_json'] is Map) {
          caracteristicas = Map<String, dynamic>.from(installationData['caracteristicas_json']);
        }
      }
      
      // Verificar si necesita actualización
      bool needsUpdate = false;
      
      if (!caracteristicas.containsKey('tiene_pistas') || caracteristicas['tiene_pistas'] != true) {
        caracteristicas['tiene_pistas'] = true;
        needsUpdate = true;
        print('🔧 La instalación no tiene configurada "tiene_pistas", actualizando...');
      }
      
      // Otras propiedades para instalaciones de tenis
      if (!caracteristicas.containsKey('tipo') || caracteristicas['tipo'] != 'tenis') {
        caracteristicas['tipo'] = 'tenis';
        needsUpdate = true;
        print('🔧 Actualizando tipo a "tenis"');
      }
      
      // Actualizar si es necesario
      if (needsUpdate) {
        await _client
            .from('instalaciones')
            .update({
              'caracteristicas_json': caracteristicas
            })
            .eq('id', installationId);
        
        print('🔧 Instalación actualizada correctamente con tiene_pistas=true');
      } else {
        print('🔧 La instalación ya tiene la configuración correcta');
      }
      
      return true;
    } catch (e) {
      print('🔧 Error al verificar/actualizar instalación: $e');
      return false;
    }
  }
}
