import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/models/event_model.dart';
import 'package:deportivov1/services/news_service.dart';
import 'package:deportivov1/services/event_service.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

class AdminNewsEventsScreen extends StatefulWidget {
  const AdminNewsEventsScreen({super.key});

  @override
  State<AdminNewsEventsScreen> createState() => _AdminNewsEventsScreenState();
}

class _AdminNewsEventsScreenState extends State<AdminNewsEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _newsList = [];
  List<Map<String, dynamic>> _eventsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      // Cargar noticias desde la base de datos
      _newsList = await NewsService.getAllNewsAsMap();

      // Cargar eventos desde la base de datos
      _eventsList = await EventService.getAllEventsAsMap();

      // Asegurar nombres de campo consistentes para mostrar en la UI
      for (var event in _eventsList) {
        // Asegurar que tenemos 'nombre' también como 'titulo' para compatibilidad
        if (event['nombre'] != null && event['titulo'] == null) {
          event['titulo'] = event['nombre'];
        }

        // Asegurar que tenemos 'fecha_inicio' también como 'fecha_evento' para compatibilidad
        if (event['fecha_inicio'] != null && event['fecha_evento'] == null) {
          event['fecha_evento'] = event['fecha_inicio'];
        }

        // Asegurar que tenemos 'fecha_fin' también como 'fecha_fin_evento' para compatibilidad
        if (event['fecha_fin'] != null && event['fecha_fin_evento'] == null) {
          event['fecha_fin_evento'] = event['fecha_fin'];
        }

        // Asegurar que tenemos 'lugar' también como 'ubicacion' para compatibilidad
        if (event['lugar'] != null && event['ubicacion'] == null) {
          event['ubicacion'] = event['lugar'];
        }
      }

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

        // Usar Future.microtask para asegurarnos de que el scaffold esté disponible
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar datos. Intenta nuevamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Noticias y Eventos'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Noticias'), Tab(text: 'Eventos')],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildNewsList(), _buildEventsList()],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isNewsTab = _tabController.index == 0;
          _showAddEditDialog(null, isNewsTab);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNewsList() {
    if (_newsList.isEmpty) {
      return _buildEmptyState('No hay noticias publicadas', Icons.article);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        itemCount: _newsList.length,
        itemBuilder: (context, index) {
          final news = _newsList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news['imagen_url'] != null &&
                    news['imagen_url'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusM),
                      topRight: Radius.circular(AppTheme.radiusM),
                    ),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      child: Image.network(
                        news['imagen_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (
                          BuildContext context,
                          Object exception,
                          StackTrace? stackTrace,
                        ) {
                          return Container(
                            color: AppTheme.grayColor.withOpacity(0.2),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppTheme.grayColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: AppTheme.grayColor.withOpacity(0.1),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: AppTheme.grayColor,
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
                              news['titulo'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(news['fecha_publicacion']),
                            style: TextStyle(
                              color: AppTheme.grayColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        news['contenido'],
                        style: TextStyle(color: AppTheme.darkColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed:
                                () => _showDeleteConfirmDialog(news, true),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(news, true),
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
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_eventsList.isEmpty) {
      return _buildEmptyState('No hay eventos programados', Icons.event);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        itemCount: _eventsList.length,
        itemBuilder: (context, index) {
          final event = _eventsList[index];
          // Verificar si el evento tiene las fechas necesarias
          final tieneFechaInicio =
              event['fecha_evento'] != null || event['fecha_inicio'] != null;
          final tieneFechaFin =
              event['fecha_fin_evento'] != null || event['fecha_fin'] != null;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['imagen_url'] != null &&
                    event['imagen_url'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusM),
                      topRight: Radius.circular(AppTheme.radiusM),
                    ),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        event['imagen_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (
                          BuildContext context,
                          Object exception,
                          StackTrace? stackTrace,
                        ) {
                          return Container(
                            color: AppTheme.grayColor.withOpacity(0.2),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppTheme.grayColor,
                              ),
                            ),
                          );
                        },
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
                              event['titulo'] ??
                                  event['nombre'] ??
                                  'Sin título',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event['descripcion'] ?? 'Sin descripción',
                        style: TextStyle(color: AppTheme.darkColor),
                      ),
                      const SizedBox(height: 8),
                      if (tieneFechaInicio) // Solo mostrar la sección de fechas si hay datos
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.grayColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tieneFechaFin
                                  ? '${_formatDate(event['fecha_evento'] ?? event['fecha_inicio'])} - ${_formatTime(event['fecha_evento'] ?? event['fecha_inicio'])} a ${_formatTime(event['fecha_fin_evento'] ?? event['fecha_fin'])}'
                                  : '${_formatDate(event['fecha_evento'] ?? event['fecha_inicio'])} - ${_formatTime(event['fecha_evento'] ?? event['fecha_inicio'])}',
                              style: TextStyle(color: AppTheme.grayColor),
                            ),
                          ],
                        ),
                      if (event['ubicacion'] != null)
                        Column(
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.grayColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event['ubicacion'],
                                  style: TextStyle(color: AppTheme.grayColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed:
                                () => _showDeleteConfirmDialog(event, false),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(event, false),
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
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grayColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.grayColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final isNewsTab = _tabController.index == 0;
              _showAddEditDialog(null, isNewsTab);
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Añadir ${_tabController.index == 0 ? 'Noticia' : 'Evento'}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(Map<String, dynamic>? item, bool isNews) {
    // Usar un StatefulBuilder para manejar los cambios de estado internos del diálogo
    final isCreating = item == null;
    final title =
        isCreating
            ? 'Crear ${isNews ? 'Noticia' : 'Evento'}'
            : 'Editar ${isNews ? 'Noticia' : 'Evento'}';

    // Variables para mantener el estado de los campos
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController(
      text: isNews ? (item?['titulo'] ?? '') : (item?['nombre'] ?? ''),
    );
    final contenidoController = TextEditingController(
      text: isNews ? (item?['contenido'] ?? '') : (item?['descripcion'] ?? ''),
    );
    final imagenUrlController = TextEditingController(
      text: item?['imagen_url'] ?? '',
    );
    final ubicacionController = TextEditingController(
      text: item?['lugar'] ?? item?['ubicacion'] ?? '',
    );

    // Variables para el estado inicial
    String categoriaValue =
        item?['categoria'] ?? (isNews ? 'noticia' : 'deportivo');
    if (isNews &&
        ![
          'evento',
          'noticia',
          'mantenimiento',
          'promocion',
          'aviso',
          'informativa',
        ].contains(categoriaValue)) {
      categoriaValue =
          'noticia'; // Valor por defecto si el valor actual no está en la lista para noticias
    } else if (!isNews &&
        ![
          'deportivo',
          'cultural',
          'formativo',
          'institucional',
          'especial',
          'otros',
        ].contains(categoriaValue)) {
      categoriaValue = 'deportivo'; // Valor por defecto para eventos
    }
    bool destacadaValue = item?['destacada'] ?? false;
    DateTime? fechaExpiracion;

    if (item != null && item['fecha_expiracion'] != null) {
      try {
        fechaExpiracion = DateTime.parse(item['fecha_expiracion']);
      } catch (e) {
        print('Error al parsear fecha de expiración: $e');
      }
    }

    // Mostrar el diálogo con StatefulBuilder para manejar cambios de estado internos
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
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
                      children:
                          isNews
                              ? [
                                const Text(
                                  'Información de la noticia',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Título *',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: tituloController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Contenido *',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  controller: contenidoController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Categoría',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: categoriaValue,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'evento',
                                      child: Text('Evento'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'noticia',
                                      child: Text('Noticia'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'mantenimiento',
                                      child: Text('Mantenimiento'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'promocion',
                                      child: Text('Promoción'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'aviso',
                                      child: Text('Aviso'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'informativa',
                                      child: Text('Informativa'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        categoriaValue = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                CheckboxListTile(
                                  title: const Text('Noticia destacada'),
                                  subtitle: const Text(
                                    'Aparecerá en la página principal',
                                  ),
                                  value: destacadaValue,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        destacadaValue = value;
                                      });
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Imagen',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'URL de imagen (opcional)',
                                              border: OutlineInputBorder(),
                                              hintText:
                                                  'Ingresa URL o selecciona una imagen',
                                            ),
                                            controller: imagenUrlController,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final imageUrl = await _uploadImage(
                                              ImageSource.gallery,
                                            );
                                            if (imageUrl != null) {
                                              imagenUrlController.text =
                                                  imageUrl;
                                            }
                                          },
                                          icon: const Icon(Icons.photo_library),
                                          label: const Text('Galería'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Previsualización de imagen si hay URL
                                    if (imagenUrlController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          width: double.infinity,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            child: Image.network(
                                              imagenUrlController.text,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Center(
                                                  child: Text(
                                                    'Error al cargar imagen',
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ]
                              : [
                                // Formulario para eventos (por implementar)
                                const Text(
                                  'Información del evento',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Título *',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: tituloController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción *',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  controller: contenidoController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Categoría',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: categoriaValue,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'deportivo',
                                      child: Text('Deportivo'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cultural',
                                      child: Text('Cultural'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'formativo',
                                      child: Text('Formativo'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'institucional',
                                      child: Text('Institucional'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'especial',
                                      child: Text('Especial'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        categoriaValue = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Ubicación *',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: ubicacionController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Fecha inicio *',
                                          border: OutlineInputBorder(),
                                          suffixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text:
                                              item?['fecha_evento'] != null
                                                  ? _formatDateTime(
                                                    item!['fecha_evento'],
                                                  )
                                                  : (item?['fecha_inicio'] !=
                                                          null
                                                      ? _formatDateTime(
                                                        item!['fecha_inicio'],
                                                      )
                                                      : ''),
                                        ),
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? 'Requerido'
                                                    : null,
                                        onTap: () async {
                                          final DateTime?
                                          picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                item?['fecha_evento'] != null
                                                    ? DateTime.parse(
                                                      item!['fecha_evento'],
                                                    )
                                                    : (item?['fecha_inicio'] !=
                                                            null
                                                        ? DateTime.parse(
                                                          item!['fecha_inicio'],
                                                        )
                                                        : DateTime.now()),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2101),
                                          );
                                          if (picked != null) {
                                            final TimeOfDay?
                                            time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  item?['fecha_evento'] != null
                                                      ? TimeOfDay.fromDateTime(
                                                        DateTime.parse(
                                                          item!['fecha_evento'],
                                                        ),
                                                      )
                                                      : (item?['fecha_inicio'] !=
                                                              null
                                                          ? TimeOfDay.fromDateTime(
                                                            DateTime.parse(
                                                              item!['fecha_inicio'],
                                                            ),
                                                          )
                                                          : TimeOfDay.now()),
                                            );
                                            if (time != null) {
                                              final newDateTime = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                                time.hour,
                                                time.minute,
                                              );
                                              setState(() {
                                                item = item ?? {};
                                                item!['fecha_evento'] =
                                                    newDateTime
                                                        .toIso8601String();
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Fecha fin *',
                                          border: OutlineInputBorder(),
                                          suffixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text:
                                              item?['fecha_fin_evento'] != null
                                                  ? _formatDateTime(
                                                    item!['fecha_fin_evento'],
                                                  )
                                                  : (item?['fecha_fin'] != null
                                                      ? _formatDateTime(
                                                        item!['fecha_fin'],
                                                      )
                                                      : ''),
                                        ),
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? 'Requerido'
                                                    : null,
                                        onTap: () async {
                                          final DateTime?
                                          picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                item?['fecha_fin_evento'] !=
                                                        null
                                                    ? DateTime.parse(
                                                      item!['fecha_fin_evento'],
                                                    )
                                                    : (item?['fecha_fin'] !=
                                                            null
                                                        ? DateTime.parse(
                                                          item!['fecha_fin'],
                                                        )
                                                        : DateTime.now()),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2101),
                                          );
                                          if (picked != null) {
                                            final TimeOfDay?
                                            time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  item?['fecha_fin_evento'] !=
                                                          null
                                                      ? TimeOfDay.fromDateTime(
                                                        DateTime.parse(
                                                          item!['fecha_fin_evento'],
                                                        ),
                                                      )
                                                      : (item?['fecha_fin'] !=
                                                              null
                                                          ? TimeOfDay.fromDateTime(
                                                            DateTime.parse(
                                                              item!['fecha_fin'],
                                                            ),
                                                          )
                                                          : TimeOfDay.now()),
                                            );
                                            if (time != null) {
                                              final newDateTime = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                                time.hour,
                                                time.minute,
                                              );
                                              setState(() {
                                                item = item ?? {};
                                                item!['fecha_fin_evento'] =
                                                    newDateTime
                                                        .toIso8601String();
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Capacidad máxima (opcional)',
                                    border: OutlineInputBorder(),
                                    hintText:
                                        'Dejar en blanco si no hay límite',
                                  ),
                                  controller: TextEditingController(
                                    text:
                                        item?['capacidad_maxima']?.toString() ??
                                        '',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Imagen',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'URL de imagen (opcional)',
                                              border: OutlineInputBorder(),
                                              hintText:
                                                  'Ingresa URL o selecciona una imagen',
                                            ),
                                            controller: imagenUrlController,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final imageUrl = await _uploadImage(
                                              ImageSource.gallery,
                                            );
                                            if (imageUrl != null) {
                                              imagenUrlController.text =
                                                  imageUrl;
                                            }
                                          },
                                          icon: const Icon(Icons.photo_library),
                                          label: const Text('Galería'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Previsualización de imagen si hay URL
                                    if (imagenUrlController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          width: double.infinity,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            child: Image.network(
                                              imagenUrlController.text,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Center(
                                                  child: Text(
                                                    'Error al cargar imagen',
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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

                      // Guardar la referencia del ScaffoldMessenger antes de cerrar el diálogo
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      Navigator.pop(context);

                      // Procesar datos usando los valores de los controllers
                      final String titulo = tituloController.text;
                      final String contenido = contenidoController.text;
                      final String? imagenUrl =
                          imagenUrlController.text.isEmpty
                              ? null
                              : imagenUrlController.text;

                      // Mostrar loading
                      this.setState(() => _isLoading = true);

                      try {
                        bool success = false;

                        if (isNews) {
                          final newsCategory = _parseNewsCategory(
                            categoriaValue,
                          );

                          if (isCreating) {
                            // Obtener ID del usuario actual para autor_id
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final userId = authProvider.user!.id;

                            // Crear noticia nueva
                            success = await NewsService.createNews(
                              titulo: titulo,
                              contenido: contenido,
                              categoria: newsCategory,
                              autorId: userId,
                              imagenUrl: imagenUrl,
                              destacada: destacadaValue,
                              sendNotifications: true,
                            );
                          } else {
                            // Actualizar noticia existente
                            success = await NewsService.updateNews(
                              newsId: item!['id'].toString(),
                              titulo: titulo,
                              contenido: contenido,
                              categoria: newsCategory,
                              imagenUrl: imagenUrl,
                              destacada: destacadaValue,
                            );
                          }
                        } else {
                          // Implementación para eventos
                          final eventCategory = _parseEventCategory(
                            categoriaValue,
                          );

                          // Verificar si tenemos una fecha válida seleccionada
                          DateTime fechaEvento = DateTime.now();
                          DateTime? fechaFinEvento = DateTime.now().add(
                            Duration(hours: 2),
                          );

                          // Manejo seguro de la fecha
                          if (item != null) {
                            if (item?['fecha_evento'] != null) {
                              try {
                                fechaEvento = DateTime.parse(
                                  item?['fecha_evento'] as String,
                                );
                              } catch (e) {
                                print(
                                  'Error al parsear fecha de inicio: $e, usando fecha actual',
                                );
                              }
                            } else if (item?['fecha_inicio'] != null) {
                              try {
                                fechaEvento = DateTime.parse(
                                  item?['fecha_inicio'] as String,
                                );
                              } catch (e) {
                                print(
                                  'Error al parsear fecha de inicio: $e, usando fecha actual',
                                );
                              }
                            }

                            if (item?['fecha_fin_evento'] != null) {
                              try {
                                fechaFinEvento = DateTime.parse(
                                  item?['fecha_fin_evento'] as String,
                                );
                              } catch (e) {
                                print(
                                  'Error al parsear fecha de fin: $e, usando fecha actual + 2h',
                                );
                              }
                            } else if (item?['fecha_fin'] != null) {
                              try {
                                fechaFinEvento = DateTime.parse(
                                  item?['fecha_fin'] as String,
                                );
                              } catch (e) {
                                print(
                                  'Error al parsear fecha de fin: $e, usando fecha actual + 2h',
                                );
                              }
                            }
                          }

                          // Obtener ubicación
                          final ubicacion = ubicacionController.text.trim();

                          if (ubicacion.isEmpty) {
                            throw Exception('La ubicación es requerida');
                          }

                          // Convertir capacidad máxima a entero si está presente
                          final capacidadMaximaStr =
                              TextEditingController(
                                text:
                                    item?['capacidad_maxima']?.toString() ?? '',
                              ).text;

                          int? capacidadMaxima;
                          if (capacidadMaximaStr.isNotEmpty) {
                            capacidadMaxima = int.tryParse(capacidadMaximaStr);
                            if (capacidadMaxima == null) {
                              throw Exception(
                                'La capacidad máxima debe ser un número válido',
                              );
                            }
                          }

                          // Obtener ID del usuario actual para organizador_id
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final userId = authProvider.user!.id;

                          if (isCreating) {
                            // Crear evento nuevo
                            success = await EventService.createEvent(
                              titulo: titulo,
                              descripcion: contenido,
                              fechaInicio: fechaEvento,
                              fechaFin: fechaFinEvento,
                              lugar: ubicacion,
                              imagenUrl: imagenUrl,
                              destacado: item?['destacado'] as bool? ?? false,
                              capacidadMaxima: capacidadMaxima,
                            );
                          } else {
                            // Actualizar evento existente
                            success = await EventService.updateEvent(
                              id: item!['id'].toString(),
                              titulo: titulo,
                              descripcion: contenido,
                              fechaInicio: fechaEvento,
                              fechaFin: fechaFinEvento,
                              lugar: ubicacion,
                              imagenUrl: imagenUrl,
                              destacado: item?['destacado'] as bool? ?? false,
                              capacidadMaxima: capacidadMaxima,
                            );
                          }
                        }

                        if (success) {
                          await _loadData(); // Recargar lista
                          if (mounted) {
                            // Usar la referencia guardada
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCreating
                                      ? '${isNews ? "Noticia" : "Evento"} creado correctamente'
                                      : '${isNews ? "Noticia" : "Evento"} actualizado correctamente',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            // Usar la referencia guardada
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error al ${isCreating ? "crear" : "actualizar"} ${isNews ? "noticia" : "evento"}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error al procesar formulario: $e');
                        if (mounted) {
                          // Usar la referencia guardada
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          this.setState(() => _isLoading = false);
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
            );
          },
        );
      },
    );
  }

  // Método para seleccionar y subir una imagen a Supabase
  Future<String?> _uploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85, // Compresión para optimizar el tamaño
        maxWidth: 1200,
      );

      if (image == null) return null;

      setState(() {
        _isLoading = true;
      });

      final Uint8List bytes = await image.readAsBytes();
      final fileExt = path.extension(image.path); // .jpg, .png, etc.
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}$fileExt';

      // Decidir la carpeta según el tipo de contenido (noticias o eventos)
      final folder = _tabController.index == 0 ? 'noticias' : 'eventos';
      final filePath = '$folder/$fileName';

      // Subir la imagen a Supabase Storage
      await SupabaseService.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      // Obtener la URL pública de la imagen
      final imageUrl = SupabaseService.client.storage
          .from('images')
          .getPublicUrl(filePath);

      setState(() {
        _isLoading = false;
      });

      return imageUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      setState(() {
        _isLoading = false;
      });

      // Si está montado, mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  // Diálogo de confirmación para eliminar
  void _showDeleteConfirmDialog(Map<String, dynamic> item, bool isNews) {
    // Verificar si el widget está montado
    if (!mounted) return;

    // Guardar título para referencia después de cerrar el diálogo
    final String itemTitle =
        item['titulo'] ?? item['nombre'] ?? 'este elemento';
    final String itemType = isNews ? "noticia" : "evento";

    // Capturar el contexto del scaffold antes de mostrar el diálogo
    final scaffoldMessengerContext = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar $itemType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Estás seguro que deseas eliminar "$itemTitle"?'),
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
                  // Capturar ID antes de cerrar el diálogo
                  final String itemId = item['id'].toString();

                  // Cerrar diálogo
                  Navigator.pop(context);

                  // Verificar si el widget sigue montado
                  if (!mounted) return;

                  setState(() => _isLoading = true);

                  try {
                    bool success = false;

                    if (isNews) {
                      // Eliminar noticia
                      success = await NewsService.deleteNews(itemId);
                    } else {
                      // Eliminar evento
                      success = await EventService.deleteEvent(itemId);
                    }

                    // Recargar lista independientemente del resultado
                    await _loadData();

                    // Verificar si el widget sigue montado después de la recarga
                    if (!mounted) return;

                    setState(() => _isLoading = false);

                    if (success) {
                      // Usar el contexto capturado para mostrar el mensaje
                      scaffoldMessengerContext.showSnackBar(
                        SnackBar(
                          content: Text(
                            '$itemType "$itemTitle" eliminado correctamente',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      // Usar el contexto capturado para mostrar el mensaje
                      scaffoldMessengerContext.showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar $itemType'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error al eliminar: $e');

                    // Verificar si el widget sigue montado
                    if (!mounted) return;

                    setState(() => _isLoading = false);

                    // Usar el contexto capturado para mostrar el mensaje
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

  // Utilidades
  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Fecha desconocida';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Formato de fecha inválido';
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Hora desconocida';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Formato de hora inválido';
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // Convertir string de categoría a enum
  NewsCategory _parseNewsCategory(String categoria) {
    switch (categoria) {
      case 'evento':
        return NewsCategory.evento;
      case 'noticia':
        return NewsCategory.noticia;
      case 'mantenimiento':
        return NewsCategory.mantenimiento;
      case 'promocion':
        return NewsCategory.promocion;
      case 'aviso':
        return NewsCategory.aviso;
      case 'informativa':
        return NewsCategory.informativa;
      case 'otros':
      default:
        // Cambiamos el valor predeterminado a 'noticia' en lugar de 'otros'
        // ya que 'otros' no parece ser un valor válido en la base de datos
        return NewsCategory.noticia;
    }
  }

  // Convertir string de categoría a enum para eventos
  EventCategory _parseEventCategory(String categoria) {
    switch (categoria) {
      case 'deportivo':
        return EventCategory.deportivo;
      case 'cultural':
        return EventCategory.cultural;
      case 'formativo':
        return EventCategory.formativo;
      case 'institucional':
        return EventCategory.institucional;
      case 'especial':
        return EventCategory.especial;
      default:
        return EventCategory.otros;
    }
  }
}
