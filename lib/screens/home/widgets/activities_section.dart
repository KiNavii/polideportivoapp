import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/utils/responsive_util.dart';
import 'package:deportivov1/widgets/cards/activity_card.dart';
import 'package:deportivov1/screens/activities/activities_screen.dart';
import 'package:intl/intl.dart';

class ActivitiesSection extends StatelessWidget {
  final List<Activity> activities;
  final bool isLoading;

  const ActivitiesSection({
    super.key,
    required this.activities,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double padding = ResponsiveUtil.getAdaptivePadding(context, 20);
    final double subtitleFontSize = ResponsiveUtil.getAdaptiveTextSize(
      context,
      18,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, subtitleFontSize),
          const SizedBox(height: 16),
          if (isLoading)
            _buildLoadingState()
          else if (activities.isEmpty)
            _buildEmptyState()
          else
            _buildActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Próximas Actividades',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkColor,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToActivities(context),
          child: Text(
            'Ver todas',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder:
            (context, index) => Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No hay actividades próximas',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: ActivityCard(
              activity: activity,
              onTap: () => _navigateToActivities(context),
            ),
          );
        },
      ),
    );
  }

  void _navigateToActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
    );
  }
}
