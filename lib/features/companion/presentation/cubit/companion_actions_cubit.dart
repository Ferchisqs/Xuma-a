// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 CORREGIDO: Extracción correcta del idUserPet + Validaciones relajadas

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import '../../../../core/services/token_manager.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/repositories/companion_repository.dart';
import '../../domain/usecases/feed_companion_via_api_usecase.dart';
import '../../domain/usecases/love_companion_via_api_usecase.dart';
import '../../domain/usecases/simulate_time_passage_usecase.dart';
import '../../domain/usecases/decrease_pet_stats_usecase.dart';
import '../../domain/usecases/increase_pet_stats_usecase.dart';

// States (sin cambios)
abstract class CompanionActionsState extends Equatable {
  const CompanionActionsState();
  @override
  List<Object?> get props => [];
}

class CompanionActionsInitial extends CompanionActionsState {}

class CompanionActionsLoading extends CompanionActionsState {
  final String action;
  final CompanionEntity companion;
  
  const CompanionActionsLoading({
    required this.action,
    required this.companion,
  });
  
  @override
  List<Object> get props => [action, companion];
}

class CompanionActionsSuccess extends CompanionActionsState {
  final String action;
  final CompanionEntity companion;
  final String message;
  
  const CompanionActionsSuccess({
    required this.action,
    required this.companion,
    required this.message,
  });
  
  @override
  List<Object> get props => [action, companion, message];
}

class CompanionActionsError extends CompanionActionsState {
  final String message;
  final String? action;
  
  const CompanionActionsError({
    required this.message,
    this.action,
  });
  
  @override
  List<Object?> get props => [message, action];
}

@injectable
class CompanionActionsCubit extends Cubit<CompanionActionsState> {
  final CompanionRepository repository;
  final TokenManager tokenManager;
  final FeedCompanionViaApiUseCase feedCompanionViaApiUseCase;
  final LoveCompanionViaApiUseCase loveCompanionViaApiUseCase;
  final SimulateTimePassageUseCase simulateTimePassageUseCase;
  final DecreasePetStatsUseCase decreasePetStatsUseCase;
  final IncreasePetStatsUseCase increasePetStatsUseCase;
  
  CompanionActionsCubit({
    required this.repository,
    required this.tokenManager,
    required this.feedCompanionViaApiUseCase,
    required this.loveCompanionViaApiUseCase,
    required this.simulateTimePassageUseCase,
    required this.decreasePetStatsUseCase,
    required this.increasePetStatsUseCase,
  }) : super(CompanionActionsInitial());

