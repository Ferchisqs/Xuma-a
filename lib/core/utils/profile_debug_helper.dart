// lib/core/utils/profile_debug_helper.dart - VERSIÓN MEJORADA
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
          final isPlaceholder = _isPlaceholderValue(value);
          print('   - $key: $value (${value.runtimeType}) ${isPlaceholder ? "⚠️ PLACEHOLDER" : "✅ REAL"}');
        });
      }
    }
    
    // Verificar si son datos placeholder
    final hasPlaceholders = _hasPlaceholderData(response);
    if (hasPlaceholders) {
      print('⚠️ ==============================');
      print('⚠️ PROBLEMA DETECTADO: DATOS PLACEHOLDER');
      print('⚠️ El backend está devolviendo datos de ejemplo');
      print('⚠️ en lugar de los datos reales del usuario');
      print('⚠️ ==============================');
    }
    
    print('🔍 === END PROFILE DEBUG ===');
  }
  
  /// Verificar si hay datos placeholder en la respuesta
  static bool _hasPlaceholderData(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return false;
    
    // Verificar firstName
    final firstName = data['firstName'];
    if (_isPlaceholderValue(firstName)) return true;
    
    // Verificar lastName
    final lastName = data['lastName'];
    if (_isPlaceholderValue(lastName)) return true;
    
    // Verificar age
    final age = data['age'];
    if (age == 0 || age == null) return true;
    
    return false;
  }
  
  /// Verificar si un valor específico es placeholder
  static bool _isPlaceholderValue(dynamic value) {
    if (value == null) return true;
    
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      return lowerValue == 'string' || 
             lowerValue == 'user' || 
             lowerValue == 'example' ||
             lowerValue.isEmpty;
    }
    
    if (value is int && value == 0) return true;
    
    return false;
  }
  
  /// Crear datos de usuario reales cuando el backend falla
  static Map<String, dynamic> createUserDataFromRegistration({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    int? age,
  }) {
    print('🔧 Creando datos de usuario desde registro...');
    print('🔧 UserId: $userId');
    print('🔧 Email: $email');
    print('🔧 FirstName: $firstName');
    print('🔧 LastName: $lastName');
    print('🔧 Age: $age');
    
    return {
      'id': userId,
      'email': email,
      'firstName': firstName ?? _extractFirstNameFromEmail(email),
      'lastName': lastName ?? 'Usuario',
      'age': age ?? 25,
      'isVerified': false,
      'accountStatus': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'ecoPoints': 150,
      'achievementsCount': 3,
      'lessonsCompleted': 5,
      'level': _getLevelFromAge(age ?? 25),
      'avatarUrl': null,
      'bio': 'Nuevo miembro de la comunidad XUMA\'A 🌱',
      'location': null,
      'needsParentalConsent': (age ?? 25) < 13,
      'lastLogin': DateTime.now().toIso8601String(),
    };
  }
  
  /// Extraer nombre del email si no tenemos datos reales
  static String _extractFirstNameFromEmail(String email) {
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      final localPart = parts[0];
      if (localPart.contains('.')) {
        final nameParts = localPart.split('.');
        return _capitalize(nameParts[0]);
      } else {
        return _capitalize(localPart);
      }
    }
    return 'Usuario';
  }
  
  /// Capitalizar primera letra
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Obtener nivel basado en edad
  static String _getLevelFromAge(int age) {
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }
  
  /// Método para forzar recarga del perfil con datos del contexto de auth
  static Map<String, dynamic> mergeAuthDataWithProfile(
    Map<String, dynamic> authUser,
    Map<String, dynamic> profileData,
  ) {
    print('🔄 Mezclando datos de auth con perfil...');
    
    // Si el perfil tiene placeholders, usar datos de auth
    final mergedData = Map<String, dynamic>.from(profileData);
    
    // Reemplazar firstName si es placeholder
    if (_isPlaceholderValue(profileData['firstName']) && 
        authUser.containsKey('firstName') && 
        !_isPlaceholderValue(authUser['firstName'])) {
      mergedData['firstName'] = authUser['firstName'];
      print('✅ FirstName corregido: ${authUser['firstName']}');
    }
    
    // Reemplazar lastName si es placeholder
    if (_isPlaceholderValue(profileData['lastName']) && 
        authUser.containsKey('lastName') && 
        !_isPlaceholderValue(authUser['lastName'])) {
      mergedData['lastName'] = authUser['lastName'];
      print('✅ LastName corregido: ${authUser['lastName']}');
    }
    
    // Reemplazar age si es placeholder
    if ((profileData['age'] == 0 || profileData['age'] == null) && 
        authUser.containsKey('age') && 
        authUser['age'] != null && 
        authUser['age'] != 0) {
      mergedData['age'] = authUser['age'];
      print('✅ Age corregido: ${authUser['age']}');
    }
    
    // Asegurar email correcto
    if (authUser.containsKey('email')) {
      mergedData['email'] = authUser['email'];
    }
    
    // Asegurar ID correcto
    if (authUser.containsKey('id')) {
      mergedData['id'] = authUser['id'];
    }
    
    print('🔄 Datos mezclados: $mergedData');
    return mergedData;
  }
  
  /// Debug del estado completo de autenticación
  static void debugAuthState(dynamic authState) {
    print('🔍 === AUTH STATE DEBUG ===');
    print('📊 State type: ${authState.runtimeType}');
    
    if (authState.toString().contains('AuthAuthenticated')) {
      try {
        final user = (authState as dynamic).user;
        print('👤 User data:');
        print('  - ID: ${user.id}');
        print('  - Email: ${user.email}');
        print('  - FirstName: ${user.firstName}');
        print('  - LastName: ${user.lastName}');
        print('  - Age: ${user.age}');
        print('  - CreatedAt: ${user.createdAt}');
        
        final fullProfile = (authState as dynamic).fullProfile;
        if (fullProfile != null) {
          print('📋 Full Profile data:');
          print('  - ID: ${fullProfile.id}');
          print('  - FirstName: ${fullProfile.firstName}');
          print('  - LastName: ${fullProfile.lastName}');
          print('  - Age: ${fullProfile.age}');
          print('  - EcoPoints: ${fullProfile.ecoPoints}');
          print('  - Level: ${fullProfile.level}');
        } else {
          print('📋 Full Profile: NULL');
        }
      } catch (e) {
        print('❌ Error accessing auth state data: $e');
      }
    }
    
    print('🔍 === END AUTH STATE DEBUG ===');
  }
}