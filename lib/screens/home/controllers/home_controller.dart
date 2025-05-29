import 'package:flutter/foundation.dart';
import 'package:deportivov1/models/activity_model.dart';
import 'package:deportivov1/models/event_model.dart';
import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/models/reservation_model.dart';
import 'package:deportivov1/services/activity_service.dart';
import 'package:deportivov1/services/event_service.dart';
import 'package:deportivov1/services/news_service.dart';
import 'package:deportivov1/services/reservation_service.dart';

class HomeController extends ChangeNotifier {
  // State
  List<Activity> _upcomingActivities = [];
  List<News> _news = [];
  List<Event> _events = [];
  List<Reservation> _activeReservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  List<Activity> get upcomingActivities => _upcomingActivities;
  List<News> get news => _news;
  List<Event> get events => _events;
  List<Reservation> get activeReservations => _activeReservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods
  Future<void> loadData({String? userId}) async {
    try {
      _setLoading(true);
      _clearError();

      // Update completed reservations before loading data
      await _updateReservations();

      // Load all data concurrently for better performance
      final results = await Future.wait([
        _loadActivities(),
        _loadNews(),
        _loadEvents(),
        if (userId != null) _loadActiveReservations(userId),
      ]);

      _upcomingActivities = results[0] as List<Activity>;
      _news = results[1] as List<News>;
      _events = results[2] as List<Event>;

      if (userId != null && results.length > 3) {
        _activeReservations = results[3] as List<Reservation>;
      }

      _setLoading(false);
    } catch (e) {
      _handleError('Error al cargar datos. Intenta nuevamente.', e);
    }
  }

  Future<List<Activity>> _loadActivities() async {
    try {
      final activities = await ActivityService.getActivitiesWithFamily(
        limit: 5,
      );

      // Sort by date and time
      activities.sort((a, b) {
        int dateCompare = a.fechaInicio.compareTo(b.fechaInicio);
        if (dateCompare != 0) return dateCompare;
        return a.horaInicio.compareTo(b.horaInicio);
      });

      return activities.take(3).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading activities: $e');
      }
      return [];
    }
  }

  Future<List<News>> _loadNews() async {
    try {
      var news = await NewsService.getFeaturedNews(limit: 3);

      // If no featured news, load most recent
      if (news.isEmpty) {
        news = await NewsService.getAllNews(limit: 3);
      }

      return news;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading news: $e');
      }
      return [];
    }
  }

  Future<List<Event>> _loadEvents() async {
    try {
      return await EventService.getUpcomingEvents(limit: 3);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading events: $e');
      }
      return [];
    }
  }

  Future<List<Reservation>> _loadActiveReservations(String userId) async {
    try {
      return await ReservationService.getActiveReservations(userId, limit: 3);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reservations: $e');
      }
      return [];
    }
  }

  Future<void> _updateReservations() async {
    try {
      await ReservationService.updateCompletedReservations();
      await ReservationService.cleanOldReservations();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reservations: $e');
      }
      // Don't throw here as this is not critical for the main flow
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(String message, dynamic error) {
    _errorMessage = message;
    _isLoading = false;

    if (kDebugMode) {
      print('HomeController Error: $error');
    }

    notifyListeners();
  }

  // Refresh method for pull-to-refresh
  Future<void> refresh({String? userId}) async {
    await loadData(userId: userId);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
