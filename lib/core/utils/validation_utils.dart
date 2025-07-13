// lib/core/utils/validation_utils.dart
class ValidationUtils {
  
  /// Valida email con regex mejorado
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }

  /// Valida contraseña con múltiples criterios
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe tener al menos una mayúscula';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe tener al menos una minúscula';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe tener al menos un número';
    }

    return null;
  }

  /// Valida confirmación de contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  /// Valida nombre
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    
    // Solo letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim())) {
      return '$fieldName solo puede contener letras';
    }
    
    return null;
  }

  /// Valida edad
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'La edad es requerida';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Ingresa una edad válida';
    }
    
    if (age < 1 || age > 120) {
      return 'Edad debe estar entre 1 y 120 años';
    }
    
    return null;
  }

  /// Valida texto requerido
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida número de teléfono (opcional)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional
    }
    
    // Regex básico para teléfono mexicano
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Ingresa un teléfono válido (10 dígitos)';
    }
    
    return null;
  }

  /// Calcula la fuerza de la contraseña (0-4)
  static int calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    
    return strength;
  }

  /// Obtiene el texto de fuerza de contraseña
  static String getPasswordStrengthText(String password) {
    final strength = calculatePasswordStrength(password);
    
    switch (strength) {
      case 0:
      case 1:
        return 'Muy débil';
      case 2:
        return 'Débil';
      case 3:
        return 'Buena';
      case 4:
        return 'Excelente';
      default:
        return 'Débil';
    }
  }

  /// Verifica si una contraseña es válida (cumple todos los requisitos)
  static bool isPasswordValid(String password) {
    return calculatePasswordStrength(password) == 4;
  }
}