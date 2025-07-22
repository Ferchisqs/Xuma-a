// lib/features/companion/data/datasources/companion_remote_datasource.dart
// 🔥 EVOLUCIÓN Y FEATURE CONECTADOS A API REAL + MANEJO DE ERRORES MEJORADO

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
  
  // 🔥 NUEVOS MÉTODOS PARA API REAL - ACTUALIZADOS
  Future<CompanionModel> evolvePetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> featurePetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> evolveOwnedPetViaApi(
      {required String userId, required String petId});
  Future<CompanionModel> selectPetStageViaApi(
      {required String userId, required String petId, required int stage});
  
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
      debugPrint('👤 [API] === OBTENIENDO MASCOTAS DEL USUARIO ===');
      debugPrint('👤 [API] Usuario ID: $userId');

      final response = await apiClient.getGamification(
        '/api/gamification/pets/$userId',
        requireAuth: true,
      );

      debugPrint('✅ [API] Respuesta mascotas usuario: ${response.statusCode}');
      debugPrint('📄 [API] Raw data type: ${response.data.runtimeType}');
      debugPrint('📄 [API] Raw data: ${response.data}');

      if (response.data == null) {
        debugPrint('ℹ️ [API] Usuario sin mascotas adoptadas');
        return [];
      }

      List<CompanionModel> adoptedCompanions = [];

      // Manejar diferentes formatos de respuesta
      dynamic petsData;

      if (response.data is List) {
        petsData = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        petsData = dataMap['pets'] ??
            dataMap['data'] ??
            dataMap['owned_pets'] ??
            dataMap['companions'] ??
            [];
        debugPrint('🔍 [API] Buscando en campos: ${dataMap.keys.toList()}');
      } else {
        debugPrint('⚠️ [API] Formato de respuesta inesperado: ${response.data.runtimeType}');
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
          debugPrint('🐾 [API] Procesando mascota $i: $petData');

          if (petData is Map<String, dynamic>) {
            final companion = _mapAdoptedPetToCompanion(petData);
            adoptedCompanions.add(companion);
            debugPrint('✅ [API] Mascota mapeada: ${companion.displayName} (${companion.id})');
          } else {
            debugPrint('⚠️ [API] Dato de mascota no es un mapa: ${petData.runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ [API] Error mapeando mascota $i: $e');
        }
      }

      debugPrint('✅ [API] === MASCOTAS USUARIO PROCESADAS ===');
      debugPrint('🏠 [API] Total mascotas del usuario: ${adoptedCompanions.length}');

      // Marcar todas las mascotas de la API como poseídas
      for (int i = 0; i < adoptedCompanions.length; i++) {
        adoptedCompanions[i] = adoptedCompanions[i].copyWith(
          isOwned: true,
          isSelected: i == 0,
        );
        debugPrint('✅ [REPO] Mascota ${i}: ${adoptedCompanions[i].displayName} - owned: ${adoptedCompanions[i].isOwned}');
      }

      // Validación adicional: Si hay mascotas pero ninguna está seleccionada
      if (adoptedCompanions.isNotEmpty && 
          !adoptedCompanions.any((c) => c.isSelected)) {
        adoptedCompanions[0] = adoptedCompanions[0].copyWith(isSelected: true);
        debugPrint('⭐ [REPO] Activando primera mascota: ${adoptedCompanions[0].displayName}');
      }

      return adoptedCompanions;
    } catch (e) {
      debugPrint('❌ [API] Error obteniendo mascotas usuario: $e');
      debugPrint('🔧 [API] Retornando lista vacía por error');
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
      debugPrint('🏪 [API] === OBTENIENDO TIENDA CON USER ID REAL ===');
      debugPrint('👤 [API] Usuario: $userId');

      if (userId.isEmpty) {
        debugPrint('❌ [API] User ID vacío, no se puede obtener tienda');
        throw Exception('User ID requerido para obtener tienda');
      }

      debugPrint('📡 [API] Obteniendo mascotas disponibles...');
      final allCompanions = await getAvailableCompanions();
      debugPrint('✅ [API] Mascotas disponibles: ${allCompanions.length}');

      debugPrint('📡 [API] Obteniendo mascotas del usuario...');
      final userCompanions = await getUserCompanions(userId);
      debugPrint('✅ [API] Mascotas del usuario: ${userCompanions.length}');

      // Crear set de IDs adoptados para filtrar
      final adoptedIds = <String>{};
      
      for (final companion in userCompanions) {
        adoptedIds.add(companion.id);
        final localId = '${companion.type.name}_${companion.stage.name}';
        adoptedIds.add(localId);
        debugPrint('🔍 [API] Mascota adoptada: ${companion.id} (${companion.displayName})');
      }
      
      debugPrint('🔍 [API] Total IDs adoptados: $adoptedIds');

      // Filtrar mascotas no adoptadas para la tienda
      final storeCompanions = <CompanionModel>[];
      
      for (final companion in allCompanions) {
        final isNotAdopted = !adoptedIds.contains(companion.id);
        debugPrint('🔍 [API] ${companion.id}: ${isNotAdopted ? "EN TIENDA" : "YA ADOPTADO"}');
        
        if (isNotAdopted) {
          storeCompanions.add(companion);
        }
      }

      // Agregar Dexter joven gratis si no lo tiene
      final hasDexterYoung = userCompanions.any((c) =>
          c.type == CompanionType.dexter && c.stage == CompanionStage.young);

      if (!hasDexterYoung) {
        debugPrint('🎁 [API] Usuario no tiene Dexter joven, agregándolo gratis a la tienda');
        
        final existingDexterYoung = storeCompanions.firstWhere(
          (c) => c.type == CompanionType.dexter && c.stage == CompanionStage.young,
          orElse: () => _createDexterYoungForStore(),
        );
        
        if (!storeCompanions.any((c) => c.type == CompanionType.dexter && c.stage == CompanionStage.young)) {
          storeCompanions.insert(0, existingDexterYoung);
        }
      }

      // Ordenar por precio (más baratos primero)
      storeCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));

      debugPrint('🛍️ [API] === TIENDA FINAL ===');
      debugPrint('🛒 [API] Mascotas en tienda: ${storeCompanions.length}');

      for (final companion in storeCompanions) {
        debugPrint('🏪 [API] - ${companion.displayName} (${companion.id}): ${companion.purchasePrice}★');
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