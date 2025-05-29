import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:intl/intl.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM', 'es_ES');
    final DateFormat timeFormat = DateFormat('HH:mm', 'es_ES');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.familia?.nombre ?? 'Actividad',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getActivityIcon(activity.nombre),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(activity.fechaInicio),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(activity.fechaInicio),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();

    if (name.contains('gimnasia') || name.contains('fitness')) {
      return Icons.fitness_center;
    } else if (name.contains('yoga') || name.contains('pilates')) {
      return Icons.self_improvement;
    } else if (name.contains('natación') || name.contains('acuática')) {
      return Icons.pool;
    } else if (name.contains('baile') || name.contains('zumba')) {
      return Icons.music_note;
    } else if (name.contains('ciclismo') || name.contains('spinning')) {
      return Icons.directions_bike;
    } else if (name.contains('boxeo') || name.contains('lucha')) {
      return Icons.sports_mma;
    } else if (name.contains('fútbol')) {
      return Icons.sports_soccer;
    } else if (name.contains('baloncesto') || name.contains('basket')) {
      return Icons.sports_basketball;
    } else if (name.contains('tenis')) {
      return Icons.sports_tennis;
    }

    return Icons.sports;
  }
}
