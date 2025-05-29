import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deportivov1/widgets/cards/activity_card.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/activity_family_model.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('ActivityCard Widget Tests', () {
    late Activity testActivity;

    setUpAll(() async {
      await initializeDateFormatting('es_ES', null);
    });

    setUp(() {
      testActivity = Activity(
        id: '1',
        nombre: 'Yoga Matutino',
        familiaId: '1',
        instalacionId: '1',
        descripcion: 'Clase de yoga para principiantes',
        plazasMax: 20,
        plazasOcupadas: 15,
        duracionMinutos: 60,
        horaInicio: '09:00',
        horaFin: '10:00',
        fechaInicio: DateTime(2024, 1, 15, 9, 0),
        esRecurrente: true,
        estado: ActivityStatus.activa,
        familia: ActivityFamily(
          id: '1',
          nombre: 'Bienestar',
          descripcion: 'Actividades de bienestar y relajación',
          color: '#4CAF50',
        ),
      );
    });

    testWidgets('should display activity information correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ActivityCard(activity: testActivity))),
      );

      // Verify activity name is displayed
      expect(find.text('Yoga Matutino'), findsOneWidget);

      // Verify family name is displayed
      expect(find.text('Bienestar'), findsOneWidget);

      // Verify date and time are displayed
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: testActivity,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActivityCard));
      expect(tapped, true);
    });

    testWidgets('should display correct icon for yoga activity', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ActivityCard(activity: testActivity))),
      );

      // Should display self_improvement icon for yoga
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    });

    testWidgets('should handle activity without family', (tester) async {
      final activityWithoutFamily = Activity(
        id: '2',
        nombre: 'Test Activity',
        familiaId: '1',
        instalacionId: '1',
        plazasMax: 10,
        plazasOcupadas: 5,
        duracionMinutos: 45,
        horaInicio: '10:00',
        horaFin: '10:45',
        fechaInicio: DateTime(2024, 1, 15, 10, 0),
        esRecurrente: false,
        estado: ActivityStatus.activa,
        // No family assigned
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityCard(activity: activityWithoutFamily)),
        ),
      );

      // Should display default 'Actividad' text
      expect(find.text('Actividad'), findsOneWidget);
      expect(find.text('Test Activity'), findsOneWidget);
    });
  });
}
