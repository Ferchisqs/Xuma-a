// lib/features/companion/data/datasources/companion_remote_datasource.dart - INTEGRACIÓN CON API REAL
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/domain/entities/companion_entity.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
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

  // 🗺️ MAPEO DE NOMBRES DE API A ASSETS LOCALES
  static const Map<String, String> _petTypeMapping = {
    // Dexter - Chihuahua
    'firulais': 'dexter',
    'chihuahua': 'dexter',
    'chihuahua peque': 'dexter',
    'dexter': 'dexter',
    
    // Elly - Panda
    'elly': 'elly',
    'panda gigante': 'elly',
    'panda': 'elly',
    
    // Paxolotl - Ajolote
    'ajolote dorado': 'paxolotl',
    'ajolote': 'paxolotl',
    'paxolotl': 'paxolotl',
    'axolotl': 'paxolotl',
    
    // Yami - Jaguar
    'yari': 'yami',
    'yami': 'yami',
    'jaguar': 'yami',
    'jaguar negro': 'yami',
  };

  // 🎨 MAPEO DE ASSETS LOCALES
  static const Map<String, String> _petAssets = {
    'dexter': 'assets/images/companions/dexter_baby.png',
    'elly': 'assets/images/companions/elly_baby.png',
    'paxolotl': 'assets/images/companions/paxolotl_baby.png',
    'yami': 'assets/images/companions/yami_baby.png',
  };

  static const Map<String, String> _petBackgrounds = {
    'dexter': 'assets/images/companions/backgrounds/chihuahua_bg.png',
    'elly': 'assets/images/companions/backgrounds/panda_bg.png',
    'paxolotl': 'assets/images/companions/backgrounds/axolotl_bg.png',
    'yami': 'assets/images/companions/backgrounds/jaguar_bg.png',
  };

  CompanionRemoteDataSourceImpl(this.apiClient, this.tokenManager);

  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      debugPrint('🌐 [REMOTE_DS] Obteniendo mascotas del usuario: $userId');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/$userId',
        requireAuth: true,
      );
      
      debugPrint('✅ [REMOTE_DS] Respuesta recibida: ${response.statusCode}');
      
      // 🔧 MANEJO ROBUSTO DE RESPUESTA - MÚLTIPLES FORMATOS
      List<dynamic> petsJson = [];
      
      if (response.data is List) {
        petsJson = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsJson = data['pets'] ?? data['data'] ?? data['companions'] ?? [];
      }
      
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas encontradas desde API');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final companion = _mapApiResponseToCompanion(petJson, isOwned: true);
          if (companion != null) {
            companions.add(companion);
            debugPrint('✅ [REMOTE_DS] Procesada: ${companion.displayName}');
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota individual: $e');
        }
      }
      
      // 🎯 SI NO HAY MASCOTAS DE LA API, DEVOLVER DEXTER COMO INICIAL
      if (companions.isEmpty) {
        debugPrint('🔧 [REMOTE_DS] Usuario sin mascotas, creando Dexter inicial');
        final initialCompanion = _createInitialCompanion(userId);
        companions.add(initialCompanion);
      }
      
      debugPrint('🎯 [REMOTE_DS] Total procesadas: ${companions.length}');
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error con API, creando mascota inicial: $e');
      
      // 🔧 FALLBACK TOTAL: SI LA API FALLA, CREAR DEXTER INICIAL
      final initialCompanion = _createInitialCompanion(userId);
      return [initialCompanion];
    }
  }

  @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REMOTE_DS] Obteniendo mascotas disponibles para adoptar');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/available',
        requireAuth: false,
      );
      
      debugPrint('✅ [REMOTE_DS] Mascotas disponibles recibidas: ${response.statusCode}');
      
      // 🔧 MANEJO ROBUSTO DE RESPUESTA
      List<dynamic> petsJson = [];
      
      if (response.data is List) {
        petsJson = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsJson = data['pets'] ?? data['data'] ?? data['available'] ?? [];
      }
      
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas disponibles desde API');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final companion = _mapApiResponseToCompanion(petJson, isOwned: false);
          if (companion != null) {
            companions.add(companion);
            debugPrint('✅ [REMOTE_DS] Disponible: ${companion.displayName}');
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota disponible: $e');
        }
      }
      
      // 🎯 SI NO HAY MASCOTAS DISPONIBLES DE LA API, CREAR SET COMPLETO LOCAL
      if (companions.isEmpty) {
        debugPrint('🔧 [REMOTE_DS] API sin mascotas disponibles, creando set local completo');
        return _createDefaultAvailableCompanions();
      }
      
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error con API disponibles, usando set local: $e');
      
      // 🔧 FALLBACK TOTAL: CREAR SET COMPLETO DE MASCOTAS LOCALES
      return _createDefaultAvailableCompanions();
    }
  }

  @override
  Future<List<CompanionModel>> getStoreCompanions() async {
    try {
      debugPrint('🏪 [REMOTE_DS] Obteniendo tienda de mascotas');
      
      final response = await apiClient.getGamification(
        '/api/gamification/pets/store',
        requireAuth: false,
      );
      
      debugPrint('✅ [REMOTE_DS] Tienda recibida: ${response.statusCode}');
      
      // 🔧 MANEJO ROBUSTO DE RESPUESTA DE TIENDA
      List<dynamic> petsJson = [];
      
      if (response.data is List) {
        petsJson = response.data;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        petsJson = data['pets'] ?? data['store'] ?? data['data'] ?? data['items'] ?? [];
      }
      
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas en tienda desde API');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final companion = _mapApiResponseToCompanion(petJson, isOwned: false, isInStore: true);
          if (companion != null) {
            companions.add(companion);
            debugPrint('🛒 [REMOTE_DS] En tienda: ${companion.displayName} - ${companion.purchasePrice}★');
          }
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota de tienda: $e');
        }
      }
      
      // 🎯 SI LA TIENDA ESTÁ VACÍA, CREAR TIENDA LOCAL COMPLETA
      if (companions.isEmpty) {
        debugPrint('🔧 [REMOTE_DS] Tienda API vacía, creando tienda local completa');
        return _createDefaultStoreCompanions();
      }
      
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error con tienda API, usando tienda local: $e');
      
      // 🔧 FALLBACK TOTAL: CREAR TIENDA LOCAL COMPLETA
      return _createDefaultStoreCompanions();
    }
  }

  @override
  Future<CompanionModel> adoptCompanion(String userId, String petId, {String? nickname}) async {
    try {
      debugPrint('🐾 [REMOTE_DS] Adoptando mascota: $petId para usuario: $userId');
      
      final requestData = {
        'petId': petId,
        if (nickname != null) 'nickname': nickname,
      };
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/$userId/adopt',
        data: requestData,
      );
      
      debugPrint('✅ [REMOTE_DS] Adopción exitosa: ${response.statusCode}');
      
      final companion = _mapApiResponseToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid adoption response format');
      }
      
      debugPrint('🎉 [REMOTE_DS] Adoptado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error adoptando mascota: $e');
      throw ServerException('Error adopting companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> purchaseCompanion(String userId, String petId, {String? nickname}) async {
    try {
      debugPrint('💰 [REMOTE_DS] Comprando mascota: $petId para usuario: $userId');
      
      final requestData = {
        'user_id': userId,
        'pet_id': petId,
        if (nickname != null) 'nickname': nickname,
      };
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/purchase',
        data: requestData,
      );
      
      debugPrint('✅ [REMOTE_DS] Compra exitosa: ${response.statusCode}');
      
      final companion = _mapApiResponseToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid purchase response format');
      }
      
      debugPrint('💰 [REMOTE_DS] Comprado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error comprando mascota: $e');
      throw ServerException('Error purchasing companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> evolveCompanion(String userId, String petId) async {
    try {
      debugPrint('⭐ [REMOTE_DS] Evolucionando mascota: $petId para usuario: $userId');
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/owned/$userId/$petId/evolve',
        data: {},
      );
      
      debugPrint('✅ [REMOTE_DS] Evolución exitosa: ${response.statusCode}');
      
      final companion = _mapApiResponseToCompanion(response.data, isOwned: true);
      if (companion == null) {
        throw ServerException('Invalid evolution response format');
      }
      
      debugPrint('🌟 [REMOTE_DS] Evolucionado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error evolucionando mascota: $e');
      throw ServerException('Error evolving companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> featureCompanion(String userId, String petId) async {
    try {
      debugPrint('⭐ [REMOTE_DS] Destacando mascota: $petId para usuario: $userId');
      
      final requestData = {
        'petId': petId,
      };
      
      final response = await apiClient.postGamification(
        '/api/gamification/pets/$userId/feature',
        data: requestData,
      );
      
      debugPrint('✅ [REMOTE_DS] Mascota destacada: ${response.statusCode}');
      
      final companion = _mapApiResponseToCompanion(response.data, isOwned: true, isFeatured: true);
      if (companion == null) {
        throw ServerException('Invalid feature response format');
      }
      
      debugPrint('🌟 [REMOTE_DS] Destacada: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error destacando mascota: $e');
      throw ServerException('Error featuring companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REMOTE_DS] Obteniendo estadísticas para usuario: $userId');
      
      // Obtener mascotas del usuario para calcular estadísticas
      final companions = await getUserCompanions(userId);
      final ownedCount = companions.length;
      
      // Calcular puntos disponibles (esto podría venir de otro endpoint)
      int totalPoints = 1000; // Valor por defecto, debería venir de un endpoint de puntos
      int spentPoints = 0;
      
      // Calcular puntos gastados estimados
      for (final companion in companions) {
        spentPoints += companion.purchasePrice;
      }
      
      final activeCompanionId = companions
          .where((c) => c.isSelected)
          .isNotEmpty 
          ? companions.firstWhere((c) => c.isSelected).id 
          : '';
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: 12, // 4 tipos x 3 etapas
        ownedCompanions: ownedCount,
        totalPoints: totalPoints,
        spentPoints: spentPoints,
        activeCompanionId: activeCompanionId,
        totalFeedCount: 0, // TODO: Implementar si la API lo soporta
        totalLoveCount: 0, // TODO: Implementar si la API lo soporta
        totalEvolutions: 0, // TODO: Implementar si la API lo soporta
        lastActivity: DateTime.now(),
      );
      
      debugPrint('📊 [REMOTE_DS] Stats calculados: ${stats.ownedCompanions}/${stats.totalCompanions}');
      return stats;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error obteniendo estadísticas: $e');
      throw ServerException('Error fetching companion stats: ${e.toString()}');
    }
  }

  // 🗺️ MÉTODO PRINCIPAL DE MAPEO API → COMPANION MODEL
  CompanionModel? _mapApiResponseToCompanion(
    dynamic petData, {
    bool isOwned = false,
    bool isInStore = false,
    bool isFeatured = false,
  }) {
    try {
      if (petData is! Map<String, dynamic>) {
        debugPrint('❌ [MAPPING] Datos de mascota no son un Map válido');
        return null;
      }

      // Extraer campos principales
      final id = petData['id']?.toString() ?? '';
      final name = petData['name']?.toString() ?? petData['nickname']?.toString() ?? '';
      final species = petData['species']?.toString()?.toLowerCase() ?? '';
      final rarity = petData['rarity']?.toString()?.toLowerCase() ?? 'common';
      final cost = _parseInteger(petData['quiz_points_cost'] ?? petData['cost'] ?? petData['price'] ?? 0);
      final isOnSale = petData['is_on_sale'] == true;
      final userCanAfford = petData['user_can_afford'] == true;
      final featured = petData['featured'] == true || isFeatured;
      final adopted = petData['adopted_at'] != null || isOwned;

      debugPrint('🔍 [MAPPING] Procesando: id=$id, name=$name, species=$species, rarity=$rarity');

      // Mapear especie a tipo local
      final localType = _mapSpeciesToLocalType(species, name);
      final localStage = _mapRarityToStage(rarity);
      
      if (localType == null || localStage == null) {
        debugPrint('❌ [MAPPING] No se pudo mapear tipo o etapa para: $species, $rarity');
        return null;
      }

      // Generar ID local consistente
      final localId = '${localType.name}_${localStage.name}';
      
      // Crear el modelo
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
        isSelected: featured,
        purchasedAt: adopted ? DateTime.now() : null,
        currentMood: CompanionMood.happy,
        purchasePrice: isOnSale ? (cost * 0.8).round() : cost,
        evolutionPrice: _getEvolutionPrice(localStage),
        unlockedAnimations: _getDefaultAnimations(),
        createdAt: DateTime.now(),
      );

      debugPrint('✅ [MAPPING] Mapeado exitosamente: ${companion.displayName} (${companion.id})');
      return companion;
    } catch (e) {
      debugPrint('❌ [MAPPING] Error mapeando mascota: $e');
      return null;
    }
  }

  // 🎯 MAPEO DE ESPECIES
  CompanionType? _mapSpeciesToLocalType(String species, String name) {
    final searchKey = '${species.toLowerCase()} ${name.toLowerCase()}';
    
    // Buscar en el mapeo por coincidencias
    for (final entry in _petTypeMapping.entries) {
      if (searchKey.contains(entry.key) || entry.key.contains(species.toLowerCase())) {
        switch (entry.value) {
          case 'dexter':
            return CompanionType.dexter;
          case 'elly':
            return CompanionType.elly;
          case 'paxolotl':
            return CompanionType.paxolotl;
          case 'yami':
            return CompanionType.yami;
        }
      }
    }
    
    // Fallback por especies comunes
    if (species.contains('dog') || species.contains('chihuahua')) return CompanionType.dexter;
    if (species.contains('panda')) return CompanionType.elly;
    if (species.contains('axolotl') || species.contains('ajolote')) return CompanionType.paxolotl;
    if (species.contains('jaguar') || species.contains('cat')) return CompanionType.yami;
    
    debugPrint('⚠️ [MAPPING] Especie no reconocida: $species, usando Dexter por defecto');
    return CompanionType.dexter;
  }

  // 🎯 MAPEO DE RAREZA A ETAPA
  CompanionStage? _mapRarityToStage(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
      case 'baby':
      case 'peque':
        return CompanionStage.baby;
      case 'rare':
      case 'young':
      case 'joven':
        return CompanionStage.young;
      case 'epic':
      case 'legendary':
      case 'adult':
      case 'adulto':
        return CompanionStage.adult;
      default:
        return CompanionStage.baby;
    }
  }

  // 🎨 MÉTODOS HELPER
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

  String _generateDescription(CompanionType type, CompanionStage stage) {
    final baseName = _getDisplayName(type);
    
    switch (stage) {
      case CompanionStage.baby:
        return 'Un adorable $baseName bebé lleno de energía';
      case CompanionStage.young:
        return '$baseName ha crecido y es más juguetón';
      case CompanionStage.adult:
        return '$baseName adulto, el compañero perfecto';
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 50;
      case CompanionStage.young:
        return 100;
      case CompanionStage.adult:
        return 0; // Ya no puede evolucionar
    }
  }

  List<String> _getDefaultAnimations() {
    return ['idle', 'blink', 'happy', 'eating', 'loving'];
  }

  int _parseInteger(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ==================== 🔧 MÉTODOS DE FALLBACK LOCAL ====================

  /// Crear la mascota inicial (Dexter) cuando el usuario no tiene ninguna
  CompanionModel _createInitialCompanion(String userId) {
    debugPrint('🐕 [FALLBACK] Creando Dexter inicial para usuario: $userId');
    
    return CompanionModel(
      id: 'dexter_baby',
      type: CompanionType.dexter,
      stage: CompanionStage.baby,
      name: 'Dexter',
      description: 'Tu primer compañero, un adorable chihuahua bebé',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true, // 🔧 ES LA MASCOTA INICIAL DEL USUARIO
      isSelected: true, // 🔧 ES LA MASCOTA ACTIVA POR DEFECTO
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔧 GRATIS COMO MASCOTA INICIAL
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
      createdAt: DateTime.now(),
    );
  }

  /// Crear el set completo de mascotas disponibles localmente
  List<CompanionModel> _createDefaultAvailableCompanions() {
    debugPrint('🎮 [FALLBACK] Creando set completo de mascotas disponibles localmente');
    
    final now = DateTime.now();
    
    return [
      // 🐕 DEXTER - Chihuahua (TODAS LAS ETAPAS)
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un adorable chihuahua bebé lleno de energía',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 0, // Gratis como inicial
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
        hunger: 90,
        energy: 95,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 75,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'happy', 'playing'],
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
        hunger: 95,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 150,
        evolutionPrice: 0, // Ya no puede evolucionar
        unlockedAnimations: ['idle', 'blink', 'happy', 'playing', 'guarding'],
        createdAt: now,
      ),
      
      // 🐼 ELLY - Panda (TODAS LAS ETAPAS)
      CompanionModel(
        id: 'elly_baby',
        type: CompanionType.elly,
        stage: CompanionStage.baby,
        name: 'Elly',
        description: 'Una tierna panda bebé que ama el bambú',
        level: 1,
        experience: 0,
        happiness: 95,
        hunger: 80,
        energy: 90,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 100,
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'eating'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'elly_young',
        type: CompanionType.elly,
        stage: CompanionStage.young,
        name: 'Elly',
        description: 'Elly joven, más grande y cariñosa',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 85,
        energy: 95,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 175,
        evolutionPrice: 125,
        unlockedAnimations: ['idle', 'blink', 'eating', 'rolling'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'elly_adult',
        type: CompanionType.elly,
        stage: CompanionStage.adult,
        name: 'Elly',
        description: 'Elly adulta, majestuosa y protectora',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 90,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 250,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'eating', 'rolling', 'meditating'],
        createdAt: now,
      ),
      
      // 🦎 PAXOLOTL - Ajolote (TODAS LAS ETAPAS)
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un pequeño ajolote lleno de curiosidad',
        level: 1,
        experience: 0,
        happiness: 90,
        hunger: 85,
        energy: 80,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 150,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'swimming'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'paxolotl_young',
        type: CompanionType.paxolotl,
        stage: CompanionStage.young,
        name: 'Paxolotl',
        description: 'Paxolotl joven, misterioso y regenerativo',
        level: 1,
        experience: 0,
        happiness: 95,
        hunger: 90,
        energy: 85,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 225,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'swimming', 'regenerating'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'paxolotl_adult',
        type: CompanionType.paxolotl,
        stage: CompanionStage.adult,
        name: 'Paxolotl',
        description: 'Paxolotl adulto, el guardián de Xochimilco',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 95,
        energy: 90,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 300,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'swimming', 'regenerating', 'healing'],
        createdAt: now,
      ),
      
      // 🐆 YAMI - Jaguar (TODAS LAS ETAPAS)
      CompanionModel(
        id: 'yami_baby',
        type: CompanionType.yami,
        stage: CompanionStage.baby,
        name: 'Yami',
        description: 'Un jaguar bebé feroz pero tierno',
        level: 1,
        experience: 0,
        happiness: 85,
        hunger: 75,
        energy: 95,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 200,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'prowling'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'yami_young',
        type: CompanionType.yami,
        stage: CompanionStage.young,
        name: 'Yami',
        description: 'Yami joven, ágil y valiente',
        level: 1,
        experience: 0,
        happiness: 90,
        hunger: 80,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 275,
        evolutionPrice: 200,
        unlockedAnimations: ['idle', 'blink', 'prowling', 'hunting'],
        createdAt: now,
      ),
      
      CompanionModel(
        id: 'yami_adult',
        type: CompanionType.yami,
        stage: CompanionStage.adult,
        name: 'Yami',
        description: 'Yami adulto, el rey de la selva',
        level: 1,
        experience: 0,
        happiness: 95,
        hunger: 85,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 350,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'prowling', 'hunting', 'roaring'],
        createdAt: now,
      ),
    ];
  }

  /// Crear tienda completa con mascotas para comprar
  List<CompanionModel> _createDefaultStoreCompanions() {
    debugPrint('🏪 [FALLBACK] Creando tienda completa local');
    
    // Obtener todas las mascotas disponibles pero marcadas como no poseídas
    final allCompanions = _createDefaultAvailableCompanions();
    
    // Filtrar solo las que no son la inicial de Dexter baby (que es gratis)
    final storeCompanions = allCompanions.where((companion) {
      return !(companion.type == CompanionType.dexter && companion.stage == CompanionStage.baby);
    }).toList();
    
    debugPrint('🏪 [FALLBACK] Tienda creada con ${storeCompanions.length} mascotas');
    
    return storeCompanions;
  }
}