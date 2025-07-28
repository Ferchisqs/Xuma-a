
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
      Future<CompanionModel> evolvePetViaApi({
      required String userId, 
      required String petId,
      CompanionStage? currentStage, // 🔥 NUEVA: Etapa actual para evolución correcta
  });
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
    debugPrint('📈 [API] === AUMENTANDO STATS VIA API REAL CON DEBUG ===');
    debugPrint('🆔 [API] idUserPet recibido: "$idUserPet"');
    debugPrint('😊 [API] Happiness a aumentar: ${happiness ?? 0}');
    debugPrint('❤️ [API] Health a aumentar: ${health ?? 0}');

    // 🔥 VALIDACIÓN DEL idUserPet
    if (idUserPet.isEmpty || idUserPet.startsWith('ERROR_') || idUserPet.startsWith('FALLBACK_')) {
      debugPrint('❌ [API] idUserPet INVÁLIDO: "$idUserPet"');
      throw ServerException('🔧 ID de mascota inválido: $idUserPet');
    }

    final endpoint = '/api/gamification/pet-stats/$idUserPet/increase';
    final requestBody = <String, dynamic>{};
    
    // 🔥 CONSTRUCCIÓN CUIDADOSA DEL BODY
    if (happiness != null && happiness > 0) {
      requestBody['happiness'] = happiness;
      debugPrint('✅ [API] Agregando happiness: $happiness');
    }
    
    if (health != null && health > 0) {
      requestBody['health'] = health;
      debugPrint('✅ [API] Agregando health: $health');
    }
    
    // 🔥 VALIDACIÓN DEL BODY
    if (requestBody.isEmpty) {
      debugPrint('⚠️ [API] Request body vacío, no hay nada que aumentar');
      throw ServerException('No hay estadísticas para aumentar');
    }

    debugPrint('📦 [API] === REQUEST DETAILS ===');
    debugPrint('🌐 [API] Endpoint completo: $endpoint');
    debugPrint('📄 [API] Request body: $requestBody');
    debugPrint('🔧 [API] Content-Type: application/json');

    final response = await apiClient.postGamification(
      endpoint,
      data: requestBody,
    );

    debugPrint('📨 [API] === RESPONSE DETAILS ===');
    debugPrint('✅ [API] Status code: ${response.statusCode}');
    debugPrint('📄 [API] Response headers: ${response.headers}');
    debugPrint('📄 [API] Response data type: ${response.data?.runtimeType}');
    debugPrint('📄 [API] Response data: ${response.data}');

    if (response.statusCode == 200 || 
        response.statusCode == 201 || 
        response.statusCode == 204) {
      debugPrint('🎉 [API] === AUMENTO DE STATS EXITOSO ===');
      
      // 🔥 OBTENER ESTADÍSTICAS ACTUALIZADAS
      final userId = await tokenManager.getUserId();
      if (userId != null) {
        debugPrint('🔄 [API] Obteniendo stats actualizadas desde pet details...');
        try {
          return await getPetDetails(petId: idUserPet, userId: userId);
        } catch (detailsError) {
          debugPrint('⚠️ [API] Error obteniendo detalles: $detailsError');
          // Fallback: crear companion desde respuesta
          return _createCompanionFromStatsResponse(idUserPet, response.data);
        }
      } else {
        // Fallback: crear companion desde respuesta
        return _createCompanionFromStatsResponse(idUserPet, response.data);
      }
    } else {
      debugPrint('❌ [API] Error en response: ${response.statusCode}');
      throw ServerException(
          'Error aumentando stats: código ${response.statusCode}, data: ${response.data}');
    }
  } catch (e) {
    debugPrint('❌ [API] === ERROR DETALLADO ===');
    debugPrint('💥 [API] Tipo de error: ${e.runtimeType}');
    debugPrint('📄 [API] Error completo: $e');
    
    final errorMessage = e.toString().toLowerCase();
    
    // 🔥 ANÁLISIS ESPECÍFICO DE ERRORES
    if (errorMessage.contains('not found') || errorMessage.contains('404')) {
      debugPrint('🔍 [API] Error 404: Mascota no encontrada');
      debugPrint('🔧 [API] Verificar idUserPet: "$idUserPet"');
      throw ServerException('🔍 Mascota no encontrada (ID: $idUserPet)');
    } else if (errorMessage.contains('400') || errorMessage.contains('bad request')) {
      debugPrint('📝 [API] Error 400: Request inválido');
      debugPrint('🔧 [API] Verificar formato del JSON');
      throw ServerException('📝 Formato de request inválido');
    } else if (errorMessage.contains('maximum') || errorMessage.contains('máximo')) {
      debugPrint('📊 [API] Error: Stats al máximo');
      throw ServerException('📊 Las estadísticas ya están al máximo');
    } else if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
      debugPrint('🔐 [API] Error de autenticación');
      throw ServerException('🔐 Error de autenticación');
    } else {
      debugPrint('❓ [API] Error desconocido');
      throw ServerException('❌ Error aumentando estadísticas: ${e.toString()}');
    }
  }
}

 @override
