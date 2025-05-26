import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Añadir controladores de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar controlador y animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Duración de la animación
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn, // Curva de aceleración
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5), // Empieza ligeramente arriba
      end: Offset.zero, // Termina en la posición original
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Curva para el deslizamiento
    ));

    // Iniciar la animación al cargar la pantalla
    _animationController.forward();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Si el inicio de sesión es exitoso, navegar a la pantalla principal
        if (authProvider.isAuthenticated) {
          // Usar pushReplacementNamed para evitar volver a la pantalla de login
          Navigator.pushReplacementNamed(context, '/'); 
        } else {
           // Manejar el caso si signIn no lanza excepción pero isAuthenticated es false
           _showErrorSnackbar('Error de inicio de sesión. Verifica tus credenciales.');
        }
      } catch (e) {
        // Manejar errores (ej. credenciales inválidas)
        _showErrorSnackbar('Error de inicio de sesión: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose(); // Liberar controlador de animación
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo y Título con Animación
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo de la aplicación (usa tu asset)
                        Image.asset(
                          'assets/images/tfgLogo.png', // <<-- Reemplaza con la ruta correcta si es necesario
                          width: 150, // Ajusta el tamaño según tu logo
                          height: 150, // Ajusta el tamaño según tu logo
                        ),
                        const SizedBox(height: 16.0), // Espacio entre logo y subtítulo
                        // Subtítulo
                        Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600], // Color neutro
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48.0), // Espacio después del encabezado animado

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu email';
                    }
                     // Validación básica de formato de email
                    if (!value.contains('@') || !value.contains('.')) {
                       return 'Ingresa un email válido';
                     }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                     prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                     contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                    suffixIcon: IconButton(
                      icon: Icon(
                         _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu contraseña';
                    }
                     if (value.length < 6) { // Ejemplo: requerir al menos 6 caracteres
                       return 'La contraseña debe tener al menos 6 caracteres';
                     }
                    return null;
                  },
                ),
                const SizedBox(height: 15.0),

                // Enlace Olvidaste tu contraseña
                 Align(
                   alignment: Alignment.centerRight,
                   child: TextButton(
                     onPressed: () {
                       // TODO: Implementar lógica para olvidar contraseña
                       print('Olvidaste tu contraseña presionado');
                     },
                     child: Text(
                       '¿Olvidaste tu contraseña?',
                       style: TextStyle(color: AppTheme.primaryColor, fontSize: 14.0),
                     ),
                   ),
                 ),
                const SizedBox(height: 24.0),

                // Botón de Iniciar Sesión
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                           begin: Alignment.centerLeft,
                           end: Alignment.centerRight,
                         ),
                         borderRadius: BorderRadius.circular(30.0),
                         boxShadow: [ // Sombra similar a la imagen
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                         ],
                      ),
                      child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Hacer transparente para mostrar el gradiente
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ),

                const SizedBox(height: 20.0),

                // Enlace Registrarse
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [ // Centrar el texto y el botón
                     Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                     ),
                     TextButton(
                       onPressed: () {
                         // Navegar a la pantalla de registro usando rutas nombradas
                          Navigator.pushNamed(context, '/register'); // Asumiendo que tienes una ruta /register
                       },
                       child: Text(
                         'Regístrate',
                         style: TextStyle(
                           color: AppTheme.primaryColor,
                           fontSize: 14.0,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                   ],
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
