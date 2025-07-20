// lib/features/companion/data/datasources/companion_remote_datasource.dart - CONECTADO A TU API
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_manager.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';
import '../../domain/entities/companion_entity.dart';

// ==================== MODELOS PARA TU API ====================

/// Respuesta de la tienda de mascotas
class PetStoreResponse {
  final List<AvailablePet> availablePets;
  final int userQuizPoints;
  final List<String> featuredPets;

  PetStoreResponse({
    required this.availablePets,
    required this.userQuizPoints,
    required this.featuredPets,
  });

  factory PetStoreResponse.fromJson(Map<String, dynamic> json) {
    return PetStoreResponse(
      availablePets: (json['available_pets'] as List)
          .map((pet) => AvailablePet.fromJson(pet))
          .toList(),
      userQuizPoints: json['user_quiz_points'] ?? 0,
      featuredPets: List<String>.from(json['featured_pets'] ?? []),
    );
  }
}

/// Mascota disponible en la tienda
class AvailablePet {
  final String petId;
  final String name;
  final int quizPointsCost;
  final String rarity;
  final String description;
  final String? avatarUrl;
  final bool isOnSale;
  final bool userCanAfford;

  AvailablePet({
    required this.petId,
    required this.name,
    required this.quizPointsCost,
    required this.rarity,
    required this.description,
    this.avatarUrl,
    required this.isOnSale,
    required this.userCanAfford,
  });

  factory AvailablePet.fromJson(Map<String, dynamic> json) {
    return AvailablePet(
      petId: json['pet_id'] ?? '',
      name: json['name'] ?? '',
      quizPointsCost: json['quiz_points_cost'] ?? 0,
      rarity: json['rarity'] ?? 'common',
      description: json['description'] ?? '',
      avatarUrl: json['avatar_url'],
      isOnSale: json['is_on_sale'] ?? false,
      userCanAfford: json['user_can_afford'] ?? false,
    );
  }
}

