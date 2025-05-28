import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:flutter/material.dart';

/// Tipos de carpetas para organizar imágenes
enum ImageFolder {
  profiles('profiles'),
  news('noticias'),
  events('eventos'),
  activities('actividades'),
  installations('instalaciones'),
  courts('pistas');

  const ImageFolder(this.path);
  final String path;
}

/// Utilidades para manejo de imágenes
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona y sube una imagen a Supabase Storage
  /// 
  /// [source] - Fuente de la imagen (cámara o galería)
  /// [folder] - Carpeta donde guardar la imagen
  /// [userId] - ID del usuario (opcional, para imágenes de perfil)
  /// [maxWidth] - Ancho máximo de la imagen
  /// [imageQuality] - Calidad de compresión (0-100)
  static Future<String?> pickAndUploadImage({
    required ImageSource source,
    required ImageFolder folder,
    String? userId,
    double maxWidth = 1200,
    int imageQuality = 85,
  }) async {
    try {
      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );

      if (image == null) return null;

      // Leer bytes de la imagen
      final Uint8List bytes = await image.readAsBytes();
      
      // Generar nombre único para el archivo
      final String fileName = _generateFileName(image.path);
      
      // Construir ruta del archivo
      final String filePath = _buildFilePath(folder, fileName, userId);

      // Subir a Supabase Storage
      await SupabaseService.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      // Obtener URL pública
      final String imageUrl = SupabaseService.client.storage
          .from('images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw ImageUploadException('Error al subir imagen: $e');
    }
  }

  /// Sube una imagen desde bytes
  static Future<String?> uploadImageFromBytes({
    required Uint8List bytes,
    required String fileName,
    required ImageFolder folder,
    String? userId,
  }) async {
    try {
      final String filePath = _buildFilePath(folder, fileName, userId);

      await SupabaseService.client.storage
          .from('images')
          .uploadBinary(filePath, bytes);

      return SupabaseService.client.storage
          .from('images')
          .getPublicUrl(filePath);
    } catch (e) {
      throw ImageUploadException('Error al subir imagen desde bytes: $e');
    }
  }

  /// Elimina una imagen de Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraer la ruta del archivo de la URL
      final Uri uri = Uri.parse(imageUrl);
      final String filePath = uri.pathSegments.skip(4).join('/'); // Skip /storage/v1/object/public/images/

      await SupabaseService.client.storage
          .from('images')
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Muestra un diálogo para seleccionar fuente de imagen
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  /// Selecciona y sube imagen con diálogo de selección
  static Future<String?> selectAndUploadImage({
    required BuildContext context,
    required ImageFolder folder,
    String? userId,
    double maxWidth = 1200,
    int imageQuality = 85,
  }) async {
    final ImageSource? source = await showImageSourceDialog(context);
    if (source == null) return null;

    return pickAndUploadImage(
      source: source,
      folder: folder,
      userId: userId,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
  }

  /// Genera un nombre único para el archivo
  static String _generateFileName(String originalPath) {
    final String extension = originalPath.split('.').last.toLowerCase();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'image_$timestamp.$extension';
  }

  /// Construye la ruta completa del archivo
  static String _buildFilePath(ImageFolder folder, String fileName, String? userId) {
    if (folder == ImageFolder.profiles && userId != null) {
      return '${folder.path}/$userId/$fileName';
    }
    return '${folder.path}/$fileName';
  }

  /// Valida si una URL es una imagen válida
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final uri = Uri.tryParse(url);
    
    if (uri == null) return false;
    
    final extension = uri.path.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }

  /// Obtiene el tamaño optimizado para diferentes tipos de imagen
  static ImageDimensions getOptimalDimensions(ImageFolder folder) {
    switch (folder) {
      case ImageFolder.profiles:
        return const ImageDimensions(maxWidth: 400, quality: 90);
      case ImageFolder.news:
      case ImageFolder.events:
        return const ImageDimensions(maxWidth: 1200, quality: 85);
      case ImageFolder.activities:
      case ImageFolder.installations:
      case ImageFolder.courts:
        return const ImageDimensions(maxWidth: 800, quality: 80);
    }
  }
}

/// Dimensiones optimizadas para imágenes
class ImageDimensions {
  final double maxWidth;
  final int quality;

  const ImageDimensions({
    required this.maxWidth,
    required this.quality,
  });
}

/// Excepción personalizada para errores de subida de imágenes
class ImageUploadException implements Exception {
  final String message;
  
  const ImageUploadException(this.message);
  
  @override
  String toString() => 'ImageUploadException: $message';
} 