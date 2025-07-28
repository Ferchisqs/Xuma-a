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
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO CON idUserPet CORREGIDO ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Companion: ${companion.displayName}');
      debugPrint('🏥 [ACTIONS_CUBIT] Salud actual: ${companion.hunger}/100');
      
      // 🔥 VALIDACIÓN RELAJADA: Permitir alimentar hasta 90 (en lugar de 95)
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
      debugPrint('🎯 [ACTIONS_CUBIT] === EXTRACCIÓN DE idUserPet ===');
      debugPrint('🆔 [ACTIONS_CUBIT] idUserPet extraído: "$idUserPet"');
      debugPrint('🔧 [ACTIONS_CUBIT] Tipo de companion: ${companion.runtimeType}');
      
      if (idUserPet.isEmpty || idUserPet.startsWith('ERROR_')) {
        debugPrint('❌ [ACTIONS_CUBIT] idUserPet inválido: $idUserPet');
        emit(CompanionActionsError(
          message: '🔧 Error: Esta mascota no tiene un ID de usuario válido. Intenta recargar.',
          action: 'feeding',
        ));
        return;
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
          debugPrint('🏥 [ACTIONS_CUBIT] Salud anterior: ${companion.hunger} → Nueva: ${fedCompanion.hunger}');
          
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
  
  // ==================== 🔥 DAR AMOR VIA API - CORREGIDO ====================
  Future<void> loveCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR VIA API CORREGIDO ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Companion: ${companion.displayName}');
      debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN RELAJADA: Permitir amar hasta 90 (en lugar de 95)
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
      
      if (idUserPet.isEmpty || idUserPet.startsWith('ERROR_')) {
        debugPrint('❌ [ACTIONS_CUBIT] idUserPet inválido: $idUserPet');
        emit(CompanionActionsError(
          message: '🔧 Error: Esta mascota no tiene un ID de usuario válido. Intenta recargar.',
          action: 'loving',
        ));
        return;
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
          debugPrint('❤️ [ACTIONS_CUBIT] Felicidad anterior: ${companion.happiness} → Nueva: ${lovedCompanion.happiness}');
          
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
    debugPrint('🆔 [EXTRACT] Local ID: ${companion.id}');
    debugPrint('🔧 [EXTRACT] Tipo: ${companion.runtimeType}');
    
    // 1. 🔥 MÉTODO PRINCIPAL: CompanionModelWithPetId
    if (companion is CompanionModelWithPetId) {
      final idUserPet = companion.petId;
      debugPrint('✅ [EXTRACT] Es CompanionModelWithPetId');
      debugPrint('🎯 [EXTRACT] petId extraído: "$idUserPet"');
      
      if (_isValidUserPetId(idUserPet)) {
        debugPrint('✅ [EXTRACT] idUserPet VÁLIDO: $idUserPet');
        return idUserPet;
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
        ];
        
        for (final key in possibleKeys) {
          if (json.containsKey(key) && json[key] != null) {
            final value = json[key] as String;
            debugPrint('🎯 [EXTRACT] Encontrado $key: "$value"');
            
            if (_isValidUserPetId(value)) {
              debugPrint('✅ [EXTRACT] idUserPet del JSON VÁLIDO: $value');
              return value;
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
    debugPrint('   1. El companion no se creó correctamente desde getPetDetails');
    debugPrint('   2. El endpoint getPetDetails no devuelve idUserPet');
    debugPrint('   3. El mapping de la respuesta está incompleto');
    debugPrint('   4. La mascota no está realmente adoptada por el usuario');
    
    // 4. 🔥 RETURN ERROR ID para debugging
    final errorId = 'ERROR_NO_USER_PET_ID_${companion.id}_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('🚨 [EXTRACT] Devolviendo ID de error: $errorId');
    debugPrint('💡 [EXTRACT] ACCIÓN REQUERIDA: Verificar el flujo de adopción y getPetDetails');
    
    return errorId;
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

      final petId = _extractCorrectUserPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID extraído: $petId');
      
      if (petId.startsWith('ERROR_')) {
        emit(CompanionActionsError(
          message: '🔧 Error: Esta mascota no tiene un ID válido para evolucionar',
          action: 'evolving',
        ));
        return;
      }
      
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
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