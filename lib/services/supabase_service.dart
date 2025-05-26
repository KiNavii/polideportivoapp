import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deportivov1/constants/supabase_constants.dart';
import 'dart:typed_data';

class SupabaseService {
  static SupabaseClient? _client;

  // Initialize Supabase
  static Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );

    _client = Supabase.instance.client;

    // Asegurar que los buckets de imágenes existan
    await _ensureImageBucketsExist();
  }

  // Crear buckets necesarios para imágenes si no existen
  static Future<void> _ensureImageBucketsExist() async {
    try {
      // Verificar si el bucket 'images' existe
      final buckets = await client.storage.listBuckets();
      bool imagesBucketExists = buckets.any(
        (bucket) => bucket.name == 'images',
      );

      // Crear el bucket si no existe
      if (!imagesBucketExists) {
        // Crear el bucket con opciones básicas
        await client.storage.createBucket('images');
        print('Bucket "images" creado correctamente');

        // Nota: Las políticas de acceso deben configurarse en el panel de Supabase
        print(
          'Importante: Configure las políticas públicas de acceso en Supabase',
        );
      }
    } catch (e) {
      print('Error al verificar/crear buckets: $e');
    }
  }

  // Subir imagen de perfil con manejo de permisos
  static Future<String?> uploadProfileImage(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final String userId = currentUser!.id;
      final String filePath = 'profiles/$userId/$fileName';

      // Intentar subir la imagen
      await client.storage.from('images').uploadBinary(filePath, bytes);

      // Obtener la URL pública
      final String imageUrl = client.storage
          .from('images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error al subir imagen de perfil: $e');

      // Si es un error 403 de políticas RLS, mostrar instrucciones
      if (e.toString().contains('violates row-level security policy') ||
          e.toString().contains('statusCode: 403')) {
        print('''
INSTRUCCIONES PARA CONFIGURAR PERMISOS DE STORAGE EN SUPABASE:
1. Ve al panel de Supabase y navega a Storage > Policies
2. Selecciona el bucket 'images'
3. Añade una nueva política con los siguientes ajustes:
   - Nombre: allow_authenticated_users_profile_images
   - Roles permitidos: authenticated
   - Operaciones permitidas: SELECT, INSERT, UPDATE, DELETE
   - Política SQL para INSERT/UPDATE: (bucket_id = 'images' AND path LIKE 'profiles/' || auth.uid() || '/%')
   - Política SQL para SELECT: (bucket_id = 'images')
''');
      }

      return null;
    }
  }

  // Getter for the Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase client not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is logged in
  static bool get isAuthenticated => currentUser != null;
}
