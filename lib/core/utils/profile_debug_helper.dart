// lib/core/utils/profile_debug_helper.dart
class ProfileDebugHelper {
  
  /// Debug completo de la respuesta del perfil
  static void debugProfileResponse(Map<String, dynamic> response) {
    print('🔍 === PROFILE DEBUG RESPONSE ===');
    print('📄 Raw response: $response');
    print('📊 Response type: ${response.runtimeType}');
    print('🔑 Keys disponibles: ${response.keys.toList()}');
    
    // Verificar estructura de datos
    if (response.containsKey('data')) {
      final data = response['data'];
      print('📦 Data encontrado: $data');
      print('📦 Data type: ${data.runtimeType}');
      
      if (data is Map<String, dynamic>) {
        print('🔍 Campos en data:');
        data.forEach((key, value) {
          print('   - $key: $value (${value.runtimeType})');
        });
      }
    }
    
    // Verificar campos específicos problemáticos
    final problematicFields = ['firstName', 'lastName', 'age', 'createdAt'];
    for (final field in problematicFields) {
      if (response.containsKey(field)) {
        print('⚠️ Campo $field en root: ${response[field]}');
      }
      if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey(field)) {
          print('✅ Campo $field en data: ${data[field]}');
        }
      }
    }
    
    print('🔍 === END PROFILE DEBUG ===');
  }
  
  /// Crear datos de fallback cuando el backend envía datos incorrectos
  static Map<String, dynamic> createFallbackProfile(String userId) {
    return {
      'id': userId,
      'email': 'usuario@xumaa.com',
      'firstName': 'Eco',
      'lastName': 'Usuario',
      'age': 25,
      'isVerified': false,
      'accountStatus': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'ecoPoints': 150,
      'achievementsCount': 3,
      'lessonsCompleted': 5,
      'level': 'Eco Guardian',
      'avatarUrl': null,
      'bio': null,
      'location': null,
      'needsParentalConsent': false,
    };
  }
  
  /// Limpiar y validar datos del perfil
  static Map<String, dynamic> cleanProfileData(Map<String, dynamic> rawData, String userId) {
    print('🧹 Limpiando datos del perfil...');
    
    // Si los datos vienen con valores de ejemplo/placeholder, usar fallback
    final firstName = rawData['firstName']?.toString() ?? '';
    final lastName = rawData['lastName']?.toString() ?? '';
    final age = rawData['age'];
    
    bool needsFallback = false;
    
    // Detectar si son datos de ejemplo
    if (firstName.toLowerCase() == 'string' || 
        firstName.toLowerCase() == 'user' ||
        firstName.toLowerCase() == 'example' ||
        firstName.isEmpty) {
      needsFallback = true;
      print('⚠️ Detectado firstName placeholder: "$firstName"');
    }
    
    if (lastName.toLowerCase() == 'string' || 
        lastName.toLowerCase() == 'user' ||
        lastName.toLowerCase() == 'example') {
      needsFallback = true;
      print('⚠️ Detectado lastName placeholder: "$lastName"');
    }
    
    if (age == 0 || age == null) {
      needsFallback = true;
      print('⚠️ Detectado age inválido: "$age"');
    }
    
    if (needsFallback) {
      print('🔄 Usando datos de fallback mejorados...');
      final fallback = createFallbackProfile(userId);
      
      // Mantener algunos datos reales si están disponibles
      return {
        ...fallback,
        'id': rawData['id'] ?? userId,
        'email': _isValidEmail(rawData['email']) ? rawData['email'] : fallback['email'],
        'isVerified': rawData['isVerified'] ?? false,
        'accountStatus': rawData['accountStatus'] ?? 'active',
        'createdAt': rawData['createdAt'] ?? fallback['createdAt'],
      };
    }
    
    return rawData;
  }
  
  /// Validar si un email parece real
  static bool _isValidEmail(dynamic email) {
    if (email == null) return false;
    final emailStr = email.toString();
    return emailStr.contains('@') && 
           emailStr.contains('.') && 
           !emailStr.toLowerCase().contains('example') &&
           !emailStr.toLowerCase().contains('test') &&
           emailStr.length > 5;
  }
  
  /// Obtener información del entorno/servidor para debug
  static void debugServerEnvironment() {
    print('🌐 === SERVER ENVIRONMENT DEBUG ===');
    print('🔗 Auth Service: https://auth-service-production-e333.up.railway.app');
    print('👥 User Service: https://user-service-xumaa-production.up.railway.app');
    print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🌐 === END SERVER DEBUG ===');
  }
}