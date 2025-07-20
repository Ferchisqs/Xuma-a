// lib/features/companion/data/datasources/companion_remote_datasource.dart - ACTUALIZADO
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
  Future<CompanionModel> adoptCompanion({required String userId, required String petId, String? nickname});
  Future<CompanionStatsModel> getCompanionStats(String userId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

  // ==================== 🆕 MÉTODO PRINCIPAL: MASCOTAS DISPONIBLES ====================
  
  @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🌐 [API] === OBTENIENDO MASCOTAS DISPONIBLES DESDE API REAL ===');
      debugPrint('🔗 [API] URL: https://gamification-service-production.up.railway.app/api/gamification/pets/available');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/available',
        requireAuth: false,
      );
      
      debugPrint('✅ [API] Respuesta recibida: ${response.statusCode}');
      debugPrint('📊 [API] Data type: ${response.data.runtimeType}');
      
      if (response.data == null || response.data is! List) {
        debugPrint('❌ [API] Respuesta inválida o vacía');
        return _getDefaultAvailableCompanions();
      }
      
      final List<dynamic> petsData = response.data;
      debugPrint('🐾 [API] Mascotas recibidas: ${petsData.length}');
      
      final allCompanions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        try {
          debugPrint('🔄 [API] Procesando pet: ${petJson['name']}');
          
          final apiPet = ApiPetResponseModel.fromJson(petJson);
          final companions = apiPet.toCompanionModels();
          
          debugPrint('✅ [API] ${apiPet.name}: ${companions.length} etapas creadas');
          
          allCompanions.addAll(companions);
          
        } catch (e) {
          debugPrint('❌ [API] Error procesando pet individual: $e');
          debugPrint('📊 [API] Pet data: $petJson');
        }
      }
      
      debugPrint('🎯 [API] Total companions generados: ${allCompanions.length}');
      
      // 🔧 ASEGURAR QUE DEXTER BABY ESTÉ MARCADO COMO INICIAL
      final dexterBaby = allCompanions.firstWhere(
        (c) => c.type == CompanionType.dexter && c.stage == CompanionStage.baby,
        orElse: () => _createInitialDexterBaby(),
      );
      
      if (!allCompanions.any((c) => c.id == dexterBaby.id)) {
        allCompanions.insert(0, dexterBaby);
        debugPrint('🔧 [API] Dexter baby agregado como inicial');
      }
      
      return allCompanions;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error conectando con API real: $e');
      debugPrint('📍 [API] StackTrace: $stackTrace');
      
      // Fallback a datos por defecto
      return _getDefaultAvailableCompanions();
    }
  }

  // ==================== 🆕 DETECTAR Y MOSTRAR DEXTER INICIAL ====================
  
  /// 🔧 MÉTODO PARA VERIFICAR SI ES LA PRIMERA VEZ DEL USUARIO
  Future<bool> isFirstTimeUser(String userId) async {
    try {
      debugPrint('🔍 [API] Verificando si es primera vez para usuario: $userId');
      
      final userPets = await getUserCompanions(userId);
      final hasAnyPet = userPets.isNotEmpty;
      
      debugPrint('🔍 [API] Usuario tiene mascotas: $hasAnyPet');
      return !hasAnyPet;
      
    } catch (e) {
      debugPrint('⚠️ [API] Error verificando primera vez, asumiendo que sí: $e');
      return true;
    }
  }

  /// 🔧 CREAR DEXTER BABY INICIAL
  CompanionModel _createInitialDexterBaby() {
    debugPrint('🐕 [API] Creando Dexter baby inicial');
    
    return CompanionModel(
      id: 'dexter_baby',
      type: CompanionType.dexter,
      stage: CompanionStage.baby,
      name: 'Dexter',
      description: 'Un pequeño chihuahua mexicano que enseña sobre el reciclaje y los hábitos urbanos sostenibles.',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true, // 🔧 MARCADO COMO POSEÍDO INICIALMENTE
      isSelected: true, // 🔧 ACTIVO POR DEFECTO
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔧 GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

  // ==================== TIENDA DE MASCOTAS ====================
  
  @override
  Future<List<CompanionModel>> getStoreCompanions({required String userId}) async {
    try {
      debugPrint('🏪 [API] === OBTENIENDO TIENDA DE MASCOTAS ===');
      debugPrint('👤 [API] User ID: $userId');
      
      // Obtener todas las mascotas disponibles
      final allCompanions = await getAvailableCompanions();
      
      // Filtrar para la tienda (excluir las ya poseídas y Dexter baby inicial)
      final storeCompanions = allCompanions.where((companion) {
        // No mostrar en tienda si ya está poseído
        if (companion.isOwned) return false;
        
        // No mostrar Dexter baby en la tienda (se da gratis)
        if (companion.type == CompanionType.dexter && companion.stage == CompanionStage.baby) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Ordenar por precio (más baratos primero)
      storeCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
      
      debugPrint('🛍️ [API] Mascotas en tienda: ${storeCompanions.length}');
      
      for (final companion in storeCompanions) {
        debugPrint('🏪 [API] - ${companion.displayName} (${companion.stageDisplayName}): ${companion.purchasePrice}★');
      }
      
      return storeCompanions;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error obteniendo tienda: $e');
      debugPrint('📍 [API] StackTrace: $stackTrace');
      throw ServerException('Error obteniendo tienda: ${e.toString()}');
    }
  }

  // ==================== MASCOTAS DEL USUARIO ====================
  
  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      debugPrint('👤 [API] === OBTENIENDO MASCOTAS DEL USUARIO ===');
      debugPrint('👤 [API] User ID: $userId');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/$userId',
        requireAuth: true,
      );
      
      debugPrint('✅ [API] Respuesta usuario: ${response.statusCode}');
      
      if (response.data == null || response.data is! List) {
        debugPrint('⚠️ [API] Usuario sin mascotas, creando Dexter inicial');
        final dexterInitial = _createInitialDexterBaby();
        return [dexterInitial];
      }
      
      final List<dynamic> petsData = response.data;
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        try {
          // Aquí mapearías las mascotas que el usuario YA tiene
          // Por ahora, crear Dexter inicial si no hay nada
        } catch (e) {
          debugPrint('❌ [API] Error procesando pet de usuario: $e');
        }
      }
      
      // 🔧 SIEMPRE ASEGURAR QUE TENGA DEXTER BABY
      if (companions.isEmpty) {
        final dexterInitial = _createInitialDexterBaby();
        companions.add(dexterInitial);
        debugPrint('🔧 [API] Dexter baby agregado como mascota inicial del usuario');
      }
      
      return companions;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error obteniendo mascotas usuario: $e');
      
      // Fallback: crear Dexter inicial
      final dexterInitial = _createInitialDexterBaby();
      return [dexterInitial];
    }
  }

 @override
 
  // ==================== ADOPTAR MASCOTA ====================
  
  @override
  Future<CompanionModel> adoptCompanion({
    required String userId, 
    required String petId,
    String? nickname,
  }) async {
    try {
      debugPrint('🐾 [API] === INICIANDO ADOPCIÓN REAL ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');
      debugPrint('🏷️ [API] Nickname: ${nickname ?? "Sin nickname"}');
      
      // 🔥 ENDPOINT CORRECTO BASADO EN TU CURL
      final endpoint = '/api/gamification/pets/$petId/adopt';
      debugPrint('🔗 [API] Endpoint: $endpoint');
      
      final requestBody = {
        'petId': petId,
        'nickname': nickname ?? 'Mi compañero',
      };
      
      debugPrint('📦 [API] Request body: $requestBody');
      
      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );
      
      debugPrint('✅ [API] Response status: ${response.statusCode}');
      debugPrint('📊 [API] Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔧 MAPEAR LA RESPUESTA DEL BACKEND A TU MODELO
        final adoptedCompanion = _mapApiResponseToCompanion(
          response.data, 
          petId, 
          nickname ?? 'Mi compañero'
        );
        
        debugPrint('🎉 [API] Adopción exitosa: ${adoptedCompanion.displayName}');
        return adoptedCompanion;
        
      } else {
        throw ServerException('Error en adopción: ${response.statusCode}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error en adopción: $e');
      debugPrint('📍 [API] StackTrace: $stackTrace');
      
      // 🔧 MANEJO DE ERRORES ESPECÍFICOS
      if (e.toString().contains('already adopted') || 
          e.toString().contains('ya adoptada')) {
        throw ServerException('Ya tienes esta mascota');
      } else if (e.toString().contains('insufficient') || 
                 e.toString().contains('insuficientes')) {
        throw ServerException('No tienes suficientes puntos');
      } else if (e.toString().contains('not found')) {
        throw ServerException('Mascota no encontrada');
      } else {
        throw ServerException('Error adoptando mascota: ${e.toString()}');
      }
    }
  }

  // 🔧 MAPEAR RESPUESTA DE LA API A TU MODELO INTERNO
  CompanionModel _mapApiResponseToCompanion(
    dynamic responseData, 
    String petId, 
    String nickname
  ) {
    try {
      debugPrint('🔄 [API] Mapeando respuesta a CompanionModel...');
      
      // 🔧 SEGÚN TU ESTRUCTURA, LA RESPUESTA PODRÍA SER:
      // { "success": true, "pet": { ... }, "userPoints": 1500 }
      // O simplemente: { "id": "...", "name": "...", ... }
      
      Map<String, dynamic> petData;
      
      if (responseData is Map<String, dynamic>) {
        // Si hay un campo 'pet' o 'data', usarlo
        if (responseData.containsKey('pet')) {
          petData = responseData['pet'] as Map<String, dynamic>;
        } else if (responseData.containsKey('data')) {
          petData = responseData['data'] as Map<String, dynamic>;
        } else {
          // La respuesta directa es el pet
          petData = responseData;
        }
      } else {
        throw Exception('Formato de respuesta inválido');
      }
      
      debugPrint('🔄 [API] Pet data extraído: $petData');
      
      // 🔧 MAPEAR A TU SISTEMA DE COMPANIONS
      final companionType = _mapPetIdToCompanionType(petId);
      final companionStage = _mapPetIdToCompanionStage(petId);
      
      final companion = CompanionModel(
        id: '${companionType.name}_${companionStage.name}',
        type: companionType,
        stage: companionStage,
        name: _getDisplayName(companionType),
        description: petData['description']?.toString() ?? 
                    _generateDescription(companionType, companionStage),
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔥 RECIÉN ADOPTADO
        isSelected: false,
        purchasedAt: DateTime.now(),
        currentMood: CompanionMood.happy,
        purchasePrice: petData['price']?.toInt() ?? 0,
        evolutionPrice: _getEvolutionPrice(companionStage),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );
      
      debugPrint('✅ [API] Companion mapeado: ${companion.displayName} (${companion.id})');
      return companion;
      
    } catch (e) {
      debugPrint('❌ [API] Error mapeando respuesta: $e');
      
      // 🔧 FALLBACK: Crear companion básico
      final companionType = _mapPetIdToCompanionType(petId);
      final companionStage = _mapPetIdToCompanionStage(petId);
      
      return CompanionModel(
        id: '${companionType.name}_${companionStage.name}',
        type: companionType,
        stage: companionStage,
        name: _getDisplayName(companionType),
        description: 'Mascota recién adoptada',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true,
        isSelected: false,
        purchasedAt: DateTime.now(),
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );
    }
  }

  // 🔧 MAPEAR PET ID DE LA API A TU SISTEMA DE TYPES
  CompanionType _mapPetIdToCompanionType(String petId) {
    // 🔧 AQUÍ NECESITAS DEFINIR CÓMO MAPEAR LOS IDs DE TU API
    // Ejemplo basado en patrones comunes:
    
    final petIdLower = petId.toLowerCase();
    
    if (petIdLower.contains('dexter') || 
        petIdLower.contains('dog') || 
        petIdLower.contains('chihuahua')) {
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || 
               petIdLower.contains('panda')) {
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') || 
               petIdLower.contains('axolotl') || 
               petIdLower.contains('ajolote')) {
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || 
               petIdLower.contains('jaguar')) {
      return CompanionType.yami;
    }
    
    // 🔧 POR DEFECTO DEXTER
    debugPrint('⚠️ [API] Pet ID no reconocido: $petId, usando Dexter por defecto');
    return CompanionType.dexter;
  }

  // 🔧 MAPEAR PET ID A ETAPA
  CompanionStage _mapPetIdToCompanionStage(String petId) {
    final petIdLower = petId.toLowerCase();
    
    if (petIdLower.contains('baby') || 
        petIdLower.contains('peque')) {
      return CompanionStage.baby;
    } else if (petIdLower.contains('young') || 
               petIdLower.contains('joven')) {
      return CompanionStage.young;
    } else if (petIdLower.contains('adult') || 
               petIdLower.contains('adulto')) {
      return CompanionStage.adult;
    }
    
    // 🔧 POR DEFECTO BABY
    return CompanionStage.baby;
  }

  // 🔧 MÉTODOS HELPER
  String _getDisplayName(CompanionType type) {
    switch (type) {
      case CompanionType.dexter: return 'Dexter';
      case CompanionType.elly: return 'Elly';
      case CompanionType.paxolotl: return 'Paxolotl';
      case CompanionType.yami: return 'Yami';
    }
  }

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

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 50;
      case CompanionStage.young: return 100;
      case CompanionStage.adult: return 0;
    }
  }
  // ==================== ESTADÍSTICAS ====================
  
  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [API] === OBTENIENDO ESTADÍSTICAS ===');
      
      // Obtener mascotas del usuario para calcular stats
      final userCompanions = await getUserCompanions(userId);
      final ownedCount = userCompanions.where((c) => c.isOwned).length;
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: 12, // Basado en tu API: 3 especies × 4 etapas aprox
        ownedCompanions: ownedCount,
        totalPoints: 1500, // 🔧 PUNTOS GENEROSOS PARA TESTING
        spentPoints: 0,
        activeCompanionId: userCompanions.isNotEmpty ? userCompanions.first.id : 'dexter_baby',
        totalFeedCount: 0,
        totalLoveCount: 0,
        totalEvolutions: 0,
        lastActivity: DateTime.now(),
      );
      
      debugPrint('📊 [API] Stats calculados: ${stats.ownedCompanions}/${stats.totalCompanions}');
      return stats;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API] Error obteniendo stats: $e');
      throw ServerException('Error obteniendo estadísticas: ${e.toString()}');
    }
  }

  // ==================== FALLBACK METHODS ====================

  /// Obtener mascotas disponibles por defecto si la API falla
  List<CompanionModel> _getDefaultAvailableCompanions() {
    debugPrint('🔧 [FALLBACK] Creando mascotas disponibles por defecto');
    
    final companions = <CompanionModel>[];
    final now = DateTime.now();
    
    // Dexter (todas las etapas)
    companions.addAll([
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un pequeño chihuahua mexicano que enseña sobre el reciclaje y los hábitos urbanos sostenibles.',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔧 INICIAL GRATIS
        isSelected: true,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_young',
        type: CompanionType.dexter,
        stage: CompanionStage.young,
        name: 'Dexter',
        description: 'Dexter ha crecido y es más juguetón',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 150,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'happy', 'eating'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_adult',
        type: CompanionType.dexter,
        stage: CompanionStage.adult,
        name: 'Dexter',
        description: 'Dexter adulto, el compañero perfecto',
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
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
        createdAt: now,
      ),
    ]);
    
    // Paxolotl (todas las etapas)
    companions.addAll([
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un anfibio mexicano en peligro de extinción que enseña sobre la conservación de ecosistemas acuáticos.',
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
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_young',
        type: CompanionType.paxolotl,
        stage: CompanionStage.young,
        name: 'Paxolotl',
        description: 'Paxolotl joven, guardián de Xochimilco',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 900,
        evolutionPrice: 200,
        unlockedAnimations: ['idle', 'blink', 'happy', 'swimming'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_adult',
        type: CompanionType.paxolotl,
        stage: CompanionStage.adult,
        name: 'Paxolotl',
        description: 'Paxolotl adulto, maestro de la regeneración',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 1200,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'swimming', 'regenerating'],
        createdAt: now,
      ),
    ]);
    
    // Yami (todas las etapas)
    companions.addAll([
      CompanionModel(
        id: 'yami_baby',
        type: CompanionType.yami,
        stage: CompanionStage.baby,
        name: 'Yami',
        description: 'Un jaguar sigiloso que representa la riqueza de la biodiversidad mexicana en la selva.',
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
        evolutionPrice: 300,
        unlockedAnimations: ['idle', 'blink', 'prowling'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_young',
        type: CompanionType.yami,
        stage: CompanionStage.young,
        name: 'Yami',
        description: 'Yami joven, cazador de la selva',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 3750,
        evolutionPrice: 500,
        unlockedAnimations: ['idle', 'blink', 'prowling', 'hunting'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_adult',
        type: CompanionType.yami,
        stage: CompanionStage.adult,
        name: 'Yami',
        description: 'Yami adulto, rey de la selva mexicana',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 5000,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'prowling', 'hunting', 'roaring'],
        createdAt: now,
      ),
    ]);
    
    debugPrint('🔧 [FALLBACK] Creadas ${companions.length} mascotas por defecto');
    return companions;
  }
}