class ActivityFamily {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? iconoUrl;
  final String? color;

  ActivityFamily({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.iconoUrl,
    this.color,
  });

  factory ActivityFamily.fromJson(Map<String, dynamic> json) {
    return ActivityFamily(
      id: json['id'].toString(),
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      iconoUrl: json['icono_url'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'icono_url': iconoUrl,
      'color': color,
    };
  }
}
