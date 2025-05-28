import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/installation_model.dart';
import 'package:deportivov1/models/reservation_model.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/installation_service.dart';
import 'package:deportivov1/services/reservation_service.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deportivov1/models/court_model.dart';
import 'package:deportivov1/services/court_service.dart';
import 'package:deportivov1/widgets/reservation_card.dart';

class ReservationsScreen extends StatefulWidget {
  final int initialTabIndex;

  const ReservationsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dayFormat = DateFormat('EEEE', 'es_ES');

  // Mapa para almacenar la pista seleccionada por cada instalación
  Map<String, Court?> _selectedCourtsByInstallation = {};

  List<Reservation> _activeReservations = [];
  List<Reservation> _historicalReservations = [];
  List<Installation> _availableInstallations = [];
  bool _isLoadingMyReservations = true;
  bool _isLoadingFacilities = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Debug the reservas table structure
    ReservationService.debugReservasTable().then((_) {
      print('Finished debugging reservas table.');
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      // Elimina actualización automática de reservas completadas y limpieza
      _loadReservations(authProvider.user!.id);
    } else {
      setState(() {
        _activeReservations = [];
        _historicalReservations = [];
        _isLoadingMyReservations = false;
      });
    }
    _loadAvailableInstallations();
  }

  Future<void> _loadReservations(String userId) async {
    setState(() {
      _isLoadingMyReservations = true;
    });

    try {
      // Cargar reservas de forma paralela
      final activeReservationsFuture = ReservationService.getActiveReservations(
        userId,
      );
      final historicalReservationsFuture =
          ReservationService.getHistoricalReservations(userId);

      final results = await Future.wait([
        activeReservationsFuture,
        historicalReservationsFuture,
      ]);

      if (mounted) {
        setState(() {
          _activeReservations = results[0] as List<Reservation>;
          _historicalReservations = results[1] as List<Reservation>;
          _isLoadingMyReservations = false;
        });

        // Depurar información de pistas
        _debugReservationPistas();
      }
    } catch (e) {
      print('Error al cargar reservas: $e');
      if (mounted) {
        setState(() {
          _isLoadingMyReservations = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reservas. Intenta nuevamente.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _loadReservations(userId),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableInstallations() async {
    setState(() {
      _isLoadingFacilities = true;
    });

    try {
      // Definir hora predeterminada para búsqueda inicial
      const String defaultStartTime = '09:00';
      const String defaultEndTime = '10:00';

      final installations = await InstallationService.getAvailableInstallations(
        _selectedDate,
        defaultStartTime,
        defaultEndTime,
      );

      if (mounted) {
        setState(() {
          _availableInstallations = installations;
          _isLoadingFacilities = false;
        });
      }
    } catch (e) {
      print('Error al cargar instalaciones: $e');
      if (mounted) {
        setState(() {
          _isLoadingFacilities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar instalaciones. Intenta nuevamente.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _loadAvailableInstallations,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAvailableInstallations();
    }
  }

  // Método para cancelar una reserva
  Future<void> _cancelReservation(String reservationId) async {
    try {
      final success = await ReservationService.cancelReservation(reservationId);

      if (success) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          _loadReservations(authProvider.user!.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cancelar la reserva'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      print('Error al cancelar reserva: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cancelar reserva'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Título principal
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reservas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Reserva tu espacio',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Nuevo TabBar mejorado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4776E6), Color(0xFF5E85E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4776E6).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  padding: EdgeInsets.zero,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          const Text('Mis Reservas'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 16),
                          const SizedBox(width: 8),
                          const Text('Reservar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            // TabBarView en Expanded para evitar overflow
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMyReservationsTab(),
                  _buildNewReservationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReservationsTab() {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: AppTheme.grayColor),
            const SizedBox(height: 16),
            Text(
              'Inicia sesión para ver tus reservas',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.grayColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMyReservations) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      child: RefreshIndicator(
        onRefresh: () => _loadReservations(authProvider.user!.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis reservas activas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 16),

              // Reservas activas
              _activeReservations.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No tienes reservas activas',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        _activeReservations.map((reservation) {
                          // Obtener nombre de la instalación
                          String facilityName = '';
                          if (reservation.instalacion != null) {
                            facilityName =
                                reservation.instalacion!['nombre'] ??
                                'Instalación';
                          }

                          // Obtener nombre de la pista si existe
                          String? pistaName;
                          if (reservation.pista != null &&
                              reservation.pista!.isNotEmpty) {
                            pistaName = reservation.pista!['nombre'];
                            print(
                              "Pista asignada correctamente: ${reservation.id} → $pistaName",
                            );
                          } else if (reservation.pistaId != null &&
                              reservation.pistaId!.isNotEmpty) {
                            // Si tenemos ID de pista pero no el objeto, podríamos buscar el nombre
                            pistaName =
                                "Pista #${reservation.pistaId!.substring(0, 6)}";
                            print(
                              "Solo tenemos ID de pista: ${reservation.pistaId}",
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ReservationCard(
                              facilityName: facilityName,
                              date: reservation.fecha,
                              startTime: reservation.horaInicio,
                              endTime: reservation.horaFin,
                              status: reservation.estado.name,
                              reservationId: reservation.id,
                              pistaName: pistaName,
                              onCancel: _cancelReservation,
                            ),
                          );
                        }).toList(),
                  ),

              const SizedBox(height: 32),

              Text(
                'Historial de reservas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 16),

              // Historial de reservas
              _historicalReservations.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No tienes historial de reservas',
                        style: TextStyle(color: AppTheme.grayColor),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        _historicalReservations.map((reservation) {
                          // Obtener nombre de la instalación
                          String facilityName = '';
                          if (reservation.instalacion != null) {
                            facilityName =
                                reservation.instalacion!['nombre'] ??
                                'Instalación';
                          }

                          // Obtener nombre de la pista si existe
                          String? pistaName;
                          if (reservation.pista != null &&
                              reservation.pista!.isNotEmpty) {
                            pistaName = reservation.pista!['nombre'];
                            print(
                              "Historial - Pista asignada: ${reservation.id} → $pistaName",
                            );
                          } else if (reservation.pistaId != null &&
                              reservation.pistaId!.isNotEmpty) {
                            // Si tenemos ID de pista pero no el objeto, podríamos buscar el nombre
                            pistaName =
                                "Pista #${reservation.pistaId!.substring(0, 6)}";
                            print(
                              "Historial - Solo ID de pista: ${reservation.pistaId}",
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ReservationCard(
                              facilityName: facilityName,
                              date: reservation.fecha,
                              startTime: reservation.horaInicio,
                              endTime: reservation.horaFin,
                              status: reservation.estado.name,
                              pistaName: pistaName,
                              reservationId:
                                  reservation.estado.name == 'confirmada'
                                      ? reservation.id
                                      : null,
                              onCancel:
                                  reservation.estado.name == 'confirmada'
                                      ? _cancelReservation
                                      : null,
                            ),
                          );
                        }).toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewReservationTab() {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildLoginPrompt();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: _buildReservationSlivers(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Inicia sesión para hacer reservas',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitas una cuenta para poder reservar instalaciones',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4776E6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReservationSlivers() {
    return <Widget>[
      _buildHeaderSliver(),
      _buildTitleSliver(),
      if (_isLoadingFacilities)
        _buildLoadingSliver()
      else if (_availableInstallations.isEmpty)
        _buildEmptySliver()
      else
        _buildInstallationsSliver(),
    ];
  }

  Widget _buildHeaderSliver() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y descripción
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_available,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reserva tu espacio',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona la instalación y el horario que prefieras',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selector de fecha
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con fecha seleccionada
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalizeFirstLetter(
                                _dayFormat.format(_selectedDate),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _dateFormat.format(_selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          onPressed: () => _selectDate(context),
                          icon: Icon(
                            Icons.edit_calendar,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Selector rápido de días
                  SizedBox(
                    height: 85,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected =
                            _selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day;
                        final dayName = DateFormat(
                          'E',
                          'es_ES',
                        ).format(date).substring(0, 3);

                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadAvailableInstallations();
                            },
                            child: Container(
                              width: 65,
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          colors: [
                                            AppTheme.primaryColor,
                                            AppTheme.primaryColor.withOpacity(
                                              0.8,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                        : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor.withOpacity(
                                              0.3,
                                            )
                                            : Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4776E6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis,
                color: Color(0xFF4776E6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Instalaciones disponibles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4776E6)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando instalaciones...',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay instalaciones disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Intenta seleccionar otra fecha para encontrar disponibilidad',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAvailableInstallations,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4776E6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationsSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final installation = _availableInstallations[index];
          return _buildFacilityCard(
            installation.nombre,
            installation.descripcion ?? '',
            _getFacilityIcon(installation.tipo),
            _getFacilityTimeSlots(),
            installation.id,
          );
        }, childCount: _availableInstallations.length),
      ),
    );
  }

  Widget _buildFacilityCard(
    String name,
    String description,
    IconData icon,
    List<Map<String, dynamic>> timeSlots,
    String installationId,
  ) {
    // Elegir colores según el tipo de instalación
    List<Color> gradientColors;
    Color accentColor;

    if (icon == Icons.pool) {
      gradientColors = [Colors.blue.shade400, Colors.cyan.shade600];
      accentColor = Colors.blue.shade600;
    } else if (icon == Icons.sports_tennis) {
      gradientColors = [Colors.green.shade400, Colors.lightGreen.shade600];
      accentColor = Colors.green.shade600;
    } else if (icon == Icons.fitness_center) {
      gradientColors = [Colors.purple.shade400, Colors.deepPurple.shade600];
      accentColor = Colors.purple.shade600;
    } else if (icon == Icons.sports_soccer) {
      gradientColors = [Colors.orange.shade400, Colors.deepOrange.shade600];
      accentColor = Colors.orange.shade600;
    } else if (icon == Icons.sports_basketball) {
      gradientColors = [Colors.red.shade400, Colors.redAccent.shade700];
      accentColor = Colors.red.shade600;
    } else {
      gradientColors = [Colors.teal.shade400, Colors.teal.shade700];
      accentColor = Colors.teal.shade600;
    }

    return FutureBuilder<bool>(
      // Verificar si la instalación tiene pistas antes de mostrar esa sección
      future: _checkIfInstallationHasCourts(installationId),
      builder: (context, hasCourtsSnapshot) {
        final bool hasCourts = hasCourtsSnapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con imagen y degradado optimizado para diferentes imágenes
                AspectRatio(
                  aspectRatio: 16 / 9, // Proporción estándar para imágenes
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fondo con gradiente base
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Icono decorativo adaptable como imagen de fondo
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(icon, color: Colors.white),
                          ),
                        ),
                      ),

                      // Overlay con gradiente para mejorar legibilidad del texto
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradientColors[0].withOpacity(0.7),
                              gradientColors[1].withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Contenido de la cabecera
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getFacilityTypeName(icon),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 1,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de pistas disponibles - solo si la instalación tiene pistas
                if (hasCourts)
                  _buildExpandableSectionWithLimitedHeight(
                    title: 'Pistas disponibles',
                    icon: Icons.sports_tennis,
                    accentColor: accentColor,
                    content: FutureBuilder<List<Widget>>(
                      future: _loadCourtsList(installationId, accentColor),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Error al cargar las pistas: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No hay pistas disponibles para esta instalación',
                            ),
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: snapshot.data!,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    maxHeight: 250,
                  ),

                // Horarios disponibles
                _buildExpandableSectionWithLimitedHeight(
                  title: 'Horarios disponibles',
                  icon: Icons.access_time,
                  accentColor: accentColor,
                  initiallyExpanded: true,
                  content:
                      _selectedCourtsByInstallation[installationId] != null
                          ? FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getCourtTimeAvailability(
                              installationId,
                              _selectedCourtsByInstallation[installationId]!.id,
                              _selectedDate,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final List<Map<String, dynamic>>
                              availabilityData = snapshot.data ?? timeSlots;

                              return Column(
                                mainAxisSize:
                                    MainAxisSize
                                        .min, // Importante para evitar expansión excesiva
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mostrar la pista seleccionada
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Pista seleccionada: ${_selectedCourtsByInstallation[installationId]!.nombre}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedCourtsByInstallation[installationId] =
                                                  null;
                                            });
                                          },
                                          child: const Text('Cambiar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Usar SingleChildScrollView para evitar overflows
                                  SizedBox(
                                    height: 70, // Altura fija para horarios
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            availabilityData.map((slot) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 10,
                                                  bottom: 10,
                                                ),
                                                child: InkWell(
                                                  onTap:
                                                      slot['available'] == true
                                                          ? () =>
                                                              _showAdvancedReservationDialog(
                                                                installationId: installationId,
                                                                facilityName: name,
                                                                timeSlot: slot['time']
                                                                    .toString(),
                                                                gradientColors: gradientColors,
                                                                icon: icon,
                                                                hasCourts: hasCourts,
                                                              )
                                                          : null,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          slot['available'] ==
                                                                  true
                                                              ? LinearGradient(
                                                                colors: [
                                                                  Colors
                                                                      .green
                                                                      .shade400,
                                                                  Colors
                                                                      .green
                                                                      .shade600,
                                                                ],
                                                                begin:
                                                                    Alignment
                                                                        .topLeft,
                                                                end:
                                                                    Alignment
                                                                        .bottomRight,
                                                              )
                                                              : LinearGradient(
                                                                colors: [
                                                                  Colors
                                                                      .red
                                                                      .shade300,
                                                                  Colors
                                                                      .red
                                                                      .shade500,
                                                                ],
                                                                begin:
                                                                    Alignment
                                                                        .topLeft,
                                                                end:
                                                                    Alignment
                                                                        .bottomRight,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              slot['available'] ==
                                                                      true
                                                                  ? Colors.green
                                                                      .withOpacity(
                                                                        0.3,
                                                                      )
                                                                  : Colors.red
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                          spreadRadius: 0,
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          slot['available'] ==
                                                                  true
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons.cancel,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          slot['time']
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                          : hasCourts
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Selecciona una pista para ver los horarios disponibles',
                                style: TextStyle(color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : SizedBox(
                            height: 70, // Altura fija para horarios
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    timeSlots.map((slot) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                          bottom: 10,
                                        ),
                                        child: InkWell(
                                          onTap:
                                              slot['available'] == true
                                                  ? () =>
                                                      _showAdvancedReservationDialog(
                                                        installationId: installationId,
                                                        facilityName: name,
                                                        timeSlot: slot['time'].toString(),
                                                        gradientColors: gradientColors,
                                                        icon: icon,
                                                        hasCourts: hasCourts,
                                                      )
                                                  : null,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  slot['available'] == true
                                                      ? LinearGradient(
                                                        colors: [
                                                          gradientColors[0]
                                                              .withOpacity(0.7),
                                                          gradientColors[1]
                                                              .withOpacity(0.7),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                      )
                                                      : null,
                                              color:
                                                  slot['available'] != true
                                                      ? Colors.grey.shade200
                                                      : null,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow:
                                                  slot['available'] == true
                                                      ? [
                                                        BoxShadow(
                                                          color:
                                                              gradientColors[0]
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                          spreadRadius: 0,
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ]
                                                      : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color:
                                                      slot['available'] == true
                                                          ? Colors.white
                                                          : Colors
                                                              .grey
                                                              .shade500,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  slot['time'].toString(),
                                                  style: TextStyle(
                                                    color:
                                                        slot['available'] ==
                                                                true
                                                            ? Colors.white
                                                            : Colors
                                                                .grey
                                                                .shade500,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                  maxHeight: 180,
                ),

                // Espacio al final para evitar desbordamientos
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para crear secciones expandibles con altura limitada
  Widget _buildExpandableSectionWithLimitedHeight({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget content,
    bool initiallyExpanded = false,
    double maxHeight = 300,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        visualDensity: VisualDensity.compact,
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: accentColor,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [LimitedBox(maxHeight: maxHeight, child: content)],
      ),
    );
  }

  // Método para verificar si una instalación tiene pistas
  Future<bool> _checkIfInstallationHasCourts(String installationId) async {
    try {
      final courts = await CourtService.getCourtsByInstallationId(
        installationId,
      );
      return courts.isNotEmpty;
    } catch (e) {
      print('Error al verificar pistas de la instalación: $e');
      return false;
    }
  }

  // Método para simular horarios disponibles (sin lógica de slots pasados)
  List<Map<String, dynamic>> _getFacilityTimeSlots() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    final currentTime = TimeOfDay.fromDateTime(now);
    final slots = [
      {'time': '09:00 - 10:00', 'available': true},
      {'time': '10:00 - 11:00', 'available': true},
      {'time': '11:00 - 12:00', 'available': true},
      {'time': '12:00 - 13:00', 'available': true},
      {'time': '15:00 - 16:00', 'available': true},
      {'time': '16:00 - 17:00', 'available': true},
      {'time': '17:00 - 18:00', 'available': true},
      {'time': '18:00 - 19:00', 'available': true},
    ];
    if (isToday) {
      for (final slot in slots) {
        final String slotTimeRange = slot['time'] as String;
        final List<String> times = slotTimeRange.split(' - ');
        final String slotEndTime = times[1];
        final slotEnd = TimeOfDay(
          hour: int.parse(slotEndTime.split(':')[0]),
          minute: int.parse(slotEndTime.split(':')[1]),
        );
        // Si la hora actual es mayor o igual a la hora de fin del slot, marcarlo como no disponible
        if (currentTime.hour > slotEnd.hour || (currentTime.hour == slotEnd.hour && currentTime.minute >= slotEnd.minute)) {
          slot['available'] = false;
          slot['past'] = true;
        }
      }
    }
    return slots;
  }

  // Método para formatear hora en formato HH:mm
  String _formatTimeString(String time) {
    // Si el tiempo ya está en formato HH:mm, devolverlo tal cual
    if (!time.contains(':')) return time;

    // Si tiene segundos, eliminarlos
    return time.split(':').take(2).join(':');
  }

  // Método para obtener la disponibilidad de horarios para una pista específica
  Future<List<Map<String, dynamic>>> _getCourtTimeAvailability(
    String installationId,
    String courtId,
    DateTime date,
  ) async {
    try {
      // Lista base de horarios
      final List<Map<String, dynamic>> timeSlots = _getFacilityTimeSlots();

      // Obtener reservas para esta pista en esta fecha
      final reservations =
          await ReservationService.getReservationsByCourtAndDate(
            courtId: courtId,
            date: date,
          );

      // Si no hay reservas, todos los horarios están disponibles
      if (reservations.isEmpty) {
        return timeSlots;
      }

      // Marcar los horarios que están ocupados
      for (final timeSlot in timeSlots) {
        final String slotTimeRange = timeSlot['time'] as String;
        final List<String> times = slotTimeRange.split(' - ');
        final String slotStartTime = _formatTimeString(times[0]);
        final String slotEndTime = _formatTimeString(times[1]);

        bool isAvailable = true;

        for (final reservation in reservations) {
          final String resStartTime = _formatTimeString(reservation.horaInicio);
          final String resEndTime = _formatTimeString(reservation.horaFin);

          // Verificar si hay solapamiento
          final bool overlap =
              !(int.parse(slotStartTime.replaceAll(':', '')) >= int.parse(resEndTime.replaceAll(':', '')) ||
                int.parse(slotEndTime.replaceAll(':', '')) <= int.parse(resStartTime.replaceAll(':', '')));

          if (overlap) {
            isAvailable = false;
            break;
          }
        }

        timeSlot['available'] = isAvailable;
      }

      return timeSlots;
    } catch (e) {
      print('Error al obtener disponibilidad de horarios: $e');
      return _getFacilityTimeSlots(); // Devolver horarios predeterminados todos disponibles
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Método para obtener icono según tipo de instalación
  IconData _getFacilityIcon(String type) {
    final tipo = type.toLowerCase();
    if (tipo.contains('piscina')) {
      return Icons.pool;
    } else if (tipo.contains('tenis')) {
      return Icons.sports_tennis;
    } else if (tipo.contains('gimnasio')) {
      return Icons.fitness_center;
    } else if (tipo.contains('fútbol') || tipo.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (tipo.contains('baloncesto')) {
      return Icons.sports_basketball;
    }
    return Icons.sports;
  }

  Widget _buildConfirmationInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Color(0xFF4776E6)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método para cargar la lista de pistas de una instalación
  Future<List<Widget>> _loadCourtsList(
    String installationId,
    Color accentColor,
  ) async {
    try {
      print('Cargando pistas para instalación: $installationId');
      final courts = await CourtService.getCourtsByInstallationId(
        installationId,
      );

      if (courts.isEmpty) {
        return [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No hay pistas disponibles en esta instalación',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ];
      }

      print('Pistas encontradas para $installationId: ${courts.length}');
      courts.forEach(
        (court) => print('Pista: ${court.nombre} (ID: ${court.id})'),
      );

      return courts.map((court) {
        final bool isSelected =
            _selectedCourtsByInstallation[installationId]?.id == court.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? accentColor.withOpacity(0.05) : Colors.white,
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCourtsByInstallation[installationId] = court;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? accentColor.withOpacity(0.2)
                              : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_tennis,
                      color: isSelected ? accentColor : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? accentColor : Colors.black87,
                          ),
                        ),
                        if (court.descripcion != null &&
                            court.descripcion!.isNotEmpty)
                          Text(
                            court.descripcion!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList();
    } catch (e) {
      print('Error al cargar pistas: $e');
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar las pistas: $e',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ];
    }
  }

  // Método para mostrar un diálogo avanzado de reserva
  void _showAdvancedReservationDialog({
    required String installationId,
    required String facilityName,
    required String timeSlot,
    required List<Color> gradientColors,
    required IconData icon,
    required bool hasCourts,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    // Obtener las horas de inicio y fin del slot seleccionado
    final timeRange = timeSlot.split(' - ');
    final startTime = timeRange[0];
    final endTime = timeRange[1];

    // Si no hay una pista seleccionada para esta instalación, mostrar mensaje de error
    if (!hasCourts && _selectedCourtsByInstallation[installationId] == null) {
      // No requiere selección de pista si no tiene pistas
    } else if (hasCourts && _selectedCourtsByInstallation[installationId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una pista primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Confirmar Reserva',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completa la información para reservar',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Información de la reserva
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConfirmationInfoRow(
                          Icons.business,
                          'INSTALACIÓN',
                          facilityName,
                        ),
                        const SizedBox(height: 12),
                        if (hasCourts)
                          _buildConfirmationInfoRow(
                            Icons.sports_tennis,
                            'PISTA',
                            _selectedCourtsByInstallation[installationId]!.nombre,
                          ),
                        if (hasCourts) const SizedBox(height: 12),
                        _buildConfirmationInfoRow(
                          Icons.calendar_today,
                          'FECHA',
                          _dateFormat.format(_selectedDate),
                        ),
                        const SizedBox(height: 12),
                        _buildConfirmationInfoRow(
                          Icons.access_time,
                          'HORARIO',
                          timeSlot,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => _createReservation(
                                  installationId,
                                  // Pasar courtId solo si la instalación tiene pistas
                                  hasCourts ? _selectedCourtsByInstallation[installationId]!.id : null,
                                  startTime,
                                  endTime,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4776E6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Confirmar Reserva',
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  // Método para crear una nueva reserva
  Future<void> _createReservation(
    String installationId,
    String? courtId,
    String startTime,
    String endTime,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    try {
      // Cerrar el diálogo de confirmación
      Navigator.pop(context);

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Llamar al servicio con los parámetros correctos
      final success = await ReservationService.createReservation(
        userId: authProvider.user!.id,
        installationId: installationId,
        courtId: courtId,
        date: _selectedDate,
        startTime: startTime,
        endTime: endTime,
      );

      // Cerrar el diálogo de carga
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          // Actualizar las reservas del usuario
          _loadReservations(authProvider.user!.id);

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reserva creada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo crear la reserva. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar el diálogo de carga
      if (mounted) Navigator.pop(context);

      print('Error al crear reserva: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para obtener el nombre del tipo de instalación según el icono
  String _getFacilityTypeName(IconData icon) {
    if (icon == Icons.pool) {
      return 'Piscina';
    } else if (icon == Icons.sports_tennis) {
      return 'Tenis';
    } else if (icon == Icons.fitness_center) {
      return 'Gimnasio';
    } else if (icon == Icons.sports_soccer) {
      return 'Fútbol';
    } else if (icon == Icons.sports_basketball) {
      return 'Baloncesto';
    }
    return 'Deportes';
  }

  // Método auxiliar para depurar la información de pistas en las reservas
  void _debugReservationPistas() {
    print("\n==== INFORMACIÓN DE PISTAS EN RESERVAS ACTIVAS ====");
    for (var reservation in _activeReservations) {
      print("Reserva ID: ${reservation.id}");
      print("  pistaId: ${reservation.pistaId}");
      print("  pista: ${reservation.pista}");
      if (reservation.pista != null) {
        print("  Nombre de pista: ${reservation.pista!['nombre']}");
      }
      print("----------------------------------------");
    }

    print("\n==== INFORMACIÓN DE PISTAS EN HISTORIAL DE RESERVAS ====");
    for (var reservation in _historicalReservations) {
      print("Reserva ID: ${reservation.id}");
      print("  pistaId: ${reservation.pistaId}");
      print("  pista: ${reservation.pista}");
      if (reservation.pista != null) {
        print("  Nombre de pista: ${reservation.pista!['nombre']}");
      }
      print("----------------------------------------");
    }
  }
}
