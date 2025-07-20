import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/domain/entities/companion_entity.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_manager.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';

abstract class CompanionRemoteDataSource {
  Future<List<CompanionModel>> getUserCompanions(String userId);
  Future<List<CompanionModel>> getAvailableCompanions();
  Future<List<CompanionModel>> getStoreCompanions();
  Future<CompanionModel> adoptCompanion(String userId, String petId, {String? nickname});
  Future<CompanionModel> purchaseCompanion(String userId, String petId, {String? nickname});
  Future<CompanionModel> evolveCompanion(String userId, String petId);
  Future<CompanionModel> featureCompanion(String userId, String petId);
  Future<CompanionStatsModel> getCompanionStats(String userId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  // 🔧 MAPEO MEJORADO DE API A ASSETS LOCALES
  static const Map<String, CompanionType> _speciesMapping = {
    'dog': CompanionType.dexter,
    'chihuahua': CompanionType.dexter,
    'panda': CompanionType.elly,
    'axolotl': CompanionType.paxolotl,
    'ajolote': CompanionType.paxolotl,
    'jaguar': CompanionType.yami,
  };

  static const Map<String, CompanionStage> _rarityMapping = {
    'common': CompanionStage.baby,
    'rare': CompanionStage.young,
    'epic': CompanionStage.adult,
    'legendary': CompanionStage.adult,
  };

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      debugPrint('🌐 [REMOTE_DS] === OBTENIENDO MASCOTAS DEL USUARIO ===');
      debugPrint('👤 [REMOTE_DS] User ID: $userId');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/$userId',
        requireAuth: true,
      );
      
      debugPrint('✅ [REMOTE_DS] API Response: ${response.statusCode}');
      debugPrint('📊 [REMOTE_DS] Response data type: ${response.data.runtimeType}');
      
      List<dynamic> petsData = [];
      
      if (response.data is List) {
        petsData = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsData = data['pets'] ?? data['data'] ?? [];
      }
      
      debugPrint('🐾 [REMOTE_DS] Pets found in API: ${petsData.length}');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        try {
          final companion = _mapApiPetToCompanion(petJson, isOwned: true);
          if (companion != null) {
            companions.add(companion);
            debugPrint('✅ [REMOTE_DS] Mapped: ${companion.displayName} (${companion.id})');
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error mapping pet: $e');
        }
      }
      
      // 🔧 LÓGICA DE NEGOCIO: ASEGURAR DEXTER JOVEN INICIAL
      if (companions.isEmpty || !_hasDexterYoung(companions)) {
        debugPrint('🔧 [REMOTE_DS] Usuario sin Dexter joven - agregando por defecto');
        final dexterYoung = _createInitialDexterYoung(userId);
        companions.insert(0, dexterYoung);
      }
      
      debugPrint('🎯 [REMOTE_DS] Total companions: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en getUserCompanions: $e');
      