Future<CompanionModel> getPetDetails({
  required String petId, 
  required String userId
}) async {
  try {
    debugPrint('🔍 [API] === OBTENIENDO DETALLES DE MASCOTA MEJORADO ===');
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
    
    // 🔥 EXTRACCIÓN BÁSICA CON VALIDACIÓN
    final responsePetId = petData['pet_id'] as String? ?? petId;
    final name = petData['name'] as String? ?? 'Mascota';
    final description = petData['description'] as String? ?? 'Una mascota especial';
    final speciesType = petData['species_type'] as String? ?? 'mammal';
    
    debugPrint('🐾 [API] Pet básico - ID: $responsePetId, Nombre: $name, Tipo: $speciesType');

    // 🔥 MAPEO CORRECTO DEL TIPO BASADO EN LA RESPUESTA REAL
    final companionType = _mapNameAndSpeciesToCompanionType(name, speciesType, responsePetId);
    debugPrint('🎯 [API] Tipo mapeado: ${companionType.name}');

    // 🔥 EXTRACCIÓN BASE STATS
    final baseStats = petData['base_stats'] as Map<String, dynamic>? ?? {};
    final baseHealth = (baseStats['health'] as num?)?.toInt() ?? 100;
    final baseHappiness = (baseStats['happiness'] as num?)?.toInt() ?? 100;
    
    debugPrint('📊 [API] Base stats - Salud: $baseHealth, Felicidad: $baseHappiness');

    // 🔥 EXTRACCIÓN USER INFO
    final userInfo = petData['user_info'] as Map<String, dynamic>? ?? {};
    final userOwns = userInfo['user_owns'] as bool? ?? false;
    final userCanAfford = userInfo['user_can_afford'] as bool? ?? false;
    final userAvailablePoints = (userInfo['user_available_points'] as num?)?.toInt() ?? 0;
    
    debugPrint('👤 [API] User info - Posee: $userOwns, Puede comprar: $userCanAfford, Puntos: $userAvailablePoints');

    // 🔥 EXTRACCIÓN MEJORADA DEL USER PET INFO
    final userPetInfo = userInfo['user_pet_info'] as Map<String, dynamic>? ?? {};
    
    // 🔥 BÚSQUEDA EXHAUSTIVA DEL idUserPet
    String idUserPet = '';
    final possibleIdKeys = [
      'idUserPet',     // Principal
      'id_user_pet',   // Snake case
      'userPetId',     // Camel case
      'user_pet_id',   // Otra variación
      'id',            // ID genérico
      'petId',         // Pet ID dentro de user_pet_info
      'user_pet_instance_id', // ID de instancia específica
      'instance_id',   // ID de instancia
    ];
    
    debugPrint('🔍 [API] === BÚSQUEDA EXHAUSTIVA DE idUserPet ===');
    debugPrint('📄 [API] user_pet_info keys: ${userPetInfo.keys.toList()}');
    
    for (final key in possibleIdKeys) {
      if (userPetInfo.containsKey(key) && userPetInfo[key] != null) {
        final value = userPetInfo[key].toString();
        debugPrint('🎯 [API] Encontrado $key: "$value"');
        
        if (value.isNotEmpty && value != 'null' && value != 'undefined') {
          idUserPet = value;
          debugPrint('✅ [API] idUserPet CONFIRMADO: $idUserPet');
          break;
        }
      }
    }
    
    // 🔥 VERIFICACIÓN CRÍTICA
    if (idUserPet.isEmpty) {
      debugPrint('🆘 [API] === CRÍTICO: NO SE ENCONTRÓ idUserPet ===');
      debugPrint('📄 [API] Contenido completo de user_pet_info:');
      userPetInfo.forEach((key, value) {
        debugPrint('   $key: $value (${value.runtimeType})');
      });
      
      // 🔥 FALLBACK: usar el pet_id original con un marcador especial
      idUserPet = 'INSTANCE_${responsePetId}_${companionType.name}_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('🚨 [API] Usando FALLBACK ID con tipo específico: $idUserPet');
    }
    
    // 🔥 EXTRACCIÓN DEL RESTO DE DATOS
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

    // 🔥 MAPEO CORRECTO DE LA ETAPA
    final companionStage = _mapEvolutionStageToCompanionStage(evolutionStage);
    
    // 🔥 CREAR COMPANION MODEL CON EL TIPO CORRECTO
    final companion = CompanionModelWithPetId(
      id: '${companionType.name}_${companionStage.name}', // 🔥 USAR TIPO CORRECTO
      type: companionType, // 🔥 USAR TIPO MAPEADO CORRECTAMENTE
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
      petId: idUserPet, // 🔥 USAR EL idUserPet EXTRAÍDO O FALLBACK
    );

    debugPrint('✅ [API] === COMPANION CREADO CON TIPO CORRECTO ===');
    debugPrint('🐾 [API] ${companion.displayName} - Tipo: ${companion.type.name}');
    debugPrint('🆔 [API] Pet ID: ${companion.petId}');
    debugPrint('📊 [API] Stats: Felicidad: ${companion.happiness}, Salud: ${companion.hunger}');
    
    // 🔥 VERIFICACIÓN FINAL
    if (companion.petId.startsWith('INSTANCE_')) {
      debugPrint('⚠️ [API] ADVERTENCIA: Se está usando un FALLBACK ID');
      debugPrint('💡 [API] ACCIÓN REQUERIDA: Verificar estructura de respuesta de API');
    }
    
    return companion;

  } catch (e) {
    debugPrint('❌ [API] Error obteniendo detalles de mascota: $e');
    throw ServerException('Error obteniendo detalles de mascota: ${e.toString()}');
  }
}

