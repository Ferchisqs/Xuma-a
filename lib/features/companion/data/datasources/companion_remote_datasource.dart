
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_manager.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';
import '../models/api_pet_response_model.dart';
import '../../domain/entities/companion_entity.dart';

abstract class CompanionRemoteDataSource {
  
  Future<List<CompanionModel>> getUserCompanions(String userId);
  Future<List<CompanionModel>> getAvailableCompanions();
  Future<List<CompanionModel>> getStoreCompanions({required String userId});
  Future<CompanionModel> adoptCompanion(
      {required String userId, required String petId, String? nickname});
  Future<CompanionStatsModel> getCompanionStats(String userId);
  Future<int> getUserPoints(String userId);
  
  Future<CompanionModel> getPetDetails({
    required String petId, 
    required String userId
  });
  // 🔥 NUEVOS MÉTODOS PARA API REAL - ACTUALIZADOS
      Future<CompanionModel> evolvePetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> featurePetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> evolveOwnedPetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> selectPetStageViaApi(
      {required String userId, required String petId, required int stage});
  
  // 🔥 MÉTODOS DE STATS CORREGIDOS
  Future<CompanionModel> increasePetStats({
    required String idUserPet, 
    int? happiness, 
    int? health
  });
  
  Future<CompanionModel> decreasePetStats({
    required String idUserPet, 
    int? happiness, 
    int? health
  });
  
  // MÉTODOS LOCALES EXISTENTES (mantener para compatibilidad)
  Future<CompanionModel> evolvePet(
      {required String userId, required String petId});
  Future<CompanionModel> featurePet(
      {required String userId, required String petId});

}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

// ==================== 🆕 OBTENER DETALLES COMPLETOS DE MASCOTA ====================
 
  // ==================== 🔥 AUMENTAR ESTADÍSTICAS VIA API ====================
  @override
  Future<CompanionModel> increasePetStats({
    required String idUserPet,
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📈 [API] === AUMENTANDO STATS VIA API REAL ===');
      debugPrint('🆔 [API] Pet ID: $idUserPet');
      debugPrint('😊 [API] Aumentar felicidad: ${happiness ?? 0}');
      debugPrint('❤️ [API] Aumentar salud: ${health ?? 0}');

      final endpoint = '/api/gamification/pet-stats/$idUserPet/increase';
      final requestBody = <String, dynamic>{};
      
      if (happiness != null) requestBody['happiness'] = happiness;
      if (health != null) requestBody['health'] = health;

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Increase stats response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Aumento de stats exitoso');
        
        // 🔥 OBTENER ESTADÍSTICAS ACTUALIZADAS DESDE EL ENDPOINT DE DETALLES
        final userId = await tokenManager.getUserId();
        if (userId != null) {
          debugPrint('🔄 [API] Obteniendo stats actualizadas desde pet details...');
          return await getPetDetails(petId: idUserPet, userId: userId);
        } else {
          // Fallback: crear companion desde respuesta
          return _createCompanionFromStatsResponse(idUserPet, response.data);
        }
      } else {
        throw ServerException(
            'Error aumentando stats: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error aumentando stats: $e');
      
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('not found') || errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada');
      } else if (errorMessage.contains('maximum') || errorMessage.contains('máximo')) {
        throw ServerException('📊 Las estadísticas ya están al máximo');
      } else {
        throw ServerException('❌ Error aumentando estadísticas de la mascota');
      }
    }
  }
 @override
