import 'dart:convert';

/// Servicio de caché en memoria para optimizar consultas repetitivas
class CacheService {
  static final Map<String, CacheItem> _cache = {};
  static const Duration _defaultTTL = Duration(minutes: 5);
  static const Duration _longTTL = Duration(hours: 1);
  static const Duration _shortTTL = Duration(minutes: 1);

  /// Obtiene un valor del caché
  /// 
  /// [key] - Clave del elemento en caché
  /// Retorna el valor si existe y no ha expirado, null en caso contrario
  static T? get<T>(String key) {
    final item = _cache[key];
    if (item != null && !item.isExpired) {
      return item.data as T;
    }
    
    // Limpiar elemento expirado
    if (item != null && item.isExpired) {
      _cache.remove(key);
    }
    
    return null;
  }

  /// Guarda un valor en el caché
  /// 
  /// [key] - Clave única para el elemento
  /// [data] - Datos a guardar
  /// [ttl] - Tiempo de vida del elemento (opcional)
  static void set<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CacheItem(
      data: data,
      expiry: DateTime.now().add(ttl ?? _defaultTTL),
    );
  }

  /// Elimina un elemento específico del caché
  static void remove(String key) {
    _cache.remove(key);
  }

  /// Elimina elementos que coincidan con un patrón
  /// 
  /// [pattern] - Patrón a buscar en las claves
  static void removePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Limpia todo el caché
  static void clear() {
    _cache.clear();
  }

  /// Limpia elementos expirados
  static void cleanExpired() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Verifica si existe un elemento en caché (sin importar si está expirado)
  static bool exists(String key) {
    return _cache.containsKey(key);
  }

  /// Verifica si existe un elemento válido (no expirado) en caché
  static bool isValid(String key) {
    final item = _cache[key];
    return item != null && !item.isExpired;
  }

  /// Obtiene estadísticas del caché
  static CacheStats getStats() {
    final total = _cache.length;
    final expired = _cache.values.where((item) => item.isExpired).length;
    final valid = total - expired;
    
    return CacheStats(
      totalItems: total,
      validItems: valid,
      expiredItems: expired,
    );
  }

  /// Genera claves de caché estandarizadas
  static String generateKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    final paramsString = jsonEncode(sortedParams);
    return '${prefix}_${paramsString.hashCode}';
  }

  // Métodos específicos para diferentes tipos de datos

  /// Caché para listas de usuarios
  static List<T>? getUsersList<T>(String key) => get<List<T>>(key);
  static void setUsersList<T>(String key, List<T> users) => 
      set(key, users, ttl: _longTTL);

  /// Caché para actividades
  static List<T>? getActivitiesList<T>(String key) => get<List<T>>(key);
  static void setActivitiesList<T>(String key, List<T> activities) => 
      set(key, activities, ttl: _defaultTTL);

  /// Caché para instalaciones
  static List<T>? getInstallationsList<T>(String key) => get<List<T>>(key);
  static void setInstallationsList<T>(String key, List<T> installations) => 
      set(key, installations, ttl: _longTTL);

  /// Caché para reservas
  static List<T>? getReservationsList<T>(String key) => get<List<T>>(key);
  static void setReservationsList<T>(String key, List<T> reservations) => 
      set(key, reservations, ttl: _shortTTL);

  /// Caché para noticias y eventos
  static List<T>? getNewsList<T>(String key) => get<List<T>>(key);
  static void setNewsList<T>(String key, List<T> news) => 
      set(key, news, ttl: _defaultTTL);

  /// Invalida caché relacionado con un usuario específico
  static void invalidateUserCache(String userId) {
    removePattern('user_$userId');
    removePattern('reservations_$userId');
  }

  /// Invalida caché relacionado con actividades
  static void invalidateActivitiesCache() {
    removePattern('activities_');
    removePattern('activity_');
  }

  /// Invalida caché relacionado con instalaciones
  static void invalidateInstallationsCache() {
    removePattern('installations_');
    removePattern('installation_');
    removePattern('courts_');
  }

  /// Invalida caché relacionado con reservas
  static void invalidateReservationsCache() {
    removePattern('reservations_');
    removePattern('availability_');
  }

  /// Invalida caché relacionado con noticias y eventos
  static void invalidateNewsCache() {
    removePattern('news_');
    removePattern('events_');
  }
}

/// Elemento individual del caché
class CacheItem {
  final dynamic data;
  final DateTime expiry;

  CacheItem({
    required this.data,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Estadísticas del caché
class CacheStats {
  final int totalItems;
  final int validItems;
  final int expiredItems;

  CacheStats({
    required this.totalItems,
    required this.validItems,
    required this.expiredItems,
  });

  double get hitRatio => totalItems > 0 ? validItems / totalItems : 0.0;
  
  @override
  String toString() {
    return 'CacheStats(total: $totalItems, valid: $validItems, expired: $expiredItems, hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
  }
} 