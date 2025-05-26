import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:intl/intl.dart';

class ReservationCard extends StatelessWidget {
  final String facilityName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? reservationId;
  final String? pistaName;
  final Function(String)? onCancel;

  const ReservationCard({
    Key? key,
    required this.facilityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reservationId,
    this.pistaName,
    this.onCancel,
  }) : super(key: key);

  // Método para formatear hora en formato HH:mm
  String _formatTimeString(String time) {
    // Si el tiempo ya está en formato HH:mm, devolverlo tal cual
    if (!time.contains(':')) return time;

    // Si tiene segundos, eliminarlos
    return time.split(':').take(2).join(':');
  }

  @override
  Widget build(BuildContext context) {
    // Format date
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final String dateStr = dateFormat.format(date);
    final String timeStr =
        '${_formatTimeString(startTime)} - ${_formatTimeString(endTime)}';

    // Determine colors and icons based on status
    Color statusColor;
    IconData statusIcon;
    List<Color> gradientColors;

    switch (status) {
      case 'confirmada':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        gradientColors = [Colors.green.shade400, Colors.green.shade600];
        break;
      case 'completada':
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.task_alt;
        gradientColors = [Colors.blue.shade400, Colors.blue.shade600];
        break;
      case 'cancelada':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        gradientColors = [Colors.red.shade300, Colors.red.shade500];
        break;
      case 'pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        gradientColors = [Colors.orange.shade300, Colors.orange.shade500];
        break;
      default:
        statusColor = AppTheme.grayColor;
        statusIcon = Icons.help;
        gradientColors = [Colors.grey.shade400, Colors.grey.shade600];
    }

    // Determine icon based on facility name
    IconData facilityIcon = Icons.sports;
    if (facilityName.toLowerCase().contains('piscina')) {
      facilityIcon = Icons.pool;
    } else if (facilityName.toLowerCase().contains('tenis')) {
      facilityIcon = Icons.sports_tennis;
    } else if (facilityName.toLowerCase().contains('gimnasio')) {
      facilityIcon = Icons.fitness_center;
    } else if (facilityName.toLowerCase().contains('fútbol') ||
        facilityName.toLowerCase().contains('futbol')) {
      facilityIcon = Icons.sports_soccer;
    } else if (facilityName.toLowerCase().contains('baloncesto')) {
      facilityIcon = Icons.sports_basketball;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient and status
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Facility name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Facility icon and name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            facilityIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          facilityName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _capitalizeFirstLetter(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Court information (if available)
                if (pistaName != null && pistaName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sports_tennis,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pista: $pistaName',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom section with date and time
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and time information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Cancel button if available
                    if (onCancel != null && reservationId != null)
                      TextButton.icon(
                        onPressed: () => onCancel!(reservationId!),
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
