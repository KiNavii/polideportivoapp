import 'package:deportivov1/models/news_model.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/automatic_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewsService {
  static final SupabaseClient _client = SupabaseService.client;

  // Obtener todas las noticias
  static Future<List<News>> getAllNews({int limit = 10}) async {
    try {
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
          print('Error al procesar noticia individual: $e');
          // Continuar con la siguiente noticia
        }
      }
      return newsList;
    } catch (e) {
      print('Error al obtener noticias: $e');
      // Devolver lista vacía en caso de error para evitar bloqueos
      return [];
    }
  }

  // Obtener noticias destacadas
  static Future<List<News>> getFeaturedNews({int limit = 5}) async {
    try {
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
          print('Error al procesar noticia individual: $e');
          // Continuar con la siguiente noticia
        }
      }
      return newsList;
    } catch (e) {
      print('Error al obtener noticias destacadas: $e');
      // Devolver lista vacía en caso de error para evitar bloqueos
      return [];
    }
  }

  // Obtener noticias por categoría
  static Future<List<News>> getNewsByCategory(
    NewsCategory category, {
    int limit = 10,
  }) async {
    try {
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
          print('Error al procesar noticia individual: $e');
          // Continuar con la siguiente noticia
        }
      }
      return newsList;
    } catch (e) {
      print('Error al obtener noticias por categoría: $e');
      return [];
    }
  }

  // Obtener una noticia por ID
  static Future<News?> getNewsById(String newsId) async {
    try {
      final response =
          await _client.from('noticias').select().eq('id', newsId).single();

      return News.fromJson(response);
    } catch (e) {
      print('Error al obtener noticia por ID: $e');
      return null;
    }
  }

  // Obtener noticias vigentes (no expiradas)
  static Future<List<News>> getActiveNews({int limit = 10}) async {
    try {
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
          print('Error al procesar noticia individual: $e');
          // Continuar con la siguiente noticia
        }
      }
      return newsList;
    } catch (e) {
      print('Error al obtener noticias vigentes: $e');
      return [];
    }
  }

  // Buscar noticias
  static Future<List<News>> searchNews(String query, {int limit = 10}) async {
    try {
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
          print('Error al procesar noticia individual: $e');
          // Continuar con la siguiente noticia
        }
      }
      return newsList;
    } catch (e) {
      print('Error al buscar noticias: $e');
      return [];
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
      final data = {
        'titulo': titulo,
        'contenido': contenido,
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
      final response = await _client
          .from('noticias')
          .insert(data)
          .select('id')
          .single();

      final newsId = response['id'].toString();

      // 🚀 ENVIAR NOTIFICACIONES AUTOMÁTICAS A TODOS LOS USUARIOS
      if (sendNotifications) {
        print('📰 Enviando notificaciones automáticas para nueva noticia...');
        
        // Ejecutar en background para no bloquear la creación de la noticia
        AutomaticNotificationService.notifyNewNews(
          newsId: newsId,
          title: titulo,
          content: contenido,
          category: categoria,
          isHighlighted: destacada,
        ).catchError((error) {
          print('⚠️ Error enviando notificaciones automáticas: $error');
          // No fallar la creación de la noticia por errores de notificación
        });
      }

      return true;
    } catch (e) {
      print('Error al crear noticia: $e');
      return false;
    }
  }

  // Actualizar una noticia existente
  static Future<bool> updateNews({
    required String id,
    String? titulo,
    String? contenido,
    NewsCategory? categoria,
    String? imagenUrl,
    bool? destacada,
    DateTime? fechaExpiracion,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (titulo != null) data['titulo'] = titulo;
      if (contenido != null) data['contenido'] = contenido;
      if (categoria != null) data['categoria'] = categoria.name;
      if (imagenUrl != null) data['imagen_url'] = imagenUrl;
      if (destacada != null) data['destacada'] = destacada;

      if (fechaExpiracion != null) {
        data['fecha_expiracion'] = fechaExpiracion.toIso8601String();
      }

      if (data.isEmpty) return true; // No hay cambios que guardar

      await _client.from('noticias').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Error al actualizar noticia: $e');
      return false;
    }
  }

  // Eliminar una noticia
  static Future<bool> deleteNews(String id) async {
    try {
      await _client.from('noticias').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error al eliminar noticia: $e');
      return false;
    }
  }

  // Obtener todas las noticias como Map (para administración)
  static Future<List<Map<String, dynamic>>> getAllNewsAsMap({
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('noticias')
          .select()
          .order('fecha_publicacion', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('Error al obtener noticias: $e');
      return [];
    }
  }
}
