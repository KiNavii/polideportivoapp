import 'package:deportivov1/models/user_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Instancia del cliente Supabase
  final SupabaseClient _supabase = SupabaseService.client;

  // Métodos de autenticación
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
  }) async {
    try {
      // Registro mediante Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error en el registro: usuario nulo');
      }

      // Crear perfil de usuario en la tabla usuarios
      final userId = response.user!.id;
      final userData = {
        'id': userId,
        'email': email,
        'nombre': nombre,
        'apellidos': apellidos,
        'telefono': telefono,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'tipo_usuario': 'socio', // Por defecto, todos son socios
        'esta_activo': true,
        'fecha_registro': DateTime.now().toIso8601String(),
      };

      await _supabase.from('usuarios').insert(userData);

      // Retornar el usuario creado
      return UserModel.fromJson(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Error en registro: $e');
      }
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Login mediante Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error en el inicio de sesión: usuario nulo');
      }

      // Obtener datos del usuario desde la tabla usuarios
      final data =
          await _supabase
              .from('usuarios')
              .select()
              .eq('id', response.user!.id)
              .single();

      return UserModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error en inicio de sesión: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error en cierre de sesión: $e');
      }
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Obtener usuario actualmente autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Obtener datos completos desde la tabla usuarios
      final data =
          await _supabase.from('usuarios').select().eq('id', user.id).single();

      return UserModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuario actual: $e');
      }
      return null;
    }
  }

  // Método para actualizar perfil de usuario
  Future<UserModel?> updateUserProfile({
    required String userId,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    String? fotoPerfil,
  }) async {
    try {
      final updates = {
        if (nombre != null) 'nombre': nombre,
        if (apellidos != null) 'apellidos': apellidos,
        if (telefono != null) 'telefono': telefono,
        if (fechaNacimiento != null)
          'fecha_nacimiento': fechaNacimiento.toIso8601String(),
        if (fotoPerfil != null) 'foto_perfil_url': fotoPerfil,
      };

      if (updates.isEmpty) return await getCurrentUser();

      await _supabase.from('usuarios').update(updates).eq('id', userId);

      return await getCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar perfil: $e');
      }
      rethrow;
    }
  }

  // Método para resetear contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      if (kDebugMode) {
        print('Error al resetear contraseña: $e');
      }
      rethrow;
    }
  }

  // Stream para observar cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
