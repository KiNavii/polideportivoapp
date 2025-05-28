import 'package:deportivov1/models/user_model.dart';
import 'package:deportivov1/services/auth_service.dart';
import 'package:deportivov1/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estado de autenticación
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _loading = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor
  AuthProvider() {
    // Iniciar escuchando cambios de autenticación
    _initAuth();
  }

  void _initAuth() {
    _loading = true;
    notifyListeners();

    // Verificar si hay un usuario en sesión
    _authService
        .getCurrentUser()
        .then((user) async {
          if (user != null) {
            _user = user;
            _status = AuthStatus.authenticated;
            
            
            
            // Inicializar servicio de notificaciones para usuario existente
            try {
              await NotificationService().initialize(user.id);
              if (kDebugMode) {
                print('✅ Servicio de notificaciones inicializado para usuario existente: ${user.id}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error al inicializar notificaciones: $e');
              }
              // No fallar la inicialización por problemas de notificaciones
            }
          } else {
            _status = AuthStatus.unauthenticated;
          }
          _loading = false;
          notifyListeners();
        })
        .catchError((error) {
          _status = AuthStatus.unauthenticated;
          _loading = false;
          notifyListeners();
        });
  }



  // Método para iniciar sesión
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signIn(email: email, password: password);

      _user = user;
      _status = AuthStatus.authenticated;
      
      // Inicializar servicio de notificaciones después del login exitoso
      if (user != null) {
        try {
          await NotificationService().initialize(user.id);
          if (kDebugMode) {
            print('✅ Servicio de notificaciones inicializado para usuario: ${user.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error al inicializar notificaciones: $e');
          }
          // No fallar el login por problemas de notificaciones
        }
      }
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para registrarse
  Future<bool> signUp({
    required String email,
    required String password,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
  }) async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signUp(
        email: email,
        password: password,
        nombre: nombre,
        apellidos: apellidos,
        telefono: telefono,
        fechaNacimiento: fechaNacimiento,
      );

      _user = user;
      _status = AuthStatus.authenticated;
      
      // Inicializar servicio de notificaciones después del registro exitoso
      if (user != null) {
        try {
          await NotificationService().initialize(user.id);
          if (kDebugMode) {
            print('✅ Servicio de notificaciones inicializado para nuevo usuario: ${user.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error al inicializar notificaciones: $e');
          }
          // No fallar el registro por problemas de notificaciones
        }
      }
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      _loading = true;
      notifyListeners();



      await _authService.signOut();

      _user = null;
      _status = AuthStatus.unauthenticated;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  // Método para actualizar perfil
  Future<bool> updateProfile({
    required String userId,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    String? fotoPerfil,
  }) async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedUser = await _authService.updateUserProfile(
        userId: userId,
        nombre: nombre,
        apellidos: apellidos,
        telefono: telefono,
        fechaNacimiento: fechaNacimiento,
        fotoPerfil: fotoPerfil,
      );

      _user = updatedUser;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para resetear contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
