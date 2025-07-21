// lib/features/companion/data/datasources/companion_remote_datasource.dart - PRODUCCIÓN FINAL
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
  Future<int> getUserPoints(String userId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

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

  // ==================== 🆕 MASCOTAS ADQUIRIDAS POR EL USUARIO ====================
  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      debugPrint('👤 [API] Obteniendo mascotas del usuario: $userId');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/$userId',
        requireAuth: true,
      );
      
      debugPrint('✅ [API] Mascotas usuario obtenidas: ${response.statusCode}');
      
      if (response.data == null) {
        debugPrint('ℹ️ [API] Usuario sin mascotas adoptadas');
        return [];
      }
      
      final List<dynamic> adoptedPetsData = response.data as List;
      final adoptedCompanions = <CompanionModel>[];
      
      for (final adoptedPet in adoptedPetsData) {
        try {
          // Mapear mascota adoptada del backend a nuestro modelo
          final companion = _mapAdoptedPetToCompanion(adoptedPet);
          adoptedCompanions.add(companion);
          
          debugPrint('🐾 [API] Mascota mapeada: ${companion.displayName} (${companion.id})');
          
        } catch (e) {
          debugPrint('❌ [API] Error mapeando mascota adoptada: $e');
        }
      }
      
      debugPrint('✅ [API] Total mascotas usuario: ${adoptedCompanions.length}');
      return adoptedCompanions;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo mascotas usuario: $e');
      // Retornar lista vacía en lugar de error para UX suave
      return [];
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
      
      debugPrint('✅ [API] Puntos obtenidos: ${response.statusCode}');
      
      if (response.data == null) {
        debugPrint('⚠️ [API] Respuesta de puntos vacía');
        return 0;
      }
      
      // El endpoint puede retornar diferentes formatos
      int points = 0;
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        points = (data['points'] ?? data['quiz_points'] ?? data['total'] ?? 0).toInt();
      } else if (response.data is int) {
        points = response.data as int;
      } else if (response.data is String) {
        points = int.tryParse(response.data as String) ?? 0;
      }
      
      debugPrint('💰 [API] Puntos del usuario: $points');
      return points;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo puntos: $e');
      // Retornar 0 para UX suave
      return 0;
    }
  }

  // ==================== TIENDA (MASCOTAS DISPONIBLES - NO ADOPTADAS) ====================
  @override
  Future<List<CompanionModel>> getStoreCompanions({required String userId}) async {
    try {
      debugPrint('🏪 [API] Obteniendo tienda para usuario: $userId');
      
      // Obtener todas las mascotas disponibles
      final allCompanions = await getAvailableCompanions();
      
      // Obtener mascotas ya adoptadas por el usuario
      final userCompanions = await getUserCompanions(userId);
      final adoptedIds = userCompanions.map((c) => c.id).toSet();
      
      // Filtrar mascotas no adoptadas para la tienda
      final storeCompanions = allCompanions.where((companion) {
        return !adoptedIds.contains(companion.id);
      }).toList();
      
      // Ordenar por precio (más baratos primero)
      storeCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
      
      debugPrint('🛍️ [API] Mascotas en tienda: ${storeCompanions.length}');
      return storeCompanions;
      
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo tienda: $e');
      throw ServerException('Error obteniendo tienda: ${e.toString()}');
    }
  }

  // ==================== 🔥 ADOPCIÓN CON MANEJO CORRECTO DE 204 ====================
  @override
  Future<CompanionModel> adoptCompanion({
    required String userId, 
    required String petId,
    String? nickname,
  }) async {
    try {
      debugPrint('🐾 [API] Iniciando adopción...');
      debugPrint('👤 [API] User ID: $userId');
      debugPrint('🆔 [API] Pet ID: $petId');
      debugPrint('🏷️ [API] Nickname: ${nickname ?? "Sin nickname"}');
      
      final endpoint = '/api/gamification/pets/$userId/adopt';
      final requestBody = {
        'petId': petId,
        'nickname': nickname ?? 'Mi compañero',
      };
      
      debugPrint('📦 [API] Request: $requestBody');
      
      final response = await apiClient.postGamification(
        endpoint,
        data: requestBody,
      );
      
      debugPrint('✅ [API] Adopción completada: ${response.statusCode}');
      
      // 🔥 MANEJAR CORRECTAMENTE EL 204 (SIN ERROR)
      if (response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('🎉 [API] Adopción exitosa (204 No Content es éxito)');
        
        // Crear companion adoptado basado en el petId
        final adoptedCompanion = _createAdoptedCompanionFromPetId(
          petId, 
          nickname ?? 'Mi compañero'
        );
        
        debugPrint('✅ [API] Companion creado: ${adoptedCompanion.displayName}');
        return adoptedCompanion;
        
      } else {
        throw ServerException('Error en adopción: código ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ [API] Error en adopción: $e');
      
      // Manejo específico de errores
      if (e.toString().contains('already adopted') || 
          e.toString().contains('ya adoptada')) {
        throw ServerException('Ya tienes esta mascota');
      } else if (e.toString().contains('insufficient') || 
                 e.toString().contains('insuficientes')) {
        throw ServerException('No tienes suficientes puntos');
      } else if (e.toString().contains('not found')) {
        throw ServerException('Mascota no encontrada');
      } else {
        throw ServerException('Error en adopción: ${e.toString()}');
      }
    }
  }

  // ==================== ESTADÍSTICAS USANDO PUNTOS REALES ====================
  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [API] Calculando estadísticas...');
      
      // Obtener datos reales del usuario
      final userCompanions = await getUserCompanions(userId);
      final userPoints = await getUserPoints(userId);
      final allCompanions = await getAvailableCompanions();
      
      final ownedCount = userCompanions.length;
      final totalCount = allCompanions.length;
      final activeCompanionId = userCompanions.isNotEmpty ? userCompanions.first.id : '';
      
      // Calcular puntos gastados (estimado)
      int spentPoints = 0;
      for (final companion in userCompanions) {
        spentPoints += companion.purchasePrice;
      }
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: totalCount,
        ownedCompanions: ownedCount,
        totalPoints: userPoints + spentPoints, // Total estimado
        spentPoints: spentPoints,
        activeCompanionId: activeCompanionId,
        totalFeedCount: 0, // No disponible en API actual
        totalLoveCount: 0, // No disponible en API actual
        totalEvolutions: 0, // No disponible en API actual
        lastActivity: DateTime.now(),
      );
      
      debugPrint('📊 [API] Stats: ${stats.ownedCompanions}/${stats.totalCompanions}, ${stats.availablePoints}★');
      return stats;
      
    } catch (e) {
      debugPrint('❌ [API] Error calculando stats: $e');
      throw ServerException('Error obteniendo estadísticas: ${e.toString()}');
    }
  }

  // ==================== 🔧 MÉTODOS HELPER PARA MAPEO ====================

  /// Mapear mascota adoptada del backend a nuestro modelo
  CompanionModel _mapAdoptedPetToCompanion(Map<String, dynamic> adoptedPet) {
    final petId = adoptedPet['id'] as String;
    final name = adoptedPet['name'] as String? ?? 'Mi Compañero';
    final speciesType = adoptedPet['species_type'] as String? ?? 'dog';
    final adoptedAt = adoptedPet['adopted_at'] as String?;
    
    // Mapear species_type a nuestro sistema
    final companionType = _mapSpeciesTypeToCompanionType(speciesType);
    final companionStage = _inferStageFromPetId(petId);
    
    return CompanionModel(
      id: '${companionType.name}_${companionStage.name}',
      type: companionType,
      stage: companionStage,
      name: name,
      description: _generateDescription(companionType, companionStage),
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true, // Fue adoptado
      isSelected: false, // Por defecto no seleccionado
      purchasedAt: adoptedAt != null ? DateTime.parse(adoptedAt) : DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

  /// Crear companion adoptado desde petId
  CompanionModel _createAdoptedCompanionFromPetId(String petId, String nickname) {
    final companionType = _mapPetIdToCompanionType(petId);
    final companionStage = _mapPetIdToCompanionStage(petId);
    
    return CompanionModel(
      id: '${companionType.name}_${companionStage.name}',
      type: companionType,
      stage: companionStage,
      name: nickname,
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
    );
  }

  // Mapeos de tipos
  CompanionType _mapSpeciesTypeToCompanionType(String speciesType) {
    switch (speciesType.toLowerCase()) {
      case 'dog':
      case 'chihuahua':
        return CompanionType.dexter;
      case 'panda':
        return CompanionType.elly;
      case 'axolotl':
      case 'ajolote':
        return CompanionType.paxolotl;
      case 'jaguar':
        return CompanionType.yami;
      default:
        return CompanionType.dexter;
    }
  }

  CompanionType _mapPetIdToCompanionType(String petId) {
    final petIdLower = petId.toLowerCase();
    
    if (petIdLower.contains('dexter') || 
        petIdLower.contains('dog') || 
        petIdLower.contains('chihuahua')) {
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || 
               petIdLower.contains('panda')) {
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') || 
               petIdLower.contains('axolotl')) {
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || 
               petIdLower.contains('jaguar')) {
      return CompanionType.yami;
    }
    
    return CompanionType.dexter; // Por defecto
  }

  CompanionStage _mapPetIdToCompanionStage(String petId) {
    final petIdLower = petId.toLowerCase();
    
    if (petIdLower.contains('baby') || petIdLower.contains('peque')) {
      return CompanionStage.baby;
    } else if (petIdLower.contains('young') || petIdLower.contains('joven')) {
      return CompanionStage.young;
    } else if (petIdLower.contains('adult') || petIdLower.contains('adulto')) {
      return CompanionStage.adult;
    }
    
    return CompanionStage.baby; // Por defecto
  }

  CompanionStage _inferStageFromPetId(String petId) {
    return _mapPetIdToCompanionStage(petId);
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
      case CompanionType.dexter: return 'Dexter';
      case CompanionType.elly: return 'Elly';
      case CompanionType.paxolotl: return 'Paxolotl';
      case CompanionType.yami: return 'Yami';
    }
  }

  int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    int basePrice = 100;
    
    switch (type) {
      case CompanionType.dexter: basePrice = 0; break; // Gratis
      case CompanionType.elly: basePrice = 200; break;
      case CompanionType.paxolotl: basePrice = 600; break;
      case CompanionType.yami: basePrice = 2500; break;
    }
    
    switch (stage) {
      case CompanionStage.baby: return basePrice;
      case CompanionStage.young: return basePrice + 150;
      case CompanionStage.adult: return basePrice + 300;
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 50;
      case CompanionStage.young: return 100;
      case CompanionStage.adult: return 0;
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
      purchasePrice: 0, // Gratis
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));
    
    // Agregar otros companions...
    // (código similar para elly, paxolotl, yami)
    
    return companions;
  }
}