// lib/features/challenges/domain/usecases/submit_evidence_usecase.dart - IMPLEMENTACIÓN COMPLETA
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/challenges_repository.dart';

class SubmitEvidenceParams extends Equatable {
  final String userChallengeId;
  final String submissionType;
  final String contentText;
  final List<String> mediaUrls;
  final Map<String, dynamic>? locationData;
  final Map<String, dynamic>? measurementData;
  final Map<String, dynamic>? metadata;

  const SubmitEvidenceParams({
    required this.userChallengeId,
    required this.submissionType,
    required this.contentText,
    required this.mediaUrls,
    this.locationData,
    this.measurementData,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    userChallengeId,
    submissionType,
    contentText,
    mediaUrls,
    locationData,
    measurementData,
    metadata,
  ];

  // 🆕 FACTORY CONSTRUCTORS PARA DIFERENTES TIPOS DE EVIDENCIA
  
  /// Crear evidencia de tipo foto
  factory SubmitEvidenceParams.photo({
    required String userChallengeId,
    required String description,
    required List<String> photoUrls,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return SubmitEvidenceParams(
      userChallengeId: userChallengeId,
      submissionType: 'photo',
      contentText: description,
      mediaUrls: photoUrls,
      locationData: latitude != null && longitude != null ? {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName ?? 'Ubicación del desafío',
      } : null,
      metadata: {
        'submissionDate': DateTime.now().toIso8601String(),
        'evidenceType': 'photographic',
      },
    );
  }

  /// Crear evidencia de tipo medición (peso, volumen, etc.)
  factory SubmitEvidenceParams.measurement({
    required String userChallengeId,
    required String description,
    required List<String> photoUrls,
    String? weight,
    String? volume,
    String? quantity,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return SubmitEvidenceParams(
      userChallengeId: userChallengeId,
      submissionType: 'measurement',
      contentText: description,
      mediaUrls: photoUrls,
      locationData: latitude != null && longitude != null ? {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName ?? 'Ubicación del desafío',
      } : null,
      measurementData: {
        if (weight != null) 'weight': weight,
        if (volume != null) 'volume': volume,
        if (quantity != null) 'quantity': quantity,
      },
      metadata: {
        'submissionDate': DateTime.now().toIso8601String(),
        'evidenceType': 'measurement',
      },
    );
  }

  /// Crear evidencia de tipo actividad (composta, limpieza, etc.)
  factory SubmitEvidenceParams.activity({
    required String userChallengeId,
    required String description,
    required List<String> photoUrls,
    String? activityType,
    String? duration,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return SubmitEvidenceParams(
      userChallengeId: userChallengeId,
      submissionType: 'activity',
      contentText: description,
      mediaUrls: photoUrls,
      locationData: latitude != null && longitude != null ? {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName ?? 'Ubicación de la actividad',
      } : null,
      metadata: {
        'submissionDate': DateTime.now().toIso8601String(),
        'evidenceType': 'activity',
        if (activityType != null) 'activityType': activityType,
        if (duration != null) 'duration': duration,
      },
    );
  }
}

@injectable
class SubmitEvidenceUseCase implements UseCase<void, SubmitEvidenceParams> {
  final ChallengesRepository repository;

  SubmitEvidenceUseCase(this.repository) {
    print('✅ [SUBMIT EVIDENCE USE CASE] Constructor - Ready to submit evidence to real API');
  }

  @override
  Future<Either<Failure, void>> call(SubmitEvidenceParams params) async {
    try {
      print('🎯 [SUBMIT EVIDENCE USE CASE] === SUBMITTING EVIDENCE ===');
      print('🎯 [SUBMIT EVIDENCE USE CASE] User Challenge ID: ${params.userChallengeId}');
      print('🎯 [SUBMIT EVIDENCE USE CASE] Submission Type: ${params.submissionType}');
      print('🎯 [SUBMIT EVIDENCE USE CASE] Content: ${params.contentText}');
      print('🎯 [SUBMIT EVIDENCE USE CASE] Media URLs: ${params.mediaUrls.length} files');
      
      // Validar parámetros antes de enviar
      final validationResult = _validateParams(params);
      if (validationResult != null) {
        print('❌ [SUBMIT EVIDENCE USE CASE] Validation failed: $validationResult');
        return Left(ValidationFailure(validationResult));
      }
      
      // Necesitamos hacer un cast del repository para acceder al método
      final repositoryImpl = repository as dynamic;
      
      final result = await repositoryImpl.submitEvidence(
        userChallengeId: params.userChallengeId,
        submissionType: params.submissionType,
        contentText: params.contentText,
        mediaUrls: params.mediaUrls,
        locationData: params.locationData,
        measurementData: params.measurementData,
        metadata: params.metadata,
      );
      
      return result.fold(
        (failure) {
          print('❌ [SUBMIT EVIDENCE USE CASE] Failed to submit evidence: ${failure.message}');
          return Left(failure);
        },
        (_) {
          print('✅ [SUBMIT EVIDENCE USE CASE] Evidence submitted successfully');
          return const Right(null);
        },
      );
      
    } catch (e) {
      print('❌ [SUBMIT EVIDENCE USE CASE] Unexpected error: $e');
      return Left(UnknownFailure('Error inesperado al enviar evidencia: ${e.toString()}'));
    }
  }

  /// Validar parámetros antes de enviar la evidencia
  String? _validateParams(SubmitEvidenceParams params) {
    // Validar ID del challenge
    if (params.userChallengeId.isEmpty) {
      return 'ID del desafío de usuario es requerido';
    }

    // Validar tipo de envío
    if (params.submissionType.isEmpty) {
      return 'Tipo de evidencia es requerido';
    }

    // Validar tipos de evidencia permitidos
    const allowedTypes = ['photo', 'measurement', 'activity', 'video', 'document'];
    if (!allowedTypes.contains(params.submissionType)) {
      return 'Tipo de evidencia no válido. Tipos permitidos: ${allowedTypes.join(', ')}';
    }

    // Validar descripción
    if (params.contentText.isEmpty) {
      return 'Descripción de la evidencia es requerida';
    }

    if (params.contentText.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    if (params.contentText.length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }

    // Validar archivos multimedia
    if (params.mediaUrls.isEmpty) {
      return 'Se requiere al menos un archivo de evidencia (foto, video, etc.)';
    }

    if (params.mediaUrls.length > 5) {
      return 'Máximo 5 archivos permitidos por evidencia';
    }

    // Validar URLs de medios
    for (final url in params.mediaUrls) {
      if (url.isEmpty) {
        return 'URLs de archivos no pueden estar vacías';
      }
      
      // Validar formato básico de URL
      if (!_isValidUrl(url)) {
        return 'URL de archivo inválida: $url';
      }
    }

    // Validar datos de ubicación si están presentes
    if (params.locationData != null) {
      final location = params.locationData!;
      
      if (location.containsKey('latitude') && location.containsKey('longitude')) {
        final lat = location['latitude'];
        final lng = location['longitude'];
        
        if (lat is! double || lng is! double) {
          return 'Coordenadas de ubicación deben ser números decimales';
        }
        
        if (lat < -90 || lat > 90) {
          return 'Latitud debe estar entre -90 y 90 grados';
        }
        
        if (lng < -180 || lng > 180) {
          return 'Longitud debe estar entre -180 y 180 grados';
        }
      }
    }

    // Validar datos de medición si están presentes
    if (params.measurementData != null) {
      final measurements = params.measurementData!;
      
      // Si hay mediciones, al menos una debe tener valor
      if (measurements.isEmpty) {
        return 'Si se incluyen datos de medición, debe haber al menos uno';
      }
      
      // Validar formatos comunes de medición
      if (measurements.containsKey('weight')) {
        final weight = measurements['weight'];
        if (weight is String && !_isValidMeasurement(weight)) {
          return 'Formato de peso inválido. Ejemplo: "5kg", "2.5kg"';
        }
      }
      
      if (measurements.containsKey('volume')) {
        final volume = measurements['volume'];
        if (volume is String && !_isValidMeasurement(volume)) {
          return 'Formato de volumen inválido. Ejemplo: "10L", "2.5L"';
        }
      }
    }

    return null; // Todo válido
  }

  /// Validar si una cadena es una URL válida básica
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validar formato de mediciones (peso, volumen, etc.)
  bool _isValidMeasurement(String measurement) {
    // Expresión regular para validar formatos como "5kg", "2.5L", "10.5cm", etc.
    final regex = RegExp(r'^\d+(\.\d+)?\s*[a-zA-Z]+$');
    return regex.hasMatch(measurement.trim());
  }
}

// 🆕 HELPER CLASS PARA CONSTRUIR EVIDENCIAS COMPLEJAS
class EvidenceBuilder {
  String? _userChallengeId;
  String? _submissionType;
  String? _contentText;
  List<String> _mediaUrls = [];
  Map<String, dynamic>? _locationData;
  Map<String, dynamic>? _measurementData;
  Map<String, dynamic>? _metadata;

  EvidenceBuilder();

  EvidenceBuilder forChallenge(String userChallengeId) {
    _userChallengeId = userChallengeId;
    return this;
  }

  EvidenceBuilder ofType(String submissionType) {
    _submissionType = submissionType;
    return this;
  }

  EvidenceBuilder withDescription(String description) {
    _contentText = description;
    return this;
  }

  EvidenceBuilder addPhoto(String photoUrl) {
    _mediaUrls.add(photoUrl);
    return this;
  }

  EvidenceBuilder addPhotos(List<String> photoUrls) {
    _mediaUrls.addAll(photoUrls);
    return this;
  }

  EvidenceBuilder atLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    _locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName ?? 'Ubicación del desafío',
    };
    return this;
  }

  EvidenceBuilder withMeasurement({
    String? weight,
    String? volume,
    String? quantity,
  }) {
    _measurementData = {};
    if (weight != null) _measurementData!['weight'] = weight;
    if (volume != null) _measurementData!['volume'] = volume;
    if (quantity != null) _measurementData!['quantity'] = quantity;
    return this;
  }

  EvidenceBuilder withMetadata(Map<String, dynamic> metadata) {
    _metadata = {...(_metadata ?? {}), ...metadata};
    return this;
  }

  EvidenceBuilder addMetadata(String key, dynamic value) {
    _metadata ??= {};
    _metadata![key] = value;
    return this;
  }

  SubmitEvidenceParams build() {
    if (_userChallengeId == null) {
      throw ArgumentError('User Challenge ID is required');
    }
    if (_submissionType == null) {
      throw ArgumentError('Submission type is required');
    }
    if (_contentText == null) {
      throw ArgumentError('Content text is required');
    }

    // Agregar metadata por defecto
    _metadata ??= {};
    _metadata!['submissionDate'] = DateTime.now().toIso8601String();
    _metadata!['builderUsed'] = true;

    return SubmitEvidenceParams(
      userChallengeId: _userChallengeId!,
      submissionType: _submissionType!,
      contentText: _contentText!,
      mediaUrls: _mediaUrls,
      locationData: _locationData,
      measurementData: _measurementData,
      metadata: _metadata,
    );
  }
}