enum ReservationStatus { pendiente, confirmada, cancelada, completada }

class Reservation {
  final String id;
  final String usuarioId;
  final String instalacionId;
  final String? pistaId;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final DateTime? fechaReserva;
  final ReservationStatus estado;
  final String? comentario;

  // Propiedades para relaciones
  final Map<String, dynamic>? instalacion;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? pista;

  Reservation({
    required this.id,
    required this.usuarioId,
    required this.instalacionId,
    this.pistaId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.fechaReserva,
    required this.estado,
    this.comentario,
    this.instalacion,
    this.usuario,
    this.pista,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Extract estado first and handle null case
    String estadoStr = 'confirmada'; // Default value if estado is null
    if (json['estado'] != null) {
      estadoStr = json['estado'];
    }

    // Manejar campos potencialmente nulos de forma segura
    String? comentario;
    if (json['comentario'] != null) {
      comentario = json['comentario'].toString();
    } else if (json['notas'] != null) {
      comentario = json['notas'].toString();
    }

    // Asegurar que horaInicio y horaFin nunca sean nulos
    final horaInicio = (json['hora_inicio'] ?? '00:00').toString();
    final horaFin = (json['hora_fin'] ?? '00:00').toString();

    return Reservation(
      id: json['id'].toString(),
      usuarioId: json['usuario_id'].toString(),
      instalacionId: json['instalacion_id'].toString(),
      pistaId: json['pista_id']?.toString(),
      fecha: DateTime.parse(json['fecha']),
      horaInicio: horaInicio,
      horaFin: horaFin,
      fechaReserva:
          json['fecha_reserva'] != null
              ? DateTime.parse(json['fecha_reserva'])
              : null,
      estado: _parseEstado(estadoStr),
      comentario: comentario,
      instalacion: json['instalaciones'],
      usuario: json['usuarios'],
      pista: json['pistas'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'usuario_id': usuarioId,
      'instalacion_id': instalacionId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'estado': estado.name,
    };

    if (pistaId != null) map['pista_id'] = pistaId!;
    if (fechaReserva != null)
      map['fecha_reserva'] = fechaReserva!.toIso8601String();
    if (comentario != null) map['notas'] = comentario!;

    return map;
  }

  // Métodos de conveniencia para acceso
  String get nombreInstalacion => instalacion?['nombre'] ?? 'Instalación';
  String get nombrePista => pista?['nombre'] ?? 'Pista no especificada';
  bool get tienePistaAsignada => pistaId != null && pista != null;
  int? get numeroPista => pista?['numero'];

  static ReservationStatus _parseEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return ReservationStatus.pendiente;
      case 'confirmada':
        return ReservationStatus.confirmada;
      case 'cancelada':
        return ReservationStatus.cancelada;
      case 'completada':
        return ReservationStatus.completada;
      default:
        return ReservationStatus.pendiente;
    }
  }
}
