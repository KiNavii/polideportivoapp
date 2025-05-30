import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/services/activity_service.dart';
import 'package:deportivov1/utils/string_extensions.dart';
import 'package:flutter/material.dart';

class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key});

  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingEnrollments = [];
  List<Map<String, dynamic>> _approvedEnrollments = [];
  List<Map<String, dynamic>> _rejectedEnrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEnrollments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar inscripciones pendientes, confirmadas y canceladas
      final pendingEnrollmentsFuture =
          ActivityServiceStatic.getEnrollmentsByStatus('pendiente');
      final approvedEnrollmentsFuture =
          ActivityServiceStatic.getEnrollmentsByStatus('confirmada');
      final rejectedEnrollmentsFuture =
          ActivityServiceStatic.getEnrollmentsByStatus('cancelada');

      final results = await Future.wait([
        pendingEnrollmentsFuture,
        approvedEnrollmentsFuture,
        rejectedEnrollmentsFuture,
      ]);

      if (mounted) {
        setState(() {
          _pendingEnrollments = results[0] as List<Map<String, dynamic>>;
          _approvedEnrollments = results[1] as List<Map<String, dynamic>>;
          _rejectedEnrollments = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar inscripciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar las inscripciones. Intenta nuevamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEnrollmentStatus(
    String enrollmentId,
    String newStatus,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ActivityServiceStatic.updateEnrollmentStatus(
        enrollmentId,
        newStatus,
      );

      if (mounted) {
        if (success) {
          _loadEnrollments(); // Recargar datos
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar el estado'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al actualizar estado: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inscripciones'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobadas'),
            Tab(text: 'Rechazadas'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildEnrollmentsList(_pendingEnrollments, true),
                  _buildEnrollmentsList(_approvedEnrollments, false),
                  _buildEnrollmentsList(_rejectedEnrollments, false),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadEnrollments,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEnrollmentsList(
    List<Map<String, dynamic>> enrollments,
    bool showActions,
  ) {
    if (enrollments.isEmpty) {
      return Center(
        child: Text(
          'No hay inscripciones en esta categoría',
          style: TextStyle(fontSize: 16, color: AppTheme.grayColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        final activity = enrollment['actividades'] ?? {};
        final user = enrollment['usuarios'] ?? {};
        final status = enrollment['estado'] ?? 'pendiente';

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
                        activity['nombre'] ?? 'Actividad sin nombre',
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
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _capitalizeFirstLetter(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Usuario',
                  '${user['nombre'] ?? ''} ${user['apellidos'] ?? ''}',
                ),
                _buildInfoRow('Email', user['email'] ?? ''),
                _buildInfoRow('Teléfono', user['telefono'] ?? 'No disponible'),
                _buildInfoRow(
                  'Fecha inscripción',
                  _formatDateTime(enrollment['fecha_inscripcion']),
                ),

                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed:
                            () => _updateEnrollmentStatus(
                              enrollment['id'],
                              'cancelada',
                            ),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.errorColor,
                        ),
                        label: const Text(
                          'Rechazar',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed:
                            () => _updateEnrollmentStatus(
                              enrollment['id'],
                              'confirmada',
                            ),
                        icon: const Icon(Icons.check),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppTheme.darkColor)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmada':
        return AppTheme.successColor;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return AppTheme.errorColor;
      default:
        return AppTheme.grayColor;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Fecha desconocida';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Formato de fecha inválido';
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
