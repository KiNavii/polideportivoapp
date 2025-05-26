import 'dart:convert';

enum CourtStatus { disponible, ocupada, mantenimiento, cerrada }

class Court {
  final String id;
  final String instalacionId;
  final String nombre;
  final String? descripcion;
  final String? fotoUrl;
  final int numero;
  final CourtStatus estado;
  final Map<String, dynamic>? caracteristicasJson;
  final DateTime? createdAt;

  // Para facilitar la visualización en la UI
  final String? instalacionNombre;

  Court({
    required this.id,
    required this.instalacionId,
    required this.nombre,
    this.descripcion,
    this.fotoUrl,
    required this.numero,
    required this.estado,
    this.caracteristicasJson,
    this.createdAt,
    this.instalacionNombre,
  });

  // Getters para acceder a características específicas
  String? get superficie => caracteristicasJson?['superficie'] as String?;
  Map<String, dynamic>? get dimensiones =>
      caracteristicasJson?['dimensiones'] as Map<String, dynamic>?;
  List<String>? get equipamiento =>
      caracteristicasJson?['equipamiento'] != null
          ? List<String>.from(caracteristicasJson!['equipamiento'])
          : null;
  bool get tieneMarcador =>
      caracteristicasJson?['tiene_marcador'] as bool? ?? false;
  bool get tieneIluminacion =>
      caracteristicasJson?['tiene_iluminacion'] as bool? ?? false;

  factory Court.fromJson(Map<String, dynamic> json) {
    String estadoStr = json['estado'] ?? 'disponible';

    // Debug
    print('🏟️ Parseando Court: $json');

    try {
      final court = Court(
      id: json['id'].toString(),
      instalacionId: json['instalacion_id'].toString(),
        nombre: json['nombre'] ?? 'Pista sin nombre',
      descripcion: json['descripcion'],
      fotoUrl: json['foto_url'],
        numero: json['numero'] is int
              ? json['numero']
            : int.tryParse(json['numero'].toString()) ?? 0,
      estado: _parseEstado(estadoStr),
        caracteristicasJson: _parseCaracteristicasJson(json['caracteristicas_json']),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
              : null,
        instalacionNombre: json['instalacion_nombre'] ?? 'Instalación',
    );
      
      print('🏟️ Court parseado con éxito: ${court.nombre} (ID: ${court.id})');
      return court;
    } catch (e) {
      print('🏟️ Error al parsear Court: $e');
      print('🏟️ Datos JSON: $json');
      
      // Intentar crear un objeto básico para no interrumpir el flujo
      return Court(
        id: json['id']?.toString() ?? 'error',
        instalacionId: json['instalacion_id']?.toString() ?? 'error',
        nombre: json['nombre']?.toString() ?? 'Error de parseo',
        numero: 0,
        estado: CourtStatus.disponible,
      );
    }
  }

  // Método seguro para parsear el JSON de características
  static Map<String, dynamic>? _parseCaracteristicasJson(dynamic jsonData) {
    if (jsonData == null) return null;
    
    try {
      if (jsonData is String) {
        // Intentar parsear el string a un mapa
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          jsonDecode(jsonData)
        );
        return parsed;
      } else if (jsonData is Map) {
        // Ya es un mapa, simplemente convertirlo
        return Map<String, dynamic>.from(jsonData);
      }
    } catch (e) {
      print('🏟️ Error al parsear características: $e');
    }
    
    // Si no se pudo parsear, devolver un mapa vacío
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'instalacion_id': instalacionId,
      'nombre': nombre,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'numero': numero,
      'estado': estado.name,
      'caracteristicas_json': caracteristicasJson,
    };
  }

  static CourtStatus _parseEstado(String estado) {
    switch (estado) {
      case 'ocupada':
        return CourtStatus.ocupada;
      case 'mantenimiento':
        return CourtStatus.mantenimiento;
      case 'cerrada':
        return CourtStatus.cerrada;
      case 'disponible':
      default:
        return CourtStatus.disponible;
    }
  }

  // Método para crear el objeto JSON de características
  static Map<String, dynamic> createCaracteristicasJson({
    String? superficie,
    Map<String, dynamic>? dimensiones,
    List<String>? equipamiento,
    bool? tieneMarcador,
    bool? tieneIluminacion,
    Map<String, dynamic>? caracteristicasAdicionales,
  }) {
    final Map<String, dynamic> json = {};

    if (superficie != null) json['superficie'] = superficie;
    if (dimensiones != null) json['dimensiones'] = dimensiones;
    if (equipamiento != null) json['equipamiento'] = equipamiento;
    if (tieneMarcador != null) json['tiene_marcador'] = tieneMarcador;
    if (tieneIluminacion != null) json['tiene_iluminacion'] = tieneIluminacion;

    // Fusionar características adicionales si se proporcionan
    if (caracteristicasAdicionales != null) {
      json.addAll(caracteristicasAdicionales);
    }

    return json;
  }
}
