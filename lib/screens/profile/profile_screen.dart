import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/widgets/custom_button.dart';
import 'package:deportivov1/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:deportivov1/utils/string_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;
  File? _selectedImageFile;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    // Cargar datos del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nombreController.text = user.nombre ?? '';
      _apellidosController.text = user.apellidos ?? '';
      _emailController.text = user.email;
      _telefonoController.text = user.telefono ?? '';
      _fechaNacimiento = user.fechaNacimiento;
      setState(() {
        _profileImageUrl = user.fotoPerfil;
      });
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Si se cancela la edición, restaurar los datos originales
        _loadUserData();
        _selectedImageFile = null;
      }
    });
  }

  Future<void> _selectProfileImage(ImageSource source) async {
    if (!_isEditing) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) return;

      setState(() {
        _selectedImageFile = File(image.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImageFile == null) return _profileImageUrl;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final Uint8List bytes = await _selectedImageFile!.readAsBytes();
      final String fileExt = path.extension(_selectedImageFile!.path);
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}$fileExt';

      // Usar el nuevo método en SupabaseService para subir la imagen
      final String? imageUrl = await SupabaseService.uploadProfileImage(
        bytes,
        fileName,
      );

      if (imageUrl == null) {
        throw Exception('No se pudo obtener la URL de la imagen');
      }

      return imageUrl;
    } catch (e) {
      print('Error al subir imagen de perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Ver solución',
              onPressed: () {
                // Mostrar un diálogo con instrucciones para el administrador
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Configuración requerida'),
                        content: const Text(
                          'Es necesario configurar los permisos de almacenamiento en Supabase para permitir la subida de imágenes de perfil. Por favor contacta con el administrador del sistema.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null) {
        // Primero subir la imagen si hay una nueva
        String? imageUrl;
        if (_selectedImageFile != null) {
          imageUrl = await _uploadProfileImage();
        }

        final success = await authProvider.updateProfile(
          userId: userId,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
          fechaNacimiento: _fechaNacimiento,
          fotoPerfil:
              imageUrl, // Pasar la URL de la imagen (o null si no hay cambios)
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          setState(() {
            _isEditing = false;
            _selectedImageFile = null;
            _profileImageUrl = imageUrl ?? _profileImageUrl;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Error al actualizar el perfil',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showProfileImageOptions() async {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _selectProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _selectProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con avatar y nombre
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      // Avatar de usuario
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: _getProfileImage(),
                        child:
                            _isUploadingImage
                                ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : (_profileImageUrl == null &&
                                    _selectedImageFile == null)
                                ? Text(
                                  user.nombre?.isNotEmpty == true
                                      ? user.nombre![0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                                : null,
                      ),
                      // Botón para cambiar imagen
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isEditing ? _showProfileImageOptions : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  _isEditing
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _isEditing ? Icons.camera_alt : Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    Text(
                      '${user.nombre ?? ''} ${user.apellidos ?? ''}'.trim(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalizeFirstLetter(user.tipoUsuario.name),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Contenido del formulario
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      CustomTextField(
                        controller: _nombreController,
                        label: 'Nombre',
                        hint: 'Tu nombre',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, introduce tu nombre';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _apellidosController,
                        label: 'Apellidos',
                        hint: 'Tus apellidos',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, introduce tus apellidos';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Correo electrónico',
                        hint: 'nombre@ejemplo.com',
                        prefixIcon: Icons.email_outlined,
                        enabled: false,
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _telefonoController,
                        label: 'Teléfono',
                        hint: 'Tu número de teléfono',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Selector de fecha con nuevo diseño
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de nacimiento',
                            style: TextStyle(
                              color: AppTheme.darkColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _fechaNacimiento != null
                                        ? _dateFormat.format(_fechaNacimiento!)
                                        : 'Selecciona tu fecha de nacimiento',
                                    style: TextStyle(
                                      color:
                                          _fechaNacimiento != null
                                              ? AppTheme.darkColor
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      CustomButton(
                        text: 'Guardar cambios',
                        onPressed: _saveProfile,
                        isLoading: authProvider.isLoading,
                        fullWidth: true,
                      ),
                    ] else ...[
                      // Vista de información en modo lectura
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoItemNew(
                              'Correo electrónico',
                              user.email,
                              Icons.email_outlined,
                            ),
                            if (user.telefono?.isNotEmpty == true)
                              _buildInfoItemNew(
                                'Teléfono',
                                user.telefono!,
                                Icons.phone_outlined,
                              ),
                            if (user.fechaNacimiento != null)
                              _buildInfoItemNew(
                                'Fecha de nacimiento',
                                _dateFormat.format(user.fechaNacimiento!),
                                Icons.calendar_today,
                              ),
                            _buildInfoItemNew(
                              'Tipo de usuario',
                              _capitalizeFirstLetter(user.tipoUsuario.name),
                              Icons.badge_outlined,
                            ),
                            if (user.fechaRegistro != null)
                              _buildInfoItemNew(
                                'Fecha de registro',
                                _dateFormat.format(user.fechaRegistro!),
                                Icons.access_time,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sección de preferencias con nuevo diseño
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferencias',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildPreferenceItemNew(
                              'Notificaciones',
                              'Recibir notificaciones sobre actividades y reservas',
                              true,
                            ),
                            _buildPreferenceItemNew(
                              'Boletín informativo',
                              'Recibir información sobre eventos y promociones',
                              false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón de cerrar sesión con nuevo diseño
                      CustomButton(
                        text: 'Cerrar sesión',
                        onPressed: _signOut,
                        type: ButtonType.outline,
                        fullWidth: true,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Si está en modo edición y la validación del formulario es correcta
      // mostrar botón de guardar
      floatingActionButton:
          _isEditing
              ? FloatingActionButton(
                onPressed: _saveProfile,
                child: const Icon(Icons.save),
                backgroundColor: AppTheme.primaryColor,
              )
              : null,
    );
  }

  // Método auxiliar para obtener la imagen de perfil
  ImageProvider? _getProfileImage() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(_profileImageUrl!);
    }
    return null;
  }

  Widget _buildInfoItemNew(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItemNew(String title, String description, bool value) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función en desarrollo'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