  // ==================== 🔥 ALIMENTAR VIA API - CORREGIDO ====================
 Future<void> feedCompanionViaApi(CompanionEntity companion) async {
  try {
    debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO CON VALIDACIÓN DE TIPO ===');
    debugPrint('🐾 [ACTIONS_CUBIT] Companion: ${companion.displayName}');
    debugPrint('🎯 [ACTIONS_CUBIT] Tipo esperado: ${companion.type.name}');
    debugPrint('🏥 [ACTIONS_CUBIT] Salud actual: ${companion.hunger}/100');
    
    // 🔥 VALIDACIÓN RELAJADA: Permitir alimentar hasta 90
    if (companion.hunger >= 90) {
      emit(CompanionActionsError(
        message: '🍽️ ${companion.displayName} está muy bien alimentado (${companion.hunger}/100)',
        action: 'feeding',
      ));
      return;
    }
    
    if (!companion.isOwned) {
      emit(CompanionActionsError(
        message: '🔒 No puedes alimentar a ${companion.displayName} porque no es tuyo',
        action: 'feeding',
      ));
      return;
    }
    
    emit(CompanionActionsLoading(
      action: 'feeding',
      companion: companion,
    ));
    
    final userId = await tokenManager.getUserId();
    if (userId == null) {
      emit(CompanionActionsError(
        message: '🔐 Usuario no autenticado',
        action: 'feeding',
      ));
      return;
    }
    
    // 🔥 EXTRACCIÓN CORREGIDA DEL idUserPet
    final idUserPet = _extractCorrectUserPetId(companion);
    debugPrint('🎯 [ACTIONS_CUBIT] === EXTRACCIÓN DE idUserPet PARA ALIMENTAR ===');
    debugPrint('🆔 [ACTIONS_CUBIT] idUserPet extraído: "$idUserPet"');
    debugPrint('🔧 [ACTIONS_CUBIT] Tipo de companion: ${companion.runtimeType}');
    debugPrint('🎯 [ACTIONS_CUBIT] Tipo esperado: ${companion.type.name}');
    
    if (idUserPet.isEmpty || idUserPet.startsWith('ERROR_')) {
      debugPrint('❌ [ACTIONS_CUBIT] idUserPet inválido: $idUserPet');
      emit(CompanionActionsError(
        message: '🔧 Error: Esta mascota no tiene un ID de usuario válido. Intenta recargar las mascotas.',
        action: 'feeding',
      ));
      return;
    }
    
    // 🔥 VALIDACIÓN FINAL: Verificar coherencia de tipo
    final detectedType = _detectTypeFromUserPetId(idUserPet);
    if (detectedType != companion.type) {
      debugPrint('⚠️ [ACTIONS_CUBIT] ADVERTENCIA: Tipo no coincide');
      debugPrint('🎯 [ACTIONS_CUBIT] Esperado: ${companion.type.name}');
      debugPrint('🔍 [ACTIONS_CUBIT] Detectado en ID: ${detectedType.name}');
    }
    
    debugPrint('🚀 [ACTIONS_CUBIT] Enviando request a API con idUserPet: $idUserPet');
    
    final result = await feedCompanionViaApiUseCase(
      FeedCompanionViaApiParams(
        userId: userId,
        petId: idUserPet, // 🔥 USAR EL idUserPet CORRECTO
      ),
    );
    
    result.fold(
      (failure) {
        debugPrint('❌ [ACTIONS_CUBIT] Error API alimentando: ${failure.message}');
        emit(CompanionActionsError(
          message: failure.message,
          action: 'feeding',
        ));
      },
      (fedCompanion) {
        debugPrint('✅ [ACTIONS_CUBIT] === ALIMENTACIÓN EXITOSA ===');
        debugPrint('🎯 [ACTIONS_CUBIT] Tipo original: ${companion.type.name}');
        debugPrint('🎯 [ACTIONS_CUBIT] Tipo alimentado: ${fedCompanion.type.name}');
        debugPrint('🏥 [ACTIONS_CUBIT] Salud anterior: ${companion.hunger} → Nueva: ${fedCompanion.hunger}');
        
        // 🔥 VALIDAR QUE SE ALIMENTÓ LA MASCOTA CORRECTA
        if (fedCompanion.type != companion.type) {
          debugPrint('🚨 [ACTIONS_CUBIT] ERROR: Se alimentó una mascota diferente!');
          debugPrint('🎯 [ACTIONS_CUBIT] Se quería alimentar: ${companion.displayName} (${companion.type.name})');
          debugPrint('🔍 [ACTIONS_CUBIT] Se alimentó: ${fedCompanion.displayName} (${fedCompanion.type.name})');
          
          emit(CompanionActionsError(
            message: '⚠️ Error: Se alimentó ${fedCompanion.displayName} en lugar de ${companion.displayName}. Problema de mapeo de IDs.',
            action: 'feeding',
          ));
          return;
        }
        
        final healthGain = fedCompanion.hunger - companion.hunger;
        final message = healthGain > 0 
            ? '🍎 ¡${fedCompanion.displayName} ha sido alimentado! +$healthGain salud (${fedCompanion.hunger}/100)'
            : '🍎 ¡${fedCompanion.displayName} ha sido alimentado! (${fedCompanion.hunger}/100)';
        
        emit(CompanionActionsSuccess(
          action: 'feeding',
          companion: fedCompanion,
          message: message,
        ));
      },
    );
    
  } catch (e) {
    debugPrint('💥 [ACTIONS_CUBIT] Error inesperado alimentando: $e');
    emit(CompanionActionsError(
      message: '❌ Error inesperado alimentando a ${companion.displayName}',
      action: 'feeding',
    ));
  }
}

// 🔥 ACTUALIZACIÓN EN DAR AMOR - Agregar más debug
Future<void> loveCompanionViaApi(CompanionEntity companion) async {
  try {
    debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR CON VALIDACIÓN DE TIPO ===');
    debugPrint('🐾 [ACTIONS_CUBIT] Companion: ${companion.displayName}');
    debugPrint('🎯 [ACTIONS_CUBIT] Tipo esperado: ${companion.type.name}');
    debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
    
    if (!companion.isOwned) {
      emit(CompanionActionsError(
        message: '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
        action: 'loving',
      ));
      return;
    }
    
    // 🔥 VALIDACIÓN RELAJADA: Permitir amar hasta 90
    if (companion.happiness >= 90) {
      emit(CompanionActionsError(
        message: '❤️ ${companion.displayName} ya está muy feliz (${companion.happiness}/100)',
        action: 'loving',
      ));
      return;
    }
    
    emit(CompanionActionsLoading(
      action: 'loving',
      companion: companion,
    ));
    
    final userId = await tokenManager.getUserId();
    if (userId == null) {
      emit(CompanionActionsError(
        message: '🔐 Usuario no autenticado',
        action: 'loving',
      ));
      return;
    }
    
    // 🔥 EXTRACCIÓN CORREGIDA DEL idUserPet
    final idUserPet = _extractCorrectUserPetId(companion);
    debugPrint('🎯 [ACTIONS_CUBIT] === EXTRACCIÓN DE idUserPet PARA AMOR ===');
    debugPrint('🆔 [ACTIONS_CUBIT] idUserPet extraído: "$idUserPet"');
    debugPrint('🎯 [ACTIONS_CUBIT] Tipo esperado: ${companion.type.name}');
    
    if (idUserPet.isEmpty || idUserPet.startsWith('ERROR_')) {
      debugPrint('❌ [ACTIONS_CUBIT] idUserPet inválido: $idUserPet');
      emit(CompanionActionsError(
        message: '🔧 Error: Esta mascota no tiene un ID de usuario válido. Intenta recargar las mascotas.',
        action: 'loving',
      ));
      return;
    }
    
    // 🔥 VALIDACIÓN FINAL: Verificar coherencia de tipo
    final detectedType = _detectTypeFromUserPetId(idUserPet);
    if (detectedType != companion.type) {
      debugPrint('⚠️ [ACTIONS_CUBIT] ADVERTENCIA: Tipo no coincide en amor');
      debugPrint('🎯 [ACTIONS_CUBIT] Esperado: ${companion.type.name}');
      debugPrint('🔍 [ACTIONS_CUBIT] Detectado en ID: ${detectedType.name}');
    }
    
    debugPrint('🚀 [ACTIONS_CUBIT] Enviando request de amor a API con idUserPet: $idUserPet');
    
    final result = await loveCompanionViaApiUseCase(
      LoveCompanionViaApiParams(
        userId: userId,
        petId: idUserPet, // 🔥 USAR EL idUserPet CORRECTO
      ),
    );
    
    result.fold(
      (failure) {
        debugPrint('❌ [ACTIONS_CUBIT] Error API dando amor: ${failure.message}');
        emit(CompanionActionsError(
          message: failure.message,
          action: 'loving',
        ));
      },
      (lovedCompanion) {
        debugPrint('✅ [ACTIONS_CUBIT] === AMOR EXITOSO ===');
        debugPrint('🎯 [ACTIONS_CUBIT] Tipo original: ${companion.type.name}');
        debugPrint('🎯 [ACTIONS_CUBIT] Tipo que recibió amor: ${lovedCompanion.type.name}');
        debugPrint('❤️ [ACTIONS_CUBIT] Felicidad anterior: ${companion.happiness} → Nueva: ${lovedCompanion.happiness}');
        
        // 🔥 VALIDAR QUE SE DIO AMOR A LA MASCOTA CORRECTA
        if (lovedCompanion.type != companion.type) {
          debugPrint('🚨 [ACTIONS_CUBIT] ERROR: Se dio amor a una mascota diferente!');
          debugPrint('🎯 [ACTIONS_CUBIT] Se quería dar amor a: ${companion.displayName} (${companion.type.name})');
          debugPrint('🔍 [ACTIONS_CUBIT] Se dio amor a: ${lovedCompanion.displayName} (${lovedCompanion.type.name})');
          
          emit(CompanionActionsError(
            message: '⚠️ Error: Se dio amor a ${lovedCompanion.displayName} en lugar de ${companion.displayName}. Problema de mapeo de IDs.',
            action: 'loving',
          ));
          return;
        }
        
        final happinessGain = lovedCompanion.happiness - companion.happiness;
        final message = happinessGain > 0 
            ? '💖 ¡${lovedCompanion.displayName} se siente amado! +$happinessGain felicidad (${lovedCompanion.happiness}/100)'
            : '💖 ¡${lovedCompanion.displayName} se siente amado! (${lovedCompanion.happiness}/100)';
        
        emit(CompanionActionsSuccess(
          action: 'loving',
          companion: lovedCompanion,
          message: message,
        ));
      },
    );
    
  } catch (e) {
    debugPrint('💥 [ACTIONS_CUBIT] Error inesperado dando amor: $e');
    emit(CompanionActionsError(
      message: '❌ Error inesperado dando amor a ${companion.displayName}',
      action: 'loving',
    ));
  }
}