CompanionType _mapNameAndSpeciesToCompanionType(String name, String speciesType, String petId) {
  debugPrint('🔍 [MAPPING] === MAPEO COMPLETO DE TIPO ===');
  debugPrint('📛 [MAPPING] Nombre: $name');
  debugPrint('🧬 [MAPPING] Especie: $speciesType');
  debugPrint('🆔 [MAPPING] Pet ID: $petId');
  
  final nameLower = name.toLowerCase();
  final speciesLower = speciesType.toLowerCase();
  final petIdLower = petId.toLowerCase();
  
  // 🔥 PRIORIDAD 1: MAPEO POR NOMBRE ESPECÍFICO
  if (nameLower.contains('dexter')) {
    debugPrint('✅ [MAPPING] Detectado DEXTER por nombre');
    return CompanionType.dexter;
  } else if (nameLower.contains('elly')) {
    debugPrint('✅ [MAPPING] Detectado ELLY por nombre');
    return CompanionType.elly;
  } else if (nameLower.contains('paxoloth') || nameLower.contains('paxolotl')) {
    debugPrint('✅ [MAPPING] Detectado PAXOLOTL por nombre');
    return CompanionType.paxolotl;
  } else if (nameLower.contains('yami')) {
    debugPrint('✅ [MAPPING] Detectado YAMI por nombre');
    return CompanionType.yami;
  }
  
  // 🔥 PRIORIDAD 2: MAPEO POR ESPECIE
  if (speciesLower.contains('dog') || 
      speciesLower.contains('chihuahua') || 
      speciesLower.contains('mammal') ||
      speciesLower.contains('canine')) {
    debugPrint('✅ [MAPPING] Detectado DEXTER por especie');
    return CompanionType.dexter;
  } else if (speciesLower.contains('panda') || 
             speciesLower.contains('bear') ||
             speciesLower.contains('oso')) {
    debugPrint('✅ [MAPPING] Detectado ELLY por especie');
    return CompanionType.elly;
  } else if (speciesLower.contains('axolotl') || 
             speciesLower.contains('ajolote') ||
             speciesLower.contains('amphibian') ||
             speciesLower.contains('anfibio')) {
    debugPrint('✅ [MAPPING] Detectado PAXOLOTL por especie');
    return CompanionType.paxolotl;
  } else if (speciesLower.contains('jaguar') || 
             speciesLower.contains('felino') ||
             speciesLower.contains('cat') ||
             speciesLower.contains('feline')) {
    debugPrint('✅ [MAPPING] Detectado YAMI por especie');
    return CompanionType.yami;
  }
  
  // 🔥 PRIORIDAD 3: MAPEO POR PET ID (UUIDs específicos)
  if (petId == 'e0512239-dc32-444f-a354-ef94446e5f1c') {
    debugPrint('✅ [MAPPING] Detectado DEXTER por UUID específico');
    return CompanionType.dexter;
  } else if (petId == 'ab23c9ee-a63a-4114-aff7-8ef9899b33f6') {
    debugPrint('✅ [MAPPING] Detectado ELLY por UUID específico');
    return CompanionType.elly;
  } else if (petId == 'afdfcdfa-aed6-4320-a8e5-51debbd1bccf') {
    debugPrint('✅ [MAPPING] Detectado PAXOLOTL por UUID específico');
    return CompanionType.paxolotl;
  } else if (petId == '19119059-bb47-40e2-8eb5-8cf7a66f21b8') {
    debugPrint('✅ [MAPPING] Detectado YAMI por UUID específico');
    return CompanionType.yami;
  }
  
  // 🔥 PRIORIDAD 4: MAPEO POR PATRONES EN PET ID
  if (petIdLower.contains('dexter') || 
      petIdLower.contains('dog') ||
      petIdLower.startsWith('d') ||
      petIdLower.contains('001')) {
    debugPrint('✅ [MAPPING] Detectado DEXTER por patrón en Pet ID');
    return CompanionType.dexter;
  } else if (petIdLower.contains('elly') || 
             petIdLower.contains('panda') ||
             petIdLower.startsWith('e') ||
             petIdLower.contains('002')) {
    debugPrint('✅ [MAPPING] Detectado ELLY por patrón en Pet ID');
    return CompanionType.elly;
  } else if (petIdLower.contains('paxolotl') || 
             petIdLower.contains('axolotl') ||
             petIdLower.startsWith('p') ||
             petIdLower.contains('003')) {
    debugPrint('✅ [MAPPING] Detectado PAXOLOTL por patrón en Pet ID');
    return CompanionType.paxolotl;
  } else if (petIdLower.contains('yami') || 
             petIdLower.contains('jaguar') ||
             petIdLower.startsWith('y') ||
             petIdLower.contains('004')) {
    debugPrint('✅ [MAPPING] Detectado YAMI por patrón en Pet ID');
    return CompanionType.yami;
  }
  
  // 🔥 ÚLTIMO RECURSO: HASH BASADO EN MÚLTIPLES FACTORES
  debugPrint('⚠️ [MAPPING] No se detectó tipo específico, usando hash combinado');
  
  // Combinar nombre, especie y petId para un hash más determinístico
  final combinedString = '$name-$speciesType-$petId';
  final hash = combinedString.hashCode.abs() % 4;
  
  switch (hash) {
    case 0:
      debugPrint('🎲 [MAPPING] Hash combinado asignó DEXTER');
      return CompanionType.dexter;
    case 1:
      debugPrint('🎲 [MAPPING] Hash combinado asignó ELLY');
      return CompanionType.elly;
    case 2:
      debugPrint('🎲 [MAPPING] Hash combinado asignó PAXOLOTL');
      return CompanionType.paxolotl;
    case 3:
      debugPrint('🎲 [MAPPING] Hash combinado asignó YAMI');
      return CompanionType.yami;
    default:
      debugPrint('🔄 [MAPPING] Fallback final a DEXTER');
      return CompanionType.dexter;
  }
}


