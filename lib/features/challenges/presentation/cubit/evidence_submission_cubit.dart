// lib/features/challenges/presentation/cubit/evidence_submission_cubit.dart - IMPLEMENTACIÓN COMPLETA
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/submit_evidence_usecase.dart';

// ==================== STATES ====================

abstract class EvidenceSubmissionState extends Equatable {
  const EvidenceSubmissionState();

  @override
  List<Object?> get props => [];
}

class EvidenceSubmissionInitial extends EvidenceSubmissionState {}

class EvidenceSubmissionLoading extends EvidenceSubmissionState {}

class EvidenceSubmissionSuccess extends EvidenceSubmissionState {
  final String message;

  const EvidenceSubmissionSuccess({
    this.message = '¡Evidencia enviada exitosamente!',
  });

  @override
  List<Object> get props => [message];
}

class EvidenceSubmissionError extends EvidenceSubmissionState {
  final String message;

  const EvidenceSubmissionError({required this.message});

  @override
  List<Object> get props => [message];
}

class EvidenceSubmissionValidating extends EvidenceSubmissionState {
  final String message;

  const EvidenceSubmissionValidating({
    this.message = 'Validando datos...',
  });

  @override
  List<Object> get props => [message];
}

class EvidenceSubmissionUploading extends EvidenceSubmissionState {
  final double progress;
  final String message;

  const EvidenceSubmissionUploading({
    required this.progress,
    this.message = 'Subiendo archivos...',
  });

  @override
  List<Object> get props => [progress, message];
}

class EvidenceSubmissionValidationPending extends EvidenceSubmissionState {
  final String submissionId;
  final DateTime submissionDate;

  const EvidenceSubmissionValidationPending({
    required this.submissionId,
    required this.submissionDate,
  });

  @override
  List<Object> get props => [submissionId, submissionDate];
}

// ==================== CUBIT ====================

@injectable
class EvidenceSubmissionCubit extends Cubit<EvidenceSubmissionState> {
  final SubmitEvidenceUseCase submitEvidenceUseCase;

  EvidenceSubmissionCubit({
    required this.submitEvidenceUseCase,
  }) : super(EvidenceSubmissionInitial()) {
    print('✅ [EVIDENCE SUBMISSION CUBIT] Constructor - Ready to submit evidence');
  }

  Future<void> submitEvidence(SubmitEvidenceParams params) async {
  try {
    print('🎯 [EVIDENCE SUBMISSION CUBIT] === STARTING EVIDENCE SUBMISSION WITH REAL PHOTOS ===');
    print('🎯 [EVIDENCE SUBMISSION CUBIT] User Challenge ID: ${params.userChallengeId}');
    print('🎯 [EVIDENCE SUBMISSION CUBIT] Submission Type: ${params.submissionType}');
    print('🎯 [EVIDENCE SUBMISSION CUBIT] Media Files: ${params.mediaUrls.length}');
    print('🎯 [EVIDENCE SUBMISSION CUBIT] Photo URLs: ${params.mediaUrls}');

    // Fase 1: Validación inicial
    emit(const EvidenceSubmissionValidating(message: 'Validando evidencia...'));
    await Future.delayed(const Duration(milliseconds: 500));

    // Validar parámetros
    final validationError = _validateSubmissionParams(params);
    if (validationError != null) {
      emit(EvidenceSubmissionError(message: validationError));
      return;
    }

    // Fase 2: Verificar que las URLs de fotos sean válidas
    if (params.mediaUrls.isNotEmpty) {
      emit(const EvidenceSubmissionValidating(message: 'Verificando fotos subidas...'));
      await Future.delayed(const Duration(milliseconds: 300));
      
      final invalidUrls = _validatePhotoUrls(params.mediaUrls);
      if (invalidUrls.isNotEmpty) {
        emit(EvidenceSubmissionError(
          message: 'URLs de fotos inválidas: ${invalidUrls.join(', ')}',
        ));
        return;
      }
    }

    // Fase 3: Envío de evidencia al quiz challenge service
    emit(EvidenceSubmissionLoading());

    final result = await submitEvidenceUseCase(params);

    result.fold(
      (failure) {
        print('❌ [EVIDENCE SUBMISSION CUBIT] Failed to submit evidence: ${failure.message}');
        emit(EvidenceSubmissionError(message: _getErrorMessage(failure.message)));
      },
      (_) {
        print('✅ [EVIDENCE SUBMISSION CUBIT] Evidence submitted successfully to quiz service');
        
        // Generar ID de submisión simulado
        final submissionId = 'submission_${DateTime.now().millisecondsSinceEpoch}';
        
        emit(EvidenceSubmissionValidationPending(
          submissionId: submissionId,
          submissionDate: DateTime.now(),
        ));

        // Después de un breve delay, mostrar mensaje de éxito
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!isClosed) {
            emit(EvidenceSubmissionSuccess(
              message: '¡Evidencia enviada exitosamente! Tu desafío está en proceso de validación.',
            ));
          }
        });
      },
    );

  } catch (e) {
    print('❌ [EVIDENCE SUBMISSION CUBIT] Unexpected error: $e');
    emit(EvidenceSubmissionError(
      message: 'Error inesperado al enviar la evidencia. Por favor, intenta nuevamente.',
    ));
  }
}