  // ==================== 🔥 MÉTODO CORREGIDO PARA EXTRAER idUserPet ====================
  String _extractCorrectUserPetId(CompanionEntity companion) {
  debugPrint('🔍 [EXTRACT] === EXTRAYENDO idUserPet CORRECTAMENTE ===');
  debugPrint('🐾 [EXTRACT] Companion: ${companion.displayName}');
  debugPrint('🎯 [EXTRACT] Tipo esperado: ${companion.type.name}');
  debugPrint('🆔 [EXTRACT] Local ID: ${companion.id}');
  debugPrint('🔧 [EXTRACT] Tipo de clase: ${companion.runtimeType}');
  
  // 1. 🔥 MÉTODO PRINCIPAL: CompanionModelWithPetId
  if (companion is CompanionModelWithPetId) {
    final idUserPet = companion.petId;
    debugPrint('✅ [EXTRACT] Es CompanionModelWithPetId');
    debugPrint('🎯 [EXTRACT] petId extraído: "$idUserPet"');
    
    if (_isValidUserPetId(idUserPet)) {
      debugPrint('✅ [EXTRACT] idUserPet VÁLIDO: $idUserPet');
      
      // 🔥 VALIDACIÓN ADICIONAL: Verificar que el tipo coincida
      final expectedType = companion.type;
      final detectedType = _detectTypeFromUserPetId(idUserPet);
      
      if (detectedType == expectedType) {
        debugPrint('✅ [EXTRACT] Tipo coincide - ${expectedType.name}');
        return idUserPet;
      } else {
        debugPrint('⚠️ [EXTRACT] ADVERTENCIA: Tipo no coincide');
        debugPrint('🎯 [EXTRACT] Esperado: ${expectedType.name}, Detectado: ${detectedType.name}');
        // 🔥 AÚN ASÍ LO USAMOS SI ES VÁLIDO
        return idUserPet;
      }
    } else {
      debugPrint('⚠️ [EXTRACT] idUserPet INVÁLIDO: "$idUserPet"');
    }
  }
  
  // 2. 🔥 MÉTODO ALTERNATIVO: JSON del CompanionModel
  if (companion is CompanionModel) {
    try {
      final json = companion.toJson();
      debugPrint('📄 [EXTRACT] Buscando en JSON...');
      debugPrint('🗝️ [EXTRACT] Keys disponibles: ${json.keys.toList()}');
      
      // Lista de posibles nombres de campo para idUserPet
      final possibleKeys = [
        'petId',           // Campo principal
        'idUserPet',       // Campo alternativo
        'userPetId',       // Otra variación
        'user_pet_id',     // Snake case
        'id_user_pet',     // Otra variación snake case
        'apiPetId',        // Si se guardó así
        'realPetId',       // Otra posibilidad
      ];
      
      for (final key in possibleKeys) {
        if (json.containsKey(key) && json[key] != null) {
          final value = json[key] as String;
          debugPrint('🎯 [EXTRACT] Encontrado $key: "$value"');
          
          if (_isValidUserPetId(value)) {
            // 🔥 VALIDACIÓN ADICIONAL: Verificar coherencia de tipo
            final expectedType = companion.type;
            final detectedType = _detectTypeFromUserPetId(value);
            
            if (detectedType == expectedType) {
              debugPrint('✅ [EXTRACT] idUserPet del JSON VÁLIDO: $value');
              return value;
            } else {
              debugPrint('⚠️ [EXTRACT] Tipo no coincide en JSON');
              debugPrint('🎯 [EXTRACT] Esperado: ${expectedType.name}, Detectado: ${detectedType.name}');
              // 🔥 AÚN ASÍ LO USAMOS SI ES EL ÚNICO VÁLIDO
              return value;
            }
          }
        }
      }
      
      debugPrint('❌ [EXTRACT] No se encontró idUserPet válido en JSON');
    } catch (e) {
      debugPrint('❌ [EXTRACT] Error accediendo JSON: $e');
    }
  }
  
  // 3. 🆘 ANÁLISIS DETALLADO DEL PROBLEMA
  debugPrint('🆘 [EXTRACT] === ANÁLISIS DEL PROBLEMA ===');
  debugPrint('❌ [EXTRACT] NO SE ENCONTRÓ idUserPet VÁLIDO');
  debugPrint('🔍 [EXTRACT] Posibles causas:');
  debugPrint('   1. El companion no se creó correctamente desde getUserCompanions');
  debugPrint('   2. El endpoint getUserCompanions no devuelve idUserPet');
  debugPrint('   3. El mapping de la respuesta está incompleto');
  debugPrint('   4. La mascota no está realmente adoptada por el usuario');
  
  // 4. 🔥 CREAR UN ID DE ERROR DESCRIPTIVO
  final expectedType = companion.type.name;
  final errorId = 'ERROR_NO_USER_PET_ID_${expectedType}_${companion.stage.name}_${DateTime.now().millisecondsSinceEpoch}';
  
  debugPrint('🚨 [EXTRACT] Devolviendo ID de error: $errorId');
  debugPrint('💡 [EXTRACT] ACCIÓN REQUERIDA: Verificar el flujo de getUserCompanions');
  
  return errorId;
}

CompanionType _detectTypeFromUserPetId(String idUserPet) {
  debugPrint('🔍 [TYPE_DETECT] Detectando tipo desde idUserPet: $idUserPet');
  
  final idLower = idUserPet.toLowerCase();
  
  // 🔥 DETECCIÓN POR PATRONES DE NOMBRE
  if (idLower.contains('dexter') ||
      idLower.contains('dog') ||
      idLower.contains('chihuahua')) {
    debugPrint('✅ [TYPE_DETECT] Detectado como Dexter');
    return CompanionType.dexter;
  } else if (idLower.contains('elly') ||
             idLower.contains('panda')) {
    debugPrint('✅ [TYPE_DETECT] Detectado como Elly');
    return CompanionType.elly;
  } else if (idLower.contains('paxolotl') ||
             idLower.contains('axolotl') ||
             idLower.contains('ajolote')) {
    debugPrint('✅ [TYPE_DETECT] Detectado como Paxolotl');
    return CompanionType.paxolotl;
  } else if (idLower.contains('yami') ||
             idLower.contains('jaguar')) {
    debugPrint('✅ [TYPE_DETECT] Detectado como Yami');
    return CompanionType.yami;
  }
  
  // 🔥 SI NO SE DETECTA ESPECÍFICAMENTE, USAR HASH CONSISTENTE
  debugPrint('⚠️ [TYPE_DETECT] No se detectó tipo específico, usando hash');
  final hash = idUserPet.hashCode.abs() % 4;
  switch (hash) {
    case 0: return CompanionType.dexter;
    case 1: return CompanionType.elly;
    case 2: return CompanionType.paxolotl;
    case 3: return CompanionType.yami;
    default: return CompanionType.dexter;
  }
}

