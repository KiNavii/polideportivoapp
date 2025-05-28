import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/screens/admin/admin_dashboard.dart';
import 'package:deportivov1/screens/home/home_screen.dart';
import 'package:deportivov1/screens/activities/activities_screen.dart';
import 'package:deportivov1/screens/reservations/reservations_screen.dart';
import 'package:deportivov1/screens/profile/profile_screen.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  bool _isAdmin = false;
  String _userType = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar tipo de usuario
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    setState(() {
      _userType = user?.tipoUsuario.name ?? 'socio';
      _isAdmin = _userType == 'administrador';
    });
  }

  // Seleccionar las pantallas según el tipo de usuario
  List<Widget> get _screens {
    // Si es administrador, mostrar solo la pantalla de administración y perfil
    if (_isAdmin) {
      return [const AdminDashboard(), const ProfileScreen()];
    }

    // Para usuarios normales (socios y monitores), mostrar todas las pantallas
    return [
      const HomeScreen(),
      const ActivitiesScreen(),
      const ReservationsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/test-push-real');
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.notifications_active),
        tooltip: 'Probar notificaciones push',
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: _isAdmin ? _buildAdminNavBar() : _buildUserNavBar(),
        ),
      ),
    );
  }

  Widget _buildUserNavBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_outlined),
          activeIcon: Icon(Icons.fitness_center),
          label: 'Actividades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Reservas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.grayColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      onTap: _onItemTapped,
    );
  }

  Widget _buildAdminNavBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.grayColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      onTap: _onItemTapped,
    );
  }
}
