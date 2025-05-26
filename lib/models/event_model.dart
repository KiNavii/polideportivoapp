enum EventCategory {
  deportivo,
  cultural,
  formativo,
  institucional,
  especial,
  otros,
}

class Event {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String lugar;
  final String? imagenUrl;
  final String autorId;
  final bool destacado;
  final DateTime fechaCreacion;
  final int? capacidadMaxima;
  final int? participantesActuales;
  final String? estado; // 'programado', 'completado', 'cancelado'

  Event({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    required this.lugar,
    this.imagenUrl,
    required this.autorId,
    this.destacado = false,
    required this.fechaCreacion,
    this.capacidadMaxima,
    this.participantesActuales,
    this.estado = 'programado',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio:
          json['fecha_inicio'] != null
              ? DateTime.parse(json['fecha_inicio'])
              : DateTime.now(),
      fechaFin:
          json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      lugar: json['lugar'] ?? '',
      imagenUrl: json['imagen_url'],
      autorId:
          json['organizador_id']?.toString() ??
          json['autor_id']?.toString() ??
          '',
      destacado: false,
      fechaCreacion:
          json['fecha_creacion'] != null
              ? DateTime.parse(json['fecha_creacion'])
              : DateTime.now(),
      capacidadMaxima: json['capacidad_maxima'],
      participantesActuales:
          json['participantes'] ?? json['participantes_actuales'] ?? 0,
      estado: json['estado_evento'] ?? json['estado'] ?? 'programado',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'lugar': lugar,
    };

    if (imagenUrl != null && imagenUrl!.isNotEmpty) {
      data['imagen_url'] = imagenUrl;
    }

    if (fechaFin != null) {
      data['fecha_fin'] = fechaFin!.toIso8601String();
    }

    if (capacidadMaxima != null) {
      data['capacidad_maxima'] = capacidadMaxima;
    }

    return data;
  }

  // Verifica si el evento está activo (no ha pasado)
  bool get isActive {
    final DateTime now = DateTime.now();
    final DateTime endDate = fechaFin ?? fechaInicio;
    return endDate.isAfter(now) && estado != 'cancelado';
  }

  // Verifica si hay cupo disponible
  bool get hasAvailableCapacity {
    if (capacidadMaxima == null || participantesActuales == null) return true;
    return participantesActuales! < capacidadMaxima!;
  }

  // Para compatibilidad con la interfaz gráfica
  String get titulo => nombre;
  DateTime get fechaEvento => fechaInicio;
  DateTime? get fechaFinEvento => fechaFin;
}
