/// Interface base para todos los servicios
abstract class IBaseService<T> {
  /// Obtiene todos los elementos con paginación
  Future<List<T>> getAll({int limit = 20, int offset = 0});
  
  /// Obtiene un elemento por ID
  Future<T?> getById(String id);
  
  /// Crea un nuevo elemento
  Future<bool> create(Map<String, dynamic> data);
  
  /// Actualiza un elemento existente
  Future<bool> update(String id, Map<String, dynamic> data);
  
  /// Elimina un elemento
  Future<bool> delete(String id);
}

/// Interface para servicios que soportan búsqueda
abstract class ISearchableService<T> {
  /// Busca elementos por término
  Future<List<T>> search(String term, {int limit = 20});
  
  /// Busca elementos por filtros específicos
  Future<List<T>> searchByFilters(Map<String, dynamic> filters, {int limit = 20});
}

/// Interface para servicios que soportan caché
abstract class ICacheableService {
  /// Invalida el caché del servicio
  void invalidateCache();
  
  /// Limpia el caché expirado
  void cleanExpiredCache();
}

/// Interface para servicios con datos destacados/featured
abstract class IFeaturedService<T> {
  /// Obtiene elementos destacados
  Future<List<T>> getFeatured({int limit = 10});
  
  /// Marca/desmarca un elemento como destacado
  Future<bool> setFeatured(String id, bool featured);
}

/// Interface para servicios con estados
abstract class IStatefulService<T> {
  /// Obtiene elementos por estado
  Future<List<T>> getByStatus(String status, {int limit = 20});
  
  /// Cambia el estado de un elemento
  Future<bool> changeStatus(String id, String newStatus);
}

/// Interface para servicios con fechas
abstract class IDateRangeService<T> {
  /// Obtiene elementos en un rango de fechas
  Future<List<T>> getByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {int limit = 20}
  );
  
  /// Obtiene elementos activos (no expirados)
  Future<List<T>> getActive({int limit = 20});
  
  /// Obtiene elementos próximos
  Future<List<T>> getUpcoming({int limit = 20});
}

/// Interface para servicios de usuario
abstract class IUserService implements IBaseService<dynamic>, 
                                      ISearchableService<dynamic>, 
                                      ICacheableService {
  /// Obtiene usuarios por tipo
  Future<List<dynamic>> getUsersByType(String userType, {int limit = 20});
  
  /// Actualiza datos del perfil de usuario
  Future<bool> updateProfile(String userId, Map<String, dynamic> profileData);
  
  /// Verifica si un email ya existe
  Future<bool> emailExists(String email);
}

/// Interface para servicios de reservas
abstract class IReservationService implements IBaseService<dynamic>, 
                                              IStatefulService<dynamic>, 
                                              IDateRangeService<dynamic>,
                                              ICacheableService {
  /// Obtiene reservas de un usuario
  Future<List<dynamic>> getUserReservations(String userId, {int limit = 20});
  
  /// Verifica disponibilidad
  Future<bool> checkAvailability({
    required String installationId,
    required DateTime date,
    required String startTime,
    required String endTime,
  });
  
  /// Cancela una reserva
  Future<bool> cancelReservation(String reservationId);
}

/// Interface para servicios de actividades
abstract class IActivityService implements IBaseService<dynamic>, 
                                          ISearchableService<dynamic>, 
                                          IStatefulService<dynamic>,
                                          ICacheableService {
  /// Obtiene actividades con familia
  Future<List<dynamic>> getActivitiesWithFamily({int limit = 20});
  
  /// Obtiene actividades por instalación
  Future<List<dynamic>> getByInstallation(String installationId, {int limit = 20});
  
  /// Inscribe usuario a actividad
  Future<bool> enrollUser(String activityId, String userId);
  
  /// Desinscribe usuario de actividad
  Future<bool> unenrollUser(String activityId, String userId);
}

/// Interface para servicios de instalaciones
abstract class IInstallationService implements IBaseService<dynamic>, 
                                               ISearchableService<dynamic>, 
                                               ICacheableService {
  /// Obtiene instalaciones por tipo
  Future<List<dynamic>> getByType(String type, {int limit = 20});
  
  /// Obtiene instalaciones disponibles en fecha/hora
  Future<List<dynamic>> getAvailable(
    DateTime date, 
    String startTime, 
    String endTime, 
    {int limit = 20}
  );
}

/// Interface para servicios de noticias
abstract class INewsService implements IBaseService<dynamic>, 
                                      ISearchableService<dynamic>, 
                                      IFeaturedService<dynamic>,
                                      IDateRangeService<dynamic>,
                                      ICacheableService {
  /// Obtiene noticias por categoría
  Future<List<dynamic>> getByCategory(String category, {int limit = 20});
}

/// Interface para servicios de eventos
abstract class IEventService implements IBaseService<dynamic>, 
                                       ISearchableService<dynamic>, 
                                       IFeaturedService<dynamic>,
                                       IDateRangeService<dynamic>,
                                       ICacheableService {
  /// Obtiene eventos por categoría
  Future<List<dynamic>> getByCategory(String category, {int limit = 20});
  
  /// Registra usuario en evento
  Future<bool> registerUser(String eventId, String userId);
  
  /// Desregistra usuario de evento
  Future<bool> unregisterUser(String eventId, String userId);
} 