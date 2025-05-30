import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/automatic_notification_service.dart';
import 'package:deportivov1/core/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewsService {
  static final SupabaseClient _client = SupabaseService.client;
  static final LoggerService _logger = LoggerService();

  // Obtener todas las noticias
  static Future<List<News>> getAllNews({int limit = 10}) async {
    try {
      _logger.info('Obteniendo todas las noticias (limit: $limit)');

      final response = await _client
          .from('noticias')
          .select()
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      List<News> newsList = [];
      for (var data in response) {
        try {
          newsList.add(News.fromJson(data));
        } catch (e) {
          _logger.warning('Error al procesar noticia individual', e);
          // Continuar con la siguiente noticia
        }
      }

      _logger.info('✅ Noticias obtenidas exitosamente: ${newsList.length}');
      return newsList;
    } catch (e) {
      _logger.error('Error al obtener noticias', e);
      throw NewsServiceException('Error al obtener noticias: $e');
    }
  }

  // Obtener noticias destacadas
  static Future<List<News>> getFeaturedNews({int limit = 5}) async {
    try {
      _logger.info('Obteniendo noticias destacadas (limit: $limit)');

      final response = await _client
          .from('noticias')
          .select()
          .eq('destacada', true)
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      List<News> newsList = [];
      for (var data in response) {
        try {
          newsList.add(News.fromJson(data));
        } catch (e) {
          _logger.warning('Error al procesar noticia destacada individual', e);
          // Continuar con la siguiente noticia
        }
      }

      _logger.info('✅ Noticias destacadas obtenidas: ${newsList.length}');
      return newsList;
    } catch (e) {
      _logger.error('Error al obtener noticias destacadas', e);
      throw NewsServiceException('Error al obtener noticias destacadas: $e');
    }
  }

  // Obtener noticias por categoría
  static Future<List<News>> getNewsByCategory(
    NewsCategory category, {
    int limit = 10,
  }) async {
    try {
      _logger.info(
        'Obteniendo noticias por categoría: ${category.name} (limit: $limit)',
      );

      final response = await _client
          .from('noticias')
          .select()
          .eq('categoria', category.name)
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      List<News> newsList = [];
      for (var data in response) {
        try {
          newsList.add(News.fromJson(data));
        } catch (e) {
          _logger.warning(
            'Error al procesar noticia de categoría individual',
            e,
          );
          // Continuar con la siguiente noticia
        }
      }

      _logger.info('✅ Noticias por categoría obtenidas: ${newsList.length}');
      return newsList;
    } catch (e) {
      _logger.error(
        'Error al obtener noticias por categoría: ${category.name}',
        e,
      );
      throw NewsServiceException('Error al obtener noticias por categoría: $e');
    }
  }

  // Obtener una noticia por ID
  static Future<News?> getNewsById(String newsId) async {
    if (newsId.isEmpty) {
      throw NewsServiceException('ID de noticia no puede estar vacío');
    }

    try {
      _logger.debug('Obteniendo noticia por ID: $newsId');

      final response =
          await _client.from('noticias').select().eq('id', newsId).single();

      final news = News.fromJson(response);
      _logger.debug('✅ Noticia obtenida exitosamente: ${news.titulo}');
      return news;
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        _logger.warning('Noticia no encontrada: $newsId');
        return null;
      }
      _logger.error('Error al obtener noticia por ID: $newsId', e);
      throw NewsServiceException('Error al obtener noticia: $e');
    }
  }

  // Obtener noticias vigentes (no expiradas)
  static Future<List<News>> getActiveNews({int limit = 10}) async {
    try {
      _logger.info('Obteniendo noticias vigentes (limit: $limit)');

      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('noticias')
          .select()
          .or('fecha_expiracion.gt.$now,fecha_expiracion.is.null')
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      List<News> newsList = [];
      for (var data in response) {
        try {
          newsList.add(News.fromJson(data));
        } catch (e) {
          _logger.warning('Error al procesar noticia vigente individual', e);
          // Continuar con la siguiente noticia
        }
      }

      _logger.info('✅ Noticias vigentes obtenidas: ${newsList.length}');
      return newsList;
    } catch (e) {
      _logger.error('Error al obtener noticias vigentes', e);
      throw NewsServiceException('Error al obtener noticias vigentes: $e');
    }
  }

  // Buscar noticias
  static Future<List<News>> searchNews(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) {
      _logger.warning('Término de búsqueda de noticias vacío');
      return [];
    }

    try {
      _logger.info('Buscando noticias: "$query" (limit: $limit)');

      final response = await _client
          .from('noticias')
          .select()
          .or('titulo.ilike.%$query%,contenido.ilike.%$query%')
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      List<News> newsList = [];
      for (var data in response) {
        try {
          newsList.add(News.fromJson(data));
        } catch (e) {
          _logger.warning(
            'Error al procesar resultado de búsqueda individual',
            e,
          );
          // Continuar con la siguiente noticia
        }
      }

      _logger.info(
        '✅ Búsqueda de noticias completada: ${newsList.length} resultados para "$query"',
      );
      return newsList;
    } catch (e) {
      _logger.error('Error al buscar noticias: "$query"', e);
      throw NewsServiceException('Error al buscar noticias: $e');
    }
  }

  // Crear una nueva noticia
  static Future<bool> createNews({
    required String titulo,
    required String contenido,
    required String autorId,
    required NewsCategory categoria,
    String? imagenUrl,
    bool destacada = false,
    DateTime? fechaExpiracion,
    bool sendNotifications = true,
  }) async {
    try {
      // Validar datos requeridos
      if (titulo.trim().isEmpty) {
        throw NewsServiceException('El título no puede estar vacío');
      }
      if (contenido.trim().isEmpty) {
        throw NewsServiceException('El contenido no puede estar vacío');
      }
      if (autorId.isEmpty) {
        throw NewsServiceException('ID del autor es requerido');
      }

      _logger.info('Creando nueva noticia: $titulo');

      final data = {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'fecha_publicacion': DateTime.now().toIso8601String(),
        'autor_id': autorId,
        'imagen_url': imagenUrl,
        'destacada': destacada,
        'categoria': categoria.name,
      };

      if (fechaExpiracion != null) {
        data['fecha_expiracion'] = fechaExpiracion.toIso8601String();
      }

      // Insertar noticia y obtener el ID
      final response =
          await _client.from('noticias').insert(data).select('id').single();

      final newsId = response['id'].toString();

      _logger.info('✅ Noticia creada exitosamente: $titulo (ID: $newsId)');

      // Enviar notificaciones si está habilitado
      if (sendNotifications) {
        try {
          await AutomaticNotificationService.notifyNewNews(
            newsId: newsId,
            title: titulo,
            content: contenido,
            category: categoria,
            isHighlighted: destacada,
          );
          _logger.info('✅ Notificaciones enviadas para nueva noticia');
        } catch (e) {
          _logger.warning('Error al enviar notificaciones de nueva noticia', e);
          // No fallar la creación por error de notificación
        }
      }

      return true;
    } catch (e) {
      _logger.error('Error al crear noticia', e);
      throw NewsServiceException('Error al crear noticia: $e');
    }
  }

  // Actualizar una noticia existente
  static Future<bool> updateNews({
    required String newsId,
    String? titulo,
    String? contenido,
    NewsCategory? categoria,
    String? imagenUrl,
    bool? destacada,
    DateTime? fechaExpiracion,
  }) async {
    try {
      _logger.info('Actualizando noticia: $newsId');

      final data = <String, dynamic>{};

      if (titulo != null && titulo.trim().isNotEmpty) {
        data['titulo'] = titulo.trim();
      }
      if (contenido != null && contenido.trim().isNotEmpty) {
        data['contenido'] = contenido.trim();
      }
      if (categoria != null) {
        data['categoria'] = categoria.name;
      }
      if (imagenUrl != null) {
        data['imagen_url'] = imagenUrl;
      }
      if (destacada != null) {
        data['destacada'] = destacada;
      }
      if (fechaExpiracion != null) {
        data['fecha_expiracion'] = fechaExpiracion.toIso8601String();
      }

      if (data.isEmpty) {
        throw NewsServiceException('No hay datos para actualizar');
      }

      data['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('noticias').update(data).eq('id', newsId);

      _logger.info('✅ Noticia actualizada exitosamente: $newsId');
      return true;
    } catch (e) {
      _logger.error('Error al actualizar noticia: $newsId', e);
      throw NewsServiceException('Error al actualizar noticia: $e');
    }
  }

  // Eliminar una noticia
  static Future<bool> deleteNews(String newsId) async {
    if (newsId.isEmpty) {
      throw NewsServiceException('ID de noticia no puede estar vacío');
    }

    try {
      _logger.info('Eliminando noticia: $newsId');

      await _client.from('noticias').delete().eq('id', newsId);

      _logger.info('✅ Noticia eliminada exitosamente: $newsId');
      return true;
    } catch (e) {
      _logger.error('Error al eliminar noticia: $newsId', e);
      throw NewsServiceException('Error al eliminar noticia: $e');
    }
  }

  // Obtener todas las noticias como Map (para compatibilidad)
  static Future<List<Map<String, dynamic>>> getAllNewsAsMap({
    int limit = 10,
  }) async {
    try {
      _logger.info('Obteniendo noticias como Map (limit: $limit)');

      final response = await _client
          .from('noticias')
          .select()
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      _logger.info('✅ Noticias como Map obtenidas: ${response.length}');
      return response;
    } catch (e) {
      _logger.error('Error al obtener noticias como Map', e);
      throw NewsServiceException('Error al obtener noticias como Map: $e');
    }
  }
}

/// Excepción personalizada para errores del servicio de noticias
class NewsServiceException implements Exception {
  final String message;

  const NewsServiceException(this.message);

  @override
  String toString() => 'NewsServiceException: $message';
}
