// lib/core/utils/error_handler.dart
class ErrorHandler {
  
  /// Convierte errores técnicos a mensajes amigables para el usuario
  static String getErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();
    
    // Errores de red
    if (error.contains('connection') || 
        error.contains('timeout') || 
        error.contains('network') ||
        error.contains('internet')) {
      return 'Revisa tu conexión a internet e intenta nuevamente';
    }
    
    // Errores de autenticación
    if (error.contains('unauthorized') || 
        error.contains('401') ||
        error.contains('credenciales') ||
        error.contains('password') ||
        error.contains('contraseña')) {
      return 'Email o contraseña incorrectos';
    }
    
    // Usuario ya existe
    if (error.contains('already exists') || 
        error.contains('ya existe') ||
        error.contains('duplicate') ||
        error.contains('email') && error.contains('use')) {
      return 'Este email ya está registrado';
    }
    
    // Validación
    if (error.contains('validation') || 
        error.contains('invalid') ||
        error.contains('formato') ||
        error.contains('válido')) {
      return 'Por favor verifica los datos ingresados';
    }
    
    // Error del servidor
    if (error.contains('500') || 
        error.contains('server error') ||
        error.contains('interno') ||
        error.contains('servidor')) {
      return 'Error del servidor. Intenta más tarde';
    }
    
    // Errores de campos requeridos
    if (error.contains('required') || 
        error.contains('requerido') ||
        error.contains('obligatorio')) {
      return 'Completa todos los campos obligatorios';
    }
    
    // Error de edad
    if (error.contains('age') || error.contains('edad')) {
      return 'Edad inválida. Debe estar entre 1 y 120 años';
    }
    
    // Error de email
    if (error.contains('email') && error.contains('format')) {
      return 'Formato de email inválido';
    }
    
    // Error de contraseña débil
    if (error.contains('weak') || error.contains('débil')) {
      return 'La contraseña debe ser más segura';
    }
    
    // Error genérico para producción
    return 'Algo salió mal. Por favor intenta nuevamente';
  }
  
  /// Determina si mostrar el error técnico (solo en desarrollo)
  static String getFinalErrorMessage(String technicalError) {
    // En desarrollo, mostrar error técnico completo
    const bool isDevelopment = bool.fromEnvironment('dart.vm.product') == false;
    
    if (isDevelopment) {
      final friendlyMessage = getErrorMessage(technicalError);
      return '$friendlyMessage\n\n[DEBUG: $technicalError]';
    }
    
    // En producción, solo mensaje amigable
    return getErrorMessage(technicalError);
  }
  
  /// Maneja errores de validación específicos
  static String handleValidationError(String field, String error) {
    if (error.contains('required')) {
      return '$field es requerido';
    }
    
    if (error.contains('format') || error.contains('invalid')) {
      return '$field tiene un formato inválido';
    }
    
    if (error.contains('length')) {
      return '$field no cumple con la longitud requerida';
    }
    
    return 'Error en $field';
  }
}