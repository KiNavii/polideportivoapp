import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/event_model.dart';
import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/models/reservation_model.dart';

import 'package:deportivov1/screens/events/events_screen.dart';
import 'package:deportivov1/screens/activities/activities_screen.dart';
import 'package:deportivov1/services/optimized_activity_service.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/event_service.dart';
import 'package:deportivov1/services/news_service.dart';
import 'package:deportivov1/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deportivov1/utils/responsive_util.dart';
import 'package:deportivov1/screens/main_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deportivov1/utils/watermark_remover.dart';
import 'package:deportivov1/services/activity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Activity> _upcomingActivities = [];
  List<News> _news = [];
  List<Event> _events = [];
  List<Reservation> _activeReservations = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'es_ES');

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
      // Actualizar reservas completadas antes de cargar los datos
      try {
        await ReservationService.updateCompletedReservations();
        // Limpiar reservas antiguas
        await ReservationService.cleanOldReservations();
      } catch (e) {
        print('Error al actualizar reservas completadas: $e');
      }

      // Cargar actividades
      List<Activity> activities = [];
      try {
        final activityService = ActivityService();
        activities = await activityService.getActivitiesWithFamily(limit: 5);

        // Ordenar por fecha y hora
        activities.sort((a, b) {
          int dateCompare = a.fechaInicio.compareTo(b.fechaInicio);
          if (dateCompare != 0) return dateCompare;
          return a.horaInicio.compareTo(b.horaInicio);
        });
      } catch (e) {
        print('Error al cargar actividades: $e');
      }

      // Cargar noticias
      List<News> news = [];
      try {
        news = await NewsService.getFeaturedNews(limit: 3);

        // Si no hay noticias destacadas, cargar las más recientes
        if (news.isEmpty) {
          news = await NewsService.getAllNews(limit: 3);
        }
      } catch (e) {
        print('Error al cargar noticias: $e');
      }

      // Cargar eventos próximos
      List<Event> events = [];
      try {
        events = await EventService.getUpcomingEvents(limit: 3);
      } catch (e) {
        print('Error al cargar eventos: $e');
      }

      // Cargar reservas activas
      List<Reservation> reservations = [];
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          reservations = await ReservationService.getUserReservations(
            authProvider.user!.id,
            limit: 3,
          );
        }
      } catch (e) {
        print('Error al cargar reservas: $e');
      }

      if (mounted) {
        setState(() {
          _upcomingActivities = activities.take(3).toList();
          _news = news;
          _events = events;
          _activeReservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos de inicio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Mostrar un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos. Intenta nuevamente.'),
            action: SnackBarAction(label: 'Reintentar', onPressed: _loadData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.nombre ?? '';
    final userEmail = user?.email ?? '';
    final userInitials =
        userName.isNotEmpty
            ? userName
                .split(' ')
                .take(2)
                .map((s) => s.isNotEmpty ? s[0] : '')
                .join('')
                .toUpperCase()
            : '?';

    // Determinar dimensiones adaptativas
    final double headerFontSize = ResponsiveUtil.getAdaptiveTextSize(
      context,
      32,
    );
    final double bodyFontSize = ResponsiveUtil.getAdaptiveTextSize(context, 16);
    final double subtitleFontSize = ResponsiveUtil.getAdaptiveTextSize(
      context,
      18,
    );
    final double cardHeight = ResponsiveUtil.getAdaptiveHeight(context, 200);
    final double padding = ResponsiveUtil.getAdaptivePadding(context, 20);
    final bool isSmallDevice = ResponsiveUtil.isSmallMobile(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con saludo y flecha - Ajustado para bajar más la posición
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          top: ResponsiveUtil.getAdaptivePadding(context, 70),
                          left: padding,
                          right: padding,
                          bottom: ResponsiveUtil.getAdaptivePadding(
                            context,
                            15,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Hola, ${userName.isNotEmpty ? userName.split(' ').first : 'Usuario'}!',
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtil.getAdaptivePadding(
                                      context,
                                      4,
                                    ),
                                  ),
                                  Text(
                                    'Bienvenido/a a Polideportivo App',
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: AppTheme.primaryColor,
                                ),
                                tooltip: 'Cerrar sesión',
                                onPressed: () {
                                  // Cerrar sesión en lugar de navegar al perfil
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Cerrar sesión'),
                                          content: const Text(
                                            '¿Estás seguro de que deseas cerrar sesión?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                authProvider.signOut();
                                              },
                                              child: const Text(
                                                'Cerrar sesión',
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Información del usuario (tarjeta)
                      Padding(
                        padding: EdgeInsets.all(padding),
                        child: Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: isSmallDevice ? 60 : 80,
                                width: isSmallDevice ? 60 : 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  image:
                                      user?.fotoPerfil != null &&
                                              user!.fotoPerfil!.isNotEmpty
                                          ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              user.fotoPerfil!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                ),
                                child:
                                    user?.fotoPerfil == null ||
                                            user!.fotoPerfil!.isEmpty
                                        ? Center(
                                          child: Text(
                                            userInitials,
                                            style: TextStyle(
                                              fontSize:
                                                  ResponsiveUtil.getAdaptiveTextSize(
                                                    context,
                                                    32,
                                                  ),
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        )
                                        : null,
                              ),
                              SizedBox(
                                width: ResponsiveUtil.getAdaptivePadding(
                                  context,
                                  20,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName.isNotEmpty
                                          ? userName
                                          : 'Usuario',
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtil.getAdaptiveTextSize(
                                              context,
                                              22,
                                            ),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      height: ResponsiveUtil.getAdaptivePadding(
                                        context,
                                        5,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size:
                                              ResponsiveUtil.getAdaptiveTextSize(
                                                context,
                                                18,
                                              ),
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(
                                          width:
                                              ResponsiveUtil.getAdaptivePadding(
                                                context,
                                                8,
                                              ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            userEmail.isNotEmpty
                                                ? userEmail
                                                : 'Sin correo',
                                            style: TextStyle(
                                              fontSize:
                                                  ResponsiveUtil.getAdaptiveTextSize(
                                                    context,
                                                    16,
                                                  ),
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
                      ),

                      // Sección de Noticias - Título con icono
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(
                                  width: ResponsiveUtil.getAdaptivePadding(
                                    context,
                                    10,
                                  ),
                                ),
                                Text(
                                  'Últimas Noticias',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtil.getAdaptiveTextSize(
                                          context,
                                          20,
                                        ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveUtil.getAdaptivePadding(context, 15),
                      ),

                      // Tarjetas de noticias - Con altura adaptable
                      Padding(
                        padding: EdgeInsets.only(bottom: padding),
                        child:
                            _news.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(padding),
                                    child: Text(
                                      'No hay noticias disponibles',
                                      style: TextStyle(
                                        color: AppTheme.grayColor,
                                      ),
                                    ),
                                  ),
                                )
                                : SizedBox(
                                  height: cardHeight,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                    ),
                                    itemCount: _news.length,
                                    itemBuilder: (context, index) {
                                      // Alternar colores entre morado y azul
                                      final color =
                                          index % 2 == 0
                                              ? Colors.purple
                                              : Colors.blue;
                                      final news = _news[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              index < _news.length - 1 ? 15 : 0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            _showNewsDetail(
                                              context,
                                              news,
                                              color,
                                            );
                                          },
                                          child: buildNewsCardGradient(
                                            context,
                                            news.titulo,
                                            news.contenido,
                                            _dateFormat.format(
                                              news.fechaPublicacion,
                                            ),
                                            color,
                                            imageUrl: news.imagenUrl,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      ),

                      const SizedBox(height: 20),

                      // Sección de Próximos Eventos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event_outlined,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Próximos Eventos',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Lista de eventos en tarjetas horizontales
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            _events.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Text(
                                      'No hay eventos próximos disponibles',
                                      style: TextStyle(
                                        color: AppTheme.grayColor,
                                      ),
                                    ),
                                  ),
                                )
                                : Column(
                                  children:
                                      _events.map((event) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 15,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              // Navegar a la pantalla de eventos al hacer clic
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const EventsScreen(),
                                                ),
                                              );
                                            },
                                            child: _buildEventCard(event),
                                          ),
                                        );
                                      }).toList(),
                                ),
                      ),

                      const SizedBox(height: 20),

                      // NUEVA SECCIÓN DE MIS PRÓXIMAS RESERVAS
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Mis Próximas Reservas',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtil.getAdaptiveTextSize(
                                          context,
                                          20,
                                        ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navegar a la pantalla de reservas, pestaña "Mis Reservas"
                                _navigateToReservations(context, 0);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Botón Crear - Para nuevas reservas
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // Navegar a la pantalla de reservas, pestaña "Reservar"
                            _navigateToReservations(context, 1);
                          },
                          child: Container(
                            width: double.infinity,
                            height: ResponsiveUtil.getAdaptiveHeight(
                              context,
                              45,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade300,
                                  Colors.orange.shade500,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Crear',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtil.getAdaptiveTextSize(
                                          context,
                                          16,
                                        ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Lista de reservas activas
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            _activeReservations.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Text(
                                      'No tienes reservas próximas',
                                      style: TextStyle(
                                        color: AppTheme.grayColor,
                                      ),
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount:
                                      _activeReservations.length > 2
                                          ? 2
                                          : _activeReservations.length,
                                  itemBuilder: (context, index) {
                                    final reservation =
                                        _activeReservations[index];
                                    String facilityName = 'Instalación';
                                    if (reservation.instalacion != null) {
                                      facilityName =
                                          reservation.instalacion!['nombre'] ??
                                          'Instalación';
                                    }
                                    return _buildReservationCard(
                                      facilityName,
                                      reservation.fecha,
                                      reservation.horaInicio,
                                      reservation.horaFin,
                                    );
                                  },
                                ),
                      ),

                      const SizedBox(
                        height: 100,
                      ), // Espacio para la barra de navegación
                    ],
                  ),
                ),
              ),
    );
  }

  // Modificar el método buildNewsCardGradient para aceptar el contexto y usar dimensiones adaptativas
  Widget buildNewsCardGradient(
    BuildContext context,
    String title,
    String content,
    String date,
    Color baseColor, {
    String? imageUrl,
  }) {
    final List<Color> gradientColors = [baseColor, baseColor.withOpacity(0.8)];

    // Ajustar tamaños según el dispositivo
    final cardWidth = ResponsiveUtil.isSmallMobile(context) ? 250.0 : 300.0;
    final titleSize = ResponsiveUtil.getAdaptiveTextSize(context, 24);
    final dateSize = ResponsiveUtil.getAdaptiveTextSize(context, 14);
    final padding = ResponsiveUtil.getAdaptivePadding(context, 16);

    return Container(
      width: cardWidth,
      height: ResponsiveUtil.getAdaptiveHeight(context, 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Imagen de fondo con gradiente superpuesto
          if (imageUrl != null && imageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                    ),
                    // Gradiente sobre la imagen para mejorar legibilidad
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            gradientColors[0].withOpacity(0.3),
                            gradientColors[1].withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Contenido: Diseño similar a la imagen de referencia
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha en la parte superior con icono
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: dateSize,
                    ),
                    SizedBox(
                      width: ResponsiveUtil.getAdaptivePadding(context, 6),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: dateSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Espacio entre fecha y título
                Spacer(flex: 1),

                // Título grande en el centro/parte inferior
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Espaciador y botón "Leer más"
                Spacer(flex: 1),

                // Botón de leer más
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtil.getAdaptivePadding(
                        context,
                        12,
                      ),
                      vertical: ResponsiveUtil.getAdaptivePadding(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Leer más',
                          style: TextStyle(
                            fontSize: ResponsiveUtil.getAdaptiveTextSize(
                              context,
                              14,
                            ),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveUtil.getAdaptivePadding(context, 4),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: ResponsiveUtil.getAdaptiveTextSize(context, 14),
                        ),
                      ],
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

  // Sección: Tarjetas de eventos en la página principal
  Widget _buildEventCard(Event event) {
    List<Color> gradientColors = _getEventGradientColors(
      event.nombre.toLowerCase(),
    );

    return GestureDetector(
      onTap: () {
        _showEventDetail(context, event);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen o icono
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: SizedBox(
                  width: 100,
                  child:
                      event.imagenUrl != null && event.imagenUrl!.isNotEmpty
                          ? Image.network(
                            event.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                'Error cargando imagen de evento: $error - URL: ${event.imagenUrl}',
                              );
                              return Container(
                                color: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  _getEventIcon(event.nombre.toLowerCase()),
                                  color: Colors.white,
                                  size: 36,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.white.withOpacity(0.2),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white.withOpacity(0.7),
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Icon(
                              _getEventIcon(event.nombre.toLowerCase()),
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                ),
              ),

              // Información del evento
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nombre del evento
                      Text(
                        event.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Fecha y lugar
                      Row(
                        children: [
                          const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _dateFormat.format(event.fechaInicio),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              event.lugar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Flecha indicadora
              Container(
                padding: const EdgeInsets.all(15),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para obtener los colores del gradiente según el tipo de evento
  List<Color> _getEventGradientColors(String eventName) {
    if (eventName.contains('gimnasia') || eventName.contains('fitness')) {
      return [Colors.teal.shade600, Colors.teal.shade400];
    } else if (eventName.contains('yoga') || eventName.contains('pilates')) {
      return [Colors.indigo.shade600, Colors.indigo.shade400];
    } else if (eventName.contains('natación') ||
        eventName.contains('acuatica')) {
      return [Colors.blue.shade600, Colors.blue.shade400];
    } else if (eventName.contains('baile') || eventName.contains('zumba')) {
      return [Colors.pink.shade600, Colors.pink.shade400];
    } else if (eventName.contains('ciclismo') ||
        eventName.contains('spinning')) {
      return [Colors.green.shade600, Colors.green.shade400];
    } else if (eventName.contains('boxeo') || eventName.contains('lucha')) {
      return [Colors.red.shade600, Colors.red.shade400];
    } else if (eventName.contains('torneo') ||
        eventName.contains('campeonato')) {
      return [Colors.purple.shade600, Colors.purple.shade400];
    } else if (eventName.contains('infantil') || eventName.contains('niños')) {
      return [Colors.amber.shade600, Colors.amber.shade400];
    } else if (eventName.contains('senior') || eventName.contains('mayores')) {
      return [Colors.orange.shade600, Colors.orange.shade400];
    }

    // Colores por defecto
    return [Colors.blue.shade600, Colors.blue.shade400];
  }

  // Mostrar detalle de noticia en un modal
  void _showNewsDetail(BuildContext context, News news, Color backgroundColor) {
    // Usar tamaños adaptables
    final double screenHeight = ResponsiveUtil.screenHeight(context);
    final double titleSize = ResponsiveUtil.getAdaptiveTextSize(context, 24);
    final double contentSize = ResponsiveUtil.getAdaptiveTextSize(context, 16);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera con imagen o color
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: backgroundColor,
                      child:
                          news.imagenUrl != null && news.imagenUrl!.isNotEmpty
                              ? Image.network(
                                news.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.article,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                              )
                              : const Icon(
                                Icons.article,
                                color: Colors.white,
                                size: 60,
                              ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateFormat.format(news.fechaPublicacion),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título con etiqueta
                      const Text(
                        'Título',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.titulo,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Descripción con etiqueta
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.contenido,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de cerrar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Mostrar detalle de evento en un modal
  void _showEventDetail(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera con imagen o color
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.blue.shade500,
                      child:
                          event.imagenUrl != null && event.imagenUrl!.isNotEmpty
                              ? Image.network(
                                event.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  print(
                                    'Error cargando imagen en detalle del evento: ${event.imagenUrl}',
                                  );
                                  return Icon(
                                    _getEventIcon(event.nombre.toLowerCase()),
                                    color: Colors.white,
                                    size: 60,
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              )
                              : Icon(
                                _getEventIcon(event.nombre.toLowerCase()),
                                color: Colors.white,
                                size: 60,
                              ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateFormat.format(event.fechaInicio),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        event.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Información
                      _buildInfoRow(
                        Icons.access_time,
                        _formatEventDateTime(event),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, event.lugar),
                      const SizedBox(height: 20),
                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.descripcion,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de cerrar
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget para mostrar información con icono
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // Función para formatear la fecha y hora del evento
  String _formatEventDateTime(Event event) {
    // Formatear la fecha
    String formattedDate = _dateFormat.format(event.fechaInicio);

    // Formatear las horas de inicio y fin
    String startTime =
        '${event.fechaInicio.hour.toString().padLeft(2, '0')}:${event.fechaInicio.minute.toString().padLeft(2, '0')}';
    String endTime =
        event.fechaFin != null
            ? '${event.fechaFin!.hour.toString().padLeft(2, '0')}:${event.fechaFin!.minute.toString().padLeft(2, '0')}'
            : '${event.fechaInicio.add(const Duration(hours: 1)).hour.toString().padLeft(2, '0')}:${event.fechaInicio.minute.toString().padLeft(2, '0')}';

    return '$formattedDate, $startTime - $endTime';
  }

  // Obtener el icono apropiado según el tipo de evento
  IconData _getEventIcon(String eventName) {
    if (eventName.contains('gimnasia') || eventName.contains('fitness')) {
      return Icons.fitness_center;
    } else if (eventName.contains('yoga') || eventName.contains('pilates')) {
      return Icons.self_improvement;
    } else if (eventName.contains('natación') ||
        eventName.contains('acuatica')) {
      return Icons.pool;
    } else if (eventName.contains('baile') || eventName.contains('zumba')) {
      return Icons.music_note;
    } else if (eventName.contains('ciclismo') ||
        eventName.contains('spinning')) {
      return Icons.directions_bike;
    } else if (eventName.contains('boxeo') || eventName.contains('lucha')) {
      return Icons.sports_mma;
    }

    // Icono por defecto
    return Icons.event;
  }

  // Método para construir tarjetas de reservas
  Widget _buildReservationCard(
    String facilityName,
    DateTime date,
    String startTime,
    String endTime,
  ) {
    // Determinar ícono basado en el nombre de la instalación
    IconData facilityIcon = Icons.sports;
    Color iconColor = Colors.blue;

    if (facilityName.toLowerCase().contains('piscina')) {
      facilityIcon = Icons.pool;
    } else if (facilityName.toLowerCase().contains('tenis')) {
      facilityIcon = Icons.sports_tennis;
    } else if (facilityName.toLowerCase().contains('futbol')) {
      facilityIcon = Icons.sports_soccer;
    } else if (facilityName.toLowerCase().contains('basket')) {
      facilityIcon = Icons.sports_basketball;
    } else if (facilityName.toLowerCase().contains('gimnasio')) {
      facilityIcon = Icons.fitness_center;
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de reservas, pestaña "Mis Reservas"
        _navigateToReservations(context, 0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de la instalación en un círculo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(facilityIcon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 12),
            // Información de la reserva
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la instalación
                  Text(
                    facilityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.grey[600],
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _dateFormat.format(date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Horario
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[600],
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_formatTimeString(startTime)} - ${_formatTimeString(endTime)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Indicador de estado (punto verde)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para navegar a la pantalla de reservas con la pestaña especificada
  void _navigateToReservations(BuildContext context, int tabIndex) {
    // Obtener el MainNavigation widget y cambiar a la pestaña de reservas
    final mainNav = context.findAncestorStateOfType<MainNavigationState>();
    if (mainNav != null) {
      mainNav.setState(() {
        mainNav.selectedIndex = 2; // Índice de la pestaña de reservas
      });
    }
  }

  // Add this helper method before the build method
  String _formatTimeString(String time) {
    // If the time already has HH:mm format, return as is
    if (!time.contains(':')) return time;

    // If it has seconds, remove them
    return time.split(':').take(2).join(':');
  }
}
