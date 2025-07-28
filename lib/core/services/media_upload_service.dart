// lib/core/services/media_upload_service.dart - CORREGIDO PARA USAR MEDIA SERVICE
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';
import '../network/api_client.dart';
import '../services/token_manager.dart';

@lazySingleton
class MediaUploadService {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  MediaUploadService(this._apiClient, this._tokenManager) {
    print('✅ [MEDIA UPLOAD SERVICE] Constructor - Ready to upload photos to MEDIA service');
  }

  /// Subir una foto al MEDIA service y obtener la URL
  Future<String> uploadPhoto({
    required File photoFile,
    String category = 'image', // ✅ Categoría válida según servidor: image, video, audio, document, other
    bool isPublic = true,
    String uploadPurpose = 'challenge_evidence',
  }) async {
    try {
      print('📤 [MEDIA UPLOAD] === UPLOADING PHOTO TO MEDIA SERVICE ===');
      print('📤 [MEDIA UPLOAD] File path: ${photoFile.path}');
      print('📤 [MEDIA UPLOAD] Category: $category');
      print('📤 [MEDIA UPLOAD] Upload purpose: $uploadPurpose');

      // Verificar que el archivo existe
      if (!await photoFile.exists()) {
        throw Exception('El archivo no existe: ${photoFile.path}');
      }

      // Verificar el tamaño del archivo
      final fileSize = await photoFile.length();
      print('📤 [MEDIA UPLOAD] File size: ${fileSize} bytes');
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB máximo
        throw Exception('El archivo es demasiado grande. Máximo 10MB permitido.');
      }

      // Crear FormData para multipart
      final originalFileName = photoFile.path.split('/').last;
      
      // 🔧 NORMALIZAR EXTENSIÓN: JPG -> JPEG para compatibilidad con servidor
      String normalizedFileName = originalFileName;
      String? contentType;
      
      if (originalFileName.toLowerCase().endsWith('.jpg')) {
        normalizedFileName = originalFileName.replaceAll(RegExp(r'\.jpg$', caseSensitive: false), '.jpeg');
        contentType = 'image/jpeg';
      } else if (originalFileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (originalFileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }
      
      print('📤 [MEDIA UPLOAD] Original filename: $originalFileName');
      print('📤 [MEDIA UPLOAD] Normalized filename: $normalizedFileName');
      print('📤 [MEDIA UPLOAD] Content type: $contentType');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photoFile.path,
          filename: normalizedFileName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        ),
        'category': category,
        'isPublic': isPublic,
        'uploadPurpose': uploadPurpose,
      });

      print('📤 [MEDIA UPLOAD] FormData created, uploading to MEDIA SERVICE...');

      // 🔧 OBTENER USER ID DINÁMICAMENTE
      final userId = await _tokenManager.getUserId();
      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario para subir la foto');
      }
      print('📤 [MEDIA UPLOAD] User ID: $userId');

      // 🔧 USAR EL ENDPOINT CORRECTO CON USER ID
      final endpoint = '/api/media/upload/$userId';
      print('📤 [MEDIA UPLOAD] Using endpoint: $endpoint');
      
      final response = await _apiClient.uploadToMedia(
        endpoint,
        formData: formData,
      );

      print('✅ [MEDIA UPLOAD] Upload successful: ${response.statusCode}');
      print('✅ [MEDIA UPLOAD] Response data: ${response.data}');

      // Extraer URL de la respuesta
      final String photoUrl = _extractPhotoUrl(response.data);
      
      print('🔗 [MEDIA UPLOAD] Photo URL: $photoUrl');
      return photoUrl;

    } catch (e) {
      print('❌ [MEDIA UPLOAD] Error uploading photo: $e');
      throw Exception('Error al subir la foto: ${e.toString()}');
    }
  }

  /// Subir múltiples fotos
  Future<List<String>> uploadMultiplePhotos({
    required List<File> photoFiles,
    String category = 'challenge_evidence',
    bool isPublic = true,
    String uploadPurpose = 'challenge_evidence',
    Function(int, int)? onProgress,
  }) async {
    try {
      print('📤 [MEDIA UPLOAD] === UPLOADING MULTIPLE PHOTOS TO MEDIA SERVICE ===');
      print('📤 [MEDIA UPLOAD] Total photos: ${photoFiles.length}');

      final List<String> uploadedUrls = [];

      for (int i = 0; i < photoFiles.length; i++) {
        try {
          print('📤 [MEDIA UPLOAD] Uploading photo ${i + 1}/${photoFiles.length}');
          
          // Callback de progreso
          onProgress?.call(i + 1, photoFiles.length);

          final photoUrl = await uploadPhoto(
            photoFile: photoFiles[i],
            category: category,
            isPublic: isPublic,
            uploadPurpose: uploadPurpose,
          );

          uploadedUrls.add(photoUrl);
          print('✅ [MEDIA UPLOAD] Photo ${i + 1} uploaded: $photoUrl');

        } catch (e) {
          print('❌ [MEDIA UPLOAD] Failed to upload photo ${i + 1}: $e');
          // Continuar con las demás fotos en lugar de fallar completamente
          continue;
        }
      }

      if (uploadedUrls.isEmpty) {
        throw Exception('No se pudo subir ninguna foto');
      }

      print('🎉 [MEDIA UPLOAD] Successfully uploaded ${uploadedUrls.length}/${photoFiles.length} photos');
      return uploadedUrls;

    } catch (e) {
      print('❌ [MEDIA UPLOAD] Error uploading multiple photos: $e');
      throw Exception('Error al subir las fotos: ${e.toString()}');
    }
  }

  /// Extraer URL de foto de la respuesta del servidor
  String _extractPhotoUrl(dynamic responseData) {
    if (responseData == null) {
      throw Exception('Respuesta del servidor vacía');
    }

    if (responseData is String) {
      // Si la respuesta es directamente una URL
      if (_isValidUrl(responseData)) {
        return responseData;
      }
    }

    if (responseData is Map<String, dynamic>) {
      // Buscar URL en diferentes campos posibles para MEDIA SERVICE
      final possibleFields = [
        'publicUrl',      // 🔧 CAMPO PRINCIPAL DE MEDIA SERVICE
        'url',
        'fileUrl', 
        'file_url',
        'downloadUrl',
        'download_url',
        'mediaUrl',
        'media_url',
        'src',
        'href',
        'link'
      ];

      for (final field in possibleFields) {
        if (responseData.containsKey(field)) {
          final url = responseData[field];
          if (url is String && _isValidUrl(url)) {
            return url;
          }
        }
      }

      // Buscar en campo 'data' anidado
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          for (final field in possibleFields) {
            if (data.containsKey(field)) {
              final url = data[field];
              if (url is String && _isValidUrl(url)) {
                return url;
              }
            }
          }
        }
      }

      // Buscar en campo 'file' anidado
      if (responseData.containsKey('file')) {
        final file = responseData['file'];
        if (file is Map<String, dynamic>) {
          for (final field in possibleFields) {
            if (file.containsKey(field)) {
              final url = file[field];
              if (url is String && _isValidUrl(url)) {
                return url;
              }
            }
          }
        }
      }
    }

    throw Exception('No se pudo extraer la URL de la foto de la respuesta del servidor. Respuesta: $responseData');
  }

  /// Validar si una cadena es una URL válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Obtener información de un archivo
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      return {
        'name': fileName,
        'size': fileSize,
        'sizeFormatted': _formatFileSize(fileSize),
        'extension': fileExtension,
        'path': file.path,
        'isValidImage': _isValidImageExtension(fileExtension),
      };
    } catch (e) {
      return {
        'name': 'Unknown',
        'size': 0,
        'sizeFormatted': '0 B',
        'extension': 'unknown',
        'path': file.path,
        'isValidImage': false,
        'error': e.toString(),
      };
    }
  }

  /// Formatear tamaño de archivo
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Verificar si la extensión es de imagen válida
  bool _isValidImageExtension(String extension) {
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return validExtensions.contains(extension.toLowerCase());
  }

  /// Validar archivo antes de subir
  String? validateFile(File file) {
    if (!file.existsSync()) {
      return 'El archivo no existe';
    }

    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    if (!_isValidImageExtension(fileExtension)) {
      return 'Formato de archivo no válido. Solo se permiten: JPG, PNG, GIF, BMP, WebP';
    }

    return null; // Archivo válido
  }

  /// Validar múltiples archivos
  List<String> validateMultipleFiles(List<File> files) {
    final errors = <String>[];

    if (files.isEmpty) {
      errors.add('Debe seleccionar al menos una foto');
      return errors;
    }

    if (files.length > 5) {
      errors.add('Máximo 5 fotos permitidas');
    }

    for (int i = 0; i < files.length; i++) {
      final validation = validateFile(files[i]);
      if (validation != null) {
        errors.add('Foto ${i + 1}: $validation');
      }
    }

    return errors;
  }
}