import 'package:flutter_test/flutter_test.dart';
import 'package:deportivov1/screens/home/controllers/home_controller.dart';

void main() {
  group('HomeController Tests', () {
    late HomeController controller;

    setUp(() {
      controller = HomeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with loading state', () {
      expect(controller.isLoading, true);
      expect(controller.upcomingActivities, isEmpty);
      expect(controller.news, isEmpty);
      expect(controller.events, isEmpty);
      expect(controller.activeReservations, isEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('should handle loading state changes', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      // Simulate loading completion
      controller.loadData();

      expect(notified, true);
    });

    test('should handle refresh functionality', () async {
      // Test that refresh calls loadData
      expect(controller.isLoading, true);

      // Note: In a real test, we would mock the services
      // For now, we just verify the method exists and can be called
      expect(() => controller.refresh(), returnsNormally);
    });

    test('should properly dispose resources', () {
      expect(() => controller.dispose(), returnsNormally);
    });
  });
}
