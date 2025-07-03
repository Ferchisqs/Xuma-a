import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Verde Natura/Ambiental
  static const Color primary = Color(0xFF2E7D32);        // Verde principal
  static const Color primaryLight = Color(0xFF4CAF50);    // Verde claro
  static const Color primaryDark = Color(0xFF1B5E20);     // Verde oscuro
  
  // Secondary Colors - Tonos naturales
  static const Color secondary = Color(0xFF558B2F);       // Verde lima
  static const Color secondaryLight = Color(0xFF8BC34A);  // Verde lima claro
  static const Color secondaryDark = Color(0xFF33691E);   // Verde lima oscuro
  
  // Accent Colors - Tierra y naturaleza
  static const Color accent = Color(0xFFFF9800);          // Naranja tierra
  static const Color accentLight = Color(0xFFFFC107);     // Amarillo tierra
  static const Color accentDark = Color(0xFFE65100);      // Naranja oscuro
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);      // Blanco natural
  static const Color backgroundLight = Color(0xFFFFFFFF); // Blanco puro
  static const Color surface = Color(0xFFFFFFFF);         // Superficie
  static const Color surfaceLight = Color(0xFFF5F5F5);    // Superficie clara
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2E2E2E);     // Texto principal
  static const Color textSecondary = Color(0xFF757575);   // Texto secundario
  static const Color textHint = Color(0xFF9E9E9E);        // Texto hint
  static const Color textDisabled = Color(0xFFBDBDBD);    // Texto deshabilitado
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);         // Éxito
  static const Color warning = Color(0xFFFF9800);         // Advertencia
  static const Color error = Color(0xFFF44336);           // Error
  static const Color info = Color(0xFF2196F3);            // Información
  
  // Special Colors
  static const Color recycling = Color(0xFF4CAF50);       // Reciclaje
  static const Color nature = Color(0xFF8BC34A);          // Naturaleza
  static const Color earth = Color(0xFF795548);           // Tierra
  static const Color water = Color(0xFF2196F3);           // Agua
  static const Color air = Color(0xFF81C784);             // Aire
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient natureGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF4CAF50),
      Color(0xFF8BC34A),
      Color(0xFFCDDC39),
    ],
  );
  
  static const LinearGradient earthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50),
      Color(0xFF66BB6A),
      Color(0xFF81C784),
    ],
  );
}