List<String> _validatePhotoUrls(List<String> photoUrls) {
  final invalidUrls = <String>[];
  
  for (final url in photoUrls) {
    if (!_isValidPhotoUrl(url)) {
      invalidUrls.add(url);
    }
  }
  
  return invalidUrls;
}
bool _isValidPhotoUrl(String url) {
  if (url.isEmpty) return false;
  
  try {
    final uri = Uri.parse(url);
    if (!uri.isAbsolute) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    
    // Verificar que sea una URL de imagen (opcional, pero recomendado)
    final path = uri.path.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    
    // Si tiene extensión, verificar que sea válida
    if (path.contains('.')) {
      return validExtensions.any((ext) => path.endsWith(ext));
    }
    
    // Si no tiene extensión, asumir que es válida (puede ser una URL dinámica)
    return true;
    
  } catch (e) {
    return false;
  }
}

  Future<void> _simulateFileUpload(List<String> mediaUrls) async {
    emit(const EvidenceSubmissionUploading(progress: 0.0, message: 'Preparando archivos...'));
    await Future.delayed(const Duration(milliseconds: 500));

    // Simular progreso de subida archivo por archivo
    for (int i = 1; i <= mediaUrls.length; i++) {
      final progress = i / mediaUrls.length;
      emit(EvidenceSubmissionUploading(
        progress: progress,
        message: 'Subiendo archivo $i de ${mediaUrls.length}...',
      ));
      
      // Simular tiempo de subida variable por archivo
      await Future.delayed(Duration(milliseconds: 600 + (i * 200)));
    }

    // Confirmación de subida completa
    emit(const EvidenceSubmissionUploading(
      progress: 1.0, 
      message: 'Archivos subidos exitosamente'
    ));
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void resetState() {
    print('🔄 [EVIDENCE SUBMISSION CUBIT] Resetting state');
    emit(EvidenceSubmissionInitial());
  }

  void retrySubmission(SubmitEvidenceParams params) {
    print('🔄 [EVIDENCE SUBMISSION CUBIT] Retrying evidence submission');
    submitEvidence(params);
  }

  String? _validateSubmissionParams(SubmitEvidenceParams params) {
    // Validar ID del challenge
    if (params.userChallengeId.isEmpty) {
      return 'ID del desafío de usuario es requerido';
    }

    // Validar tipo de evidencia
    if (params.submissionType.isEmpty) {
      return 'Tipo de evidencia es requerido';
    }

    const allowedTypes = ['photo', 'measurement', 'activity', 'video', 'document'];
    if (!allowedTypes.contains(params.submissionType)) {
      return 'Tipo de evidencia no válido';
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
      return 'Se requiere al menos un archivo de evidencia';
    }

    if (params.mediaUrls.length > 5) {
      return 'Máximo 5 archivos permitidos por evidencia';
    }

    // Validar URLs de medios
    for (final url in params.mediaUrls) {
      if (url.isEmpty) {
        return 'URLs de archivos no pueden estar vacías';
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

  bool _isValidMeasurement(String measurement) {
    // Expresión regular para validar formatos como "5kg", "2.5L", "10.5cm", etc.
    final regex = RegExp(r'^\d+(\.\d+)?\s*[a-zA-Z]+$');
    return regex.hasMatch(measurement.trim());
  }

  String _getErrorMessage(String originalError) {
    final errorLower = originalError.toLowerCase();
    
    // Errores de validación
    if (errorLower.contains('validation') || errorLower.contains('required')) {
      return 'Por favor verifica que todos los campos estén completos correctamente.';
    }
    
    // Errores de red
    if (errorLower.contains('network') || errorLower.contains('internet') || errorLower.contains('connection')) {
      return 'Sin conexión a internet. Verifica tu conexión e intenta nuevamente.';
    }
    
    // Errores del servidor
    if (errorLower.contains('server') || errorLower.contains('500')) {
      return 'Error del servidor. Intenta nuevamente en unos minutos.';
    }
    
    // Errores de autenticación
    if (errorLower.contains('unauthorized') || errorLower.contains('401')) {
      return 'Sesión expirada. Por favor inicia sesión nuevamente.';
    }
    
    // Errores de archivo
    if (errorLower.contains('file') || errorLower.contains('upload') || errorLower.contains('media')) {
      return 'Error al subir archivos. Verifica que las imágenes sean válidas.';
    }
    
    // Errores de tamaño
    if (errorLower.contains('size') || errorLower.contains('large') || errorLower.contains('big')) {
      return 'Uno o más archivos son demasiado grandes. Intenta con imágenes más pequeñas.';
    }
    
    // Errores de formato
    if (errorLower.contains('format') || errorLower.contains('type') || errorLower.contains('invalid')) {
      return 'Formato de archivo no válido. Solo se permiten imágenes JPG, PNG.';
    }
    
    // Error genérico
    return 'Error al enviar la evidencia. Por favor intenta nuevamente.';
  }

  // ==================== GETTERS DE ESTADO ====================

  bool get isInitial => state is EvidenceSubmissionInitial;
  bool get isLoading => state is EvidenceSubmissionLoading;
  bool get isValidating => state is EvidenceSubmissionValidating;
  bool get isUploading => state is EvidenceSubmissionUploading;
  bool get isSuccess => state is EvidenceSubmissionSuccess;
  bool get isError => state is EvidenceSubmissionError;
  bool get isPendingValidation => state is EvidenceSubmissionValidationPending;

  double get uploadProgress {
    final currentState = state;
    if (currentState is EvidenceSubmissionUploading) {
      return currentState.progress;
    }
    return 0.0;
  }

  String get statusMessage {
    final currentState = state;
    if (currentState is EvidenceSubmissionValidating) {
      return currentState.message;
    } else if (currentState is EvidenceSubmissionUploading) {
      return currentState.message;
    } else if (currentState is EvidenceSubmissionSuccess) {
      return currentState.message;
    } else if (currentState is EvidenceSubmissionError) {
      return currentState.message;
    }
    return '';
  }

  bool get canRetry => state is EvidenceSubmissionError;

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Cancelar proceso actual (si es posible)
  void cancelSubmission() {
    if (state is EvidenceSubmissionValidating || state is EvidenceSubmissionUploading) {
      print('🚫 [EVIDENCE SUBMISSION CUBIT] Cancelling submission');
      emit(EvidenceSubmissionInitial());
    }
  }

  /// Obtener información del estado actual para debugging
  Map<String, dynamic> getStateInfo() {
    final currentState = state;
    return {
      'stateType': currentState.runtimeType.toString(),
      'isLoading': isLoading,
      'isSuccess': isSuccess,
      'isError': isError,
      'uploadProgress': uploadProgress,
      'statusMessage': statusMessage,
      'canRetry': canRetry,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Simular validación exitosa (para testing)
  void simulateValidationSuccess() {
    emit(const EvidenceSubmissionSuccess(
      message: '¡Evidencia validada y aprobada! Has ganado puntos.',
    ));
  }

  /// Simular validación fallida (para testing) 
  void simulateValidationFailure(String reason) {
    emit(EvidenceSubmissionError(
      message: 'Evidencia rechazada: $reason. Por favor, envía nueva evidencia.',
    ));
  }
}

// ==================== HELPER CLASSES ====================

/// Información detallada sobre el progreso de subida
class UploadProgressInfo {
  final int currentFile;
  final int totalFiles;
  final double fileProgress;
  final String fileName;
  final int bytesUploaded;
  final int totalBytes;

  const UploadProgressInfo({
    required this.currentFile,
    required this.totalFiles,
    required this.fileProgress,
    required this.fileName,
    required this.bytesUploaded,
    required this.totalBytes,
  });

  double get overallProgress {
    if (totalFiles == 0) return 0.0;
    return ((currentFile - 1) + fileProgress) / totalFiles;
  }

  String get progressText {
    return 'Subiendo $fileName ($currentFile/$totalFiles)';
  }

  String get sizeText {
    return '${_formatBytes(bytesUploaded)} / ${_formatBytes(totalBytes)}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Resultado de validación de evidencia local
class LocalValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? suggestions;

  const LocalValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.suggestions,
  });

  factory LocalValidationResult.valid() {
    return const LocalValidationResult(
      isValid: true,
      errors: [],
      warnings: [],
    );
  }

  factory LocalValidationResult.invalid(List<String> errors) {
    return LocalValidationResult(
      isValid: false,
      errors: errors,
      warnings: [],
    );
  }

  factory LocalValidationResult.withWarnings(List<String> warnings) {
    return LocalValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
    );
  }

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
}