@override
Future<List<CompanionModel>> getUserCompanions(String userId) async {
  try {
    debugPrint('👤 [API] === OBTENIENDO MASCOTAS DEL USUARIO CON VALIDACIÓN DE TIPOS ===');
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
        debugPrint('🐾 [API] === PROCESANDO MASCOTA $i ===');
        debugPrint('📄 [API] Pet data: $petData');

        if (petData is Map<String, dynamic>) {
          // 🔥 EXTRAER EL pet_id PARA LLAMAR A getPetDetails
          final petId = petData['id'] as String? ?? 
                       petData['pet_id'] as String? ?? 
                       petData['petId'] as String? ?? 
                       'unknown';
          
          final petName = petData['name'] as String? ?? 'Mascota';
          final speciesType = petData['species_type'] as String? ?? 'unknown';
          
          debugPrint('🆔 [API] Pet ID extraído: $petId');
          debugPrint('📛 [API] Nombre: $petName');
          debugPrint('🧬 [API] Especie: $speciesType');
          
          // 🔥 DETERMINAR EL TIPO ESPERADO DESDE LOS DATOS BÁSICOS
          final expectedType = _mapNameAndSpeciesToCompanionType(petName, speciesType, petId);
          debugPrint('🎯 [API] Tipo esperado: ${expectedType.name}');
          
          // 🔥 OBTENER DETALLES COMPLETOS CON idUserPet
          try {
            debugPrint('🔄 [API] Obteniendo detalles con idUserPet para: $petId');
            final companionWithRealStats = await getPetDetails(petId: petId, userId: userId);
            
            // 🔥 VERIFICAR QUE EL TIPO SEA CORRECTO
            if (companionWithRealStats.type != expectedType) {
              debugPrint('⚠️ [API] === ADVERTENCIA: TIPO NO COINCIDE ===');
              debugPrint('🎯 [API] Tipo esperado: ${expectedType.name}');
              debugPrint('🔍 [API] Tipo devuelto: ${companionWithRealStats.type.name}');
              debugPrint('💡 [API] Corriendo corrección de tipo...');
              
              // 🔥 CORREGIR EL TIPO SI ES NECESARIO
              final correctedCompanion = _correctCompanionType(companionWithRealStats, expectedType, petName);
              adoptedCompanions.add(correctedCompanion);
            } else {
              debugPrint('✅ [API] Tipo correcto: ${companionWithRealStats.type.name}');
              
              // 🔥 VERIFICAR QUE TENGA idUserPet VÁLIDO
              if (companionWithRealStats is CompanionModelWithPetId) {
                final idUserPet = companionWithRealStats.petId;
                debugPrint('✅ [API] Mascota con idUserPet: ${companionWithRealStats.displayName} -> $idUserPet');
                
                if (idUserPet.isNotEmpty && idUserPet != 'unknown') {
                  adoptedCompanions.add(companionWithRealStats);
                } else {
                  debugPrint('⚠️ [API] idUserPet vacío para ${companionWithRealStats.displayName}');
                  // Crear con datos básicos
                  final basicCompanion = _createBasicCompanionFromUserPet(petData);
                  if (basicCompanion != null) {
                    adoptedCompanions.add(basicCompanion);
                  }
                }
              } else {
                debugPrint('⚠️ [API] Companion no es CompanionModelWithPetId');
                adoptedCompanions.add(companionWithRealStats);
              }
            }
            
          } catch (detailsError) {
            debugPrint('⚠️ [API] Error obteniendo detalles de $petId: $detailsError');
            
            // 🔥 CREAR COMPANION BÁSICO PERO CON TIPO CORRECTO
            debugPrint('🔧 [API] Creando companion básico con tipo correcto: ${expectedType.name}');
            final basicCompanion = _createBasicCompanionWithCorrectType(petData, expectedType);
            if (basicCompanion != null) {
              adoptedCompanions.add(basicCompanion);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [API] Error mapeando mascota $i: $e');
      }
    }

    debugPrint('✅ [API] === MASCOTAS USUARIO CON TIPOS VALIDADOS ===');
    debugPrint('🏠 [API] Total mascotas del usuario: ${adoptedCompanions.length}');

    // Debug de todos los tipos y idUserPet
    for (int i = 0; i < adoptedCompanions.length; i++) {
      final companion = adoptedCompanions[i];
      final petIdInfo = companion is CompanionModelWithPetId ? companion.petId : 'No petId';
      debugPrint('[$i] ${companion.displayName} (${companion.type.name}) -> idUserPet: $petIdInfo');
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

CompanionModel _correctCompanionType(
  CompanionModel originalCompanion, 
  CompanionType correctType, 
  String correctName
) {
  debugPrint('🔧 [CORRECTION] === CORRIGIENDO TIPO DE COMPANION ===');
  debugPrint('🔍 [CORRECTION] Original: ${originalCompanion.type.name}');
  debugPrint('🎯 [CORRECTION] Correcto: ${correctType.name}');
  
  // Determinar el ID local correcto
  final correctLocalId = '${correctType.name}_${originalCompanion.stage.name}';
  
  if (originalCompanion is CompanionModelWithPetId) {
    return CompanionModelWithPetId(
      id: correctLocalId, // 🔥 ID local correcto
      type: correctType, // 🔥 Tipo correcto
      stage: originalCompanion.stage,
      name: correctName.isNotEmpty ? correctName : originalCompanion.name,
      description: _generateDescriptionForType(correctType, originalCompanion.stage),
      level: originalCompanion.level,
      experience: originalCompanion.experience,
      happiness: originalCompanion.happiness,
      hunger: originalCompanion.hunger,
      energy: originalCompanion.energy,
      isOwned: originalCompanion.isOwned,
      isSelected: originalCompanion.isSelected,
      purchasedAt: originalCompanion.purchasedAt,
      lastFeedTime: originalCompanion.lastFeedTime,
      lastLoveTime: originalCompanion.lastLoveTime,
      currentMood: originalCompanion.currentMood,
      purchasePrice: originalCompanion.purchasePrice,
      evolutionPrice: originalCompanion.evolutionPrice,
      unlockedAnimations: originalCompanion.unlockedAnimations,
      createdAt: originalCompanion.createdAt,
      petId: originalCompanion.petId, // 🔥 Preservar el petId original
    );
  } else {
    return originalCompanion.copyWith(
      id: correctLocalId,
      type: correctType,
      name: correctName.isNotEmpty ? correctName : originalCompanion.name,
      description: _generateDescriptionForType(correctType, originalCompanion.stage),
    );
  }
}

// 🔥 NUEVO MÉTODO: Crear companion básico con tipo correcto
CompanionModel? _createBasicCompanionWithCorrectType(
  Map<String, dynamic> petData, 
  CompanionType correctType
) {
  try {
    debugPrint('🔧 [BASIC] === CREANDO COMPANION BÁSICO CON TIPO CORRECTO ===');
    debugPrint('🎯 [BASIC] Tipo correcto: ${correctType.name}');
    
    // Buscar idUserPet en los datos básicos
    final idUserPet = petData['idUserPet'] as String? ?? 
                     petData['id_user_pet'] as String? ?? 
                     petData['user_pet_id'] as String? ??
                     petData['id'] as String?;
    
    if (idUserPet == null || idUserPet.isEmpty) {
      debugPrint('⚠️ [BASIC] No se encontró idUserPet en datos básicos');
      return null;
    }
    
    final name = petData['name'] as String? ?? _getDisplayNameForType(correctType);
    final stage = CompanionStage.young; // Por defecto
    
    debugPrint('🔧 [BASIC] Creando companion básico: $name (${correctType.name})');
    debugPrint('🆔 [BASIC] Con idUserPet: $idUserPet');
    
    return CompanionModelWithPetId(
      id: '${correctType.name}_${stage.name}', // 🔥 ID con tipo correcto
      type: correctType, // 🔥 Tipo correcto
      stage: stage,
      name: name,
      description: _generateDescriptionForType(correctType, stage),
      level: 1,
      experience: 0,
      happiness: 75,
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
    debugPrint('❌ [BASIC] Error creando companion básico: $e');
    return null;
  }
}

// 🔥 MÉTODO HELPER: Generar descripción para tipo específico
String _generateDescriptionForType(CompanionType type, CompanionStage stage) {
  final baseName = _getDisplayNameForType(type);
  
  switch (stage) {
    case CompanionStage.baby:
      return 'Un adorable $baseName bebé lleno de energía';
    case CompanionStage.young:
      return '$baseName ha crecido y es más juguetón';
    case CompanionStage.adult:
      return '$baseName adulto, el compañero perfecto';
  }
}

// 🔥 MÉTODO HELPER: Obtener nombre para tipo específico
String _getDisplayNameForType(CompanionType type) {
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
    debugPrint('🏪 [API] === OBTENIENDO TIENDA CORREGIDA PARA EVOLUCIONES ===');
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

    // 🔥 3. CREAR SET DE TIPOS DE MASCOTAS YA ADOPTADAS (NO SOLO IDs ESPECÍFICOS)
    final adoptedTypes = <CompanionType>{};
    final adoptedIds = <String>{};
    final adoptedLocalIds = <String>{};
    
    for (final companion in userCompanions) {
      // 🔥 MARCAR EL TIPO COMPLETO COMO ADOPTADO
      adoptedTypes.add(companion.type);
      
      // Agregar también los IDs específicos (para compatibilidad)
      if (companion is CompanionModelWithPetId) {
        adoptedIds.add(companion.petId);
      }
      adoptedLocalIds.add(companion.id);
      
      final localId = '${companion.type.name}_${companion.stage.name}';
      adoptedLocalIds.add(localId);
      
      debugPrint('🔍 [API] Mascota adoptada: ${companion.displayName} (Tipo: ${companion.type.name})');
    }
    
    debugPrint('🔍 [API] === RESUMEN DE ADOPCIONES ===');
    debugPrint('🐾 [API] Tipos adoptados: ${adoptedTypes.map((t) => t.name).toList()}');
    debugPrint('🆔 [API] IDs adoptados: $adoptedIds');
    debugPrint('📝 [API] IDs locales adoptados: $adoptedLocalIds');

    // 🔥 4. MARCAR MASCOTAS COMO ADOPTADAS O DISPONIBLES (CORREGIDO)
    final storeCompanions = <CompanionModel>[];
    
    for (final companion in allCompanions) {
      // 🔥 VERIFICAR SI EL TIPO DE MASCOTA YA FUE ADOPTADO (CUALQUIER ETAPA)
      bool isTypeAdopted = adoptedTypes.contains(companion.type);
      
      // También verificar por ID específico (compatibilidad)
      bool isSpecificAdopted = false;
      if (companion is CompanionModelWithPetId) {
        isSpecificAdopted = adoptedIds.contains(companion.petId);
      }
      if (!isSpecificAdopted) {
        isSpecificAdopted = adoptedLocalIds.contains(companion.id);
      }
      
      // 🔥 LÓGICA CORREGIDA: Si ya tienes CUALQUIER etapa de este tipo, todas las etapas están "adoptadas"
      final isAdopted = isTypeAdopted || isSpecificAdopted;
      
      // Marcar correctamente el estado
      final companionForStore = companion.copyWith(
        isOwned: isAdopted,
        isSelected: false, // Ninguna está seleccionada en la tienda
      );
      
      storeCompanions.add(companionForStore);
      
      final status = isAdopted ? "YA ADOPTADA" : "DISPONIBLE";
      final reason = isTypeAdopted ? "(por tipo)" : isSpecificAdopted ? "(por ID)" : "";
      debugPrint('🏪 [API] ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★ ($status $reason)');
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

    debugPrint('🛍️ [API] === TIENDA FINAL (EVOLUCIONES CORREGIDAS) ===');
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

  // ==================== 🔥 EVOLUTION API IMPLEMENTATION - CORREGIDO ====================
  @override
Future<CompanionModel> evolvePetViaApi({
  required String userId, 
  required String petId,
  CompanionStage? currentStage,
}) async {
  try {
    debugPrint('🦋 [API] === INICIANDO EVOLUCIÓN VIA API REAL CORREGIDA ===');
    debugPrint('👤 [API] User ID: $userId');
    debugPrint('🆔 [API] Pet ID (TEMPLATE): $petId');
    debugPrint('🎯 [API] Etapa actual: ${currentStage?.name ?? "No especificada"}');

    final endpoint = '/api/gamification/pets/owned/$userId/$petId/evolve';
    final requestBody = <String, dynamic>{};

    debugPrint('📦 [API] Request body: $requestBody');
    debugPrint('🌐 [API] Endpoint: $endpoint');

    final response = await apiClient.postGamification(
      endpoint,
      data: requestBody,
    );

    debugPrint('✅ [API] Evolution response: ${response.statusCode}');
    debugPrint('📄 [API] Response data: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      debugPrint('🎉 [API] === EVOLUCIÓN EXITOSA (${response.statusCode}) ===');
      
      // 🔥 CORRECCIÓN CRÍTICA: Para respuesta 204, crear companion correcto
      if (response.statusCode == 204) {
        debugPrint('✅ [API] Evolución exitosa con respuesta vacía (204)');
        
        // 🔥 CREAR COMPANION PRESERVANDO EL TIPO ORIGINAL
        if (currentStage != null) {
          debugPrint('✅ [API] Usando etapa actual proporcionada: ${currentStage.name}');
          
          // 🔥 MAPEAR PET ID AL TIPO CORRECTO PRIMERO
          final originalType = _mapPetIdToOriginalCompanionType(petId);
          debugPrint('🎯 [API] Tipo original detectado: ${originalType.name}');
          
          return _createEvolvedCompanionWithCorrectType(petId, currentStage, originalType);
        } else {
          debugPrint('⚠️ [API] FALLBACK: Asumiendo evolución baby -> young');
          final originalType = _mapPetIdToOriginalCompanionType(petId);
          return _createEvolvedCompanionWithCorrectType(petId, CompanionStage.baby, originalType);
        }
      } else {
        // Para 200/201, usar datos de la respuesta PERO VALIDAR EL TIPO
        return _createEvolvedCompanionFromResponseCorrected(petId, response.data, currentStage);
      }
    } else {
      debugPrint('❌ [API] Error en evolución: ${response.statusCode}');
      throw ServerException('Error evolucionando mascota: ${response.data}');
    }
  } catch (e) {
    debugPrint('❌ [API] Error en evolución: $e');
    
    final errorMessage = e.toString().toLowerCase();
    if (errorMessage.contains('insufficient') ||
        errorMessage.contains('points') ||
        errorMessage.contains('cost')) {
      throw ServerException('💰 No tienes suficientes puntos para evolucionar');
    } else if (errorMessage.contains('max level') ||
        errorMessage.contains('maximum') ||
        errorMessage.contains('adulto')) {
      throw ServerException('🏆 Esta mascota ya está en su máxima evolución');
    } else if (errorMessage.contains('not found') ||
        errorMessage.contains('404')) {
      throw ServerException('🔍 Mascota no encontrada en tu colección');
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

CompanionType _mapPetIdToOriginalCompanionType(String petId) {
  debugPrint('🔍 [MAPPING] === MAPEANDO PET ID A TIPO ORIGINAL ===');
  debugPrint('🆔 [MAPPING] Pet ID recibido: $petId');
  
  final petIdLower = petId.toLowerCase();
  
  // 🔥 MAPEO ESPECÍFICO PARA TUS PET IDS REALES
  // Estos son los UUIDs reales de tu API
  if (petId == 'e0512239-dc32-444f-a354-ef94446e5f1c') {
    debugPrint('✅ [MAPPING] UUID de Dexter detectado');
    return CompanionType.dexter;
  }
  if (petId == 'ab23c9ee-a63a-4114-aff7-8ef9899b33f6') {
    debugPrint('✅ [MAPPING] UUID de Elly detectado');
    return CompanionType.elly;
  }
  if (petId == 'afdfcdfa-aed6-4320-a8e5-51debbd1bccf') {
    debugPrint('✅ [MAPPING] UUID de Paxolotl detectado');
    return CompanionType.paxolotl;
  }
  if (petId == '19119059-bb47-40e2-8eb5-8cf7a66f21b8') {
    debugPrint('✅ [MAPPING] UUID de Yami detectado');
    return CompanionType.yami;
  }
  
  // 🔥 MAPEO POR PATRONES DE NOMBRE
  if (petIdLower.contains('dexter') ||
      petIdLower.contains('dog') ||
      petIdLower.contains('chihuahua') ||
      petIdLower.contains('mammal') ||
      petIdLower.contains('canine')) {
    debugPrint('✅ [MAPPING] Dexter detectado por nombre');
    return CompanionType.dexter;
  } else if (petIdLower.contains('elly') || 
             petIdLower.contains('panda') ||
             petIdLower.contains('bear') ||
             petIdLower.contains('oso')) {
    debugPrint('✅ [MAPPING] Elly detectado por nombre');
    return CompanionType.elly;
  } else if (petIdLower.contains('paxolotl') ||
             petIdLower.contains('axolotl') ||
             petIdLower.contains('ajolote') ||
             petIdLower.contains('amphibian') ||
             petIdLower.contains('anfibio')) {
    debugPrint('✅ [MAPPING] Paxolotl detectado por nombre');
    return CompanionType.paxolotl;
  } else if (petIdLower.contains('yami') || 
             petIdLower.contains('jaguar') ||
             petIdLower.contains('felino') ||
             petIdLower.contains('cat') ||
             petIdLower.contains('feline')) {
    debugPrint('✅ [MAPPING] Yami detectado por nombre');
    return CompanionType.yami;
  }

  // 🔥 MAPEO POR PATRONES NUMÉRICOS
  if (petIdLower.contains('001') || petIdLower.contains('pet1') || petIdLower.startsWith('d')) {
    debugPrint('✅ [MAPPING] Dexter detectado por patrón');
    return CompanionType.dexter;
  } else if (petIdLower.contains('002') || petIdLower.contains('pet2') || petIdLower.startsWith('e')) {
    debugPrint('✅ [MAPPING] Elly detectado por patrón');
    return CompanionType.elly;
  } else if (petIdLower.contains('003') || petIdLower.contains('pet3') || petIdLower.startsWith('p')) {
    debugPrint('✅ [MAPPING] Paxolotl detectado por patrón');
    return CompanionType.paxolotl;
  } else if (petIdLower.contains('004') || petIdLower.contains('pet4') || petIdLower.startsWith('y')) {
    debugPrint('✅ [MAPPING] Yami detectado por patrón');
    return CompanionType.yami;
  }

  // 🔥 ADVERTENCIA: No se pudo mapear
  debugPrint('⚠️ [MAPPING] No se pudo mapear Pet ID: $petId');
  debugPrint('🔧 [MAPPING] Usando hash para distribución equitativa');
  
  // Usar hash del petId para distribución más equitativa
  final hash = petId.hashCode.abs() % 4;
  switch (hash) {
    case 0:
      debugPrint('🎲 [MAPPING] Hash asignado a Dexter');
      return CompanionType.dexter;
    case 1:
      debugPrint('🎲 [MAPPING] Hash asignado a Elly');
      return CompanionType.elly;
    case 2:
      debugPrint('🎲 [MAPPING] Hash asignado a Paxolotl');
      return CompanionType.paxolotl;
    case 3:
      debugPrint('🎲 [MAPPING] Hash asignado a Yami');
      return CompanionType.yami;
    default:
      debugPrint('🔄 [MAPPING] Fallback final a Dexter');
      return CompanionType.dexter;
  }
}

// 🔥 NUEVO MÉTODO: Crear companion evolucionado con tipo correcto
CompanionModel _createEvolvedCompanionWithCorrectType(
  String petId, 
  CompanionStage currentStage, 
  CompanionType originalType
) {
  debugPrint('🦋 [EVOLUTION] === CREANDO COMPANION EVOLUCIONADO CON TIPO CORRECTO ===');
  debugPrint('🆔 [EVOLUTION] Pet ID: $petId');
  debugPrint('🎯 [EVOLUTION] Tipo original: ${originalType.name}');
  debugPrint('📊 [EVOLUTION] Etapa actual: ${currentStage.name}');
  
  // 🔥 DETERMINAR LA SIGUIENTE ETAPA DE EVOLUCIÓN
  CompanionStage nextStage;
  switch (currentStage) {
    case CompanionStage.baby:
      nextStage = CompanionStage.young;
      break;
    case CompanionStage.young:
      nextStage = CompanionStage.adult;
      break;
    case CompanionStage.adult:
      nextStage = CompanionStage.adult; // Ya está en máxima evolución
      break;
  }
  
  debugPrint('✨ [EVOLUTION] Evolución: ${currentStage.name} → ${nextStage.name}');
  debugPrint('🎯 [EVOLUTION] Tipo PRESERVADO: ${originalType.name}');
  
  // 🔥 GENERAR NUEVO ID LOCAL PARA LA ETAPA EVOLUCIONADA CON EL TIPO CORRECTO
  final evolvedLocalId = '${originalType.name}_${nextStage.name}';
  
  // 🔥 CREAR COMPANION EVOLUCIONADO CON EL TIPO CORRECTO
  final evolvedCompanion = CompanionModelWithPetId(
    id: evolvedLocalId,
    type: originalType, // 🔥 USAR EL TIPO ORIGINAL CORRECTO
    stage: nextStage,
    name: _getCompanionNameForStageAndType(originalType, nextStage),
    description: _generateDescriptionForType(originalType, nextStage),
    level: _getInitialLevelForStage(nextStage),
    experience: 0,
    happiness: 85,
    hunger: 15,
    energy: 90,
    currentMood: CompanionMood.excited,
    lastFeedTime: DateTime.now().subtract(const Duration(hours: 2)),
    lastLoveTime: DateTime.now().subtract(const Duration(hours: 1)),
    isOwned: true,
    isSelected: false,
    purchasePrice: 0,
    evolutionPrice: _getEvolutionPriceForStage(_getStageNumber(nextStage)),
    unlockedAnimations: _getAnimationsForStage(nextStage),
    createdAt: DateTime.now(),
    petId: petId, // 🔥 PRESERVAR EL PET ID ORIGINAL
  );
  
  debugPrint('🎉 [EVOLUTION] === COMPANION EVOLUCIONADO CREADO CORRECTAMENTE ===');
  debugPrint('🐾 [EVOLUTION] Nombre: ${evolvedCompanion.displayName}');
  debugPrint('🎯 [EVOLUTION] Tipo FINAL: ${evolvedCompanion.type.name}');
  debugPrint('📊 [EVOLUTION] Etapa FINAL: ${evolvedCompanion.stage.name}');
  debugPrint('🆔 [EVOLUTION] Pet ID preservado: ${evolvedCompanion.petId}');
  
  return evolvedCompanion;
}

// 🔥 MÉTODO CORREGIDO: Crear companion desde respuesta con validación de tipo
CompanionModel _createEvolvedCompanionFromResponseCorrected(
  String petId, 
  dynamic responseData, 
  CompanionStage? currentStage
) {
  debugPrint('🦋 [EVOLUTION] === CREANDO DESDE RESPUESTA CORREGIDA ===');
  debugPrint('🆔 [EVOLUTION] Pet ID: $petId');
  debugPrint('📄 [EVOLUTION] Response data: $responseData');

  // 🔥 OBTENER EL TIPO ORIGINAL CORRECTO PRIMERO
  final originalType = _mapPetIdToOriginalCompanionType(petId);
  debugPrint('🎯 [EVOLUTION] Tipo original detectado: ${originalType.name}');

  // 🔥 MAPEAR ETAPA DESDE LA RESPUESTA O USAR ACTUAL + 1
  CompanionStage nextStage = CompanionStage.young; // Fallback
  
  if (currentStage != null) {
    switch (currentStage) {
      case CompanionStage.baby:
        nextStage = CompanionStage.young;
        break;
      case CompanionStage.young:
        nextStage = CompanionStage.adult;
        break;
      case CompanionStage.adult:
        nextStage = CompanionStage.adult;
        break;
    }
  }

  // 🔥 EXTRAER INFORMACIÓN DE EVOLUCIÓN DE LA RESPUESTA
  String realName = _getCompanionNameForStageAndType(originalType, nextStage);
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
      nextStage = _mapStringToCompanionStage(newStageStr);
    }
    
    debugPrint('✅ [EVOLUTION] Datos extraídos - Nombre: $realName, Nivel: $newLevel, Etapa: ${nextStage.name}');
  }

  final localId = '${originalType.name}_${nextStage.name}'; // 🔥 USAR TIPO ORIGINAL
  debugPrint('🆔 [EVOLUTION] Local ID CORREGIDO: $localId');

  return CompanionModelWithPetId(
    id: localId,
    type: originalType, // 🔥 USAR TIPO ORIGINAL CORRECTO
    stage: nextStage,
    name: realName,
    description: _generateDescriptionForType(originalType, nextStage),
    level: newLevel,
    experience: 0,
    happiness: 100,
    hunger: 100,
    energy: 100,
    isOwned: true,
    isSelected: true,
    purchasedAt: DateTime.now(),
    currentMood: CompanionMood.excited,
    purchasePrice: _getDefaultPrice(originalType, nextStage),
    evolutionPrice: _getEvolutionPrice(nextStage),
    unlockedAnimations: ['idle', 'blink', 'happy', 'excited'],
    createdAt: DateTime.now(),
    petId: petId,
  );
}

// 🔥 HELPERS CORREGIDOS PARA USAR EL TIPO CORRECTO

String _getCompanionNameForStageAndType(CompanionType type, CompanionStage stage) {
  switch (type) {
    case CompanionType.dexter:
      switch (stage) {
        case CompanionStage.baby: return 'Dexter Bebé';
        case CompanionStage.young: return 'Dexter Joven';
        case CompanionStage.adult: return 'Dexter Adulto';
      }
    case CompanionType.elly:
      switch (stage) {
        case CompanionStage.baby: return 'Elly Bebé';
        case CompanionStage.young: return 'Elly Joven';
        case CompanionStage.adult: return 'Elly Adulta';
      }
    case CompanionType.paxolotl:
      switch (stage) {
        case CompanionStage.baby: return 'Paxolotl Bebé';
        case CompanionStage.young: return 'Paxolotl Joven';
        case CompanionStage.adult: return 'Paxolotl Adulto';
      }
    case CompanionType.yami:
      switch (stage) {
        case CompanionStage.baby: return 'Yami Bebé';
        case CompanionStage.young: return 'Yami Joven';
        case CompanionStage.adult: return 'Yami Adulto';
      }
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

  /// 🔥 CREAR COMPANION EVOLUCIONADO DESDE PET ID Y ETAPA ACTUAL (para respuestas 204)
  CompanionModel _createEvolvedCompanionFromPetIdAndStage(String petId, CompanionStage currentStage) {
    debugPrint('🦋 [EVOLUTION] Creando companion evolucionado desde petId: $petId');
    debugPrint('📊 [EVOLUTION] Etapa actual recibida: ${currentStage.name}');
    
    // 🔥 MAPEAR PET ID A TIPO CON CONTEXTO MEJORADO
    final companionType = _mapPetIdToCompanionTypeWithContext(petId, currentStage);
    
    // 🔥 DETERMINAR LA SIGUIENTE ETAPA DE EVOLUCIÓN
    CompanionStage nextStage;
    switch (currentStage) {
      case CompanionStage.baby:
        nextStage = CompanionStage.young;
        break;
      case CompanionStage.young:
        nextStage = CompanionStage.adult;
        break;
      case CompanionStage.adult:
        nextStage = CompanionStage.adult; // Ya está en máxima evolución
        break;
    }
    
    debugPrint('✨ [EVOLUTION] Evolución: ${currentStage.name} → ${nextStage.name}');
    debugPrint('🎯 [EVOLUTION] Tipo preservado: ${companionType.name}');
    
    // 🔥 GENERAR NUEVO ID LOCAL PARA LA ETAPA EVOLUCIONADA
    final evolvedLocalId = '${companionType.name}_${nextStage.name}';
    
    // 🔥 CREAR COMPANION EVOLUCIONADO CON DATOS MEJORADOS
    final evolvedCompanion = CompanionModelWithPetId(
      id: evolvedLocalId,
      type: companionType,
      stage: nextStage,
      name: _getCompanionNameForStage(companionType, nextStage),
      description: _generateDescription(companionType, nextStage),
      level: _getInitialLevelForStage(nextStage),
      experience: 0,
      happiness: 85, // Feliz por la evolución
      hunger: 15,    // Poco hambre después de evolucionar
      energy: 90,    // Energía alta después de evolucionar
      currentMood: CompanionMood.excited, // Emocionado por evolucionar
      lastFeedTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastLoveTime: DateTime.now().subtract(const Duration(hours: 1)),
      isOwned: true,
      isSelected: false,
      purchasePrice: 0, // Ya adoptado
      evolutionPrice: _getEvolutionPriceForStage(_getStageNumber(nextStage)),
      unlockedAnimations: _getAnimationsForStage(nextStage),
      createdAt: DateTime.now(),
      petId: petId, // 🔥 PRESERVAR EL PET ID ORIGINAL
    );
    
    debugPrint('🎉 [EVOLUTION] Companion evolucionado creado: ${evolvedCompanion.displayName}');
    debugPrint('🆔 [EVOLUTION] Pet ID preservado: ${evolvedCompanion.petId}');
    debugPrint('🎯 [EVOLUTION] Tipo final: ${evolvedCompanion.type.name}');
    
    return evolvedCompanion;
  }
  
  /// 🔥 MAPEO CON CONTEXTO PARA EVOLUCIÓN - EVITA FALLBACK A DEXTER
  CompanionType _mapPetIdToCompanionTypeWithContext(String petId, CompanionStage currentStage) {
    debugPrint('🔍 [CONTEXT_MAPPING] Mapeando con contexto: $petId (${currentStage.name})');
    
    // Primero intentar el mapeo normal
    final normalMapping = _mapPetIdToCompanionType(petId);
    
    // Si el mapeo normal no es por hash (es decir, fue reconocido), usarlo
    final petIdLower = petId.toLowerCase();
    bool wasRecognized = petIdLower.contains('dexter') ||
                        petIdLower.contains('dog') ||
                        petIdLower.contains('chihuahua') ||
                        petIdLower.contains('mammal') ||
                        petIdLower.contains('canine') ||
                        petIdLower.contains('elly') ||
                        petIdLower.contains('panda') ||
                        petIdLower.contains('bear') ||
                        petIdLower.contains('oso') ||
                        petIdLower.contains('paxolotl') ||
                        petIdLower.contains('axolotl') ||
                        petIdLower.contains('ajolote') ||
                        petIdLower.contains('amphibian') ||
                        petIdLower.contains('anfibio') ||
                        petIdLower.contains('yami') ||
                        petIdLower.contains('jaguar') ||
                        petIdLower.contains('felino') ||
                        petIdLower.contains('cat') ||
                        petIdLower.contains('feline') ||
                        petIdLower.contains('001') ||
                        petIdLower.contains('002') ||
                        petIdLower.contains('003') ||
                        petIdLower.contains('004') ||
                        petIdLower.contains('pet1') ||
                        petIdLower.contains('pet2') ||
                        petIdLower.contains('pet3') ||
                        petIdLower.contains('pet4') ||
                        petIdLower.startsWith('d') ||
                        petIdLower.startsWith('e') ||
                        petIdLower.startsWith('p') ||
                        petIdLower.startsWith('y');
    
    if (wasRecognized) {
      debugPrint('✅ [CONTEXT_MAPPING] Pet ID reconocido, usando mapeo normal: ${normalMapping.name}');
      return normalMapping;
    }
    
    // Si no fue reconocido, intentar preservar el contexto de la etapa anterior
    debugPrint('⚠️ [CONTEXT_MAPPING] Pet ID no reconocido, intentando preservar contexto');
    
    // Para evitar el fallback a Dexter, usar una distribución más inteligente
    // basada en características del ID
    if (petId.length > 10) {
      // IDs largos probablemente son UUIDs, usar distribución por longitud
      final lengthHash = petId.length % 4;
      switch (lengthHash) {
        case 0: return CompanionType.elly;
        case 1: return CompanionType.paxolotl;
        case 2: return CompanionType.yami;
        case 3: return CompanionType.dexter;
      }
    }
    
    // Usar el mapeo normal como último recurso
    debugPrint('🎲 [CONTEXT_MAPPING] Usando mapeo normal como último recurso: ${normalMapping.name}');
    return normalMapping;
  }
  
  /// Helper para obtener nombre del companion según la etapa
  String _getCompanionNameForStage(CompanionType type, CompanionStage stage) {
    switch (type) {
      case CompanionType.dexter:
        switch (stage) {
          case CompanionStage.baby: return 'Dexter Bebé';
          case CompanionStage.young: return 'Dexter Joven';
          case CompanionStage.adult: return 'Dexter Adulto';
        }
      case CompanionType.elly:
        switch (stage) {
          case CompanionStage.baby: return 'Elly Bebé';
          case CompanionStage.young: return 'Elly Joven';
          case CompanionStage.adult: return 'Elly Adulta';
        }
      case CompanionType.paxolotl:
        switch (stage) {
          case CompanionStage.baby: return 'Paxolotl Bebé';
          case CompanionStage.young: return 'Paxolotl Joven';
          case CompanionStage.adult: return 'Paxolotl Adulto';
        }
      case CompanionType.yami:
        switch (stage) {
          case CompanionStage.baby: return 'Yami Bebé';
          case CompanionStage.young: return 'Yami Joven';
          case CompanionStage.adult: return 'Yami Adulto';
        }
    }
  }
  
  /// Helper para obtener nivel inicial según la etapa
  int _getInitialLevelForStage(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 1;
      case CompanionStage.young: return 5;
      case CompanionStage.adult: return 10;
    }
  }
  
  /// Helper para obtener número de etapa
  int _getStageNumber(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 1;
      case CompanionStage.young: return 2;
      case CompanionStage.adult: return 3;
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

  /// Mapear Pet ID a CompanionType con lógica mejorada
  CompanionType _mapPetIdToCompanionType(String petId) {
    final petIdLower = petId.toLowerCase();
    
    debugPrint(' [MAPPING] Mapeando Pet ID: $petId');

    // MAPEO MEJORADO CON MÁS PATRONES
    if (petIdLower.contains('dexter') ||
        petIdLower.contains('dog') ||
        petIdLower.contains('chihuahua') ||
        petIdLower.contains('mammal') ||
        petIdLower.contains('canine')) {
      debugPrint(' [MAPPING] Detectado como Dexter');
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || 
               petIdLower.contains('panda') ||
               petIdLower.contains('bear') ||
               petIdLower.contains('oso')) {
      debugPrint(' [MAPPING] Detectado como Elly');
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') ||
               petIdLower.contains('axolotl') ||
               petIdLower.contains('ajolote') ||
               petIdLower.contains('amphibian') ||
               petIdLower.contains('anfibio')) {
      debugPrint(' [MAPPING] Detectado como Paxolotl');
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || 
               petIdLower.contains('jaguar') ||
               petIdLower.contains('felino') ||
               petIdLower.contains('cat') ||
               petIdLower.contains('feline')) {
      debugPrint(' [MAPPING] Detectado como Yami');
      return CompanionType.yami;
    }

    // MAPEO POR PATRONES DE ID NUMÉRICOS O CÓDIGOS
    if (petIdLower.contains('001') || petIdLower.contains('pet1') || petIdLower.startsWith('d')) {
      debugPrint(' [MAPPING] Detectado por patrón como Dexter');
      return CompanionType.dexter;
    } else if (petIdLower.contains('002') || petIdLower.contains('pet2') || petIdLower.startsWith('e')) {
      debugPrint(' [MAPPING] Detectado por patrón como Elly');
      return CompanionType.elly;
    } else if (petIdLower.contains('003') || petIdLower.contains('pet3') || petIdLower.startsWith('p')) {
      debugPrint(' [MAPPING] Detectado por patrón como Paxolotl');
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('004') || petIdLower.contains('pet4') || petIdLower.startsWith('y')) {
      debugPrint(' [MAPPING] Detectado por patrón como Yami');
      return CompanionType.yami;
    }

    // ÚLTIMO RECURSO: Intentar extraer de contexto o usar hash
    debugPrint(' [MAPPING] Pet ID no reconocido: $petId');
    debugPrint(' [MAPPING] Usando hash para distribución equitativa');
    
    // Usar hash del petId para distribución más equitativa en lugar de siempre dexter
    final hash = petId.hashCode.abs() % 4;
    switch (hash) {
      case 0:
        debugPrint(' [MAPPING] Hash asignado a Dexter');
        return CompanionType.dexter;
      case 1:
        debugPrint(' [MAPPING] Hash asignado a Elly');
        return CompanionType.elly;
      case 2:
        debugPrint(' [MAPPING] Hash asignado a Paxolotl');
        return CompanionType.paxolotl;
      case 3:
        debugPrint(' [MAPPING] Hash asignado a Yami');
        return CompanionType.yami;
      default:
        debugPrint(' [MAPPING] Fallback final a Dexter');
        return CompanionType.dexter;
    }
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