  // 🔥 HELPER PARA VALIDAR idUserPet
  bool _isValidUserPetId(String? idUserPet) {
    if (idUserPet == null || idUserPet.isEmpty) return false;
    if (idUserPet == 'unknown') return false;
    if (idUserPet.startsWith('ERROR_')) return false;
    if (idUserPet.startsWith('FALLBACK_')) return false;
    if (idUserPet == 'undefined') return false;
    if (idUserPet == 'null') return false;
    
    // El idUserPet debe ser un string con contenido válido
    return idUserPet.length > 0;
  }

  // 🔥 NUEVO MÉTODO PARA EXTRAER PET ID (TEMPLATE ID) PARA EVOLUCIÓN
  String _extractPetIdForEvolution(CompanionEntity companion) {
    debugPrint('🔍 [EVOLUTION_EXTRACT] === EXTRAYENDO PET ID PARA EVOLUCIÓN ===');
    debugPrint('🐾 [EVOLUTION_EXTRACT] Companion: ${companion.displayName}');
    debugPrint('🆔 [EVOLUTION_EXTRACT] Local ID: ${companion.id}');
    debugPrint('🔧 [EVOLUTION_EXTRACT] Tipo: ${companion.runtimeType}');
    
    // 🔥 IMPORTANTE: Para evolución necesitamos el PET ID (template), NO el idUserPet (instancia)
    // El endpoint de evolución espera: /api/gamification/pets/owned/userId/petId/evolve
    // Donde petId es el ID del template de la mascota, no la instancia del usuario
    
    // 1. 🔥 BUSCAR EN LA RESPUESTA DE LA API EL PET ID REAL
    if (companion is CompanionModelWithPetId) {
      debugPrint('✅ [EVOLUTION_EXTRACT] Es CompanionModelWithPetId');
      
      // 🔥 PROBLEMA: El campo petId en CompanionModelWithPetId actualmente contiene idUserPet
      // Necesitamos buscar el pet_id real del template en los datos de la API
      
      try {
        final json = companion.toJson();
        debugPrint('📄 [EVOLUTION_EXTRACT] Buscando pet_id en JSON...');
        debugPrint('🗝️ [EVOLUTION_EXTRACT] Keys disponibles: ${json.keys.toList()}');
        
        // 🔥 BUSCAR EL PET ID REAL DEL TEMPLATE (no el idUserPet)
        final possiblePetIdKeys = [
          'originalPetId',    // Si se preservó el ID original
          'templatePetId',    // ID del template
          'basePetId',        // ID base
          'pet_template_id',  // Snake case
          'template_id',      // Simplificado
        ];
        
        for (final key in possiblePetIdKeys) {
          if (json.containsKey(key) && json[key] != null) {
            final value = json[key] as String;
            debugPrint('🎯 [EVOLUTION_EXTRACT] Encontrado $key: "$value"');
            
            if (_isValidPetId(value)) {
              debugPrint('✅ [EVOLUTION_EXTRACT] PET ID TEMPLATE VÁLIDO: $value');
              return value;
            }
          }
        }
        
        debugPrint('⚠️ [EVOLUTION_EXTRACT] No se encontró pet ID template en JSON');
      } catch (e) {
        debugPrint('❌ [EVOLUTION_EXTRACT] Error accediendo JSON: $e');
      }
    }
    
    // 2. 🔥 FALLBACK: MAPEAR DESDE EL NOMBRE DE LA MASCOTA AL PET ID CONOCIDO
    debugPrint('🔄 [EVOLUTION_EXTRACT] Usando mapeo por nombre como fallback...');
    final petId = _mapCompanionNameToPetId(companion.displayName, companion.type);
    
    if (_isValidPetId(petId)) {
      debugPrint('✅ [EVOLUTION_EXTRACT] Pet ID mapeado: $petId');
      return petId;
    }
    
    // 3. 🆘 ANÁLISIS DEL PROBLEMA
    debugPrint('🆘 [EVOLUTION_EXTRACT] === ANÁLISIS DEL PROBLEMA ===');
    debugPrint('❌ [EVOLUTION_EXTRACT] NO SE ENCONTRÓ PET ID VÁLIDO PARA EVOLUCIÓN');
    debugPrint('🔍 [EVOLUTION_EXTRACT] Posibles causas:');
    debugPrint('   1. La respuesta de getUserCompanions no incluye el pet_id original');
    debugPrint('   2. El mapping de la API no preserva el template ID');
    debugPrint('   3. La mascota se creó localmente sin datos de API');
    debugPrint('   4. El endpoint de evolución necesita un ID diferente');
    
    // 4. 🔥 RETURN ERROR ID para debugging
    final errorId = 'ERROR_NO_TEMPLATE_PET_ID_${companion.id}_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('🚨 [EVOLUTION_EXTRACT] Devolviendo ID de error: $errorId');
    debugPrint('💡 [EVOLUTION_EXTRACT] ACCIÓN REQUERIDA: Verificar que getUserCompanions preserve el pet_id original');
    
    return errorId;
  }
  
