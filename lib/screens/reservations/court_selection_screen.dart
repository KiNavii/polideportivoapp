import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/court_model.dart';
import 'package:deportivov1/models/installation_model.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/court_service.dart';
import 'package:deportivov1/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CourtSelectionScreen extends StatefulWidget {
  final Installation installation;
  final DateTime selectedDate;
  final String startTime;
  final String endTime;

  const CourtSelectionScreen({
    Key? key,
    required this.installation,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courtsWithAvailability = [];
  Court? _selectedCourt;
  String? _errorMessage;
  late TabController _tabController;

  // Filtros
  String _currentFilter = "Todas";
  List<String> _filterOptions = ["Todas", "Disponibles", "No disponibles"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourtsWithAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourtsWithAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
        '⚠️ Cargando pistas para la instalación: ${widget.installation.id}',
      );

      // Intentar obtener las pistas con disponibilidad
      var courtsWithAvailability =
          await CourtService.getAllCourtsWithAvailability(
            installationId: widget.installation.id,
            date: widget.selectedDate,
            startTime: widget.startTime,
            endTime: widget.endTime,
          );

      // Si no hay pistas, intentar crear pistas de demostración
      if (courtsWithAvailability.isEmpty) {
        print('⚠️ No se encontraron pistas, creando pistas de demostración');
        final createdDemo = await CourtService.createDemoCourts(
          widget.installation.id,
        );

        if (createdDemo) {
          // Volver a cargar las pistas después de crear las de demostración
          courtsWithAvailability =
              await CourtService.getAllCourtsWithAvailability(
                installationId: widget.installation.id,
                date: widget.selectedDate,
                startTime: widget.startTime,
                endTime: widget.endTime,
              );
        }
      }

      setState(() {
        _courtsWithAvailability = courtsWithAvailability;
        _isLoading = false;
        if (courtsWithAvailability.isEmpty) {
          _errorMessage = 'No hay pistas disponibles para esta instalación';
        }
      });
    } catch (e) {
      print('⚠️ Error al cargar pistas: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar las pistas: ${e.toString()}';
      });
    }
  }

  Future<void> _createReservation() async {
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una pista disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user!.id;

      final success = await ReservationService.createReservation(
        userId: userId,
        installationId: widget.installation.id,
        courtId: _selectedCourt!.id,
        date: widget.selectedDate,
        startTime: widget.startTime,
        endTime: widget.endTime,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva realizada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        // Volver a la pantalla anterior después de una breve pausa
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(true); // Devolver true para indicar éxito
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la reserva'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filtrar las pistas según el filtro seleccionado
  List<Map<String, dynamic>> get _filteredCourts {
    if (_currentFilter == "Todas") return _courtsWithAvailability;

    return _courtsWithAvailability.where((courtData) {
      final isAvailable = courtData['isAvailable'] as bool;
      return (_currentFilter == "Disponibles") ? isAvailable : !isAvailable;
    }).toList();
  }

  // Add this helper method before the build method
  String _formatTimeString(String time) {
    // If the time already has HH:mm format, return as is
    if (!time.contains(':')) return time;

    // If it has seconds, remove them
    return time.split(':').take(2).join(':');
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final bool canReserve =
        _selectedCourt != null &&
        _courtsWithAvailability
            .where((court) => court['court'].id == _selectedCourt!.id)
            .first['isAvailable'];

    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        strokeWidth: 6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Cargando pistas",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  // Header y App Bar personalizado
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppTheme.primaryColor,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(
                        left: 20,
                        bottom: 16,
                        right: 16,
                      ),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECCIONAR PISTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.installation.nombre,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Fondo con gradiente
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.8),
                                  AppTheme.primaryColor.withOpacity(1.0),
                                ],
                              ),
                            ),
                          ),
                          // Patrón de decoración
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: 0.2,
                              child: Image.network(
                                'https://img.freepik.com/premium-vector/tennis-pattern-with-ball-racket-icons-white-background_53562-8132.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Información de la reserva
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 70,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateFormat.format(widget.selectedDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_formatTimeString(widget.startTime)} - ${_formatTimeString(widget.endTime)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadCourtsWithAvailability,
                      ),
                    ],
                  ),

                  // Mensaje de error si existe
                  if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                await CourtService.createDemoCourts(
                                  widget.installation.id,
                                );
                                _loadCourtsWithAvailability();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Crear pistas de demostración'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Controles de filtrado
                  if (_errorMessage == null &&
                      _courtsWithAvailability.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tabs de vista
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppTheme.primaryColor,
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey.shade600,
                                tabs: const [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.grid_view),
                                        SizedBox(width: 8),
                                        Text("Cuadrícula"),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.view_list),
                                        SizedBox(width: 8),
                                        Text("Lista"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Filtros de disponibilidad
                            Row(
                              children: [
                                const Text(
                                  "Filtrar: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Wrap(
                                  spacing: 8,
                                  children:
                                      _filterOptions.map((filter) {
                                        final isSelected =
                                            _currentFilter == filter;
                                        return ChoiceChip(
                                          label: Text(filter),
                                          selected: isSelected,
                                          selectedColor: AppTheme.primaryColor,
                                          labelStyle: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                          onSelected: (_) {
                                            setState(() {
                                              _currentFilter = filter;
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),

                            // Contador de pistas
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                "Se encontraron ${_filteredCourts.length} pistas",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Listado de pistas
                  if (_errorMessage == null &&
                      _courtsWithAvailability.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: 400, // Altura fija para el TabBarView
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Vista de cuadrícula
                              GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: _filteredCourts.length,
                                itemBuilder: (context, index) {
                                  final courtData = _filteredCourts[index];
                                  final court = courtData['court'] as Court;
                                  final isAvailable =
                                      courtData['isAvailable'] as bool;
                                  final reason = courtData['reason'] as String?;
                                  final isSelected =
                                      _selectedCourt?.id == court.id;

                                  return GestureDetector(
                                    onTap:
                                        isAvailable
                                            ? () {
                                              setState(() {
                                                _selectedCourt = court;
                                              });
                                            }
                                            : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                isSelected
                                                    ? AppTheme.primaryColor
                                                        .withOpacity(0.3)
                                                    : Colors.grey.withOpacity(
                                                      0.2,
                                                    ),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Cabecera con estado
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  isAvailable
                                                      ? Colors.green
                                                      : Colors.red.shade400,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      16,
                                                    ),
                                                    topRight: Radius.circular(
                                                      16,
                                                    ),
                                                  ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Pista ${court.numero}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Icon(
                                                  isAvailable
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Imagen o icono representativo
                                          Expanded(
                                            child: Container(
                                              color:
                                                  isSelected
                                                      ? AppTheme.primaryColor
                                                          .withOpacity(0.1)
                                                      : Colors.grey.shade50,
                                              child: Center(
                                                child: Icon(
                                                  Icons.sports_tennis,
                                                  size: 50,
                                                  color:
                                                      isSelected
                                                          ? AppTheme
                                                              .primaryColor
                                                          : Colors
                                                              .grey
                                                              .shade400,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Información de la pista
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  court.nombre,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  court.superficie ??
                                                      "Superficie estándar",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        isSelected
                                                            ? Colors.white70
                                                            : Colors
                                                                .grey
                                                                .shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (!isAvailable &&
                                                    reason != null) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    reason,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isSelected
                                                              ? Colors.white70
                                                              : Colors
                                                                  .orange
                                                                  .shade800,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Vista de lista
                              ListView.separated(
                                itemCount: _filteredCourts.length,
                                separatorBuilder:
                                    (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final courtData = _filteredCourts[index];
                                  final court = courtData['court'] as Court;
                                  final isAvailable =
                                      courtData['isAvailable'] as bool;
                                  final reason = courtData['reason'] as String?;
                                  final isSelected =
                                      _selectedCourt?.id == court.id;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side:
                                          isSelected
                                              ? BorderSide(
                                                color: AppTheme.primaryColor,
                                                width: 2,
                                              )
                                              : BorderSide.none,
                                    ),
                                    tileColor:
                                        isSelected
                                            ? AppTheme.primaryColor.withOpacity(
                                              0.1,
                                            )
                                            : null,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          isAvailable
                                              ? Colors.green
                                              : Colors.red.shade400,
                                      radius: 26,
                                      child: Text(
                                        "${court.numero}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      court.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          court.superficie ??
                                              "Superficie estándar",
                                        ),
                                        if (!isAvailable && reason != null)
                                          Text(
                                            reason,
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing:
                                        isAvailable
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                            : const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                            ),
                                    onTap:
                                        isAvailable
                                            ? () {
                                              setState(() {
                                                _selectedCourt = court;
                                              });
                                            }
                                            : null,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

      // Botón flotante de reserva
      floatingActionButton:
          (!_isLoading && _errorMessage == null && canReserve)
              ? FloatingActionButton.extended(
                onPressed: _createReservation,
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.check_circle),
                label: const Text("CONFIRMAR RESERVA"),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Barra inferior con información de la pista seleccionada
      bottomNavigationBar:
          (!_isLoading && _selectedCourt != null)
              ? Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "Pista seleccionada: ${_selectedCourt!.nombre}",
                  style: TextStyle(
                    color: canReserve ? AppTheme.primaryColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : null,
    );
  }
}