Future<CompanionModel> getPetDetails({
  required String petId, 
  required String userId
}) async {
  try {
    debugPrint('🔍 [API] === OBTENIENDO DETALLES DE MASCOTA ===');
    debugPrint('🆔 [API] Pet ID: $petId');
    debugPrint('👤 [API] User ID: $userId');

    final endpoint = '/api/gamification/pets/$petId/details';
    final queryParams = {'userId': userId};

    debugPrint('🌐 [API] Endpoint: $endpoint');
    debugPrint('📝 [API] Query params: $queryParams');

    final response = await apiClient.getGamification(
      endpoint,
      queryParameters: queryParams,
      requireAuth: true,
    );

    debugPrint('✅ [API] Pet details response: ${response.statusCode}');
    debugPrint('📄 [API] Response data keys: ${response.data?.keys?.toList()}');

    if (response.data == null) {
      throw ServerException('❌ Respuesta vacía del servidor');
    }

    final petData = response.data as Map<String, dynamic>;
    
    // 🔥 EXTRAER INFORMACIÓN BÁSICA
    final responsePetId = petData['pet_id'] as String;
    final name = petData['name'] as String? ?? 'Mascota';
    final description = petData['description'] as String? ?? 'Una mascota especial';
    final speciesType = petData['species_type'] as String? ?? 'mammal';
    
    debugPrint('🐾 [API] Pet básico - ID: $responsePetId, Nombre: $name, Tipo: $speciesType');

    // 🔥 EXTRAER BASE STATS
    final baseStats = petData['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHealth = (baseStats['health'] as num?)?.toInt() ?? 100;
    final baseHappiness = (baseStats['happiness'] as num?)?.toInt() ?? 100;
    
    debugPrint('📊 [API] Base stats - Salud: $baseHealth, Felicidad: $baseHappiness');

    // 🔥 EXTRAER USER INFO
    final userInfo = petData['user_info'] as Map<String, dynamic>? ?? {};
    final userOwns = userInfo['user_owns'] as bool? ?? false;
    final userCanAfford = userInfo['user_can_afford'] as bool? ?? false;
    final userAvailablePoints = (userInfo['user_available_points'] as num?)?.toInt() ?? 0;
    
    debugPrint('👤 [API] User info - Posee: $userOwns, Puede comprar: $userCanAfford, Puntos: $userAvailablePoints');

    // 🔥 EXTRAER USER PET INFO - AQUÍ ESTÁ EL idUserPet CRÍTICO
    final userPetInfo = userInfo['user_pet_info'] as Map<String, dynamic>? ?? {};
    
    // 🔥 ¡ESTE ES EL ID QUE NECESITAMOS!
    final idUserPet = userPetInfo['idUserPet'] as String? ?? '';
    
    final currentHappiness = (userPetInfo['happiness_level'] as num?)?.toInt() ?? baseHappiness;
    final currentHealth = (userPetInfo['health_level'] as num?)?.toInt() ?? baseHealth;
    final level = (userPetInfo['level'] as num?)?.toInt() ?? 1;
    final evolutionStage = (userPetInfo['evolution_stage'] as num?)?.toInt() ?? 1;
    final experiencePoints = (userPetInfo['experience_points'] as num?)?.toInt() ?? 0;
    final isFeatured = userPetInfo['is_featured'] as bool? ?? false;
    final nickname = userPetInfo['nickname'] as String? ?? name;
    
    debugPrint('📈 [API] === STATS REALES DE LA MASCOTA ===');
    debugPrint('🆔 [API] ID USUARIO MASCOTA (CRÍTICO): $idUserPet');
    debugPrint('❤️ [API] Felicidad actual: $currentHappiness/100');
    debugPrint('🏥 [API] Salud actual: $currentHealth/100');
    debugPrint('🎯 [API] Nivel: $level, Etapa: $evolutionStage, EXP: $experiencePoints');
    debugPrint('⭐ [API] Destacada: $isFeatured, Nickname: $nickname');

    // 🔥 CORRECCIÓN: USAR EL MÉTODO DE MAPEO CORRECTO BASADO EN EL NOMBRE
    final companionType = _mapNameToCompanionType(name); // ✅ USAR ESTE MÉTODO
    final companionStage = _mapEvolutionStageToCompanionStage(evolutionStage);
    
    // 🔥 CREAR COMPANION MODEL CON EL idUserPet COMO PET ID
    final companion = CompanionModelWithPetId(
      id: '${companionType.name}_${companionStage.name}',
      type: companionType,
      stage: companionStage,
      name: nickname,
      description: description,
      level: level,
      experience: experiencePoints,
      happiness: currentHappiness,
      hunger: currentHealth, // Mapear health a hunger
      energy: 100,
      isOwned: userOwns,
      isSelected: isFeatured,
      purchasedAt: userOwns ? DateTime.now() : null,
      currentMood: _determineMoodFromStats(currentHappiness, currentHealth),
      purchasePrice: 0,
      evolutionPrice: _getEvolutionPriceForStage(evolutionStage),
      unlockedAnimations: _getAnimationsForStage(companionStage),
      createdAt: DateTime.now(),
      petId: idUserPet, // 🔥 USAR idUserPet EN LUGAR DE pet_id
    );

    debugPrint('✅ [API] === COMPANION CREADO CON idUserPet ===');
    debugPrint('🐾 [API] ${companion.displayName} - Pet ID: ${companion.petId}');
    debugPrint('📊 [API] Stats: Felicidad: ${companion.happiness}, Salud: ${companion.hunger}');
    
    return companion;

  } catch (e) {
    debugPrint('❌ [API] Error obteniendo detalles de mascota: $e');
    throw ServerException('Error obteniendo detalles de mascota: ${e.toString()}');
  }
}


@override
Future<List<CompanionModel>> getUserCompanions(String userId) async {
  try {
    debugPrint('👤 [API] === OBTENIENDO MASCOTAS DEL USUARIO CON idUserPet ===');
    debugPrint('👤 [API] Usuario ID: $userId');

    final response = await apiClient.getGamification(
      '/api/gamification/pets/$userId',
      requireAuth: true,
    );

    debugPrint('✅ [API] Respuesta mascotas usuario: ${response.statusCode}');

    if (response.data == null) {
      debugPrint('ℹ️ [API] Usuario sin mascotas adoptadas');
      return [];
    }

    List<CompanionModel> adoptedCompanions = [];
    dynamic petsData;

    if (response.data is List) {
      petsData = response.data as List;
    } else if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      petsData = dataMap['pets'] ?? dataMap['data'] ?? dataMap['owned_pets'] ?? [];
    } else {
      debugPrint('⚠️ [API] Formato de respuesta inesperado');
      return [];
    }

    if (petsData is! List) {
      debugPrint('⚠️ [API] Los datos de mascotas no son una lista');
      return [];
    }

    debugPrint('📝 [API] Procesando ${petsData.length} mascotas adoptadas');

    for (int i = 0; i < petsData.length; i++) {
      try {
        final petData = petsData[i];
        debugPrint('🐾 [API] Procesando mascota $i: ${petData['id'] ?? petData['pet_id']}');

        if (petData is Map<String, dynamic>) {
          // 🔥 EXTRAER EL pet_id PARA LLAMAR A getPetDetails
          final petId = petData['id'] as String? ?? petData['pet_id'] as String? ?? 'unknown';
          
          // 🔥 OBTENER DETALLES COMPLETOS CON idUserPet
          try {
            debugPrint('🔄 [API] Obteniendo detalles con idUserPet para: $petId');
            final companionWithRealStats = await getPetDetails(petId: petId, userId: userId);
            
            // 🔥 VERIFICAR QUE TENGA idUserPet
            if (companionWithRealStats is CompanionModelWithPetId) {
              final idUserPet = companionWithRealStats.petId;
              debugPrint('✅ [API] Mascota con idUserPet: ${companionWithRealStats.displayName} -> $idUserPet');
              
              if (idUserPet.isNotEmpty && idUserPet != 'unknown') {
                adoptedCompanions.add(companionWithRealStats);
              } else {
                debugPrint('⚠️ [API] idUserPet vacío para ${companionWithRealStats.displayName}');
              }
            } else {
              debugPrint('⚠️ [API] Companion no es CompanionModelWithPetId');
            }
            
          } catch (detailsError) {
            debugPrint('⚠️ [API] Error obteniendo detalles de $petId: $detailsError');
            // 🔥 CREAR COMPANION BÁSICO SI FALLA getPetDetails
            final basicCompanion = _createBasicCompanionFromUserPet(petData);
            if (basicCompanion != null) {
              adoptedCompanions.add(basicCompanion);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [API] Error mapeando mascota $i: $e');
      }
    }

    debugPrint('✅ [API] === MASCOTAS USUARIO CON idUserPet PROCESADAS ===');
    debugPrint('🏠 [API] Total mascotas del usuario: ${adoptedCompanions.length}');

    // Debug de todos los idUserPet
    for (int i = 0; i < adoptedCompanions.length; i++) {
      final companion = adoptedCompanions[i];
      if (companion is CompanionModelWithPetId) {
        debugPrint('[$i] ${companion.displayName} -> idUserPet: ${companion.petId}');
      }
    }

    // Marcar todas como poseídas y asegurar una activa
    for (int i = 0; i < adoptedCompanions.length; i++) {
      adoptedCompanions[i] = adoptedCompanions[i].copyWith(
        isOwned: true,
        isSelected: i == 0,
      );
    }

    return adoptedCompanions;
  } catch (e) {
    debugPrint('❌ [API] Error obteniendo mascotas usuario: $e');
    return [];
  }
}

// 🔥 MÉTODO HELPER PARA CREAR COMPANION BÁSICO
CompanionModel? _createBasicCompanionFromUserPet(Map<String, dynamic> petData) {
  try {
    // Si el endpoint de getUserCompanions ya incluye el idUserPet, usarlo directamente
    final idUserPet = petData['idUserPet'] as String? ?? 
                     petData['id_user_pet'] as String? ?? 
                     petData['user_pet_id'] as String?;
    
    if (idUserPet == null || idUserPet.isEmpty) {
      debugPrint('⚠️ [API] No se encontró idUserPet en datos básicos');
      return null;
    }
    
    final name = petData['name'] as String? ?? 'Mi Mascota';
    final speciesType = petData['species_type'] as String? ?? 'mammal';
    
    debugPrint('🔧 [API] Creando companion básico con idUserPet: $idUserPet');
    
    return CompanionModelWithPetId(
      id: '${speciesType}_basic',
      type: _mapSpeciesTypeToCompanionType(name),
      stage: CompanionStage.young,
      name: name,
      description: 'Mascota básica',
      level: 1,
      experience: 0,
      happiness: 75, // Stats por defecto
      hunger: 80,
      energy: 100,
      isOwned: true,
      isSelected: false,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
      petId: idUserPet, // 🔥 EL idUserPet CRÍTICO
    );
  } catch (e) {
    debugPrint('❌ [API] Error creando companion básico: $e');
    return null;
  }
}

// 🔥 MÉTODO HELPER PARA EXTRAER PET ID
String? _extractApiPetIdFromCompanion(CompanionModel companion) {
  if (companion is CompanionModelWithPetId) {
    return companion.petId;
  }
  if (companion is CompanionModel) {
    try {
      final json = companion.toJson();
      return json['petId'] as String?;
    } catch (e) {
      return null;
    }
  }
  return null;
}
  // ==================== 🔥 REDUCIR ESTADÍSTICAS VIA API ====================
  @override
  Future<CompanionModel> decreasePetStats({
    required String idUserPet,
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📉 [API] === REDUCIENDO STATS VIA API REAL ===');
      debugPrint('🆔 [API] Pet ID: $idUserPet');
      debugPrint('😢 [API] Reducir felicidad: ${happiness ?? 0}');
      debugPrint('🩹 [API] Reducir salud: ${health ?? 0}');

      final endpoint = '/api/gamification/pet-stats/$idUserPet/decrease';
      final requestBody = <String, dynamic>{};
      
      if (happiness != null) requestBody['happiness'] = happiness;
      if (health != null) requestBody['health'] = health;

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Decrease stats response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Reducción de stats exitosa');
        
        // 🔥 OBTENER ESTADÍSTICAS ACTUALIZADAS DESDE EL ENDPOINT DE DETALLES
        final userId = await tokenManager.getUserId();
        if (userId != null) {
          debugPrint('🔄 [API] Obteniendo stats actualizadas desde pet details...');
          return await getPetDetails(petId: idUserPet, userId: userId);
        } else {
          // Fallback: crear companion desde respuesta
          return _createCompanionFromStatsResponse(idUserPet, response.data);
        }
      } else {
        throw ServerException(
            'Error reduciendo stats: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error reduciendo stats: $e');
      
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('not found') || errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada');
      } else if (errorMessage.contains('minimum') || errorMessage.contains('límite')) {
        throw ServerException('📊 Las estadísticas ya están en el mínimo permitido');
      } else {
        throw ServerException('❌ Error reduciendo estadísticas de la mascota');
      }
    }
  }


  // ==================== MASCOTAS DISPONIBLES PARA ADOPTAR ====================
    @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🌐 [API] Obteniendo mascotas disponibles...');

      final response = await apiClient.getGamification(
        '/api/gamification/pets/available',
        requireAuth: false,
      );

      debugPrint('✅ [API] Mascotas disponibles obtenidas: ${response.statusCode}');

      if (response.data == null || response.data is! List) {
        debugPrint('⚠️ [API] Respuesta vacía o inválida');
        return _getDefaultAvailableCompanions();
      }

      final List<dynamic> petsData = response.data;
      final allCompanions = <CompanionModel>[];

      for (final petJson in petsData) {
        try {
          final apiPet = ApiPetResponseModel.fromJson(petJson);
          final companions = apiPet.toCompanionModels();
          allCompanions.addAll(companions);
        } catch (e) {
          debugPrint('❌ [API] Error procesando pet: $e');
        }
      }

      return allCompanions;
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo mascotas disponibles: $e');
      return _getDefaultAvailableCompanions();
    }
  }

  

  

  // ==================== 🆕 PUNTOS REALES DEL USUARIO ====================
  @override
  Future<int> getUserPoints(String userId) async {
    try {
      debugPrint('💰 [API] Obteniendo puntos del usuario: $userId');

      final response = await apiClient.getGamification(
        '/api/gamification/quiz-points/$userId',
        requireAuth: true,
      );

      debugPrint('✅ [API] Respuesta puntos: ${response.statusCode}');
      debugPrint('📄 [API] Data completa: ${response.data}');

      if (response.data == null) {
        debugPrint('⚠️ [API] Respuesta de puntos vacía');
        return 0;
      }

      int points = 0;

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        points = (data['available_quiz_points'] ?? 0).toInt();
        debugPrint('💰 [API] available_quiz_points: ${data['available_quiz_points']}');
        debugPrint('💰 [API] total_quiz_points: ${data['total_quiz_points']}');
        debugPrint('💰 [API] spent_quiz_points: ${data['spent_quiz_points']}');
      } else if (response.data is int) {
        points = response.data as int;
      } else if (response.data is String) {
        points = int.tryParse(response.data as String) ?? 0;
      } else {
        debugPrint('⚠️ [API] Tipo de respuesta inesperado: ${response.data.runtimeType}');
        debugPrint('📄 [API] Valor: ${response.data}');
      }

      debugPrint('💰 [API] PUNTOS FINALES EXTRAÍDOS: $points');
      return points;
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error obteniendo puntos: $e');
      debugPrint('📍 [API] StackTrace: $stackTrace');
      debugPrint('🔧 [API] Usando puntos de prueba: 9400');
      return 9400;
    }
  }

  // ==================== TIENDA (MASCOTAS DISPONIBLES - NO ADOPTADAS) ====================
  @override
