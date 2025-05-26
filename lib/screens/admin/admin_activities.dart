import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:deportivov1/services/activity_service.dart';
import 'package:deportivov1/services/installation_service.dart';
import 'package:deportivov1/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:deportivov1/services/supabase_service.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  List<Activity> _activities = [];
  List<ActivityFamily> _families = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('AdminActivitiesScreen - initState called');
    _loadData();
  }

  Future<void> _loadData() async {
    print('AdminActivitiesScreen - _loadData started');
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar actividades y familias de forma paralela
      // Aumentar el límite para asegurar que se carguen todas las actividades
      final activitiesFuture = ActivityService.getActivitiesWithFamily(
        limit: 50,
      );
      final familiesFuture = ActivityService.getAllActivityFamilies();

      final results = await Future.wait([activitiesFuture, familiesFuture]);

      if (mounted) {
        final activities = results[0] as List<Activity>;
        final families = results[1] as List<ActivityFamily>;

        print(
          'AdminActivitiesScreen - Actividades cargadas: ${activities.length}',
        );
        print('AdminActivitiesScreen - Familias cargadas: ${families.length}');

        setState(() {
          _activities = activities;
          _families = families;
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
            content: Text('Error al cargar datos. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteActivity(String activityId, String activityName) async {
    // Verificar si el widget está montado
    if (!mounted) return;

    // Capturar contexto del ScaffoldMessenger antes de cualquier operación asíncrona
    final scaffoldMessengerContext = ScaffoldMessenger.of(context);

    // Confirmar eliminación
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar actividad'),
            content: Text(
              '¿Estás seguro de que deseas eliminar la actividad "$activityName"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Verificar si el widget sigue montado después del diálogo
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ActivityService.deleteActivity(activityId);

      // Verificar nuevamente si el widget está montado
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Usar el contexto capturado para mostrar el SnackBar
        scaffoldMessengerContext.showSnackBar(
          SnackBar(
            content: Text('Actividad "$activityName" eliminada correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadData(); // Recargar datos
      } else {
        // Usar el contexto capturado para mostrar el SnackBar
        scaffoldMessengerContext.showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la actividad'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar actividad: $e');

      // Verificar nuevamente si el widget está montado
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Usar el contexto capturado para mostrar el SnackBar
      scaffoldMessengerContext.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showEditActivityDialog(Activity? activity) async {
    // Si activity es null, estamos creando una nueva actividad
    final isCreating = activity == null;

    // Si estamos creando, necesitamos cargar instalaciones primero
    List<Map<String, dynamic>> installations = [];
    if (isCreating) {
      try {
        installations = await InstallationService.getAllInstallationsAsMap();
        if (installations.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error: No hay instalaciones disponibles para asignar a la actividad.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // No continuar si no hay instalaciones
        }
      } catch (e) {
        print('Error al cargar instalaciones: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar instalaciones: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // No continuar si hay error
      }
    }

    // Crear una actividad vacía si estamos creando
    activity ??= Activity(
      id: '',
      nombre: '',
      familiaId: _families.isNotEmpty ? _families.first.id : '',
      instalacionId:
          installations.isNotEmpty ? installations.first['id'].toString() : '',
      plazasMax: 10,
      plazasOcupadas: 0,
      duracionMinutos: 60,
      horaInicio: '09:00',
      horaFin: '10:00',
      fechaInicio: DateTime.now(),
      esRecurrente: true,
      estado: ActivityStatus.activa,
    );

    // Mostrar formulario de edición
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ActivityFormScreen(
              activity: activity!,
              families: _families,
              isCreating: isCreating,
            ),
        fullscreenDialog: true,
      ),
    );

    // Si se cerró el diálogo sin guardar, result será null
    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      if (isCreating) {
        success = await ActivityService.createActivity(result);
      } else {
        success = await ActivityService.updateActivity(activity!.id, result);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCreating
                    ? 'Actividad creada correctamente'
                    : 'Actividad actualizada correctamente',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
          // Recargar datos inmediatamente con el método de fuerza
          _forceRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al ${isCreating ? 'crear' : 'actualizar'} la actividad. Por favor, verifica los datos.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al ${isCreating ? 'crear' : 'actualizar'} actividad: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Método para forzar una recarga completa de datos
  Future<void> _forceRefresh() async {
    print('AdminActivitiesScreen - forceRefresh iniciado');
    setState(() {
      _activities = [];
      _isLoading = true;
    });

    // Esperar un breve momento para asegurar que la BD tenga los nuevos datos
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Cargar actividades y familias de forma paralela con un límite alto
      final activitiesFuture = ActivityService.getActivitiesWithFamily(
        limit: 100,
      );
      final familiesFuture = ActivityService.getAllActivityFamilies();

      final results = await Future.wait([activitiesFuture, familiesFuture]);

      if (mounted) {
        final activities = results[0] as List<Activity>;
        final families = results[1] as List<ActivityFamily>;

        print('ForceRefresh - Actividades cargadas: ${activities.length}');
        if (activities.isNotEmpty) {
          print('ForceRefresh - Nombres de algunas actividades:');
          for (int i = 0; i < activities.length && i < 5; i++) {
            print('  - ${activities[i].nombre}');
          }
        }

        setState(() {
          _activities = activities;
          _families = families;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error en forceRefresh: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar datos. Intenta nuevamente.'),
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
        title: const Text('Gestión de Actividades'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón de recargar en la barra de aplicación
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Recargar actividades',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activities.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_gymnastics,
                      size: 64,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay actividades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.grayColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pulse el botón + para crear una actividad',
                      style: TextStyle(fontSize: 14, color: AppTheme.grayColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showEditActivityDialog(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear actividad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
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
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(activity.estado),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    activity.estado.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              activity.descripcion ?? 'Sin descripción',
                              style: TextStyle(color: AppTheme.darkColor),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: AppTheme.grayColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Plazas: ${activity.plazasOcupadas}/${activity.plazasMax}',
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
                                  '${activity.horaInicio} - ${activity.horaFin}',
                                  style: TextStyle(color: AppTheme.grayColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed:
                                      () => _deleteActivity(
                                        activity.id,
                                        activity.nombre,
                                      ),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _showEditActivityDialog(activity),
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
              ),
      floatingActionButton:
          !_isLoading && _activities.isNotEmpty
              ? FloatingActionButton(
                onPressed: () => _showEditActivityDialog(null),
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.activa:
        return AppTheme.successColor;
      case ActivityStatus.cancelada:
        return AppTheme.errorColor;
      case ActivityStatus.completada:
        return AppTheme.infoColor;
      case ActivityStatus.suspendida:
        return Colors.orange;
      default:
        return AppTheme.grayColor;
    }
  }
}

// Pantalla de formulario para crear/editar actividades
class ActivityFormScreen extends StatefulWidget {
  final Activity activity;
  final List<ActivityFamily> families;
  final bool isCreating;

  const ActivityFormScreen({
    super.key,
    required this.activity,
    required this.families,
    required this.isCreating,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _plazasMaxController;
  late TextEditingController _duracionController;
  late TextEditingController _horaInicioController;
  late TextEditingController _horaFinController;
  late TextEditingController _nivelController;
  late TextEditingController _imagenUrlController;

  // Valores para selección
  String? _selectedFamilyId;
  String? _selectedInstallationId;
  List<String> _selectedDays = [];
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;
  bool _esRecurrente = true;
  ActivityStatus _status = ActivityStatus.activa;
  File? _selectedImageFile;
  bool _isUploadingImage = false;

  // Lista de instalaciones disponibles
  List<Map<String, dynamic>> _installations = [];
  bool _loadingInstallations = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con los valores de la actividad
    _nombreController = TextEditingController(text: widget.activity.nombre);
    _descripcionController = TextEditingController(
      text: widget.activity.descripcion ?? '',
    );
    _plazasMaxController = TextEditingController(
      text: widget.activity.plazasMax.toString(),
    );
    _duracionController = TextEditingController(
      text: widget.activity.duracionMinutos.toString(),
    );
    _horaInicioController = TextEditingController(
      text: _formatTimeString(widget.activity.horaInicio),
    );
    _horaFinController = TextEditingController(
      text: _formatTimeString(widget.activity.horaFin),
    );
    _nivelController = TextEditingController(text: widget.activity.nivel ?? '');
    _imagenUrlController = TextEditingController(
      text: widget.activity.imagenUrl ?? '',
    );

    // Inicializar valores seleccionados
    _selectedFamilyId = widget.activity.familiaId;
    _selectedInstallationId =
        widget.activity.instalacionId.isEmpty
            ? null
            : widget.activity.instalacionId;
    _selectedDays = widget.activity.diasSemana?.toList() ?? [];
    _fechaInicio = widget.activity.fechaInicio;
    _fechaFin = widget.activity.fechaFin;
    _esRecurrente = widget.activity.esRecurrente;
    _status = widget.activity.estado;

    // Cargar las instalaciones
    _loadInstallations();
  }

  // Cargar instalaciones desde la base de datos
  Future<void> _loadInstallations() async {
    setState(() {
      _loadingInstallations = true;
    });

    try {
      // Importar el servicio aquí para evitar dependencias circulares
      final installations =
          await InstallationService.getAllInstallationsAsMap();

      setState(() {
        _installations = installations;
        _loadingInstallations = false;

        // Si no hay ID de instalación seleccionado y hay instalaciones disponibles, seleccionar la primera
        if (_selectedInstallationId == null && _installations.isNotEmpty) {
          _selectedInstallationId = _installations.first['id'].toString();
        }
      });
    } catch (e) {
      print('Error al cargar instalaciones: $e');
      setState(() {
        _loadingInstallations = false;
      });

      // Mostrar un mensaje de error si falla la carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar instalaciones'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para formatear correctamente las horas
  String _formatTimeString(String time) {
    // If the time already has HH:mm format, return as is
    if (!time.contains(':')) return time;

    // If it has seconds, remove them
    return time.split(':').take(2).join(':');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _plazasMaxController.dispose();
    _duracionController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _nivelController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  // Método para seleccionar y subir una imagen a Supabase
  Future<String?> _uploadImage(ImageSource source) async {
    if (_isUploadingImage) return null; // Evitar subidas múltiples

    setState(() {
      _isUploadingImage = true;
    });

    String? uploadedImageUrl;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image == null) {
        setState(() => _isUploadingImage = false);
        return null;
      }

      final Uint8List bytes = await image.readAsBytes();
      final fileExt = path.extension(image.path);
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath =
          'actividades/$fileName'; // Carpeta específica para actividades

      await SupabaseService.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      uploadedImageUrl = SupabaseService.client.storage
          .from('images')
          .getPublicUrl(filePath);

      if (uploadedImageUrl != null) {
        setState(() {
          _imagenUrlController.text = uploadedImageUrl!;
          _selectedImageFile = File(
            image.path,
          ); // Guardar para previsualización
        });
      }
    } catch (e) {
      print('Error al subir imagen para actividad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
    return uploadedImageUrl;
  }

  // Guardar la actividad
  void _saveActivity() {
    if (_formKey.currentState?.validate() != true) return;

    // Normalizar formatos de hora (eliminar los segundos si están presentes)
    String horaInicio = _horaInicioController.text;
    String horaFin = _horaFinController.text;

    // Si tienen formato HH:MM:SS, convertir a HH:MM
    if (horaInicio.split(':').length > 2) {
      horaInicio = horaInicio.substring(0, 5);
    }

    if (horaFin.split(':').length > 2) {
      horaFin = horaFin.substring(0, 5);
    }

    // Convertir los días de la semana de strings a enteros (1=lunes, 2=martes, etc.)
    final Map<String, int> dayToNumber = {
      'lunes': 1,
      'martes': 2,
      'miercoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sabado': 6,
      'domingo': 7,
    };

    // Convertir nombres de días a números
    final List<int> diasSemanaNumeros =
        _selectedDays
            .map((day) => dayToNumber[day] ?? 0)
            .where((number) => number > 0)
            .toList();

    final activityData = {
      'nombre': _nombreController.text,
      'descripcion': _descripcionController.text,
      'familia_id': _selectedFamilyId,
      'instalacion_id': _selectedInstallationId,
      'plazas_max': int.parse(_plazasMaxController.text),
      'duracion_minutos': int.parse(_duracionController.text),
      'dias_semana':
          diasSemanaNumeros, // Ahora usando números en lugar de strings
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'fecha_inicio': _fechaInicio.toIso8601String(),
      'fecha_fin': _fechaFin?.toIso8601String(),
      'es_recurrente': _esRecurrente,
      'nivel': _nivelController.text,
      'estado': _status.name,
      'imagen_url': _imagenUrlController.text,
    };

    Navigator.pop(context, activityData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreating ? 'Nueva Actividad' : 'Editar Actividad'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveActivity,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Familia
              DropdownButtonFormField<String>(
                value: _selectedFamilyId,
                decoration: const InputDecoration(
                  labelText: 'Familia',
                  border: OutlineInputBorder(),
                ),
                items:
                    widget.families.map((family) {
                      return DropdownMenuItem<String>(
                        value: family.id,
                        child: Text(family.nombre),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFamilyId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La familia es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Instalación
              _loadingInstallations
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                    value: _selectedInstallationId,
                    decoration: const InputDecoration(
                      labelText: 'Instalación',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _installations.map((installation) {
                          return DropdownMenuItem<String>(
                            value: installation['id'].toString(),
                            child: Text(installation['nombre']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedInstallationId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La instalación es obligatoria';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),

              // Plazas máximas
              TextFormField(
                controller: _plazasMaxController,
                decoration: const InputDecoration(
                  labelText: 'Plazas máximas',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Las plazas máximas son obligatorias';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duración
              TextFormField(
                controller: _duracionController,
                decoration: const InputDecoration(
                  labelText: 'Duración (minutos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La duración es obligatoria';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Horario
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _horaInicioController,
                      decoration: const InputDecoration(
                        labelText: 'Hora inicio (HH:MM)',
                        border: OutlineInputBorder(),
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
                      controller: _horaFinController,
                      decoration: const InputDecoration(
                        labelText: 'Hora fin (HH:MM)',
                        border: OutlineInputBorder(),
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

              // Días de la semana
              const Text(
                'Días de la semana',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Switch para actividad recurrente
              SwitchListTile(
                title: const Text('Actividad recurrente'),
                subtitle: const Text('La actividad se repite semanalmente'),
                value: _esRecurrente,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _esRecurrente = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Estado
              DropdownButtonFormField<ActivityStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items:
                    ActivityStatus.values.map((status) {
                      return DropdownMenuItem<ActivityStatus>(
                        value: status,
                        child: Text(status.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Nivel
              TextFormField(
                controller: _nivelController,
                decoration: const InputDecoration(
                  labelText: 'Nivel (principiante, intermedio, avanzado)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo para URL de imagen o selección de galería
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Imagen de la Actividad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imagenUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen (opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'https://ejemplo.com/imagen.jpg',
                          ),
                          // Puedes añadir validación si es necesario
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
                            _isUploadingImage
                                ? null
                                : () => _uploadImage(ImageSource.gallery),
                        tooltip: 'Seleccionar de galería',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isUploadingImage)
                    const Center(child: CircularProgressIndicator()),
                  if (!_isUploadingImage && _selectedImageFile != null)
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
                  else if (!_isUploadingImage &&
                      _imagenUrlController.text.isNotEmpty)
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.isCreating ? 'Crear Actividad' : 'Guardar Cambios',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, String day) {
    final isSelected = _selectedDays.contains(day);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
    );
  }
}
