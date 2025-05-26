import 'package:deportivov1/models/activity_family_model.dart';

enum ActivityStatus { activa, cancelada, completada, suspendida }

class Activity {
  final String id;
  final String nombre;
  final String familiaId;
  final String instalacionId;
  final String? descripcion;
  final int plazasMax;
  final int plazasOcupadas;
  final int duracionMinutos;
  final List<String>? diasSemana;
  final String horaInicio;
  final String horaFin;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool esRecurrente;
  final String? monitorId;
  final String? nivel;
  final ActivityStatus estado;
  final String? imagenUrl;

  // Propiedades calculadas
  bool get tieneDisponibilidad => plazasOcupadas < plazasMax;
  int get plazasDisponibles => plazasMax - plazasOcupadas;

  // Opcional: referencias a otros modelos para relaciones
  ActivityFamily? familia;

  Activity({
    required this.id,
    required this.nombre,
    required this.familiaId,
    required this.instalacionId,
    this.descripcion,
    required this.plazasMax,
    required this.plazasOcupadas,
    required this.duracionMinutos,
    this.diasSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
    this.fechaFin,
    required this.esRecurrente,
    this.monitorId,
    this.nivel,
    required this.estado,
    this.imagenUrl,
    this.familia,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Para manejar días de semana que pueden venir como enteros de la base de datos
    List<String>? diasSemana;
    if (json['dias_semana'] != null) {
      if (json['dias_semana'] is List) {
        // Mapear números del 1-7 a nombres de día (1=lunes, 2=martes, etc.)
        final Map<int, String> numberToDay = {
          1: 'lunes',
          2: 'martes',
          3: 'miercoles',
          4: 'jueves',
          5: 'viernes',
          6: 'sabado',
          7: 'domingo',
        };

        diasSemana =
            (json['dias_semana'] as List).map((item) {
              // Si el ítem es un entero, convertirlo al nombre del día
              if (item is int || int.tryParse(item.toString()) != null) {
                final dayNumber =
                    item is int ? item : int.parse(item.toString());
                return numberToDay[dayNumber] ?? dayNumber.toString();
              }
              return item.toString();
            }).toList();
      }
    }

    return Activity(
      id: json['id'].toString(),
      nombre: json['nombre'],
      familiaId: json['familia_id'].toString(),
      instalacionId: json['instalacion_id'].toString(),
      descripcion: json['descripcion'],
      plazasMax: json['plazas_max'],
      plazasOcupadas: json['plazas_ocupadas'],
      duracionMinutos: json['duracion_minutos'],
      diasSemana: diasSemana,
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin:
          json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      esRecurrente: json['es_recurrente'],
      monitorId: json['monitor_id']?.toString(),
      nivel: json['nivel'],
      estado: _parseEstado(json['estado']),
      imagenUrl: json['imagen_url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'familia_id': familiaId,
      'instalacion_id': instalacionId,
      'descripcion': descripcion,
      'plazas_max': plazasMax,
      'plazas_ocupadas': plazasOcupadas,
      'duracion_minutos': duracionMinutos,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'es_recurrente': esRecurrente,
      'monitor_id': monitorId,
      'nivel': nivel,
      'estado': estado.name,
      'imagen_url': imagenUrl,
    };

    if (fechaFin != null) {
      data['fecha_fin'] = fechaFin!.toIso8601String();
    }

    return data;
  }

  static ActivityStatus _parseEstado(String estado) {
    switch (estado) {
      case 'activa':
        return ActivityStatus.activa;
      case 'cancelada':
        return ActivityStatus.cancelada;
      case 'completada':
        return ActivityStatus.completada;
      case 'suspendida':
        return ActivityStatus.suspendida;
      default:
        return ActivityStatus.activa;
    }
  }
}