Future<List<CompanionModel>> getStoreCompanions({required String userId}) async {
  try {
    debugPrint('🏪 [API] === OBTENIENDO TIENDA REAL SIN DATOS LOCALES ===');
    debugPrint('👤 [API] Usuario: $userId');

    if (userId.isEmpty) {
      debugPrint('❌ [API] User ID vacío, no se puede obtener tienda');
      throw Exception('User ID requerido para obtener tienda');
    }

    // 🔥 1. OBTENER TODAS LAS MASCOTAS DISPONIBLES DE LA API
    debugPrint('📡 [API] Obteniendo mascotas disponibles...');
    final allCompanions = await getAvailableCompanions();
    debugPrint('✅ [API] Mascotas disponibles desde API: ${allCompanions.length}');

    // 🔥 2. OBTENER MASCOTAS YA ADOPTADAS POR EL USUARIO
    debugPrint('📡 [API] Obteniendo mascotas del usuario...');
    final userCompanions = await getUserCompanions(userId);
    debugPrint('✅ [API] Mascotas del usuario: ${userCompanions.length}');

    // 🔥 3. CREAR SET DE IDs YA ADOPTADOS PARA FILTRAR
    final adoptedIds = <String>{};
    final adoptedLocalIds = <String>{};
    
    for (final companion in userCompanions) {
      // Agregar tanto el Pet ID como el ID local
      if (companion is CompanionModelWithPetId) {
        adoptedIds.add(companion.petId);
      }
      adoptedLocalIds.add(companion.id);
      
      final localId = '${companion.type.name}_${companion.stage.name}';
      adoptedLocalIds.add(localId);
      
      debugPrint('🔍 [API] Mascota adoptada: ${companion.displayName} (${companion.id})');
    }
    
    debugPrint('🔍 [API] IDs adoptados: $adoptedIds');
    debugPrint('🔍 [API] IDs locales adoptados: $adoptedLocalIds');

    // 🔥 4. MARCAR MASCOTAS COMO ADOPTADAS O DISPONIBLES
    final storeCompanions = <CompanionModel>[];
    
    for (final companion in allCompanions) {
      // Verificar si ya está adoptada
      bool isAdopted = false;
      
      // Verificar por Pet ID si es CompanionModelWithPetId
      if (companion is CompanionModelWithPetId) {
        isAdopted = adoptedIds.contains(companion.petId);
      }
      
      // También verificar por ID local
      if (!isAdopted) {
        isAdopted = adoptedLocalIds.contains(companion.id);
      }
      
      // Marcar correctamente el estado
      final companionForStore = companion.copyWith(
        isOwned: isAdopted,
        isSelected: false, // Ninguna está seleccionada en la tienda
      );
      
      storeCompanions.add(companionForStore);
      
      final status = isAdopted ? "YA ADOPTADA" : "DISPONIBLE";
      debugPrint('🏪 [API] ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★ ($status)');
    }

    // 🔥 5. ORDENAR: Disponibles primero, luego por precio
    storeCompanions.sort((a, b) {
      // Primero por disponibilidad (disponibles primero)
      if (a.isOwned != b.isOwned) {
        return a.isOwned ? 1 : -1; // Disponibles (false) primero
      }
      
      // Luego por precio (más baratos primero)
      return a.purchasePrice.compareTo(b.purchasePrice);
    });

    debugPrint('🛍️ [API] === TIENDA FINAL (SOLO API) ===');
    debugPrint('🛒 [API] Total mascotas en tienda: ${storeCompanions.length}');

    for (final companion in storeCompanions) {
      final status = companion.isOwned ? "YA TIENES" : "DISPONIBLE";
      debugPrint('🏪 [API] ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★ ($status)');
    }

    return storeCompanions;
    
  } catch (e) {
    debugPrint('❌ [API] Error obteniendo tienda: $e');
    throw ServerException('Error obteniendo tienda: ${e.toString()}');
  }
}

  // ==================== 🔥 ADOPCIÓN CON MANEJO MEJORADO DE ERRORES ====================
  @override
  Future<CompanionModel> adoptCompanion({
    required String userId,
    required String petId,
    String? nickname,
  }) async {
    try {
      debugPrint('🐾 [API] === INICIANDO ADOPCIÓN ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID (desde tienda): $petId');
      debugPrint('🏷️ [API] Nickname: ${nickname ?? "Sin nickname"}');

      final endpoint = '/api/gamification/pets/$userId/adopt';
      final requestBody = {
        'petId': petId,
        'nickname': nickname ?? 'Mi compañero',
      };

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Adopción response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      // Manejar correctamente los códigos de éxito
      if (response.statusCode == 204 ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        debugPrint('🎉 [API] Adopción exitosa (código ${response.statusCode})');

        // 🔥 CREAR COMPANION CON NOMBRE REAL DE LA RESPUESTA
        final adoptedCompanion = _createAdoptedCompanionFromResponse(
          petId,
          nickname ?? 'Mi compañero',
          response.data, // 🔥 PASAR LA RESPUESTA PARA EXTRAER EL NOMBRE REAL
        );

        debugPrint('✅ [API] Companion creado: ${adoptedCompanion.displayName}');
        return adoptedCompanion;
      } else {
        throw ServerException(
            'Error en adopción: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error en adopción: $e');

      // 🔥 MANEJO MEJORADO DE ERRORES ESPECÍFICOS CON MENSAJES CLAROS
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('already') ||
          errorMessage.contains('adoptada') ||
          errorMessage.contains('ya tienes') ||
          errorMessage.contains('duplicate') ||
          errorMessage.contains('409')) {
        throw ServerException('⚠️ Esta mascota ya fue adquirida');
      } else if (errorMessage.contains('insufficient') ||
          errorMessage.contains('puntos') ||
          errorMessage.contains('not enough') ||
          errorMessage.contains('400')) {
        throw ServerException('💰 No tienes suficientes puntos para esta adopción');
      } else if (errorMessage.contains('not found') ||
          errorMessage.contains('encontrada') ||
          errorMessage.contains('no existe') ||
          errorMessage.contains('404')) {
        throw ServerException('🔍 Esta mascota no está disponible');
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('authentication')) {
        throw ServerException('🔐 Error de autenticación. Por favor, reinicia sesión');
      } else if (errorMessage.contains('stage') ||
          errorMessage.contains('etapa') ||
          errorMessage.contains('evolution') ||
          errorMessage.contains('previous')) {
        throw ServerException('📈 Debes tener la etapa anterior antes de adoptar esta');
      } else {
        throw ServerException('❌ Error durante la adopción. Intenta de nuevo');
      }
    }
  }

  // ==================== 🔥 EVOLUCIÓN VIA API REAL - MEJORADA ====================
  @override
  Future<CompanionModel> evolvePetViaApi({
    required String userId, 
    required String petId
  }) async {
    try {
      debugPrint('🦋 [API] === INICIANDO EVOLUCIÓN VIA API REAL ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');

      final endpoint = '/api/gamification/pets/$userId/evolve';
      final requestBody = {'petId': petId};

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Evolución response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Evolución exitosa');
        
        // 🔥 CREAR COMPANION EVOLUCIONADO CON DATOS REALES DE LA RESPUESTA
        final evolvedCompanion = _createEvolvedCompanionFromResponse(petId, response.data);
        debugPrint('✅ [API] Companion evolucionado: ${evolvedCompanion.displayName}');
        return evolvedCompanion;
      } else {
        throw ServerException(
            'Error en evolución: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error en evolución: $e');
      
      // 🔥 MANEJO ESPECÍFICO DE ERRORES DE EVOLUCIÓN CON MENSAJES CLAROS
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('insufficient') ||
          errorMessage.contains('puntos') ||
          errorMessage.contains('not enough') ||
          errorMessage.contains('400')) {
        throw ServerException('💰 No tienes suficientes puntos para evolucionar');
      } else if (errorMessage.contains('max level') ||
          errorMessage.contains('maximum') ||
          errorMessage.contains('máximo') ||
          errorMessage.contains('adulto') ||
          errorMessage.contains('already')) {
        throw ServerException('🏆 Esta mascota ya está en su máxima evolución');
      } else if (errorMessage.contains('not found') ||
          errorMessage.contains('no encontrada') ||
          errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada en tu colección');
      } else if (errorMessage.contains('experience') ||
          errorMessage.contains('experiencia') ||
          errorMessage.contains('nivel') ||
          errorMessage.contains('requirements')) {
        throw ServerException('📊 Tu mascota necesita más experiencia para evolucionar');
      } else if (errorMessage.contains('stage') ||
          errorMessage.contains('etapa') ||
          errorMessage.contains('previous') ||
          errorMessage.contains('order')) {
        throw ServerException('📈 No se puede evolucionar desde esta etapa. Debes tener la etapa anterior');
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw ServerException('🔐 Error de autenticación. Reinicia sesión');
      } else {
        throw ServerException('❌ Error evolucionando mascota. Intenta de nuevo');
      }
    }
  }

  // ==================== 🔥 DESTACAR MASCOTA VIA API REAL - MEJORADA ====================
  @override
  Future<CompanionModel> featurePetViaApi({
    required String userId, 
    required String petId
  }) async {
    try {
      debugPrint('⭐ [API] === DESTACANDO MASCOTA VIA API REAL ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');

      final endpoint = '/api/gamification/pets/$userId/feature';
      final requestBody = {'petId': petId};

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Feature response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Feature exitoso');
        
        // 🔥 CREAR COMPANION DESTACADO
        final featuredCompanion = _createFeaturedCompanionFromResponse(petId, response.data);
        debugPrint('✅ [API] Companion destacado: ${featuredCompanion.displayName}');
        return featuredCompanion;
      } else {
        throw ServerException(
            'Error al destacar mascota: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error al destacar mascota: $e');
      
      // 🔥 MANEJO ESPECÍFICO DE ERRORES DE FEATURE CON MENSAJES CLAROS
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('not found') ||
          errorMessage.contains('no encontrada') ||
          errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada en tu colección');
      } else if (errorMessage.contains('already featured') ||
          errorMessage.contains('ya destacada') ||
          errorMessage.contains('already selected') ||
          errorMessage.contains('409')) {
        throw ServerException('⭐ Esta mascota ya está destacada');
      } else if (errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        throw ServerException('🔐 Error de autenticación. Reinicia sesión');
      } else {
        throw ServerException('❌ Error destacando mascota. Intenta de nuevo');
      }
    }
  }

  // ==================== 🆕 EVOLUCIÓN DE MASCOTA POSEÍDA ====================
  @override
  Future<CompanionModel> evolveOwnedPetViaApi({
    required String userId, 
    required String petId
  }) async {
    try {
      debugPrint('🦋 [API] === EVOLUCIONANDO MASCOTA POSEÍDA ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');

      final endpoint = '/api/gamification/pets/owned/$userId/$petId/evolve';
      final requestBody = <String, dynamic>{};

      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Evolución owned response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Evolución owned exitosa');
        
        final evolvedCompanion = _createEvolvedCompanionFromResponse(petId, response.data);
        debugPrint('✅ [API] Owned companion evolucionado: ${evolvedCompanion.displayName}');
        return evolvedCompanion;
      } else {
        throw ServerException(
            'Error en evolución owned: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error en evolución owned: $e');
      
      // 🔥 MISMO MANEJO DE ERRORES QUE EVOLUCIÓN NORMAL
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('insufficient') ||
          errorMessage.contains('puntos') ||
          errorMessage.contains('not enough')) {
        throw ServerException('💰 No tienes suficientes puntos para evolucionar');
      } else if (errorMessage.contains('max level') ||
          errorMessage.contains('maximum') ||
          errorMessage.contains('adulto')) {
        throw ServerException('🏆 Esta mascota ya está en su máxima evolución');
      } else if (errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada en tu colección');
      } else {
        throw ServerException('❌ Error evolucionando mascota poseída');
      }
    }
  }

  // ==================== 🆕 SELECCIONAR ETAPA VISUALIZADA ====================
  @override
  Future<CompanionModel> selectPetStageViaApi({
    required String userId, 
    required String petId, 
    required int stage
  }) async {
    try {
      debugPrint('🎭 [API] === SELECCIONANDO ETAPA VISUALIZADA ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');
      debugPrint('🎯 [API] Stage: $stage');

      final endpoint = '/api/gamification/pets/owned/$userId/$petId/selected-stage';
      final requestBody = {'stage': stage};

      debugPrint('📦 [API] Request body: $requestBody');
      debugPrint('🌐 [API] Endpoint: $endpoint');

      final response = await apiClient.patchGamification(
        endpoint,
        data: requestBody,
      );

      debugPrint('✅ [API] Select stage response: ${response.statusCode}');
      debugPrint('📄 [API] Response data: ${response.data}');

      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        debugPrint('🎉 [API] Selección de etapa exitosa');
        
        final updatedCompanion = _createCompanionWithSelectedStage(petId, stage, response.data);
        debugPrint('✅ [API] Companion con etapa seleccionada: ${updatedCompanion.displayName}');
        return updatedCompanion;
      } else {
        throw ServerException(
            'Error seleccionando etapa: código ${response.statusCode}, data: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [API] Error seleccionando etapa: $e');
      
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('not unlocked') ||
          errorMessage.contains('no desbloqueada') ||
          errorMessage.contains('403')) {
        throw ServerException('🔒 Esta etapa no está desbloqueada aún');
      } else if (errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        throw ServerException('🔍 Mascota no encontrada');
      } else {
        throw ServerException('❌ Error seleccionando etapa');
      }
    }
  }

  // ==================== ESTADÍSTICAS USANDO PUNTOS REALES ====================
  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [API] Calculando estadísticas...');

      final userCompanions = await getUserCompanions(userId);
      final userPoints = await getUserPoints(userId);
      final allCompanions = await getAvailableCompanions();

      final ownedCount = userCompanions.length;
      final totalCount = allCompanions.length;
      final activeCompanionId =
          userCompanions.isNotEmpty ? userCompanions.first.id : '';

      int spentPoints = 0;
      for (final companion in userCompanions) {
        spentPoints += companion.purchasePrice;
      }

      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: totalCount,
        ownedCompanions: ownedCount,
        totalPoints: userPoints + spentPoints,
        spentPoints: spentPoints,
        activeCompanionId: activeCompanionId,
        totalFeedCount: 0,
        totalLoveCount: 0,
        totalEvolutions: 0,
        lastActivity: DateTime.now(),
      );

      debugPrint('📊 [API] Stats: ${stats.ownedCompanions}/${stats.totalCompanions}, ${stats.availablePoints}★');
      return stats;
    } catch (e) {
      debugPrint('❌ [API] Error calculando stats: $e');
      throw ServerException('Error obteniendo estadísticas: ${e.toString()}');
    }
  }

  // ==================== MÉTODOS LEGACY (mantener compatibilidad) ====================
  @override
  Future<CompanionModel> evolvePet({required String userId, required String petId}) async {
    // Redirigir al método de API real
    return evolvePetViaApi(userId: userId, petId: petId);
  }

  @override
  Future<CompanionModel> featurePet({required String userId, required String petId}) async {
    // Redirigir al método de API real
    return featurePetViaApi(userId: userId, petId: petId);
  }