/// Mascota adoptada por el usuario
class AdoptedPet {
  final String id;
  final String name;
  final String speciesType;
  final DateTime? adoptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdoptedPet({
    required this.id,
    required this.name,
    required this.speciesType,
    this.adoptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdoptedPet.fromJson(Map<String, dynamic> json) {
    return AdoptedPet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      speciesType: json['species_type'] ?? '',
      adoptedAt: json['adopted_at'] != null 
          ? DateTime.parse(json['adopted_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// ==================== REMOTE DATA SOURCE ====================

abstract class CompanionRemoteDataSource {
  Future<List<CompanionModel>> getUserCompanions(String userId);
  Future<List<CompanionModel>> getAvailableCompanions();
  Future<List<CompanionModel>> getStoreCompanions({required String userId});
  Future<CompanionModel> adoptCompanion({required String userId, required String petId});
  Future<CompanionStatsModel> getCompanionStats(String userId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

  // ==================== TIENDA DE MASCOTAS ====================
  
  @override
  Future<List<CompanionModel>> getStoreCompanions({required String userId}) async {
    try {
      debugPrint('🏪 [API] === OBTENIENDO TIENDA DE MASCOTAS ===');
      debugPrint('👤 [API] User ID: $userId');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/store',
        queryParameters: {'userId': userId},
        requireAuth: true,
      );
      
      debugPrint('✅ [API] Respuesta tienda: ${response.statusCode}');
      debugPrint('📊 [API] Data: ${response.data}');
      
      // Parsear respuesta de tu API
      final storeResponse = PetStoreResponse.fromJson(response.data);
      
      debugPrint('🛍️ [API] Mascotas en tienda: ${storeResponse.availablePets.length}');
      debugPrint('💰 [API] Puntos usuario: ${storeResponse.userQuizPoints}');
      
      // Convertir a modelos locales
      final companions = <CompanionModel>[];
      
      for (final pet in storeResponse.availablePets) {
        final companion = _mapApiPetToCompanion(
          pet, 
          userPoints: storeResponse.userQuizPoints,
          isFeatured: storeResponse.featuredPets.contains(pet.petId),
        );
        
        if (companion != null) {
          companions.add(companion);
          debugPrint('✅ [API] Mapeado: ${companion.displayName} (${pet.quizPointsCost}★)');
        }
      }
      
      debugPrint('🎯 [API] Total companions mapeados: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo tienda: $e');
      throw ServerException('Error obteniendo tienda: ${e.toString()}');
    }
  }

  // ==================== MASCOTAS DISPONIBLES (SIN PRECIOS) ====================
  
  @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🌐 [API] === OBTENIENDO MASCOTAS DISPONIBLES ===');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/available',
        requireAuth: false,
      );
      
      debugPrint('✅ [API] Respuesta disponibles: ${response.statusCode}');
      
      final List<dynamic> petsData = response.data;
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        final companion = _mapAvailablePetToCompanion(petJson);
        if (companion != null) {
          companions.add(companion);
        }
      }
      
      debugPrint('🌐 [API] Total disponibles: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo disponibles: $e');
      throw ServerException('Error obteniendo mascotas disponibles: ${e.toString()}');
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
      
      final List<dynamic> petsData = response.data;
      final companions = <CompanionModel>[];
      
      for (final petJson in petsData) {
        final adoptedPet = AdoptedPet.fromJson(petJson);
        final companion = _mapAdoptedPetToCompanion(adoptedPet);
        
        if (companion != null) {
          companions.add(companion);
          debugPrint('🏠 [API] Mascota adoptada: ${companion.displayName}');
        }
      }
      
      // 🔧 AGREGAR DEXTER INICIAL SI NO HAY MASCOTAS
      if (companions.isEmpty) {
        debugPrint('🔧 [API] Usuario sin mascotas - agregando Dexter inicial');
        final dexterInitial = _createInitialDexterYoung(userId);
        companions.add(dexterInitial);
      }
      
      debugPrint('🎯 [API] Total mascotas usuario: ${companions.length}');
      return companions;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo mascotas usuario: $e');
      
      // Fallback: crear Dexter inicial
      final dexterInitial = _createInitialDexterYoung(userId);
      return [dexterInitial];
    }
  }

  // ==================== ADOPTAR MASCOTA ====================
  
  @override
  Future<CompanionModel> adoptCompanion({required String userId, required String petId}) async {
    try {
      debugPrint('🐾 [API] === ADOPTANDO MASCOTA ===');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/$userId/adopt',
        data: {'petId': petId},
      );
      
      debugPrint('✅ [API] Adopción exitosa: ${response.statusCode}');
      debugPrint('📊 [API] Respuesta: ${response.data}');
      
      // Convertir respuesta a companion
      final adoptedPet = AdoptedPet.fromJson(response.data);
      final companion = _mapAdoptedPetToCompanion(adoptedPet);
      
      if (companion == null) {
        throw ServerException('No se pudo mapear la mascota adoptada');
      }
      
      debugPrint('🎉 [API] Mascota adoptada exitosamente: ${companion.displayName}');
      return companion;
      
    } catch (e) {
      debugPrint('❌ [API] Error adoptando mascota: $e');
      throw ServerException('Error adoptando mascota: ${e.toString()}');
    }
  }

  // ==================== ESTADÍSTICAS ====================
  
  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [API] === OBTENIENDO ESTADÍSTICAS ===');
      
      // Obtener mascotas del usuario para calcular stats
      final userCompanions = await getUserCompanions(userId);
      
      // Obtener puntos desde la tienda
      final storeData = await getStoreCompanions(userId: userId);
      int userPoints = 1000; // Default
      
      try {
        final storeResponse = await apiClient.getGamification(
          '/api/gamification/pets/store',
          queryParameters: {'userId': userId},
        );
        
        final storeInfo = PetStoreResponse.fromJson(storeResponse.data);
        userPoints = storeInfo.userQuizPoints;
      } catch (e) {
        debugPrint('⚠️ [API] No se pudieron obtener puntos del usuario: $e');
      }
      
      final ownedCount = userCompanions.where((c) => c.isOwned).length;
      final activeCompanionId = userCompanions
          .where((c) => c.isSelected)
          .isNotEmpty 
          ? userCompanions.firstWhere((c) => c.isSelected).id 
          : 'dexter_young';
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: 12, // 4 tipos x 3 etapas
        ownedCompanions: ownedCount,
        totalPoints: userPoints,
        spentPoints: 0, // Calcular según API si es necesario
        activeCompanionId: activeCompanionId,
        totalFeedCount: 0,
        totalLoveCount: 0,
        totalEvolutions: 0,
        lastActivity: DateTime.now(),
      );
      