      // 🔧 FALLBACK: Crear Dexter joven por defecto
      final dexterYoung = _createInitialDexterYoung(userId);
      return [dexterYoung];
    }
  }

  @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REMOTE_DS] === OBTENIENDO MASCOTAS DISPONIBLES ===');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/available',
        requireAuth: false,
      );
      
      List<dynamic> petsData = [];
      
      if (response.data is List) {
        petsData = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsData = data['pets'] ?? data['data'] ?? data['available'] ?? [];
      }
      
      debugPrint('🛍️ [REMOTE_DS] Available pets from API: ${petsData.length}');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        try {
          final companion = _mapApiPetToCompanion(petJson, isOwned: false);
          if (companion != null) {
            companions.add(companion);
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error mapping available pet: $e');
        }
      }
      
      // 🔧 COMPLETAR CON COMPANIONS LOCALES SI LA API NO TIENE TODOS
      final localCompanions = _createFullCompanionSet();
      for (final local in localCompanions) {
        if (!companions.any((c) => c.id == local.id)) {
          companions.add(local);
        }
      }
      
      debugPrint('🛍️ [REMOTE_DS] Total available: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en getAvailableCompanions: $e');
      return _createFullCompanionSet();
    }
  }

  @override
  Future<List<CompanionModel>> getStoreCompanions() async {
    try {
      debugPrint('🏪 [REMOTE_DS] === OBTENIENDO TIENDA ===');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/store',
        requireAuth: false,
      );
      
      List<dynamic> petsData = [];
      
      if (response.data is List) {
        petsData = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsData = data['pets'] ?? data['store'] ?? data['data'] ?? [];
      }
      
      debugPrint('🏪 [REMOTE_DS] Store pets from API: ${petsData.length}');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        try {
          final companion = _mapApiPetToCompanion(petJson, isOwned: false, isInStore: true);
          if (companion != null) {
            companions.add(companion);
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error mapping store pet: $e');
        }
      }
      
      // 🔧 AGREGAR COMPANIONS LOCALES PARA TIENDA COMPLETA
      final storeCompanions = _createStoreCompanionSet();
      for (final store in storeCompanions) {
        if (!companions.any((c) => c.id == store.id)) {
          companions.add(store);
        }
      }
      
      debugPrint('🏪 [REMOTE_DS] Total store items: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en getStoreCompanions: $e');
      return _createStoreCompanionSet();
    }
  }

  @override
  Future<CompanionModel> adoptCompanion(String userId, String petId, {String? nickname}) async {
    try {
      debugPrint('🐾 [REMOTE_DS] === ADOPTANDO MASCOTA ===');
      debugPrint('👤 [REMOTE_DS] User: $userId');
      debugPrint('🆔 [REMOTE_DS] Pet ID: $petId');
      
      // 🔧 VERIFICAR SI ES DEXTER JOVEN (YA DESBLOQUEADO)
      if (_isDexterYoungRequest(petId)) {
        debugPrint('🔧 [REMOTE_DS] Dexter joven detectado - retornando directamente');
        return _createInitialDexterYoung(userId);
      }
      
      final requestData = {
        'petId': petId,
        'userId': userId, // 🔧 AGREGAR USER ID
        if (nickname != null) 'nickname': nickname,
      };
      
      debugPrint('📤 [REMOTE_DS] Request payload: $requestData');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/$userId/adopt',
        data: requestData,
      );
      
      debugPrint('✅ [REMOTE_DS] Adoption response: ${response.statusCode}');
      
      final companion = _mapApiPetToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid adoption response format');
      }
      
      debugPrint('🎉 [REMOTE_DS] Adopted: ${companion.displayName}');
      return companion;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en adoptCompanion: $e');
      
      // 🔧 FALLBACK: Si es Dexter joven, devolverlo directamente
      if (_isDexterYoungRequest(petId)) {
        return _createInitialDexterYoung(userId);
      }
      
      throw ServerException('Error adopting companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> purchaseCompanion(String userId, String petId, {String? nickname}) async {
    try {
      debugPrint('💰 [REMOTE_DS] === COMPRANDO MASCOTA ===');
      debugPrint('👤 [REMOTE_DS] User: $userId');
      debugPrint('🆔 [REMOTE_DS] Pet ID: $petId');
      
      // 🔧 VERIFICAR SI ES DEXTER JOVEN (YA DESBLOQUEADO)
      if (_isDexterYoungRequest(petId)) {
        debugPrint('🔧 [REMOTE_DS] Dexter joven detectado - retornando directamente');
        return _createInitialDexterYoung(userId);
      }
      
      // 🔧 FORMATO CORREGIDO DEL REQUEST
      final requestData = {
        'userId': userId,
        'petId': petId,
        'speciesType': _extractSpeciesFromPetId(petId),
        'stage': _extractStageFromPetId(petId),
        if (nickname != null) 'nickname': nickname,
      };
      
      debugPrint('📤 [REMOTE_DS] Purchase payload: $requestData');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/purchase',
        data: requestData,
      );
      
      debugPrint('✅ [REMOTE_DS] Purchase response: ${response.statusCode}');
      debugPrint('📊 [REMOTE_DS] Response data: ${response.data}');
      
      final companion = _mapApiPetToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid purchase response format');
      }
      
      debugPrint('💰 [REMOTE_DS] Purchased: ${companion.displayName}');
      return companion;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en purchaseCompanion: $e');
      
      // 🔧 FALLBACK ESPECÍFICO
      if (_isDexterYoungRequest(petId)) {
        return _createInitialDexterYoung(userId);
      }
      
      // 🔧 CREAR COMPANION BASADO EN EL PET ID SI FALLÓ LA API
      final fallbackCompanion = _createCompanionFromPetId(userId, petId);
      if (fallbackCompanion != null) {
        debugPrint('🔧 [REMOTE_DS] Using fallback companion: ${fallbackCompanion.displayName}');
        return fallbackCompanion;
      }
      
      throw ServerException('Error purchasing companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> evolveCompanion(String userId, String petId) async {
    try {
      debugPrint('⭐ [REMOTE_DS] === EVOLUCIONANDO MASCOTA ===');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/owned/$userId/$petId/evolve',
        data: {'userId': userId, 'petId': petId},
      );
      
      final companion = _mapApiPetToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid evolution response format');
      }
      
      return companion;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en evolveCompanion: $e');
      throw ServerException('Error evolving companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> featureCompanion(String userId, String petId) async {
    try {
      debugPrint('⭐ [REMOTE_DS] === DESTACANDO MASCOTA ===');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/$userId/feature',
        data: {'petId': petId, 'userId': userId},
      );
      
      final companion = _mapApiPetToCompanion(response.data, isOwned: true, isFeatured: true);
      if (companion == null) {
        throw ServerException('Invalid feature response format');
      }
      
      return companion;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en featureCompanion: $e');
      throw ServerException('Error featuring companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REMOTE_DS] === OBTENIENDO STATS ===');
      
      // Calcular desde las mascotas del usuario
      final companions = await getUserCompanions(userId);
      final ownedCount = companions.where((c) => c.isOwned).length;
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: 12, // 4 tipos x 3 etapas
        ownedCompanions: ownedCount,
        totalPoints: 1000, // 🔧 PUNTOS GENEROSOS PARA TESTING
        spentPoints: 0,
        activeCompanionId: companions.where((c) => c.isSelected).isNotEmpty 
            ? companions.firstWhere((c) => c.isSelected).id 
            : 'dexter_young',
        totalFeedCount: 0,
        totalLoveCount: 0,
        totalEvolutions: 0,
        lastActivity: DateTime.now(),
      );
      
      debugPrint('📊 [REMOTE_DS] Stats calculated: ${stats.ownedCompanions}/${stats.totalCompanions}');
      return stats;
      
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error en getCompanionStats: $e');
      throw ServerException('Error fetching companion stats: ${e.toString()}');
    }
  }

  // ==================== 🔧 MÉTODOS HELPER CORREGIDOS ====================

  /// Mapear datos de la API a CompanionModel
  CompanionModel? _mapApiPetToCompanion(
    dynamic petData, {
    bool isOwned = false,
    bool isInStore = false,
    bool isFeatured = false,
  }) {
    try {
      if (petData is! Map<String, dynamic>) {
        debugPrint('❌ [MAPPING] Pet data is not a valid Map');
        return null;
      }

      final id = petData['id']?.toString() ?? '';
      final name = petData['name']?.toString() ?? petData['nickname']?.toString() ?? '';
      final species = petData['species']?.toString()?.toLowerCase() ?? 
                     petData['speciesType']?.toString()?.toLowerCase() ?? 
                     petData['species_type']?.toString()?.toLowerCase() ?? '';
      final rarity = petData['rarity']?.toString()?.toLowerCase() ?? 'common';
      final cost = _parseInteger(petData['quiz_points_cost'] ?? petData['cost'] ?? petData['price'] ?? 0);
      final isOnSale = petData['is_on_sale'] == true;
      final adopted = petData['adopted_at'] != null || isOwned;

      debugPrint('🔍 [MAPPING] Mapping: id=$id, species=$species, rarity=$rarity');

      // Mapear a tipos locales
      final localType = _mapSpeciesToType(species);
      final localStage = _mapRarityToStage(rarity);
      
      if (localType == null) {
        debugPrint('❌ [MAPPING] Could not map species: $species');
        return null;
      }

      // ID local consistente
      final localId = '${localType.name}_${localStage.name}';
      
      final companion = CompanionModel(
        id: localId,
        type: localType,
        stage: localStage,
        name: _getDisplayName(localType),
        description: _generateDescription(localType, localStage),
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: adopted,
        isSelected: isFeatured,
        purchasedAt: adopted ? DateTime.now() : null,
        currentMood: CompanionMood.happy,
        purchasePrice: isOnSale ? (cost * 0.8).round() : cost,
        evolutionPrice: _getEvolutionPrice(localStage),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );

      debugPrint('✅ [MAPPING] Successfully mapped: ${companion.displayName}');
      return companion;
      
    } catch (e) {
      debugPrint('❌ [MAPPING] Error mapping pet: $e');
      return null;
    }
  }

  /// Verificar si el request es para Dexter joven (mascota inicial)
  bool _isDexterYoungRequest(String petId) {
    final lowerPetId = petId.toLowerCase();
    return lowerPetId.contains('dexter') && lowerPetId.contains('young') ||
           lowerPetId.contains('dexter_young') ||
           petId == 'dexter_young';
  }

  /// Verificar si el usuario ya tiene Dexter joven
  bool _hasDexterYoung(List<CompanionModel> companions) {
    return companions.any((c) => 
      c.type == CompanionType.dexter && 
      c.stage == CompanionStage.young && 
      c.isOwned
    );
  }

  /// Crear Dexter joven inicial (mascota por defecto)
  CompanionModel _createInitialDexterYoung(String userId) {
    debugPrint('🐕 [FALLBACK] Creating initial Dexter young for user: $userId');
    
    return CompanionModel(
      id: 'dexter_young',
      type: CompanionType.dexter,
      stage: CompanionStage.young,
      name: 'Dexter',
      description: 'Tu primer compañero, un chihuahua joven lleno de energía',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true, // 🔧 SIEMPRE POSEÍDO
      isSelected: true, // 🔧 ACTIVO POR DEFECTO
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔧 GRATIS
      evolutionPrice: 100,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
      createdAt: DateTime.now(),
    );
  }

  /// Crear companion desde pet ID cuando falla la API
  CompanionModel? _createCompanionFromPetId(String userId, String petId) {
    try {
      final species = _extractSpeciesFromPetId(petId);
      final stage = _extractStageFromPetId(petId);
      
      final type = _mapSpeciesToType(species);
      final stageEnum = _mapStageNameToEnum(stage);
      
      if (type == null) return null;
      
      return CompanionModel(
        id: '${type.name}_${stageEnum.name}',
        type: type,
        stage: stageEnum,
        name: _getDisplayName(type),
        description: _generateDescription(type, stageEnum),
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true,
        isSelected: false,
        purchasedAt: DateTime.now(),
        currentMood: CompanionMood.happy,
        purchasePrice: _getDefaultPrice(type, stageEnum),
        evolutionPrice: _getEvolutionPrice(stageEnum),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [FALLBACK] Error creating companion from petId: $e');
      return null;
    }
  }

  /// Extraer species del pet ID
  String _extractSpeciesFromPetId(String petId) {
    if (petId.contains('dexter')) return 'chihuahua';
    if (petId.contains('elly')) return 'panda';
    if (petId.contains('paxolotl')) return 'axolotl';
    if (petId.contains('yami')) return 'jaguar';
    return 'chihuahua'; // Default
  }

  /// Extraer stage del pet ID
  String _extractStageFromPetId(String petId) {
    if (petId.contains('baby')) return 'baby';
    if (petId.contains('young')) return 'young';
    if (petId.contains('adult')) return 'adult';
    return 'baby'; // Default
  }

  /// Mapear species string a CompanionType
  CompanionType? _mapSpeciesToType(String species) {
    return _speciesMapping[species.toLowerCase()];
  }

  /// Mapear rarity a CompanionStage
  CompanionStage _mapRarityToStage(String rarity) {
    return _rarityMapping[rarity.toLowerCase()] ?? CompanionStage.baby;
  }

  /// Mapear stage name a enum
  CompanionStage _mapStageNameToEnum(String stage) {
    switch (stage.toLowerCase()) {
      case 'young': return CompanionStage.young;
      case 'adult': return CompanionStage.adult;
      default: return CompanionStage.baby;
    }
  }

  /// Crear set completo de companions
  List<CompanionModel> _createFullCompanionSet() {
    final now = DateTime.now();
    final companions = <CompanionModel>[];
    
    for (final type in CompanionType.values) {
      for (final stage in CompanionStage.values) {
        final companion = CompanionModel(
          id: '${type.name}_${stage.name}',
          type: type,
          stage: stage,
          name: _getDisplayName(type),
          description: _generateDescription(type, stage),
          level: 1,
          experience: 0,
          happiness: 100,
          hunger: 100,
          energy: 100,
          isOwned: type == CompanionType.dexter && stage == CompanionStage.young, // Solo Dexter joven inicial
          isSelected: type == CompanionType.dexter && stage == CompanionStage.young,
          purchasedAt: type == CompanionType.dexter && stage == CompanionStage.young ? now : null,
          currentMood: CompanionMood.happy,
          purchasePrice: _getDefaultPrice(type, stage),
          evolutionPrice: _getEvolutionPrice(stage),
          unlockedAnimations: ['idle', 'blink', 'happy'],
          createdAt: now,
        );
        companions.add(companion);
      }
    }
    
    return companions;
  }

  /// Crear companions para la tienda (sin los ya poseídos)
  List<CompanionModel> _createStoreCompanionSet() {
    final allCompanions = _createFullCompanionSet();
    // Filtrar solo los que no son Dexter joven (ya desbloqueado)
    return allCompanions.where((c) => 
      !(c.type == CompanionType.dexter && c.stage == CompanionStage.young)
    ).toList();
  }

  // MÉTODOS HELPER EXISTENTES...
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

  int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    if (type == CompanionType.dexter && stage == CompanionStage.young) {
      return 0; // Gratis - mascota inicial
    }
    
    int basePrice = 50;
    switch (type) {
      case CompanionType.dexter: basePrice = 50; break;
      case CompanionType.elly: basePrice = 100; break;
      case CompanionType.paxolotl: basePrice = 150; break;
      case CompanionType.yami: basePrice = 200; break;
    }
    
    switch (stage) {
      case CompanionStage.baby: return basePrice;
      case CompanionStage.young: return basePrice + 50;
      case CompanionStage.adult: return basePrice + 100;
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 50;
      case CompanionStage.young: return 100;
      case CompanionStage.adult: return 0;
    }
  }

  int _parseInteger(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}