/// Aumentar felicidad y/o salud de una mascota
  // ==================== 🔧 MÉTODOS HELPER MEJORADOS ====================

  /// 🔥 CREAR COMPANION ADOPTADO CON NOMBRE REAL DE LA RESPUESTA
  CompanionModel _createAdoptedCompanionFromResponse(
    String petId, 
    String fallbackNickname, 
    dynamic responseData
  ) {
    debugPrint('🐾 [ADOPTION] Creando companion adoptado para petId: $petId');
    debugPrint('📄 [ADOPTION] Response data: $responseData');

    // 🔥 EXTRAER NOMBRE REAL DE LA RESPUESTA DE LA API
    String realName = fallbackNickname;
    
    if (responseData is Map<String, dynamic>) {
      // Intentar extraer el nombre real de diferentes campos posibles
      realName = responseData['name'] as String? ??
                 responseData['pet_name'] as String? ??
                 responseData['nickname'] as String? ??
                 responseData['display_name'] as String? ??
                 fallbackNickname;
                 
      debugPrint('✅ [ADOPTION] Nombre extraído de respuesta: $realName');
    } else {
      debugPrint('⚠️ [ADOPTION] Respuesta no es Map, usando fallback: $fallbackNickname');
    }

    final companionType = _mapPetIdToCompanionType(petId);
    final companionStage = _mapPetIdToCompanionStage(petId);

    final localId = '${companionType.name}_${companionStage.name}';
    debugPrint('🆔 [ADOPTION] Local ID generado: $localId, Pet ID preservado: $petId');

    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: realName, // 🔥 USAR NOMBRE REAL
      description: _generateDescription(companionType, companionStage),
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: false,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
      petId: petId, // Preservar Pet ID original
    );
  }

    CompanionType _mapSpeciesTypeToCompanionType(String speciesType) {
    switch (speciesType.toLowerCase()) {
      case 'dog':
      case 'chihuahua':
      case 'mammal':
        return CompanionType.dexter;
      case 'panda':
        return CompanionType.elly;
      case 'axolotl':
      case 'ajolote':
      case 'amphibian':
        return CompanionType.paxolotl;
      case 'jaguar':
      case 'felino':
        return CompanionType.yami;
      default:
        debugPrint('⚠️ [MAPPING] Species type no reconocido: $speciesType');
        return CompanionType.dexter;
    }
  }

  /// Mapear evolution stage number a companion stage
  CompanionStage _mapEvolutionStageToCompanionStage(int evolutionStage) {
    switch (evolutionStage) {
      case 1:
        return CompanionStage.baby;
      case 2:
        return CompanionStage.young;
      case 3:
      case 4: // Por si hay más etapas
        return CompanionStage.adult;
      default:
        debugPrint('⚠️ [MAPPING] Evolution stage no reconocido: $evolutionStage');
        return CompanionStage.baby;
    }
  }

  /// Determinar mood basado en estadísticas reales
  CompanionMood _determineMoodFromStats(int happiness, int health) {
    if (happiness >= 80 && health >= 80) {
      return CompanionMood.excited;
    } else if (happiness >= 60 && health >= 60) {
      return CompanionMood.happy;
    } else if (happiness <= 30 || health <= 30) {
      return CompanionMood.sad;
    } else if (health <= 40) {
      return CompanionMood.hungry;
    } else {
      return CompanionMood.normal;
    }
  }

  /// Obtener precio de evolución para etapa
  int _getEvolutionPriceForStage(int evolutionStage) {
    switch (evolutionStage) {
      case 1:
        return 50;
      case 2:
        return 100;
      case 3:
        return 0; // Ya es la etapa máxima
      default:
        return 50;
    }
  }

  /// Obtener animaciones para etapa
  List<String> _getAnimationsForStage(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return ['idle', 'blink', 'happy'];
      case CompanionStage.young:
        return ['idle', 'blink', 'happy', 'eating'];
      case CompanionStage.adult:
        return ['idle', 'blink', 'happy', 'eating', 'loving', 'excited'];
    }
  }


  CompanionModel _createEvolvedCompanionFromResponse(String petId, dynamic responseData) {
    debugPrint('🦋 [EVOLUTION] Creando companion evolucionado para petId: $petId');
    debugPrint('📄 [EVOLUTION] Response data: $responseData');

    final companionType = _mapPetIdToCompanionType(petId);
    var companionStage = _mapPetIdToCompanionStage(petId);

    // 🔥 EXTRAER INFORMACIÓN DE EVOLUCIÓN DE LA RESPUESTA
    String realName = _getDisplayName(companionType);
    int newLevel = 2;
    
    if (responseData is Map<String, dynamic>) {
      realName = responseData['name'] as String? ??
                 responseData['pet_name'] as String? ??
                 responseData['nickname'] as String? ??
                 realName;
                 
      newLevel = responseData['level'] as int? ??
                 responseData['new_level'] as int? ??
                 newLevel;
                 
      // Intentar extraer nueva etapa de la respuesta
      final newStageStr = responseData['stage'] as String? ??
                         responseData['new_stage'] as String? ??
                         responseData['evolution_stage'] as String?;
                         
      if (newStageStr != null) {
        companionStage = _mapStringToCompanionStage(newStageStr);
      } else {
        // Evolucionar a la siguiente etapa manualmente
        switch (companionStage) {
          case CompanionStage.baby:
            companionStage = CompanionStage.young;
            break;
          case CompanionStage.young:
            companionStage = CompanionStage.adult;
            break;
          case CompanionStage.adult:
            // Ya está al máximo
            break;
        }
      }
      
      debugPrint('✅ [EVOLUTION] Datos extraídos - Nombre: $realName, Nivel: $newLevel, Etapa: ${companionStage.name}');
    }

    final localId = '${companionType.name}_${companionStage.name}';
    debugPrint('🆔 [EVOLUTION] New local ID: $localId, preserving petId: $petId');

    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: realName, // 🔥 USAR NOMBRE REAL
      description: _generateDescription(companionType, companionStage),
      level: newLevel, // 🔥 USAR NIVEL REAL
      experience: 0, // Resetear experiencia
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: true,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.excited,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: ['idle', 'blink', 'happy', 'excited'],
      createdAt: DateTime.now(),
      petId: petId, // Preservar Pet ID original
    );
  }

  CompanionModel _createFeaturedCompanionFromResponse(String petId, dynamic responseData) {
    debugPrint('⭐ [FEATURE] Creando companion destacado para petId: $petId');
    debugPrint('📄 [FEATURE] Response data: $responseData');

    final companionType = _mapPetIdToCompanionType(petId);
    final companionStage = _mapPetIdToCompanionStage(petId);

    // 🔥 EXTRAER NOMBRE REAL DE LA RESPUESTA
    String realName = _getDisplayName(companionType);
    
    if (responseData is Map<String, dynamic>) {
      realName = responseData['name'] as String? ??
                 responseData['pet_name'] as String? ??
                 responseData['nickname'] as String? ??
                 realName;
      debugPrint('✅ [FEATURE] Nombre extraído: $realName');
    }

    final localId = '${companionType.name}_${companionStage.name}';
    debugPrint('🆔 [FEATURE] Local ID: $localId, preserving petId: $petId');

    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: realName, // 🔥 USAR NOMBRE REAL
      description: _generateDescription(companionType, companionStage),
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: true, // Destacado/Activo
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
      petId: petId, // Preservar Pet ID original
    );
  }

  CompanionModel _createCompanionWithSelectedStage(String petId, int stage, dynamic responseData) {
    debugPrint('🎭 [STAGE] Creando companion con etapa seleccionada: $stage');
    debugPrint('📄 [STAGE] Response data: $responseData');

    final companionType = _mapPetIdToCompanionType(petId);
    final companionStage = _mapIntToCompanionStage(stage);

    // 🔥 EXTRAER NOMBRE REAL
    String realName = _getDisplayName(companionType);
    
    if (responseData is Map<String, dynamic>) {
      realName = responseData['name'] as String? ??
                 responseData['pet_name'] as String? ??
                 responseData['nickname'] as String? ??
                 realName;
    }

    final localId = '${companionType.name}_${companionStage.name}';
    debugPrint('🆔 [STAGE] Local ID: $localId, stage: ${companionStage.name}');

    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: realName, // 🔥 USAR NOMBRE REAL
      description: _generateDescription(companionType, companionStage),
      level: _getLevelForStage(companionStage),
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: true,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: _getAnimationsForStage(companionStage),
      createdAt: DateTime.now(),
      petId: petId,
    );
  }

  /// Mapear Pet ID a CompanionType
  CompanionType _mapPetIdToCompanionType(String petId) {
    final petIdLower = petId.toLowerCase();

    if (petIdLower.contains('dexter') ||
        petIdLower.contains('dog') ||
        petIdLower.contains('chihuahua')) {
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || petIdLower.contains('panda')) {
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') ||
        petIdLower.contains('axolotl') ||
        petIdLower.contains('ajolote')) {
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || petIdLower.contains('jaguar')) {
      return CompanionType.yami;
    }

    debugPrint('⚠️ [MAPPING] Pet ID no reconocido: $petId, usando dexter por defecto');
    return CompanionType.dexter;
  }

  /// Mapear Pet ID a CompanionStage
  CompanionStage _mapPetIdToCompanionStage(String petId) {
    final petIdLower = petId.toLowerCase();

    if (petIdLower.contains('baby') || 
        petIdLower.contains('1') || 
        petIdLower.contains('peque')) {
      return CompanionStage.baby;
    } else if (petIdLower.contains('young') || 
               petIdLower.contains('2') || 
               petIdLower.contains('joven')) {
      return CompanionStage.young;
    } else if (petIdLower.contains('adult') || 
               petIdLower.contains('3') || 
               petIdLower.contains('adulto')) {
      return CompanionStage.adult;
    }

    debugPrint('⚠️ [MAPPING] Stage no reconocido en petId: $petId, usando baby por defecto');
    return CompanionStage.baby;
  }
 CompanionModel _createCompanionFromStatsResponse(String petId, dynamic responseData) {
    // [El método existente se mantiene igual]
    debugPrint('🔄 [API] === CREANDO COMPANION DESDE STATS RESPONSE ===');
    
    String realName = 'Mi Compañero';
    int happinessLevel = 50;
    int healthLevel = 50;
    
    if (responseData is Map<String, dynamic>) {
      realName = responseData['name'] as String? ?? realName;
      happinessLevel = (responseData['happiness_level'] as num?)?.toInt() ?? happinessLevel;
      healthLevel = (responseData['health_level'] as num?)?.toInt() ?? healthLevel;
    }

    final companionType = _mapPetIdToCompanionType(petId);
    final companionStage = _mapPetIdToCompanionStage(petId);
    final localId = '${companionType.name}_${companionStage.name}';

    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: realName,
      description: 'Mascota con estadísticas actualizadas',
      level: 1,
      experience: 0,
      happiness: happinessLevel,
      hunger: healthLevel,
      energy: 100,
      isOwned: true,
      isSelected: false,
      purchasedAt: DateTime.now(),
      currentMood: _determineMoodFromStats(happinessLevel, healthLevel),
      purchasePrice: 0,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
      petId: petId,
    );
  }

