enum NewsCategory {
  eventos,
  instalaciones,
  actividades,
  mantenimiento,
  promocion,
}

class News {
  final String id;
  final String titulo;
  final String contenido;
  final DateTime fechaPublicacion;
  final String autorId;
  final String? imagenUrl;
  final bool destacada;
  final NewsCategory categoria;
  final DateTime? fechaExpiracion;

  News({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    required this.autorId,
    this.imagenUrl,
    required this.destacada,
    required this.categoria,
    this.fechaExpiracion,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'].toString(),
      titulo: json['titulo'],
      contenido: json['contenido'],
      fechaPublicacion: DateTime.parse(json['fecha_publicacion']),
      autorId: json['autor_id'].toString(),
      imagenUrl: json['imagen_url'],
      destacada: json['destacada'],
      categoria: _parseCategoria(json['categoria']),
      fechaExpiracion:
          json['fecha_expiracion'] != null
              ? DateTime.parse(json['fecha_expiracion'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'titulo': titulo,
      'contenido': contenido,
      'fecha_publicacion': fechaPublicacion.toIso8601String(),
      'autor_id': autorId,
      'imagen_url': imagenUrl,
      'destacada': destacada,
      'categoria': categoria.name,
    };

    if (fechaExpiracion != null) {
      data['fecha_expiracion'] = fechaExpiracion!.toIso8601String();
    }

    return data;
  }

  static NewsCategory _parseCategoria(String categoria) {
    switch (categoria) {
      case 'eventos':
        return NewsCategory.eventos;
      case 'instalaciones':
        return NewsCategory.instalaciones;
      case 'actividades':
        return NewsCategory.actividades;
      case 'mantenimiento':
        return NewsCategory.mantenimiento;
      case 'promocion':
        return NewsCategory.promocion;
      default:
        return NewsCategory.eventos;
    }
  }
}
