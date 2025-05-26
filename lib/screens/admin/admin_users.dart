import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/user_service.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _usersList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar usuarios desde la base de datos usando el UserService
      _usersList = await UserService.getAllUsers(limit: 100);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Socios'),
            Tab(text: 'Administradores'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersList(_usersList),
                  _buildUsersList(
                    _usersList
                        .where((user) => user['tipo_usuario'] == 'socio')
                        .toList(),
                  ),
                  _buildUsersList(
                    _usersList
                        .where(
                          (user) => user['tipo_usuario'] == 'administrador',
                        )
                        .toList(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: AppTheme.grayColor),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios en esta categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grayColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          (user['nombre'] ?? 'U')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: _getUserTypeColor(
                          user['tipo_usuario'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user['nombre'] ?? ''} ${user['apellidos'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              user['email'] ?? 'Sin email',
                              style: TextStyle(
                                color: AppTheme.grayColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getUserStatusColor(user['esta_activo']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getUserStatusText(user['esta_activo']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: AppTheme.grayColor),
                      const SizedBox(width: 8),
                      Text(
                        user['telefono'] ?? 'No disponible',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.grayColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Registro: ${_formatDate(user['fecha_registro'])}',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.grayColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Última conexión: ${_formatDateTime(user['ultima_conexion'])}',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          _toggleUserStatus(user['id'], user['esta_activo']);
                        },
                        icon: Icon(
                          user['esta_activo'] == true
                              ? Icons.block
                              : Icons.check_circle,
                          color:
                              user['esta_activo'] == true
                                  ? Colors.red
                                  : Colors.green,
                        ),
                        tooltip:
                            user['esta_activo'] == true
                                ? 'Bloquear usuario'
                                : 'Activar usuario',
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmDialog(context, user);
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        tooltip: 'Eliminar usuario',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showEditUserDialog(context, user);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Método para cambiar el estado de un usuario (activo/bloqueado)
  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      setState(() => _isLoading = true);

      bool success = await UserService.updateUserStatus(userId, !currentStatus);

      if (success) {
        // Recargar los datos para mostrar el cambio
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Usuario bloqueado correctamente'
                  : 'Usuario activado correctamente',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar el estado del usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al cambiar estado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar el estado del usuario'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Fecha desconocida';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Formato de fecha inválido';
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Fecha desconocida';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Formato de fecha inválido';
    }
  }

  Color _getUserTypeColor(String? type) {
    switch (type) {
      case 'administrador':
        return Colors.purple;
      case 'socio':
        return Colors.blue;
      case 'monitor':
        return Colors.orange;
      default:
        return AppTheme.grayColor;
    }
  }

  Color _getUserStatusColor(bool? isActive) {
    return isActive == true ? AppTheme.successColor : AppTheme.errorColor;
  }

  String _getUserStatusText(bool? isActive) {
    return isActive == true ? 'Activo' : 'Bloqueado';
  }

  // Diálogo para añadir un nuevo usuario
  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String apellidos = '';
    String email = '';
    String telefono = '';
    String password = '';
    String tipoUsuario = 'socio'; // Por defecto, socio

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Añadir nuevo usuario'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => nombre = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Apellidos *',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => apellidos = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (!value.contains('@')) return 'Email inválido';
                          return null;
                        },
                        onSaved: (value) => email = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Contraseña *',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Requerido';
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                        onSaved: (value) => password = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (value) => telefono = value!,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Configuración de usuario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de usuario',
                          border: OutlineInputBorder(),
                        ),
                        value: tipoUsuario,
                        items: const [
                          DropdownMenuItem(
                            value: 'socio',
                            child: Text('Socio'),
                          ),
                          DropdownMenuItem(
                            value: 'administrador',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'monitor',
                            child: Text('Monitor'),
                          ),
                        ],
                        onChanged: (value) => tipoUsuario = value!,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    Navigator.pop(context);

                    setState(() => _isLoading = true);

                    try {
                      // Implementar registro de usuario
                      final success = await _registerUser(
                        email: email,
                        password: password,
                        nombre: nombre,
                        apellidos: apellidos,
                        telefono: telefono,
                        tipoUsuario: tipoUsuario,
                      );

                      if (success) {
                        await _loadData(); // Recargar lista
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Usuario creado correctamente'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al crear usuario'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error al registrar usuario: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // Método para registrar un nuevo usuario
  Future<bool> _registerUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    required String tipoUsuario,
    String? telefono,
  }) async {
    try {
      // Implementamos el registro usando AuthService a través de UserService
      await UserService.registerUser(
        email: email,
        password: password,
        nombre: nombre,
        apellidos: apellidos,
        telefono: telefono,
        tipoUsuario: tipoUsuario,
      );
      return true;
    } catch (e) {
      print('Error al registrar usuario: $e');
      rethrow; // Relanzar para manejo en UI
    }
  }

  // Diálogo para editar un usuario existente
  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    String nombre = user['nombre'] ?? '';
    String apellidos = user['apellidos'] ?? '';
    String telefono = user['telefono'] ?? '';
    String tipoUsuario = user['tipo_usuario'] ?? 'socio';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar usuario'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: nombre,
                        validator:
                            (value) => value!.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => nombre = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Apellidos *',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: apellidos,
                        validator:
                            (value) => value!.isEmpty ? 'Requerido' : null,
                        onSaved: (value) => apellidos = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                        initialValue: user['email'],
                        enabled: false, // No permitir cambiar el email
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: telefono,
                        keyboardType: TextInputType.phone,
                        onSaved: (value) => telefono = value!,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Configuración de usuario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de usuario',
                          border: OutlineInputBorder(),
                        ),
                        value: tipoUsuario,
                        items: const [
                          DropdownMenuItem(
                            value: 'socio',
                            child: Text('Socio'),
                          ),
                          DropdownMenuItem(
                            value: 'administrador',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'monitor',
                            child: Text('Monitor'),
                          ),
                        ],
                        onChanged: (value) => tipoUsuario = value!,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    Navigator.pop(context);

                    setState(() => _isLoading = true);

                    try {
                      // Actualizar datos del usuario
                      final success =
                          await UserService.updateUserData(user['id'], {
                            'nombre': nombre,
                            'apellidos': apellidos,
                            'telefono': telefono,
                            'tipo_usuario': tipoUsuario,
                          });

                      if (success) {
                        await _loadData(); // Recargar lista
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Usuario actualizado correctamente',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al actualizar usuario'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error al actualizar usuario: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // Diálogo de confirmación para eliminar usuario
  void _showDeleteConfirmDialog(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar usuario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro que deseas eliminar al usuario "${user['nombre'] ?? ''} ${user['apellidos'] ?? ''}"?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta acción eliminará:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Todas sus inscripciones a actividades'),
                const Text('• Todas sus reservas de instalaciones'),
                const Text('• Toda su información personal'),
                const SizedBox(height: 16),
                const Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  setState(() => _isLoading = true);

                  try {
                    // Eliminar el usuario y todos sus datos asociados
                    final success = await UserService.deleteUser(user['id']);

                    if (success) {
                      await _loadData(); // Recargar lista
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Usuario y todos sus datos eliminados correctamente',
                            ),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al eliminar usuario'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error al eliminar usuario: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}
