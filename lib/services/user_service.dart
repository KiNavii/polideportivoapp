import 'package:deportivov1/models/user_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final SupabaseClient _client = SupabaseService.client;

  // Registro de nuevos usuarios
  static Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    required String tipoUsuario,
    String? telefono,
    DateTime? fechaNacimiento,
  }) async {
    try {
      // Registrar usuario con Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error en el registro: usuario nulo');
      }

      // Crear perfil en la tabla usuarios
      final userId = response.user!.id;
      final userData = {
        'id': userId,
        'email': email,
        'nombre': nombre,
        'apellidos': apellidos,
        'telefono': telefono,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'tipo_usuario': tipoUsuario,
        'esta_activo': true,
        'fecha_registro': DateTime.now().toIso8601String(),
        'ultima_conexion': DateTime.now().toIso8601String(),
      };

      await _client.from('usuarios').insert(userData);

      // Restaurar la sesión del administrador actual
      // Esto es necesario porque signUp inicia sesión automáticamente con el nuevo usuario
      await _client.auth.signOut();

      return UserModel.fromJson(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Error en registro de usuario: $e');
      }
      rethrow;
    }
  }

  // Obtener todos los usuarios
  static Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('usuarios')
          .select()
          .order('fecha_registro', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuarios: $e');
      }
      return [];
    }
  }

  // Obtener usuarios por tipo
  static Future<List<Map<String, dynamic>>> getUsersByType(
    String userType, {
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('usuarios')
          .select()
          .eq('tipo_usuario', userType)
          .order('fecha_registro', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuarios por tipo: $e');
      }
      return [];
    }
  }

  // Obtener un usuario por ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await _client.from('usuarios').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuario por ID: $e');
      }
      return null;
    }
  }

  // Actualizar estado de usuario (activar/desactivar)
  static Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _client
          .from('usuarios')
          .update({
            'esta_activo': isActive,
            'ultima_conexion': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar estado de usuario: $e');
      }
      return false;
    }
  }

  // Actualizar tipo de usuario
  static Future<bool> updateUserType(String userId, String userType) async {
    try {
      await _client
          .from('usuarios')
          .update({
            'tipo_usuario': userType,
            'ultima_conexion': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar tipo de usuario: $e');
      }
      return false;
    }
  }

  // Actualizar datos de usuario
  static Future<bool> updateUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Añadir timestamp de última conexión
      userData['ultima_conexion'] = DateTime.now().toIso8601String();

      await _client.from('usuarios').update(userData).eq('id', userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar datos de usuario: $e');
      }
      return false;
    }
  }

  // Eliminar un usuario y todas sus relaciones
  static Future<bool> deleteUser(String userId) async {
    try {
      // 1. Eliminar todas las inscripciones de actividades del usuario
      await _client
          .from('inscripciones_actividades')
          .delete()
          .eq('usuario_id', userId);

      // 2. Eliminar todas las reservas del usuario
      await _client.from('reservas').delete().eq('usuario_id', userId);

      // 3. Eliminar cualquier otra relación que tenga el usuario (pagos, notificaciones, etc.)
      // Ejemplo (descomenta y adapta según tus tablas):
      // await _client.from('pagos').delete().eq('usuario_id', userId);
      // await _client.from('notificaciones').delete().eq('usuario_id', userId);

      // 4. Finalmente eliminamos el registro en nuestra tabla de usuarios
      await _client.from('usuarios').delete().eq('id', userId);

      // 5. Si es posible, eliminamos el usuario de Supabase Auth
      try {
        // Esta operación requiere derechos administrativos
        // Para entornos de producción, puede ser necesario un endpoint serverless
        await _client.auth.admin.deleteUser(userId);
      } catch (e) {
        if (kDebugMode) {
          print('Advertencia: No se pudo eliminar usuario de Auth: $e');
        }
        // Continuamos incluso si esto falla, ya que el usuario está eliminado de nuestra tabla
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar usuario: $e');
      }
      rethrow;
    }
  }
}
