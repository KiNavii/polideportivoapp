class Installation {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? fotoUrl;
  final String? ubicacion;
  final String tipo;
  final bool disponible;
  final int? capacidadMax;
  final Map<String, dynamic>? caracteristicasJson;

  Installation({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fotoUrl,
    this.ubicacion,
    required this.tipo,
    required this.disponible,
    this.capacidadMax,
    this.caracteristicasJson,
  });

  int? get duracionMinReserva =>
      caracteristicasJson?['duracion_min_reserva'] as int?;
  int? get duracionMaxReserva =>
      caracteristicasJson?['duracion_max_reserva'] as int?;
  String? get horaApertura => caracteristicasJson?['hora_apertura'] as String?;
  String? get horaCierre => caracteristicasJson?['hora_cierre'] as String?;
  List<String>? get diasDisponibles =>
      caracteristicasJson?['dias_disponibles'] != null
          ? List<String>.from(caracteristicasJson!['dias_disponibles'])
          : null;
  bool get tienePistas => caracteristicasJson?['tiene_pistas'] == true;

  factory Installation.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? caracteristicasJson;
    if (json['caracteristicas_json'] != null) {
      caracteristicasJson =
          json['caracteristicas_json'] is String
              ? Map<String, dynamic>.from(
                Map<String, dynamic>.from(json['caracteristicas_json']),
              )
              : Map<String, dynamic>.from(json['caracteristicas_json'] as Map);
    }

    return Installation(
      id: json['id'].toString(),
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      fotoUrl: json['foto_url'],
      ubicacion: json['ubicacion'],
      tipo: json['tipo'],
      disponible: json['disponible'] ?? true,
      capacidadMax: json['capacidad_max'],
      caracteristicasJson: caracteristicasJson,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'ubicacion': ubicacion,
      'tipo': tipo,
      'disponible': disponible,
      'capacidad_max': capacidadMax,
      'caracteristicas_json': caracteristicasJson,
    };

    return data;
  }

  static Map<String, dynamic> createCaracteristicasJson({
    int? duracionMinReserva,
    int? duracionMaxReserva,
    String? horaApertura,
    String? horaCierre,
    List<String>? diasDisponibles,
    bool? tienePistas,
  }) {
    final Map<String, dynamic> json = {};

    if (duracionMinReserva != null)
      json['duracion_min_reserva'] = duracionMinReserva;
    if (duracionMaxReserva != null)
      json['duracion_max_reserva'] = duracionMaxReserva;
    if (horaApertura != null) json['hora_apertura'] = horaApertura;
    if (horaCierre != null) json['hora_cierre'] = horaCierre;
    if (diasDisponibles != null) json['dias_disponibles'] = diasDisponibles;
    if (tienePistas != null) json['tiene_pistas'] = tienePistas;

    return json;
  }
}
