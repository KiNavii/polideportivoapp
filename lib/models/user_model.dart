enum UserType { socio, administrador, monitor }

class UserModel {
  final String id;
  final String email;
  final String? nombre;
  final String? apellidos;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final UserType tipoUsuario;
  final bool estaActivo;
  final String? fotoPerfil;
  final DateTime? fechaRegistro;
  final DateTime? ultimaConexion;
  final String? numeroSocio;

  UserModel({
    required this.id,
    required this.email,
    this.nombre,
    this.apellidos,
    this.telefono,
    this.fechaNacimiento,
    this.tipoUsuario = UserType.socio,
    this.estaActivo = true,
    this.fotoPerfil,
    this.fechaRegistro,
    this.ultimaConexion,
    this.numeroSocio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      nombre: json['nombre'],
      apellidos: json['apellidos'],
      telefono: json['telefono'],
      fechaNacimiento:
          json['fecha_nacimiento'] != null
              ? DateTime.parse(json['fecha_nacimiento'])
              : null,
      tipoUsuario: _parseUserType(json['tipo_usuario']),
      estaActivo: json['esta_activo'] ?? true,
      fotoPerfil: json['foto_perfil_url'],
      fechaRegistro:
          json['fecha_registro'] != null
              ? DateTime.parse(json['fecha_registro'])
              : null,
      ultimaConexion:
          json['ultima_conexion'] != null
              ? DateTime.parse(json['ultima_conexion'])
              : null,
      numeroSocio: json['numero_socio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'tipo_usuario': tipoUsuario.name,
      'esta_activo': estaActivo,
      'foto_perfil_url': fotoPerfil,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'ultima_conexion': ultimaConexion?.toIso8601String(),
      'numero_socio': numeroSocio,
    };
  }

  static UserType _parseUserType(String? type) {
    if (type == 'administrador') return UserType.administrador;
    if (type == 'monitor') return UserType.monitor;
    return UserType.socio;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    UserType? tipoUsuario,
    bool? estaActivo,
    String? fotoPerfil,
    DateTime? fechaRegistro,
    DateTime? ultimaConexion,
    String? numeroSocio,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      estaActivo: estaActivo ?? this.estaActivo,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimaConexion: ultimaConexion ?? this.ultimaConexion,
      numeroSocio: numeroSocio ?? this.numeroSocio,
    );
  }
}
