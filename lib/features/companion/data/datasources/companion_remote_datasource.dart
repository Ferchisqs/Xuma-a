// lib/features/companion/data/datasources/companion_remote_datasource.dart - ACTUALIZADO PARA API
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/companion_model.dart';
import '../models/companion_api_model.dart';
import '../models/companion_stats_model.dart';

abstract class CompanionRemoteDataSource {
  Future<List<CompanionModel>> getUserCompanions(String userId);
  Future<List<CompanionModel>> getAvailableCompanions();
  Future<List<CompanionModel>> getStoreCompanions();
  Future<CompanionModel> adoptCompanion(String userId, String petId, String speciesType);
  Future<CompanionModel> evolveCompanion(String userId, String petId);
  Future<CompanionModel> featureCompanion(String userId, String petId);
  Future<CompanionModel> selectCompanionStage(String userId, String petId, String stage);
  Future<CompanionModel> getCompanionDetails(String petId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;

  CompanionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      debugPrint('🌐 [REMOTE_DS] Obteniendo mascotas del usuario: $userId');
      
      final response = await apiClient.get(
        ApiEndpoints.getUserPets(userId),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Respuesta recibida: ${response.statusCode}');
      
      // La API devuelve directamente una lista
      final List<dynamic> petsJson = response.data;
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas encontradas');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final apiModel = CompanionApiModel.fromJson(petJson);
          final companion = CompanionModel.fromEntity(apiModel.toEntity());
          companions.add(companion);
          
          debugPrint('✅ [REMOTE_DS] Procesada: ${companion.displayName} (${companion.type.name}_${companion.stage.name})');
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota individual: $e');
          debugPrint('📄 [REMOTE_DS] JSON problemático: $petJson');
        }
      }
      
