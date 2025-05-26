import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/court_model.dart';
import 'package:deportivov1/models/installation_model.dart';
import 'package:deportivov1/services/court_service.dart';
import 'package:deportivov1/services/installation_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class AdminCourtsScreen extends StatefulWidget {
  final String? installationId;

  const AdminCourtsScreen({Key? key, this.installationId}) : super(key: key);

  @override
  State<AdminCourtsScreen> createState() => _AdminCourtsScreenState();
}

class _AdminCourtsScreenState extends State<AdminCourtsScreen> {
  bool _isLoading = false;
  List<Court> _courts = [];
  List<Installation> _installations = [];
  Installation? _selectedInstallation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar instalaciones que tienen pistas
      final installations = await InstallationService.getAllInstallations();
      _installations = installations.where((inst) => inst.tienePistas).toList();

      // Si se proporcionó un ID de instalación o si hay instalaciones disponibles
      if (widget.installationId != null) {
        // Buscar la instalación por ID
        _selectedInstallation = _installations.firstWhere(
          (inst) => inst.id == widget.installationId,
          orElse:
              () => _installations.isNotEmpty ? _installations.first : null!,
        );
      } else if (_installations.isNotEmpty) {
        _selectedInstallation = _installations.first;
      }

      // Cargar pistas según la instalación seleccionada
      if (_selectedInstallation != null) {
        await _loadCourts(_selectedInstallation!.id);
      } else {
        _courts = [];
      }

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
          const SnackBar(
            content: Text('Error al cargar datos. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCourts(String installationId) async {
    try {
      _courts = await CourtService.getCourtsByInstallation(installationId);
    } catch (e) {
      print('Error al cargar pistas: $e');
      _courts = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pistas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Recargar pistas',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_installations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Instalación',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedInstallation?.id,
                      items:
                          _installations
                              .map(
                                (installation) => DropdownMenuItem(
                                  value: installation.id,
                                  child: Text(installation.nombre),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedInstallation = _installations.firstWhere(
                              (inst) => inst.id == value,
                            );
                          });
                          _loadCourts(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed:
                        _selectedInstallation != null
                            ? () => _showAddEditCourtDialog(null)
                            : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Pista'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _courts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _courts.length,
                      itemBuilder: (context, index) {
                        return _buildCourtCard(_courts[index]);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _installations.isEmpty || _selectedInstallation == null
              ? null
              : FloatingActionButton(
                onPressed: () => _showAddEditCourtDialog(null),
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.add),
              ),
    );
  }

  Widget _buildEmptyState() {
    if (_selectedInstallation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_baseball_outlined,
              size: 64,
              color: AppTheme.grayColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay instalaciones con pistas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Primero debe crear instalaciones y marcarlas como "tiene pistas"',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis, size: 64, color: AppTheme.grayColor),
          const SizedBox(height: 16),
          Text(
            'No hay pistas para ${_selectedInstallation!.nombre}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulse el botón + para crear una nueva pista',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddEditCourtDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('Crear pista'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(Court court) {
    // Función auxiliar para mapear el estado a un color
    Color _getStatusColor(CourtStatus status) {
      switch (status) {
        case CourtStatus.disponible:
          return Colors.green;
        case CourtStatus.ocupada:
          return Colors.orange;
        case CourtStatus.mantenimiento:
          return Colors.amber;
        case CourtStatus.cerrada:
          return Colors.red;
      }
    }

    // Función auxiliar para mapear el estado a un texto
    String _getStatusText(CourtStatus status) {
      switch (status) {
        case CourtStatus.disponible:
          return 'Disponible';
        case CourtStatus.ocupada:
          return 'Ocupada';
        case CourtStatus.mantenimiento:
          return 'En mantenimiento';
        case CourtStatus.cerrada:
          return 'Cerrada';
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusM),
                topRight: Radius.circular(AppTheme.radiusM),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Pista ${court.numero}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        court.nombre,
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
                        color: _getStatusColor(court.estado),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(court.estado),
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
                if (court.descripcion != null && court.descripcion!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        court.descripcion!,
                        style: TextStyle(color: AppTheme.darkColor),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Características
                if (court.superficie != null ||
                    court.tieneMarcador ||
                    court.tieneIluminacion)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Características:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (court.superficie != null)
                            Chip(
                              label: Text('Superficie: ${court.superficie}'),
                              backgroundColor: AppTheme.primaryColor
                                  .withOpacity(0.1),
                            ),
                          if (court.tieneMarcador)
                            Chip(
                              label: const Text('Con marcador'),
                              backgroundColor: AppTheme.primaryColor
                                  .withOpacity(0.1),
                            ),
                          if (court.tieneIluminacion)
                            Chip(
                              label: const Text('Con iluminación'),
                              backgroundColor: AppTheme.primaryColor
                                  .withOpacity(0.1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(court),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditCourtDialog(court),
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

  void _showAddEditCourtDialog(Court? court) {
    if (!mounted || _selectedInstallation == null) return;

    final isCreating = court == null;
    final title = isCreating ? 'Crear Pista' : 'Editar Pista';

    // Controladores para los campos de texto
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: court?.nombre ?? 'Pista ${_courts.length + 1}',
    );
    final descripcionController = TextEditingController(
      text: court?.descripcion ?? '',
    );
    final numeroController = TextEditingController(
      text: court?.numero.toString() ?? (_courts.length + 1).toString(),
    );
    final imagenUrlController = TextEditingController(
      text: court?.fotoUrl ?? '',
    );

    // Valores iniciales
    var estadoValue = court?.estado ?? CourtStatus.disponible;
    var superficieValue = court?.superficie ?? 'Sintética';
    var tieneMarcadorValue = court?.tieneMarcador ?? false;
    var tieneIluminacionValue = court?.tieneIluminacion ?? false;

    // Lista de opciones para superficie
    final tiposSuperficie = [
      'Sintética',
      'Cesped',
      'Cesped artificial',
      'Tierra batida',
      'Hormigón',
      'Madera',
      'Tarima',
      'Cristal',
      'Cemento',
      'Moqueta',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Container(
                width: MediaQuery.of(builderContext).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(builderContext).size.height * 0.85,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        const Text(
                          'Información básica',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                            border: OutlineInputBorder(),
                          ),
                          controller: nombreController,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'El nombre es requerido'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Número *',
                            border: OutlineInputBorder(),
                            hintText: 'Número de la pista (1, 2, 3...)',
                          ),
                          controller: numeroController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El número es requerido';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          controller: descripcionController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen',
                            border: OutlineInputBorder(),
                            hintText: 'https://example.com/image.jpg',
                          ),
                          controller: imagenUrlController,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<CourtStatus>(
                          decoration: const InputDecoration(
                            labelText: 'Estado de la pista',
                            border: OutlineInputBorder(),
                          ),
                          value: estadoValue,
                          items:
                              CourtStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(_getStatusText(status)),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                estadoValue = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Características
                        const Text(
                          'Características de la pista',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Tipo de superficie',
                            border: OutlineInputBorder(),
                          ),
                          value: superficieValue,
                          items:
                              tiposSuperficie
                                  .map(
                                    (tipo) => DropdownMenuItem(
                                      value: tipo,
                                      child: Text(tipo),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                superficieValue = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          title: const Text('Tiene marcador'),
                          subtitle: const Text(
                            'La pista cuenta con marcador para el tanteo',
                          ),
                          value: tieneMarcadorValue,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                tieneMarcadorValue = value;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          title: const Text('Tiene iluminación'),
                          subtitle: const Text(
                            'La pista cuenta con iluminación para uso nocturno',
                          ),
                          value: tieneIluminacionValue,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                tieneIluminacionValue = value;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      // Procesar datos del formulario
                      final String nombre = nombreController.text;
                      final String descripcion = descripcionController.text;
                      final int numero = int.parse(numeroController.text);
                      final String? imagenUrl =
                          imagenUrlController.text.isEmpty
                              ? null
                              : imagenUrlController.text;

                      // Crear características JSON
                      final caracteristicasJson =
                          Court.createCaracteristicasJson(
                            superficie: superficieValue,
                            tieneMarcador: tieneMarcadorValue,
                            tieneIluminacion: tieneIluminacionValue,
                          );

                      // Cerrar el diálogo antes de operaciones asíncronas
                      Navigator.pop(dialogContext);

                      // Ejecutar operaciones en el contexto principal
                      if (!mounted) return;

                      // Mostrar loading
                      setState(() => _isLoading = true);

                      try {
                        bool success = false;

                        if (isCreating) {
                          // Crear pista
                          final createdCourt = await CourtService.createCourt(
                            instalacionId: _selectedInstallation!.id,
                            nombre: nombre,
                            numero: numero,
                            descripcion: descripcion,
                            fotoUrl: imagenUrl,
                            estado: estadoValue.name,
                            caracteristicasJson: caracteristicasJson,
                          );
                          success = createdCourt != null;
                        } else {
                          // Actualizar pista
                          success = await CourtService.updateCourt(
                            id: court!.id,
                            nombre: nombre,
                            numero: numero,
                            descripcion: descripcion,
                            fotoUrl: imagenUrl,
                            estado: estadoValue.name,
                            caracteristicasJson: caracteristicasJson,
                          );
                        }

                        // Recargar datos
                        if (_selectedInstallation != null) {
                          await _loadCourts(_selectedInstallation!.id);
                        }

                        // Actualizar estado
                        if (mounted) {
                          setState(() => _isLoading = false);

                          // Mostrar mensaje
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? isCreating
                                        ? 'Pista creada correctamente'
                                        : 'Pista actualizada correctamente'
                                    : 'Error al ${isCreating ? "crear" : "actualizar"} la pista',
                              ),
                              backgroundColor:
                                  success ? AppTheme.successColor : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error al procesar pista: $e');
                        if (mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Court court) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar pista'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro que deseas eliminar la pista "${court.nombre}"?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta acción no se puede deshacer y eliminará también todas las reservas asociadas.',
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
                  // Cerrar diálogo
                  Navigator.pop(context);

                  // Mostrar loading
                  if (mounted) {
                    setState(() => _isLoading = true);
                  }

                  try {
                    // Eliminar pista
                    final success = await CourtService.deleteCourt(court.id);

                    // Recargar lista
                    if (_selectedInstallation != null) {
                      await _loadCourts(_selectedInstallation!.id);
                    }

                    // Mostrar mensaje
                    if (mounted) {
                      setState(() => _isLoading = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Pista eliminada correctamente'
                                : 'Error al eliminar la pista',
                          ),
                          backgroundColor:
                              success ? AppTheme.successColor : Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error al eliminar pista: $e');
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
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

  String _getStatusText(CourtStatus status) {
    switch (status) {
      case CourtStatus.disponible:
        return 'Disponible';
      case CourtStatus.ocupada:
        return 'Ocupada';
      case CourtStatus.mantenimiento:
        return 'En mantenimiento';
      case CourtStatus.cerrada:
        return 'Cerrada';
    }
  }
}
