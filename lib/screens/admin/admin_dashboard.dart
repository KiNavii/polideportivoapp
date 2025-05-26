import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/screens/admin/admin_activities.dart';
import 'package:deportivov1/screens/admin/admin_courts.dart';
import 'package:deportivov1/screens/admin/admin_enrollments.dart';
import 'package:deportivov1/screens/admin/admin_installations.dart';
import 'package:deportivov1/screens/admin/admin_news_events.dart';
import 'package:deportivov1/screens/admin/admin_users.dart';
import 'package:flutter/material.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Verificar si el usuario es administrador
    if (user == null || user.tipoUsuario.name != 'administrador') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Acceso denegado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No tienes permisos de administrador',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminTile(
              title: 'Inscripciones',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminEnrollmentsScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Actividades',
              icon: Icons.fitness_center,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminActivitiesScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Instalaciones',
              icon: Icons.sports_tennis,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminInstallationsScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Pistas',
              icon: Icons.sports_baseball,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminCourtsScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Noticias/Eventos',
              icon: Icons.event,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminNewsEventsScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Usuarios',
              icon: Icons.person,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen(),
                  ),
                );
              },
            ),
            _buildAdminTile(
              title: 'Reportes',
              icon: Icons.bar_chart,
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Solo pantalla de reportes aún no implementada completamente
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reportes y Estadísticas'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    ),
    body: const Center(
      child: Text('Pantalla de reportes y estadísticas (en desarrollo)'),
    ),
  );
}