  // 🔥 HELPER PARA VALIDAR PET ID
  bool _isValidPetId(String? petId) {
    if (petId == null || petId.isEmpty) return false;
    if (petId == 'unknown') return false;
    if (petId.startsWith('ERROR_')) return false;
    if (petId.startsWith('FALLBACK_')) return false;
    if (petId == 'undefined') return false;
    if (petId == 'null') return false;
    
    // El petId debe ser un UUID válido o string con contenido
    return petId.length > 10; // Los UUIDs tienen al menos 36 caracteres
  }
  
  // 🔥 MAPEAR NOMBRE DE COMPANION A PET ID CONOCIDO
  String _mapCompanionNameToPetId(String name, CompanionType type) {
    debugPrint('🗺️ [MAPPING] Mapeando $name (${type.name}) a Pet ID...');
    
    // 🔥 ESTOS SON LOS PET IDs REALES DEL API QUE DEBES USAR
    // Basado en tu log: "pet_id":"e0512239-dc32-444f-a354-ef94446e5f1c"
    
    switch (type) {
      case CompanionType.dexter:
        // 🔥 USAR EL PET ID REAL DE DEXTER DESDE TU API
        return 'e0512239-dc32-444f-a354-ef94446e5f1c'; 
      case CompanionType.elly:
        return 'ab23c9ee-a63a-4114-aff7-8ef9899b33f6'; 
      case CompanionType.paxolotl:
        return 'afdfcdfa-aed6-4320-a8e5-51debbd1bccf';
      case CompanionType.yami:
        return '19119059-bb47-40e2-8eb5-8cf7a66f21b8'; 
    }
  }