      debugPrint('📊 [API] Stats calculados: ${stats.ownedCompanions}/${stats.totalCompanions}');
      return stats;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo stats: $e');
      throw ServerException('Error obteniendo estadísticas: ${e.toString()}');
    }
  }

  // ==================== MAPEO DE DATOS ====================

  /// Mapear mascota de tienda a CompanionModel
  CompanionModel? _mapApiPetToCompanion(
    AvailablePet pet, {
    required int userPoints,
    bool isFeatured = false,
  }) {
    try {
      // Mapear especies y rareza a tipos locales
      final localType = _mapSpeciesToType(pet.petId);
      final localStage = _mapRarityToStage(pet.rarity);
      
      if (localType == null) {
        debugPrint('❌ [MAPPING] No se pudo mapear pet: ${pet.petId}');
        return null;
      }
      
      final localId = '${localType.name}_${localStage.name}';
      
      return CompanionModel(
        id: localId,
        type: localType,
        stage: localStage,
        name: _getDisplayName(localType),
        description: pet.description,
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false, // En tienda = no poseído
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: pet.isOnSale ? (pet.quizPointsCost * 0.8).round() : pet.quizPointsCost,
        evolutionPrice: _getEvolutionPrice(localStage),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [MAPPING] Error mapeando pet de tienda: $e');
      return null;
    }
  }

  /// Mapear mascota disponible a CompanionModel
  CompanionModel? _mapAvailablePetToCompanion(Map<String, dynamic> petJson) {
    try {
      final petId = petJson['id'] ?? '';
      final localType = _mapSpeciesToType(petId);
      final rarity = petJson['rarity'] ?? 'common';
      final localStage = _mapRarityToStage(rarity);
      
      if (localType == null) return null;
      
      final localId = '${localType.name}_${localStage.name}';
      
      return CompanionModel(
        id: localId,
        type: localType,
        stage: localStage,
        name: petJson['name'] ?? _getDisplayName(localType),
        description: petJson['description'] ?? '',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: petJson['quiz_points_cost'] ?? 0,
        evolutionPrice: _getEvolutionPrice(localStage),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [MAPPING] Error mapeando pet disponible: $e');
      return null;
    }
  }

  /// Mapear mascota adoptada a CompanionModel
  CompanionModel? _mapAdoptedPetToCompanion(AdoptedPet adoptedPet) {
    try {
      final localType = _mapSpeciesToType(adoptedPet.id);
      
      if (localType == null) return null;
      
      // Determinar etapa basado en cuánto tiempo tiene adoptada
      final adoptionDays = adoptedPet.adoptedAt != null 
          ? DateTime.now().difference(adoptedPet.adoptedAt!).inDays
          : 0;
      
      CompanionStage stage;
      if (adoptionDays < 7) {
        stage = CompanionStage.baby;
      } else if (adoptionDays < 30) {
        stage = CompanionStage.young;
      } else {
        stage = CompanionStage.adult;
      }
      
      final localId = '${localType.name}_${stage.name}';
      
      return CompanionModel(
        id: localId,
        type: localType,
        stage: stage,
        name: adoptedPet.name,
        description: _generateDescription(localType, stage),
        level: _calculateLevel(adoptionDays),
        experience: adoptionDays * 5,
        happiness: 100,
        hunger: 80,
        energy: 90,
        isOwned: true, // Ya adoptada
        isSelected: false, // Configurar según lógica
        purchasedAt: adoptedPet.adoptedAt,
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: _getEvolutionPrice(stage),
        unlockedAnimations: _getAnimationsForStage(stage),
        createdAt: adoptedPet.createdAt,
      );
    } catch (e) {
      debugPrint('❌ [MAPPING] Error mapeando pet adoptada: $e');
      return null;
    }
  }

  // ==================== MAPEO HELPER METHODS ====================

  CompanionType? _mapSpeciesToType(String petId) {
    final lowerPetId = petId.toLowerCase();
    
    if (lowerPetId.contains('ajolote') || lowerPetId.contains('axolotl')) {
      return CompanionType.paxolotl;
    } else if (lowerPetId.contains('dog') || lowerPetId.contains('perro')) {
      return CompanionType.dexter;
    } else if (lowerPetId.contains('panda')) {
      return CompanionType.elly;
    } else if (lowerPetId.contains('jaguar') || lowerPetId.contains('cat')) {
      return CompanionType.yami;
    }
    
    // Fallback basado en palabras clave
    if (lowerPetId.contains('agua') || lowerPetId.contains('water')) {
      return CompanionType.paxolotl;
    } else if (lowerPetId.contains('bosque') || lowerPetId.contains('forest')) {
      return CompanionType.elly;
    }
    
    return CompanionType.dexter; // Default
  }

  CompanionStage _mapRarityToStage(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return CompanionStage.baby;
      case 'rare':
        return CompanionStage.young;
      case 'epic':
      case 'legendary':
        return CompanionStage.adult;
      default:
        return CompanionStage.baby;
    }
  }

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

  int _calculateLevel(int adoptionDays) {
    return (adoptionDays / 7).floor() + 1;
  }

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

  CompanionModel _createInitialDexterYoung(String userId) {
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
      isOwned: true,
      isSelected: true,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0,
      evolutionPrice: 100,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating'],
      createdAt: DateTime.now(),
    );
  }
}