/// Determinar mood basado en las estadísticas

  /// 🔥 MAPEAR STRING A COMPANION STAGE (PARA RESPUESTAS DE LA API)
  CompanionStage _mapStringToCompanionStage(String stageStr) {
    final stageLower = stageStr.toLowerCase();
    
    if (stageLower.contains('baby') || 
        stageLower.contains('peque') ||
        stageLower == '1') {
      return CompanionStage.baby;
    } else if (stageLower.contains('young') || 
               stageLower.contains('joven') ||
               stageLower == '2') {
      return CompanionStage.young;
    } else if (stageLower.contains('adult') || 
               stageLower.contains('adulto') ||
               stageLower == '3') {
      return CompanionStage.adult;
    }
    
    debugPrint('⚠️ [MAPPING] Stage string no reconocido: $stageStr, usando baby');
    return CompanionStage.baby;
  }

  /// Mapear int a CompanionStage
  CompanionStage _mapIntToCompanionStage(int stage) {
    switch (stage) {
      case 1:
        return CompanionStage.baby;
      case 2:
        return CompanionStage.young;
      case 3:
        return CompanionStage.adult;
      default:
        debugPrint('⚠️ [MAPPING] Stage int desconocido: $stage, usando baby');
        return CompanionStage.baby;
    }
  }

  /// Actualizar método para mapear mascota adoptada preservando Pet ID
  CompanionModel _mapAdoptedPetToCompanion(Map<String, dynamic> adoptedPet) {
    debugPrint('🔄 [MAPPING] === MAPEANDO MASCOTA ADOPTADA CORREGIDO ===');
    debugPrint('📄 [MAPPING] Raw pet data: $adoptedPet');

    // Extraer Pet ID REAL de la respuesta de la API
    final realPetId = adoptedPet['id'] as String? ??
        adoptedPet['pet_id'] as String? ??
        adoptedPet['petId'] as String? ??
        'unknown_pet_id';

    debugPrint('🆔 [MAPPING] Real Pet ID from API: $realPetId');

    // Extraer campos básicos con múltiples opciones
    final name = adoptedPet['name'] as String? ??
        adoptedPet['nickname'] as String? ??
        'Mi Compañero';

    final speciesType = adoptedPet['species_type'] as String? ??
        adoptedPet['speciesType'] as String? ??
        adoptedPet['type'] as String? ??
        'mammal';

    final adoptedAt = adoptedPet['adopted_at'] as String? ??
        adoptedPet['adoptedAt'] as String? ??
        adoptedPet['created_at'] as String? ??
        adoptedPet['createdAt'] as String?;

    // Mapeo correcto por nombre de la mascota
    debugPrint('🔍 [MAPPING] Name from API: $name');
    debugPrint('🔍 [MAPPING] Species: $speciesType');
    
    final companionType = _mapNameToCompanionType(name);
    final companionStage = CompanionStage.young; // Por defecto young
    
    // Crear ID local consistente
    final localId = '${companionType.name}_${companionStage.name}';
    
    // Si es Paxoloth, corregir a Paxolotl
    final correctedName = name == 'Paxoloth' ? 'Paxolotl' : name;

    debugPrint('✅ [MAPPING] MAPEO CORREGIDO:');
    debugPrint('🔍 [MAPPING] Nombre original: $name -> Corregido: $correctedName');
    debugPrint('🔍 [MAPPING] Tipo detectado: ${companionType.name}');
    debugPrint('🔍 [MAPPING] ID local generado: $localId');
    debugPrint('🆔 [MAPPING] Pet ID preservado: $realPetId');

    // Usar CompanionModelWithPetId para preservar el Pet ID real
    return CompanionModelWithPetId(
      id: localId,
      type: companionType,
      stage: companionStage,
      name: correctedName,
      description: adoptedPet['description'] as String? ?? _generateDescription(companionType, companionStage),
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true, // Siempre true porque fue adoptada
      isSelected: false, // Por defecto no seleccionada
      purchasedAt: adoptedAt != null ? DateTime.tryParse(adoptedAt) ?? DateTime.now() : DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
      petId: realPetId, // Preservar el Pet ID real de la API
    );
  }
  
  /// Mapeo correcto por nombre de la mascota
 CompanionType _mapNameToCompanionType(String name) {
  final nameLower = name.toLowerCase();
  
  debugPrint('🔍 [NAME_MAPPING] Mapeando nombre: $name');
  
  if (nameLower.contains('dexter')) {
    debugPrint('✅ [NAME_MAPPING] -> CompanionType.dexter');
    return CompanionType.dexter;
  } else if (nameLower.contains('elly')) {
    debugPrint('✅ [NAME_MAPPING] -> CompanionType.elly');
    return CompanionType.elly;
  } else if (nameLower.contains('paxoloth') || nameLower.contains('paxolotl')) {
    debugPrint('✅ [NAME_MAPPING] -> CompanionType.paxolotl');
    return CompanionType.paxolotl;
  } else if (nameLower.contains('yami')) {
    debugPrint('✅ [NAME_MAPPING] -> CompanionType.yami');
    return CompanionType.yami;
  }
  
  // Fallback: Mapear por species_type si el nombre no coincide
  debugPrint('⚠️ [NAME_MAPPING] Nombre no reconocido, usando fallback');
  return CompanionType.dexter; // Por defecto
}
  /// Crear Dexter joven para la tienda
  CompanionModel _createDexterYoungForStore() {
    return CompanionModel(
      id: 'dexter_young',
      type: CompanionType.dexter,
      stage: CompanionStage.young,
      name: 'Dexter',
      description: 'Tu primer compañero gratuito',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

  // Métodos helper para precios y descripciones
  String _generateDescription(CompanionType type, CompanionStage stage) {
    final name = _getDisplayName(type);
    switch (stage) {
      case CompanionStage.baby:
        return 'Un adorable $name bebé lleno de energía';
      case CompanionStage.young:
        return '$name ha crecido y es más juguetón';
      case CompanionStage.adult:
        return '$name adulto, el compañero perfecto';
    }
  }

  String _getDisplayName(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return 'Dexter';
      case CompanionType.elly:
        return 'Elly';
      case CompanionType.paxolotl:
        return 'Paxolotl';
      case CompanionType.yami:
        return 'Yami';
    }
  }

  int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    int basePrice = 100;

    switch (type) {
      case CompanionType.dexter:
        basePrice = 0;
        break; // Gratis
      case CompanionType.elly:
        basePrice = 200;
        break;
      case CompanionType.paxolotl:
        basePrice = 600;
        break;
      case CompanionType.yami:
        basePrice = 2500;
        break;
    }

    switch (stage) {
      case CompanionStage.baby:
        return basePrice;
      case CompanionStage.young:
        return basePrice + 150;
      case CompanionStage.adult:
        return basePrice + 300;
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 50;
      case CompanionStage.young:
        return 100;
      case CompanionStage.adult:
        return 0;
    }
  }

  int _getLevelForStage(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 1;
      case CompanionStage.young:
        return 2;
      case CompanionStage.adult:
        return 3;
    }
  }

 

  // ==================== FALLBACK DATA ====================
  List<CompanionModel> _getDefaultAvailableCompanions() {
    debugPrint('🔧 [FALLBACK] Usando mascotas por defecto');

    final companions = <CompanionModel>[];
    final now = DateTime.now();

    // Dexter (gratis como inicial)
    companions.add(CompanionModel(
      id: 'dexter_baby',
      type: CompanionType.dexter,
      stage: CompanionStage.baby,
      name: 'Dexter',
      description: 'Un pequeño chihuahua mexicano',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));

    // Elly
    companions.add(CompanionModel(
      id: 'elly_baby',
      type: CompanionType.elly,
      stage: CompanionStage.baby,
      name: 'Elly',
      description: 'Una panda tierna y juguetona',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 200,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));

    // Paxolotl
    companions.add(CompanionModel(
      id: 'paxolotl_baby',
      type: CompanionType.paxolotl,
      stage: CompanionStage.baby,
      name: 'Paxolotl',
      description: 'Un ajolote amigable y curioso',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 600,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));

    // Yami
    companions.add(CompanionModel(
      id: 'yami_baby',
      type: CompanionType.yami,
      stage: CompanionStage.baby,
      name: 'Yami',
      description: 'Un jaguar misterioso y ágil',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 2500,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));

    return companions;
  }
}