  // ==================== 🔥 EVOLUCIÓN CORREGIDA (resto del código igual) ====================
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === INICIANDO EVOLUCIÓN ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName} ${companion.stage.name}');
      debugPrint('📊 [ACTIONS_CUBIT] Nivel: ${companion.level}, EXP: ${companion.experience}/${companion.experienceNeededForNextStage}');
      debugPrint('✅ [ACTIONS_CUBIT] Puede evolucionar: ${companion.canEvolve}');
      
      final validationResult = _validateEvolution(companion);
      if (!validationResult.isValid) {
        debugPrint('❌ [ACTIONS_CUBIT] Validación fallida: ${validationResult.message}');
        emit(CompanionActionsError(
          message: validationResult.message,
          action: 'evolving',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'evolving',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'evolving',
        ));
        return;
      }

      // 🔥 EXTRAER PET ID CORRECTO PARA EVOLUCIÓN (TEMPLATE ID, NO USER PET ID)
      final petId = _extractPetIdForEvolution(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID (template) extraído para evolución: $petId');
      
      if (petId.startsWith('ERROR_')) {
        emit(CompanionActionsError(
          message: '🔧 Error: Esta mascota no tiene un Pet ID válido para evolucionar',
          action: 'evolving',
        ));
        return;
      }
      
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
        currentStage: companion.stage, // 🔥 PASAR ETAPA ACTUAL DEL COMPANION
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error evolución API: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
          debugPrint('🎉 [ACTIONS_CUBIT] === EVOLUCIÓN EXITOSA ===');
          debugPrint('✨ [ACTIONS_CUBIT] Nueva etapa: ${evolvedCompanion.stage.name}');
          
          final nextStageName = _getNextStageName(companion.stage);
          final realName = evolvedCompanion.displayName.isNotEmpty 
              ? evolvedCompanion.displayName 
              : companion.displayName;
              
          emit(CompanionActionsSuccess(
            action: 'evolving',
            companion: evolvedCompanion,
            message: '🎉 ¡$realName ha evolucionado a $nextStageName!',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado evolución: $e');
      emit(CompanionActionsError(
        message: '❌ Error inesperado evolucionando a ${companion.displayName}',
        action: 'evolving',
      ));
    }
  }

  // ==================== 🔥 DESTACAR MASCOTA ====================
  Future<void> featureCompanion(CompanionEntity companion) async {
    try {
      debugPrint('⭐ [ACTIONS_CUBIT] === DESTACANDO MASCOTA ===');
      
      if (companion.isSelected) {
        emit(CompanionActionsError(
          message: '⭐ ${companion.displayName} ya es tu compañero activo',
          action: 'featuring',
        ));
        return;
      }
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes destacar a ${companion.displayName} porque no es tuyo',
          action: 'featuring',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'featuring',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'featuring',
        ));
        return;
      }
      
      final petId = _extractCorrectUserPetId(companion);
      
      final result = await repository.featureCompanion(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          emit(CompanionActionsError(
            message: failure.message,
            action: 'featuring',
          ));
        },
        (featuredCompanion) {
          final realName = featuredCompanion.displayName.isNotEmpty 
              ? featuredCompanion.displayName 
              : companion.displayName;
              
          emit(CompanionActionsSuccess(
            action: 'featuring',
            companion: featuredCompanion,
            message: '⭐ ¡$realName ahora es tu compañero activo!',
          ));
        },
      );
      
    } catch (e) {
      emit(CompanionActionsError(
        message: '❌ Error inesperado destacando a ${companion.displayName}',
        action: 'featuring',
      ));
    }
  }

  // ==================== MÉTODOS DE ESTADÍSTICAS DIRECTOS ====================
  Future<void> decreaseCompanionStats(
    CompanionEntity companion, {
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📉 [ACTIONS_CUBIT] === REDUCIENDO STATS DIRECTAMENTE ===');
      
      emit(CompanionActionsLoading(
        action: 'decreasing',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'decreasing',
        ));
        return;
      }
      
      final petId = _extractCorrectUserPetId(companion);
      
      final result = await decreasePetStatsUseCase(
        DecreasePetStatsParams(
          userId: userId,
          petId: petId,
          happiness: happiness,
          health: health,
        ),
      );
      
      result.fold(
        (failure) {
          emit(CompanionActionsError(
            message: failure.message,
            action: 'decreasing',
          ));
        },
        (updatedCompanion) {
          emit(CompanionActionsSuccess(
            action: 'decreasing',
            companion: updatedCompanion,
            message: '📉 Stats de ${updatedCompanion.displayName} reducidas',
          ));
        },
      );
      
    } catch (e) {
      emit(CompanionActionsError(
        message: '❌ Error reduciendo stats de ${companion.displayName}',
        action: 'decreasing',
      ));
    }
  }
  
  Future<void> increaseCompanionStats(
    CompanionEntity companion, {
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📈 [ACTIONS_CUBIT] === AUMENTANDO STATS DIRECTAMENTE ===');
      
      emit(CompanionActionsLoading(
        action: 'increasing',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'increasing',
        ));
        return;
      }
      
      final petId = _extractCorrectUserPetId(companion);
      
      final result = await increasePetStatsUseCase(
        IncreasePetStatsParams(
          userId: userId,
          petId: petId,
          happiness: happiness,
          health: health,
        ),
      );
      
      result.fold(
        (failure) {
          emit(CompanionActionsError(
            message: failure.message,
            action: 'increasing',
          ));
        },
        (updatedCompanion) {
          emit(CompanionActionsSuccess(
            action: 'increasing',
            companion: updatedCompanion,
            message: '📈 Stats de ${updatedCompanion.displayName} aumentadas',
          ));
        },
      );
      
    } catch (e) {
      emit(CompanionActionsError(
        message: '❌ Error aumentando stats de ${companion.displayName}',
        action: 'increasing',
      ));
    }
  }

  // ==================== MÉTODOS LEGACY ====================
  Future<void> feedCompanion(CompanionEntity companion) async {
    await feedCompanionViaApi(companion);
  }
  
  Future<void> loveCompanion(CompanionEntity companion) async {
    await loveCompanionViaApi(companion);
  }
  
  // ==================== MÉTODOS HELPER ====================
  ValidationResult _validateEvolution(CompanionEntity companion) {
    debugPrint('🎯 [VALIDATION] === VALIDANDO EVOLUCIÓN ===');
    
    if (!companion.isOwned) {
      return ValidationResult(false, '🔒 No puedes evolucionar a ${companion.displayName} porque no es tuyo');
    }
    
    if (companion.stage == CompanionStage.adult) {
      return ValidationResult(false, '🏆 ${companion.displayName} ya está en su máxima evolución');
    }
    
    if (!companion.canEvolve) {
      final needed = companion.experienceNeededForNextStage - companion.experience;
      return ValidationResult(false, '📊 ${companion.displayName} necesita $needed puntos más de experiencia');
    }
    
    return ValidationResult(true, '');
  }
  
  String _getNextStageName(CompanionStage currentStage) {
    switch (currentStage) {
      case CompanionStage.baby:
        return 'Joven';
      case CompanionStage.young:
        return 'Adulto';
      case CompanionStage.adult:
        return 'Máximo';
    }
  }
  
  void resetState() {
    emit(CompanionActionsInitial());
  }
  
  bool get isLoading => state is CompanionActionsLoading;
  
  String? get currentAction {
    final currentState = state;
    if (currentState is CompanionActionsLoading) {
      return currentState.action;
    }
    return null;
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  
  ValidationResult(this.isValid, this.message);
}