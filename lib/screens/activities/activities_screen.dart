import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/services/activity_service.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  List<Activity> _activities = [];
  List<ActivityFamily> _families = [];
  List<Activity> _popularActivities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedFamilyId;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Esto se activa tanto para clics como para deslizamientos
      setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar actividades y familias de forma paralela
      final activitiesFuture = ActivityServiceStatic.getActivitiesWithFamily();
      final familiesFuture = ActivityServiceStatic.getAllActivityFamilies();

      // Esperar a que ambas operaciones terminen
      final results = await Future.wait([activitiesFuture, familiesFuture]);

      final activities = results[0] as List<Activity>;
      final families = results[1] as List<ActivityFamily>;

      // Crear una lista de actividades populares (ordenadas por plazas ocupadas)
      final popular = List<Activity>.from(activities);
      popular.sort((a, b) => b.plazasOcupadas.compareTo(a.plazasOcupadas));

      if (mounted) {
        setState(() {
          _activities = activities;
          _families = families;
          _popularActivities =
              popular.take(3).toList(); // Tomar las 3 más populares
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos. Intenta nuevamente.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _loadData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _filterActivities(String? familyId) {
    setState(() {
      _selectedFamilyId = familyId;
    });
  }

  List<Activity> get _filteredActivities {
    List<Activity> result = _activities;

    // Filtrar por familia si hay una seleccionada
    if (_selectedFamilyId != null) {
      result = result.where((a) => a.familiaId == _selectedFamilyId).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      result =
          result
              .where(
                (a) =>
                    a.nombre.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (a.descripcion != null &&
                        a.descripcion!.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        )),
              )
              .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isUserAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Encabezado con título
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Actividades',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '¡Encuentra tu actividad favorita!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Banner de "Mis Actividades" para usuarios autenticados
                      if (isUserAuthenticated)
                        SliverToBoxAdapter(
                          child: GestureDetector(
                            onTap:
                                () => _showUserEnrollmentsDialog(
                                  context,
                                  authProvider.user!.id,
                                ),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade700,
                                    Colors.blue.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade300.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.sports_gymnastics,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Mis actividades',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ver mis inscripciones a actividades',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Sección de actividades populares
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 0,
                            top: 20,
                            bottom: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Populares',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _popularActivities.length,
                                  itemBuilder: (_, index) {
                                    final activity = _popularActivities[index];

                                    // Determinar color basado en familia
                                    List<Color> cardGradient = [
                                      Colors.blue.shade400,
                                      Colors.blue.shade300,
                                    ];
                                    if (activity.familia?.nombre != null) {
                                      final name =
                                          activity.familia!.nombre
                                              .toLowerCase();
                                      if (name.contains('natación')) {
                                        cardGradient = [
                                          Colors.blue.shade600,
                                          Colors.lightBlue.shade300,
                                        ];
                                      } else if (name.contains('pádel') ||
                                          name.contains('tenis')) {
                                        cardGradient = [
                                          Colors.orange.shade600,
                                          Colors.amber.shade300,
                                        ];
                                      } else if (name.contains('fitness')) {
                                        cardGradient = [
                                          Colors.teal.shade600,
                                          Colors.teal.shade300,
                                        ];
                                      } else if (name.contains('equipo')) {
                                        cardGradient = [
                                          Colors.green.shade600,
                                          Colors.lightGreen.shade300,
                                        ];
                                      } else if (name.contains('artes') ||
                                          name.contains('karate')) {
                                        cardGradient = [
                                          Colors.red.shade600,
                                          Colors.deepOrange.shade300,
                                        ];
                                      } else if (name.contains('yoga') ||
                                          name.contains('pilates')) {
                                        cardGradient = [
                                          Colors.purple.shade600,
                                          Colors.purple.shade300,
                                        ];
                                      } else if (name.contains('baile') ||
                                          name.contains('zumba')) {
                                        cardGradient = [
                                          Colors.pink.shade600,
                                          Colors.pink.shade300,
                                        ];
                                      } else if (name.contains('cardio') ||
                                          name.contains('running')) {
                                        cardGradient = [
                                          Colors.indigo.shade600,
                                          Colors.indigo.shade300,
                                        ];
                                      } else if (name.contains('ciclismo') ||
                                          name.contains('spinning')) {
                                        cardGradient = [
                                          Colors.deepPurple.shade600,
                                          Colors.deepPurple.shade300,
                                        ];
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: GestureDetector(
                                        onTap:
                                            () =>
                                                _showActivityDetails(activity),
                                        child: Container(
                                          width: 300,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: cardGradient,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: cardGradient[0]
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                            horizontal: 20,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Etiqueta destacado
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: const Text(
                                                  'Destacado',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              // Espacio entre etiqueta y título
                                              const SizedBox(height: 15),

                                              // Título de la actividad
                                              Text(
                                                activity.nombre,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              // Espacio flexible
                                              const Spacer(),

                                              // Horario
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      _formatSchedule(activity),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Espacio antes del botón
                                              const SizedBox(height: 12),

                                              // Botón de inscripción
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Inscribirse',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sección de categorías
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Categorías',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Column(
                                children:
                                    _families
                                        .map(
                                          (family) =>
                                              _buildCategoryTile(family),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.darkColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.lightGrayColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, BuildContext context) {
    IconData iconData = Icons.fitness_center;

    // Asignar ícono según la familia de actividad
    if (activity.familia?.nombre != null) {
      final familyName = activity.familia!.nombre.toLowerCase();
      if (familyName.contains('yoga') || familyName.contains('pilates')) {
        iconData = Icons.self_improvement;
      } else if (familyName.contains('natación') ||
          familyName.contains('acuatica')) {
        iconData = Icons.pool;
      } else if (familyName.contains('baile') || familyName.contains('zumba')) {
        iconData = Icons.music_note;
      } else if (familyName.contains('ciclismo') ||
          familyName.contains('spinning')) {
        iconData = Icons.directions_bike;
      }
    }

    // Formatear días de la semana
    String daysText = activity.diasSemana?.join(', ') ?? 'No especificado';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusM),
                topRight: Radius.circular(AppTheme.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(iconData, size: 24, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          activity.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.descripcion ?? 'Sin descripción disponible',
                  style: TextStyle(color: AppTheme.darkColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Detalles
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.grayColor,
                    ),
                    const SizedBox(width: 8),
                    Text(daysText, style: TextStyle(color: AppTheme.grayColor)),
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
                      _formatSchedule(activity),
                      style: TextStyle(color: AppTheme.grayColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (activity.nivel != null)
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: AppTheme.grayColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nivel: ${activity.nivel}',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Botón de inscripción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        activity.tieneDisponibilidad
                            ? () async {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );

                              if (authProvider.isAuthenticated) {
                                try {
                                  // Mostrar indicador de carga
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Procesando inscripción...',
                                      ),
                                      backgroundColor: AppTheme.infoColor,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  // Realizar la inscripción
                                  final success =
                                      await ActivityServiceStatic.enrollActivity(
                                        activity.id,
                                        authProvider.user!.id,
                                      );

                                  if (mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Tu solicitud de inscripción se ha enviado correctamente. Un administrador la revisará pronto.',
                                          ),
                                          backgroundColor:
                                              AppTheme.successColor,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Error al procesar la inscripción. Intenta nuevamente.',
                                          ),
                                          backgroundColor: AppTheme.errorColor,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  print('Error en inscripción: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error al procesar la inscripción. Intenta nuevamente.',
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Inicia sesión para inscribirte',
                                    ),
                                    backgroundColor: AppTheme.warningColor,
                                  ),
                                );
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: AppTheme.lightGrayColor,
                    ),
                    child: const Text('Inscribirse'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo con inscripciones
  Future<void> _showUserEnrollmentsDialog(
    BuildContext context,
    String userId,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener inscripciones del usuario
      final enrollments = await ActivityServiceStatic.getUserEnrollments(
        userId,
      );

      // Cerrar indicador de carga
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (enrollments.isEmpty) {
        if (mounted) {
          _showEmptyEnrollmentsDialog(context);
        }
        return;
      }

      // Mostrar diálogo con inscripciones
      if (mounted) {
        // Agrupar inscripciones por estado
        final pendingEnrollments =
            enrollments
                .where((e) => (e['estado'] ?? 'pendiente') == 'pendiente')
                .toList();
        final confirmedEnrollments =
            enrollments
                .where((e) => (e['estado'] ?? '') == 'confirmada')
                .toList();
        final cancelledEnrollments =
            enrollments
                .where((e) => (e['estado'] ?? '') == 'cancelada')
                .toList();

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder:
              (context) => _ShowUserEnrollmentsDialog(
                pendingEnrollments: pendingEnrollments,
                confirmedEnrollments: confirmedEnrollments,
                cancelledEnrollments: cancelledEnrollments,
                onCancelEnrollment: _cancelEnrollment,
              ),
        );
      }
    } catch (e) {
      print('Error al obtener inscripciones: $e');
      if (mounted) {
        // Cerrar indicador de carga si está visible
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener tus inscripciones.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Mostrar diálogo cuando no hay inscripciones
  void _showEmptyEnrollmentsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 400,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No tienes inscripciones',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '¡Explora nuestras actividades y inscríbete para empezar a disfrutar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Explorar actividades'),
                ),
              ],
            ),
          ),
    );
  }

  // Cancelar una inscripción
  Future<void> _cancelEnrollment(
    String enrollmentId,
    BuildContext context,
  ) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancelar inscripción'),
              content: const Text(
                '¿Estás seguro de que deseas cancelar esta inscripción?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí'),
                ),
              ],
            ),
      );

      if (confirm == true) {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final success = await ActivityServiceStatic.cancelEnrollment(
          enrollmentId,
        );

        // Cerrar indicador de carga
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscripción cancelada correctamente.'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Cerrar diálogo de inscripciones
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          // Actualizar datos
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          if (authProvider.isAuthenticated) {
            _showUserEnrollmentsDialog(context, authProvider.user!.id);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cancelar la inscripción.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al cancelar inscripción: $e');
      if (mounted) {
        // Cerrar indicador de carga si está visible
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cancelar la inscripción.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Método para formatear los días
  String _formatDays(List<String> days) {
    return days.map((day) => day.substring(0, 3).toUpperCase()).join(', ');
  }

  // Método para formatear hora en formato HH:mm
  String _formatTimeString(String time) {
    // Si el tiempo ya está en formato HH:mm, devolverlo tal cual
    if (!time.contains(':')) return time;

    // Si tiene segundos, eliminarlos
    return time.split(':').take(2).join(':');
  }

  // Método para formatear el horario completo
  String _formatSchedule(Activity activity) {
    final String formattedStart = _formatTimeString(activity.horaInicio);
    final String formattedEnd = _formatTimeString(activity.horaFin);
    final String diasText =
        activity.diasSemana != null && activity.diasSemana!.isNotEmpty
            ? _formatDays(activity.diasSemana!)
            : '';

    return diasText.isNotEmpty
        ? '$diasText, $formattedStart - $formattedEnd'
        : '$formattedStart - $formattedEnd';
  }

  // Método para mostrar detalles de actividad
  void _showActivityDetails(Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                Navigator.pop(context);
              }
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                color: Colors.white,
                child: Column(
                  children: [
                    // Barra de arrastre
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.lightGrayColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contenido
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildActivityDetailCard(activity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Método para construir tarjeta de detalle de actividad
  Widget _buildActivityDetailCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen o encabezado
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child:
                activity.imagenUrl != null && activity.imagenUrl!.isNotEmpty
                    ? Image.network(
                      activity.imagenUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.blue.shade100,
                            child: Center(
                              child: Icon(
                                _getActivityIcon(activity.nombre),
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                    )
                    : Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.blue.shade100,
                      child: Center(
                        child: Icon(
                          _getActivityIcon(activity.nombre),
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                    ),
          ),

          // Información
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con valoración
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Detalles (horario)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatSchedule(activity),
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Botón Inscribirse
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        activity.tieneDisponibilidad
                            ? () => _enrollActivity(activity)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Inscribirse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construir tile de categoría
  Widget _buildCategoryTile(ActivityFamily family) {
    // Contar actividades por familia
    final activityCount =
        _activities.where((a) => a.familiaId == family.id).length;

    // Seleccionar un icono y color adecuado para cada categoría
    final Map<String, Map<String, dynamic>> categoryIcons = {
      'infantiles': {
        'icon': Icons.emoji_people,
        'color': Colors.blue.shade100,
        'iconColor': Colors.blue.shade600,
      },
      'seniors': {
        'icon': Icons.elderly,
        'color': Colors.purple.shade100,
        'iconColor': Colors.purple.shade600,
      },
      'acuáticas': {
        'icon': Icons.pool,
        'color': Colors.cyan.shade100,
        'iconColor': Colors.cyan.shade600,
      },
      'marciales': {
        'icon': Icons.sports_martial_arts,
        'color': Colors.red.shade100,
        'iconColor': Colors.red.shade600,
      },
      'aventura': {
        'icon': Icons.terrain,
        'color': Colors.green.shade100,
        'iconColor': Colors.green.shade600,
      },
      'combate': {
        'icon': Icons.sports_kabaddi,
        'color': Colors.orange.shade100,
        'iconColor': Colors.orange.shade600,
      },
      'raqueta': {
        'icon': Icons.sports_tennis,
        'color': Colors.amber.shade100,
        'iconColor': Colors.amber.shade600,
      },
      'gimnasia': {
        'icon': Icons.fitness_center,
        'color': Colors.teal.shade100,
        'iconColor': Colors.teal.shade600,
      },
      'yoga': {
        'icon': Icons.self_improvement,
        'color': Colors.indigo.shade100,
        'iconColor': Colors.indigo.shade600,
      },
      'natación': {
        'icon': Icons.water,
        'color': Colors.blue.shade100,
        'iconColor': Colors.blue.shade600,
      },
      'baile': {
        'icon': Icons.music_note,
        'color': Colors.pink.shade100,
        'iconColor': Colors.pink.shade600,
      },
      'equipo': {
        'icon': Icons.groups,
        'color': Colors.green.shade100,
        'iconColor': Colors.green.shade600,
      },
    };

    // Determinar el icono y color adecuado según el nombre de la familia
    Map<String, dynamic> categoryData = {
      'icon': Icons.sports,
      'color': Colors.blue.shade100,
      'iconColor': Colors.blue.shade600,
    };

    final familyName = family.nombre.toLowerCase();

    for (var key in categoryIcons.keys) {
      if (familyName.contains(key)) {
        categoryData = categoryIcons[key]!;
        break;
      }
    }

    return GestureDetector(
      onTap: () => _showCategoryActivities(family),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: categoryData['color'],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  categoryData['icon'],
                  color: categoryData['iconColor'],
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activityCount actividades',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Método para mostrar actividades de categoría
  void _showCategoryActivities(ActivityFamily family) {
    setState(() {
      _selectedFamilyId = family.id;
    });

    // Mostrar modal con las actividades de esta categoría
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Encabezado
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getCategoryIcon(family.nombre),
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Actividades disponibles',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Lista de actividades
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _filteredActivities[index];
                    return _buildActivityDetailCard(activity);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para obtener ícono de categoría
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('natación')) {
      return Icons.pool;
    } else if (name.contains('fitness')) {
      return Icons.fitness_center;
    } else if (name.contains('equipo')) {
      return Icons.sports_soccer;
    } else if (name.contains('raqueta')) {
      return Icons.sports_tennis;
    } else if (name.contains('yoga') || name.contains('pilates')) {
      return Icons.self_improvement;
    } else if (name.contains('entrenamiento')) {
      return Icons.person;
    } else if (name.contains('infantiles')) {
      return Icons.emoji_people;
    } else if (name.contains('seniors')) {
      return Icons.elderly;
    } else if (name.contains('acuáticas')) {
      return Icons.water;
    } else if (name.contains('marciales')) {
      return Icons.sports_martial_arts;
    } else if (name.contains('aventura')) {
      return Icons.terrain;
    } else if (name.contains('combate')) {
      return Icons.sports_kabaddi;
    } else if (name.contains('baile')) {
      return Icons.music_note;
    }

    return Icons.sports;
  }

  Future<void> _enrollActivity(Activity activity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para inscribirte'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Procesando inscripción...'),
          backgroundColor: AppTheme.infoColor,
          duration: Duration(seconds: 1),
        ),
      );

      // Realizar la inscripción
      final success = await ActivityServiceStatic.enrollActivity(
        activity.id,
        authProvider.user!.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu solicitud de inscripción se ha enviado correctamente. Un administrador la revisará pronto.',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error al procesar la inscripción. Intenta nuevamente.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en inscripción: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al procesar la inscripción. Intenta nuevamente.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Métodos adicionales para soporte
  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('natación') || name.contains('aqua')) return Icons.pool;
    if (name.contains('yoga')) return Icons.self_improvement;
    if (name.contains('spinning')) return Icons.directions_bike;
    if (name.contains('boxeo')) return Icons.sports_mma;
    if (name.contains('baile')) return Icons.music_note;
    if (name.contains('gimnasia')) return Icons.fitness_center;
    if (name.contains('karate') || name.contains('escalada'))
      return Icons.sports_martial_arts;
    if (name.contains('multideporte')) return Icons.sports_handball;
    if (name.contains('espalda')) return Icons.health_and_safety;
    return Icons.sports;
  }
}

// Clase separada para el diálogo de inscripciones
class _ShowUserEnrollmentsDialog extends StatefulWidget {
  final List<dynamic> pendingEnrollments;
  final List<dynamic> confirmedEnrollments;
  final List<dynamic> cancelledEnrollments;
  final Function(String, BuildContext) onCancelEnrollment;

  const _ShowUserEnrollmentsDialog({
    Key? key,
    required this.pendingEnrollments,
    required this.confirmedEnrollments,
    required this.cancelledEnrollments,
    required this.onCancelEnrollment,
  }) : super(key: key);

  @override
  State<_ShowUserEnrollmentsDialog> createState() =>
      _ShowUserEnrollmentsDialogState();
}

class _ShowUserEnrollmentsDialogState extends State<_ShowUserEnrollmentsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Indice actual para actualización en tiempo real durante el deslizamiento
  int get _currentIndex =>
      _tabController.animation?.value.round() ?? _tabController.index;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    // Esto actualiza la UI constantemente durante la animación de deslizamiento
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  // Obtiene el color según el índice actual, usando animación continua
  Color _getTabColor(int tabIndex) {
    // Calcular la animación entre pestañas cercanas
    if (_tabController.animation == null ||
        _tabController.animation!.value == tabIndex) {
      // Si estamos exactamente en este índice, devolver su color
      return tabIndex == 0
          ? Colors.amber.shade300
          : tabIndex == 1
          ? Colors.green.shade300
          : Colors.red.shade300;
    }

    // Estamos en la transición entre pestañas
    return tabIndex == 0
        ? Colors.amber.shade300
        : tabIndex == 1
        ? Colors.green.shade300
        : Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Barra de arrastre
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Pestañas mejoradas según la imagen
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color:
                    currentIndex == 0
                        ? Colors.amber.shade300
                        : currentIndex == 1
                        ? Colors.green.shade300
                        : Colors.red.shade300,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_outlined,
                        size: 18,
                        color:
                            currentIndex == 0
                                ? Colors.black
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pendientes',
                        style: TextStyle(
                          fontWeight:
                              currentIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color:
                            currentIndex == 1
                                ? Colors.black
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Confirmada',
                        style: TextStyle(
                          fontWeight:
                              currentIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color:
                            currentIndex == 2
                                ? Colors.black
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Canceladas',
                        style: TextStyle(
                          fontWeight:
                              currentIndex == 2
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEnrollmentsList(widget.pendingEnrollments, 'pendiente'),
                _buildEnrollmentsList(
                  widget.confirmedEnrollments,
                  'confirmada',
                ),
                _buildEnrollmentsList(widget.cancelledEnrollments, 'cancelada'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList(List<dynamic> enrollments, String status) {
    if (enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pendiente'
                  ? Icons.hourglass_empty_rounded
                  : status == 'confirmada'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay inscripciones ${status == 'pendiente'
                  ? 'pendientes'
                  : status == 'confirmada'
                  ? 'confirmadas'
                  : 'canceladas'}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Las inscripciones que realices aparecerán aquí mientras se confirman',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        final activity =
            enrollment['actividades'] as Map<String, dynamic>? ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color:
                status == 'pendiente'
                    ? Colors.amber.shade50
                    : status == 'confirmada'
                    ? Colors.green.shade50
                    : Colors.red.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    // Icono de actividad
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _getActivityIcon(activity['nombre'] ?? ''),
                        color:
                            status == 'pendiente'
                                ? Colors.amber.shade700
                                : status == 'confirmada'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Información de la actividad
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['nombre'] ?? 'Actividad sin nombre',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Inscrito el ${_formatDateOnly(enrollment['fecha_inscripcion'] ?? '', "10/05/2025")}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Botón de cancelar (X)
                    if (status != 'cancelada')
                      GestureDetector(
                        onTap:
                            () => widget.onCancelEnrollment(
                              enrollment['id'].toString(),
                              context,
                            ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.close,
                            color: Colors.red.shade500,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Sección de horario
              Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${activity['hora_inicio'] ?? ''} - ${activity['hora_fin'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
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
      },
    );
  }

  String _formatDateOnly(String dateTimeStr, String defaultValue) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return defaultValue;
    }
  }

  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('natación') || name.contains('aqua')) return Icons.pool;
    if (name.contains('yoga')) return Icons.self_improvement;
    if (name.contains('spinning')) return Icons.directions_bike;
    if (name.contains('boxeo')) return Icons.sports_mma;
    if (name.contains('baile')) return Icons.music_note;
    if (name.contains('gimnasia')) return Icons.fitness_center;
    if (name.contains('karate') || name.contains('escalada'))
      return Icons.sports_martial_arts;
    if (name.contains('multideporte')) return Icons.sports_handball;
    if (name.contains('espalda')) return Icons.health_and_safety;
    return Icons.sports;
  }
}
