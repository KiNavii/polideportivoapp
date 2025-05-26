import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 18)), // Default 18 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Verificar que las contraseñas coincidan
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorSnackbar('Las contraseñas no coinciden');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
          fechaNacimiento: _fechaNacimiento, // Puede ser nulo si no se selecciona
        );

        if (success) {
          // Registro exitoso, navegar a la pantalla principal o de verificación de email
          // Depende de la implementación de tu AuthProvider y flujo de registro
          // Por ahora, navegamos a la principal (asumiendo auto-login o verificación separada)
           Navigator.pushReplacementNamed(context, '/');
        } else {
           // Manejar el caso si signUp no lanza excepción pero no fue exitoso
           _showErrorSnackbar(authProvider.errorMessage ?? 'Error en el registro. Intenta nuevamente.');
        }
      } catch (e) {
        // Manejar errores
        _showErrorSnackbar('Error en el registro: ${e.toString()}');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registro'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor, // Usar color del tema
        foregroundColor: Colors.white,
        elevation: 0, // Sin sombra
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Título
                Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                 const SizedBox(height: 8.0),
                 Text(
                   'Completa tus datos para unirte',
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 16,
                     color: Colors.grey[600],
                   ),
                 ),
                const SizedBox(height: 40.0),

                 // Campo de Nombre
                 TextFormField(
                   controller: _nombreController,
                   decoration: InputDecoration(
                     labelText: 'Nombre',
                     prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryColor.withOpacity(0.7)),
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
                       return 'Por favor, ingresa tu nombre';
                     }
                     return null;
                   },
                 ),
                const SizedBox(height: 20.0),

                // Campo de Apellidos
                 TextFormField(
                   controller: _apellidosController,
                   decoration: InputDecoration(
                     labelText: 'Apellidos',
                     prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryColor.withOpacity(0.7)),
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
                       return 'Por favor, ingresa tus apellidos';
                     }
                     return null;
                   },
                 ),
                const SizedBox(height: 20.0),

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
                     if (!value.contains('@') || !value.contains('.')) {
                       return 'Ingresa un email válido';
                     }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                 // Campo de Teléfono
                 TextFormField(
                   controller: _telefonoController,
                   keyboardType: TextInputType.phone,
                   decoration: InputDecoration(
                     labelText: 'Teléfono',
                     prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryColor.withOpacity(0.7)),
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
                       return 'Por favor, ingresa tu teléfono';
                     }
                     return null;
                   },
                 ),
                 const SizedBox(height: 20.0),

                 // Campo de Fecha de Nacimiento
                 GestureDetector(
                   onTap: () => _selectDate(context),
                   child: AbsorbPointer( // Evita que el campo de texto se active
                     child: TextFormField(
                       readOnly: true, // No permite escribir directamente
                       controller: TextEditingController( // Usar un controlador temporal para mostrar la fecha
                         text: _fechaNacimiento == null
                             ? 'Seleccionar fecha'
                             : DateFormat('dd/MM/yyyy').format(_fechaNacimiento!),
                       ),
                       decoration: InputDecoration(
                         labelText: 'Fecha de Nacimiento',
                         prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor.withOpacity(0.7)),
                          border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(12.0),
                             borderSide: BorderSide.none,
                           ),
                           filled: true,
                           fillColor: Colors.grey[200],
                           contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                         suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor.withOpacity(0.7)),
                       ),
                        validator: (value) {
                          if (_fechaNacimiento == null) {
                            return 'Por favor, selecciona tu fecha de nacimiento';
                          }
                          return null;
                        },
                     ),
                   ),
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
                      return 'Por favor, ingresa una contraseña';
                    }
                     if (value.length < 6) { // Ejemplo: requerir al menos 6 caracteres
                       return 'La contraseña debe tener al menos 6 caracteres';
                     }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
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
                         _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.primaryColor.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // Botón de Registrarse
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
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Hacer transparente para mostrar el gradiente
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ),

                const SizedBox(height: 20.0),

                // Enlace Ya tienes una cuenta
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [ // Centrar el texto y el botón
                     Text(
                        '¿Ya tienes una cuenta?',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                     ),
                     TextButton(
                       onPressed: () {
                         // Navegar de vuelta a la pantalla de login
                          Navigator.pop(context); // O Navigator.pushReplacementNamed(context, '/login');
                       },
                       child: Text(
                         'Iniciar sesión',
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
