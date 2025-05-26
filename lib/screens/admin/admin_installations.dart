import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/installation_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:deportivov1/screens/admin/admin_courts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/models/installation_model.dart';

class AdminInstallationsScreen extends StatefulWidget {
  const AdminInstallationsScreen({super.key});

  @override
  State<AdminInstallationsScreen> createState() =>
      _AdminInstallationsScreenState();
}

class _AdminInstallationsScreenState extends State<AdminInstallationsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _installations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      _installations = await InstallationService.getAllInstallationsAsMap(
        limit: 50,
      );
      print('Instalaciones cargadas: ${_installations.length}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar datos. Intenta nuevamente: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Instalaciones'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de recargar en la barra de aplicaciones
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Recargar instalaciones',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _installations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_basketball,
                      size: 64,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay instalaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pulse el botón + para crear una nueva instalación',
                      style: TextStyle(fontSize: 14, color: AppTheme.grayColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditInstallationDialog(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear instalación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _forceRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recargar datos'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _forceRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  itemCount: _installations.length,
                  itemBuilder: (context, index) {
                    final installation = _installations[index];
                    return _buildInstallationCard(installation);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditInstallationDialog(null),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis, size: 64, color: AppTheme.grayColor),
          const SizedBox(height: 16),
          Text(
            'No hay instalaciones registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.grayColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddEditInstallationDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Añadir instalación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationCard(Map<String, dynamic> installation) {
    final status = installation['estado'] ?? 'disponible';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de cabecera (placeholder)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.grayColor.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusM),
                topRight: Radius.circular(AppTheme.radiusM),
              ),
            ),
            child: Center(
              child: Icon(
                _getInstallationIcon(installation['tipo']),
                size: 64,
                color: AppTheme.grayColor,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        installation['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Descripción
                Text(
                  installation['descripcion'] ?? 'Sin descripción disponible',
                  style: TextStyle(color: AppTheme.darkColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Tipo y capacidad
                Row(
                  children: [
                    Icon(
                      _getInstallationIcon(installation['tipo']),
                      size: 16,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      installation['tipo']?.toString().toUpperCase() ??
                          'TIPO DESCONOCIDO',
                      style: TextStyle(
                        color: AppTheme.grayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Capacidad: ${installation['capacidad_max'] ?? installation['capacidad'] ?? 'N/A'}',
                      style: TextStyle(color: AppTheme.grayColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Horario
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // Primero intentar con horario estructurado, luego con horario simple
                      (installation['horario'] != null)
                          ? _getHorarioResumen(installation['horario'])
                          : (installation['hora_apertura'] != null &&
                              installation['hora_cierre'] != null)
                          ? '${_formatTimeString(installation['hora_apertura'])} - ${_formatTimeString(installation['hora_cierre'])}'
                          : 'Horario no disponible',
                      style: TextStyle(color: AppTheme.grayColor),
                    ),
                    TextButton(
                      onPressed: () {
                        if (!mounted) return;

                        if (installation['horario'] != null) {
                          _showHorarioDialog(installation);
                        } else if (installation['hora_apertura'] != null &&
                            installation['hora_cierre'] != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Horario de apertura: ${installation['hora_apertura']}, Cierre: ${installation['hora_cierre']}',
                              ),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No hay información de horario disponible',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Ver horario',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(installation),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    // Add a button to manage courts if installation has courts
                    if (installation['caracteristicas_json'] != null &&
                        (installation['caracteristicas_json'] is String
                            ? jsonDecode(
                                  installation['caracteristicas_json'],
                                )['tiene_pistas'] ==
                                true
                            : installation['caracteristicas_json']['tiene_pistas'] ==
                                true))
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AdminCourtsScreen(
                                      installationId:
                                          installation['id'].toString(),
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sports_baseball),
                          label: const Text('Pistas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed:
                          () => _showAddEditInstallationDialog(installation),
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
        ],
      ),
    );
  }

  void _showAddEditInstallationDialog(
    Map<String, dynamic>? installation,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Pasar el contexto del Scaffold principal si es necesario para SnackBars
        return _AddEditInstallationDialog(
          installation: installation,
          scaffoldContext: context,
        );
      },
    );

    if (result == true) {
      _loadData(); // Recargar datos si se guardó algo
    }
  }

  void _showHorarioDialog(Map<String, dynamic> installation) {
    final horario = installation['horario'] as Map<String, dynamic>?;

    if (horario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay información de horario disponible'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Horario de ${installation['nombre']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHorarioItem('Lunes', horario['lunes']),
                  _buildHorarioItem('Martes', horario['martes']),
                  _buildHorarioItem('Miércoles', horario['miercoles']),
                  _buildHorarioItem('Jueves', horario['jueves']),
                  _buildHorarioItem('Viernes', horario['viernes']),
                  _buildHorarioItem('Sábado', horario['sabado']),
                  _buildHorarioItem('Domingo', horario['domingo']),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildHorarioItem(String day, Map<String, dynamic>? hours) {
    if (hours == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Text('Cerrado'),
          ],
        ),
      );
    }

    final apertura = _formatTimeString(hours['apertura']);
    final cierre = _formatTimeString(hours['cierre']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text('$apertura - $cierre'),
        ],
      ),
    );
  }

  String _getHorarioResumen(Map<String, dynamic>? horario) {
    // Si hay horarios estructurados
    if (horario != null) {
      final lunes = horario['lunes'];
      if (lunes != null) {
        return '${lunes['apertura']} - ${lunes['cierre']} (L-V)';
      }
      return 'Consultar horarios';
    }

    return 'No disponible';
  }

  IconData _getInstallationIcon(String? tipo) {
    switch (tipo) {
      case 'piscina':
        return Icons.pool;
      case 'cancha':
        return Icons.sports_basketball;
      case 'gimnasio':
        return Icons.fitness_center;
      case 'pista':
        return Icons.sports_tennis;
      case 'pista_polivalente':
        return Icons.sports_soccer;
      case 'sala':
        return Icons.meeting_room;
      default:
        return Icons.sports;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disponible':
        return AppTheme.successColor;
      case 'mantenimiento':
        return Colors.orange;
      case 'cerrado':
        return AppTheme.errorColor;
      default:
        return AppTheme.grayColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'mantenimiento':
        return 'En mantenimiento';
      case 'cerrado':
        return 'Cerrado';
      default:
        return status;
    }
  }

  // Diálogo de confirmación para eliminar
  void _showDeleteConfirmDialog(Map<String, dynamic> installation) {
    // Verificar si el widget está montado antes de continuar
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar instalación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro que deseas eliminar "${installation['nombre'] ?? 'esta instalación'}"?',
                ),
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
                  // Capturar ID y nombre antes de cerrar diálogo
                  final String installationId = installation['id'].toString();
                  final String installationName =
                      installation['nombre'] ?? 'la instalación';

                  // Capturar el contexto del scaffold antes de cerrarlo
                  final scaffoldMessengerContext = ScaffoldMessenger.of(
                    context,
                  );

                  // Cerrar diálogo
                  Navigator.pop(context);

                  // Mostrar loading
                  if (mounted) {
                    setState(() => _isLoading = true);
                  }

                  try {
                    // Realizar eliminación
                    bool success = await InstallationService.deleteInstallation(
                      installationId,
                    );

                    // Recargar lista independientemente del resultado
                    await _forceRefresh();

                    // Verificar si el widget sigue montado antes de continuar
                    if (!mounted) return;

                    // Actualizar estado de loading
                    setState(() => _isLoading = false);

                    // Mostrar mensajes según resultado usando el contexto capturado
                    if (success) {
                      scaffoldMessengerContext.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Instalación "$installationName" eliminada correctamente',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      scaffoldMessengerContext.showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar instalación'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error al eliminar: $e');

                    // Verificar si el widget sigue montado antes de actualizar UI
                    if (!mounted) return;

                    setState(() => _isLoading = false);

                    // Usar el contexto capturado para mostrar el mensaje de error
                    scaffoldMessengerContext.showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  String _formatTimeString(String time) {
    // If the time already has HH:mm format, return as is
    if (!time.contains(':')) return time;

    // If it has seconds, remove them
    return time.split(':').take(2).join(':');
  }
}

// Widget de Diálogo para Añadir/Editar Instalación
class _AddEditInstallationDialog extends StatefulWidget {
  final Map<String, dynamic>? installation;
  final BuildContext
  scaffoldContext; // Para mostrar SnackBars globales si es necesario

  const _AddEditInstallationDialog({
    this.installation,
    required this.scaffoldContext,
  });

  @override
  _AddEditInstallationDialogState createState() =>
      _AddEditInstallationDialogState();
}

class _AddEditInstallationDialogState
    extends State<_AddEditInstallationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _tipoController;
  late TextEditingController _capacidadController;
  late TextEditingController _ubicacionController;
  late TextEditingController _imagenUrlController;
  late TextEditingController _horaAperturaController;
  late TextEditingController _horaCierreController;
  late TextEditingController _duracionMinReservaController;
  late TextEditingController _duracionMaxReservaController;

  String _estado = 'disponible';
  bool _tienePistas = false;
  List<String> _diasDisponibles = [];
  File? _selectedImageFile;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final inst = widget.installation;

    // Inicializar controladores con valores existentes o vacíos
    _nombreController = TextEditingController(text: inst?['nombre'] ?? '');
    _descripcionController = TextEditingController(
      text: inst?['descripcion'] ?? '',
    );
    _tipoController = TextEditingController(text: inst?['tipo'] ?? '');
    _capacidadController = TextEditingController(
      text: inst?['capacidad_max']?.toString() ?? '',
    );
    _ubicacionController = TextEditingController(
      text: inst?['ubicacion'] ?? '',
    );
    _imagenUrlController = TextEditingController(text: inst?['foto_url'] ?? '');

    // Extraer valores de caracteristicas_json
    Map<String, dynamic> caracteristicas = {};
    if (inst?['caracteristicas_json'] != null) {
      caracteristicas =
          inst!['caracteristicas_json'] is String
              ? jsonDecode(inst['caracteristicas_json'])
              : inst['caracteristicas_json'];
    }

    _horaAperturaController = TextEditingController(
      text: caracteristicas['hora_apertura'] ?? '09:00',
    );
    _horaCierreController = TextEditingController(
      text: caracteristicas['hora_cierre'] ?? '22:00',
    );
    _duracionMinReservaController = TextEditingController(
      text: caracteristicas['duracion_min_reserva']?.toString() ?? '60',
    );
    _duracionMaxReservaController = TextEditingController(
      text: caracteristicas['duracion_max_reserva']?.toString() ?? '120',
    );

    _estado = inst?['estado'] ?? 'disponible';
    _tienePistas = caracteristicas['tiene_pistas'] ?? false;
    _diasDisponibles = List<String>.from(
      caracteristicas['dias_disponibles'] ?? [],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _capacidadController.dispose();
    _ubicacionController.dispose();
    _imagenUrlController.dispose();
    _horaAperturaController.dispose();
    _horaCierreController.dispose();
    _duracionMinReservaController.dispose();
    _duracionMaxReservaController.dispose();
    super.dispose();
  }

  Future<String?> _pickAndUploadImage(ImageSource source) async {
    if (_isProcessing) return null;

    setState(() {
      _isProcessing = true;
    });

    String? uploadedImageUrl;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) {
        if (mounted) setState(() => _isProcessing = false);
        return null;
      }

      final Uint8List bytes = await image.readAsBytes();
      final fileExt = path.extension(image.path);
      final fileName = 'inst_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'instalaciones/$fileName';

      await SupabaseService.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      uploadedImageUrl = SupabaseService.client.storage
          .from('images')
          .getPublicUrl(filePath);

      if (uploadedImageUrl != null && mounted) {
        setState(() {
          _imagenUrlController.text = uploadedImageUrl!;
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error al subir imagen para instalación: $e');
      if (mounted) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          // Usar scaffoldContext
          SnackBar(
            content: Text('Error al subir la imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
    return uploadedImageUrl;
  }

  Future<void> _saveInstallation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      bool success = false;
      if (widget.installation == null) {
        // Crear nueva instalación
        success = await InstallationService.createInstallation(
          nombre: _nombreController.text,
          tipo: _tipoController.text,
          descripcion:
              _descripcionController.text.isNotEmpty
                  ? _descripcionController.text
                  : null,
          capacidadMax: int.tryParse(_capacidadController.text),
          disponible: _estado == 'disponible',
          imagenUrl:
              _imagenUrlController.text.isNotEmpty
                  ? _imagenUrlController.text
                  : null,
          ubicacion:
              _ubicacionController.text.isNotEmpty
                  ? _ubicacionController.text
                  : null,
          duracionMinReserva: int.tryParse(_duracionMinReservaController.text),
          duracionMaxReserva: int.tryParse(_duracionMaxReservaController.text),
          horaApertura: _horaAperturaController.text,
          horaCierre: _horaCierreController.text,
          diasDisponibles: _diasDisponibles,
          tienePistas: _tienePistas,
        );
      } else {
        // Actualizar instalación existente
        success = await InstallationService.updateInstallation(
          id: widget.installation!['id'].toString(),
          nombre: _nombreController.text,
          tipo: _tipoController.text,
          descripcion:
              _descripcionController.text.isNotEmpty
                  ? _descripcionController.text
                  : null,
          capacidadMax: int.tryParse(_capacidadController.text),
          disponible: _estado == 'disponible',
          imagenUrl:
              _imagenUrlController.text.isNotEmpty
                  ? _imagenUrlController.text
                  : null,
          ubicacion:
              _ubicacionController.text.isNotEmpty
                  ? _ubicacionController.text
                  : null,
          duracionMinReserva: int.tryParse(_duracionMinReservaController.text),
          duracionMaxReserva: int.tryParse(_duracionMaxReservaController.text),
          horaApertura: _horaAperturaController.text,
          horaCierre: _horaCierreController.text,
          diasDisponibles: _diasDisponibles,
          tienePistas: _tienePistas,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Instalación ${widget.installation == null ? 'creada' : 'actualizada'} correctamente'
                  : 'Error al ${widget.installation == null ? 'crear' : 'actualizar'} la instalación',
            ),
            backgroundColor:
                success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
        if (success) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('Error al guardar instalación: $e');
      if (mounted) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Error crítico al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.installation == null
            ? 'Nueva Instalación'
            : 'Editar Instalación',
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica
                const Text(
                  'Información básica',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    hintText: 'Ej: Piscina, Gimnasio, Cancha...',
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'El tipo es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacidadController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad máxima',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.toggle_on),
                  ),
                  items:
                      ['disponible', 'mantenimiento', 'cerrada']
                          .map(
                            (label) => DropdownMenuItem(
                              value: label,
                              child: Text(label.capitalizeFirst()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _estado = value);
                  },
                ),

                const SizedBox(height: 32),
                // Configuración de reservas
                const Text(
                  'Configuración de reservas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _horaAperturaController,
                        decoration: const InputDecoration(
                          labelText: 'Hora apertura',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                          hintText: 'HH:MM',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          // Validate only HH:MM format
                          if (!RegExp(
                            r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
                          ).hasMatch(value)) {
                            return 'Formato inválido (HH:MM)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _horaCierreController,
                        decoration: const InputDecoration(
                          labelText: 'Hora cierre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                          hintText: 'HH:MM',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          // Validate only HH:MM format
                          if (!RegExp(
                            r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$',
                          ).hasMatch(value)) {
                            return 'Formato inválido (HH:MM)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _duracionMinReservaController,
                        decoration: const InputDecoration(
                          labelText: 'Duración mínima (min)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _duracionMaxReservaController,
                        decoration: const InputDecoration(
                          labelText: 'Duración máxima (min)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer_off),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Días disponibles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDayChip('Lunes', 'lunes'),
                    _buildDayChip('Martes', 'martes'),
                    _buildDayChip('Miércoles', 'miercoles'),
                    _buildDayChip('Jueves', 'jueves'),
                    _buildDayChip('Viernes', 'viernes'),
                    _buildDayChip('Sábado', 'sabado'),
                    _buildDayChip('Domingo', 'domingo'),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Tiene pistas'),
                  subtitle: const Text(
                    'La instalación cuenta con pistas reservables',
                  ),
                  value: _tienePistas,
                  onChanged: (value) {
                    if (value != null) setState(() => _tienePistas = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 32),
                // Imagen
                const Text(
                  'Imagen de la instalación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imagenUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de imagen',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          hintText: 'https://ejemplo.com/imagen.jpg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        Icons.photo_library,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                      onPressed:
                          _isProcessing
                              ? null
                              : () => _pickAndUploadImage(ImageSource.gallery),
                      tooltip: 'Seleccionar de galería',
                    ),
                  ],
                ),
                if (_isProcessing && _selectedImageFile == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_selectedImageFile != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: FileImage(_selectedImageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (_imagenUrlController.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.network(
                      _imagenUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircularProgressIndicator(),
          ),
        TextButton(
          onPressed:
              _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _saveInstallation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.installation == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildDayChip(String label, String day) {
    final isSelected = _diasDisponibles.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _diasDisponibles.add(day);
          } else {
            _diasDisponibles.remove(day);
          }
        });
      },
    );
  }
}

extension StringExtensions on String {
  String capitalizeFirst() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