      debugPrint('🎯 [REMOTE_DS] Total procesadas exitosamente: ${companions.length}');
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error obteniendo mascotas del usuario: $e');
      throw ServerException('Error fetching user companions: ${e.toString()}');
    }
  }

  @override
  Future<List<CompanionModel>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REMOTE_DS] Obteniendo mascotas disponibles para adoptar');
      
      final response = await apiClient.get(
        ApiEndpoints.availablePets,
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Mascotas disponibles recibidas: ${response.statusCode}');
      
      final List<dynamic> petsJson = response.data;
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas disponibles');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final apiModel = CompanionApiModel.fromJson(petJson);
          final companion = CompanionModel.fromEntity(apiModel.toEntity());
          companions.add(companion);
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota disponible: $e');
        }
      }
      
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error obteniendo mascotas disponibles: $e');
      throw ServerException('Error fetching available companions: ${e.toString()}');
    }
  }

  @override
  Future<List<CompanionModel>> getStoreCompanions() async {
    try {
      debugPrint('🏪 [REMOTE_DS] Obteniendo tienda de mascotas');
      
      final response = await apiClient.get(
        ApiEndpoints.petStore,
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Tienda recibida: ${response.statusCode}');
      
      // La respuesta puede tener estructura diferente para la tienda
      dynamic storeData = response.data;
      List<dynamic> petsJson;
      
      if (storeData is Map<String, dynamic> && storeData.containsKey('pets')) {
        petsJson = storeData['pets'];
      } else if (storeData is List) {
        petsJson = storeData;
      } else {
        throw ServerException('Formato de respuesta de tienda inesperado');
      }
      
      debugPrint('📊 [REMOTE_DS] ${petsJson.length} mascotas en tienda');
      
      final companions = <CompanionModel>[];
      
      for (final petJson in petsJson) {
        try {
          final apiModel = CompanionApiModel.fromJson(petJson);
          final companion = CompanionModel.fromEntity(apiModel.toEntity());
          companions.add(companion);
        } catch (e) {
          debugPrint('❌ [REMOTE_DS] Error procesando mascota de tienda: $e');
        }
      }
      
      return companions;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error obteniendo tienda: $e');
      throw ServerException('Error fetching store companions: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> adoptCompanion(String userId, String petId, String speciesType) async {
    try {
      debugPrint('🐾 [REMOTE_DS] Adoptando mascota: $petId para usuario: $userId');
      
      final request = AdoptPetRequest(
        petId: petId,
        speciesType: speciesType,
      );
      
      final response = await apiClient.post(
        ApiEndpoints.getAdoptPet(userId),
        data: request.toJson(),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Adopción exitosa: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('🎉 [REMOTE_DS] Adoptado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error adoptando mascota: $e');
      throw ServerException('Error adopting companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> evolveCompanion(String userId, String petId) async {
    try {
      debugPrint('⭐ [REMOTE_DS] Evolucionando mascota: $petId para usuario: $userId');
      
      final request = EvolvePetRequest(petId: petId);
      
      final response = await apiClient.post(
        ApiEndpoints.getEvolveOwnedPet(userId, petId),
        data: request.toJson(),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Evolución exitosa: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('🌟 [REMOTE_DS] Evolucionado: ${companion.displayName} a ${companion.stage.name}');
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
      
      final request = FeaturePetRequest(petId: petId);
      
      final response = await apiClient.post(
        ApiEndpoints.getFeaturePet(userId),
        data: request.toJson(),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Mascota destacada: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('🌟 [REMOTE_DS] Destacada: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error destacando mascota: $e');
      throw ServerException('Error featuring companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> selectCompanionStage(String userId, String petId, String stage) async {
    try {
      debugPrint('🔄 [REMOTE_DS] Seleccionando etapa: $stage para mascota: $petId');
      
      final request = SelectStageRequest(selectedStage: stage);
      
      final response = await apiClient.patch(
        ApiEndpoints.getSelectPetStage(userId, petId),
        data: request.toJson(),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Etapa seleccionada: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('🔄 [REMOTE_DS] Etapa cambiada: ${companion.displayName} -> ${companion.stage.name}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error seleccionando etapa: $e');
      throw ServerException('Error selecting companion stage: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> getCompanionDetails(String petId) async {
    try {
      debugPrint('🔍 [REMOTE_DS] Obteniendo detalles de mascota: $petId');
      
      final response = await apiClient.get(
        ApiEndpoints.getPetDetails(petId),
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Detalles recibidos: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('🔍 [REMOTE_DS] Detalles procesados: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error obteniendo detalles: $e');
      throw ServerException('Error fetching companion details: ${e.toString()}');
    }
  }

  // 🔧 MÉTODOS ADICIONALES PARA COMPATIBILIDAD CON INTERFAZ ANTERIOR

  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REMOTE_DS] Obteniendo estadísticas para usuario: $userId');
      
      // Obtener mascotas del usuario para calcular estadísticas
      final companions = await getUserCompanions(userId);
      final ownedCount = companions.where((c) => c.isOwned).length;
      
      // TODO: Implementar endpoint específico para estadísticas si existe
      // Por ahora calculamos basado en las mascotas obtenidas
      
      final stats = CompanionStatsModel(
        userId: userId,
        totalCompanions: 12, // 4 tipos x 3 etapas
        ownedCompanions: ownedCount,
        totalPoints: 1000, // TODO: Obtener de endpoint de puntos
        spentPoints: ownedCount * 50, // Estimado
        activeCompanionId: companions.where((c) => c.isSelected).isNotEmpty 
          ? companions.firstWhere((c) => c.isSelected).id 
          : '',
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

  // 🔧 MÉTODO ALTERNATIVO DE COMPRA (USANDO PURCHASE ENDPOINT)
  Future<CompanionModel> purchaseCompanion(String userId, String petId, String speciesType) async {
    try {
      debugPrint('💰 [REMOTE_DS] Comprando mascota: $petId para usuario: $userId');
      
      final requestData = {
        'user_id': userId,
        'pet_id': petId,
        'species_type': speciesType,
      };
      
      final response = await apiClient.post(
        ApiEndpoints.purchasePet,
        data: requestData,
        options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
      );
      
      debugPrint('✅ [REMOTE_DS] Compra exitosa: ${response.statusCode}');
      
      final apiModel = CompanionApiModel.fromJson(response.data);
      final companion = CompanionModel.fromEntity(apiModel.toEntity());
      
      debugPrint('💰 [REMOTE_DS] Comprado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [REMOTE_DS] Error comprando mascota: $e');
      throw ServerException('Error purchasing companion: ${e.toString()}');
    }
  }

  // 🔧 MÉTODOS DE INTERACCIÓN (COMPATIBILIDAD)
  Future<CompanionModel> feedCompanion(String userId, String companionId) async {
    // TODO: Implementar si la API soporta alimentar mascotas
    // Por ahora retornamos la mascota sin cambios
    debugPrint('🍎 [REMOTE_DS] Feed no implementado en API, usando mock');
    throw UnimplementedError('Feed companion not implemented in API');
  }

  Future<CompanionModel> loveCompanion(String userId, String companionId) async {
    // TODO: Implementar si la API soporta dar amor a mascotas
    // Por ahora retornamos la mascota sin cambios
    debugPrint('💖 [REMOTE_DS] Love no implementado en API, usando mock');
    throw UnimplementedError('Love companion not implemented in API');
  }
}