// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 ACTUALIZADO: Integración con estadísticas reales desde pet details + Evolución funcional

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

// States
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

  // ==================== 🔥 ALIMENTAR VIA API CON STATS REALES ====================
  Future<void> feedCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO VIA API CON STATS REALES ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🏥 [ACTIONS_CUBIT] Salud actual: ${companion.hunger}/100');
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes alimentar a ${companion.displayName} porque no es tuyo',
          action: 'feeding',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN MEJORADA: Permitir alimentar hasta 95 (no 90)
      if (companion.hunger >= 95) {
        emit(CompanionActionsError(
          message: '🍽️ ${companion.displayName} está muy bien alimentado (${companion.hunger}/100)',
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
      
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para alimentar: $petId');
      debugPrint('🔄 [ACTIONS_CUBIT] Llamando a repository.feedCompanionViaApi...');
      
      // 🔥 USAR EL NUEVO MÉTODO QUE OBTIENE STATS REALES
      final result = await feedCompanionViaApiUseCase(
        FeedCompanionViaApiParams(
          userId: userId,
          petId: petId,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error alimentando: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'feeding',
          ));
        },
        (fedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] === ALIMENTACIÓN EXITOSA CON STATS REALES ===');
          debugPrint('🏥 [ACTIONS_CUBIT] Salud anterior: ${companion.hunger} → Nueva: ${fedCompanion.hunger}');
          debugPrint('📈 [ACTIONS_CUBIT] Ganancia de salud: +${fedCompanion.hunger - companion.hunger}');
          
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
  
  // ==================== 🔥 DAR AMOR VIA API CON STATS REALES ====================
  Future<void> loveCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR VIA API CON STATS REALES ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN MEJORADA: Permitir amar hasta 95 (no 90)
      if (companion.happiness >= 95) {
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
      
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para dar amor: $petId');
      debugPrint('🔄 [ACTIONS_CUBIT] Llamando a repository.loveCompanionViaApi...');
      
      // 🔥 USAR EL NUEVO MÉTODO QUE OBTIENE STATS REALES
      final result = await loveCompanionViaApiUseCase(
        LoveCompanionViaApiParams(
          userId: userId,
          petId: petId,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error dando amor: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'loving',
          ));
        },
        (lovedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] === AMOR EXITOSO CON STATS REALES ===');
          debugPrint('❤️ [ACTIONS_CUBIT] Felicidad anterior: ${companion.happiness} → Nueva: ${lovedCompanion.happiness}');
          debugPrint('📈 [ACTIONS_CUBIT] Ganancia de felicidad: +${lovedCompanion.happiness - companion.happiness}');
          
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

  // ==================== 🔥 SIMULAR TIEMPO CON STATS REALES ====================
  Future<void> simulateTimePassage(CompanionEntity companion) async {
    try {
      debugPrint('⏰ [ACTIONS_CUBIT] === SIMULANDO PASO DEL TIEMPO CON STATS REALES ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('📊 [ACTIONS_CUBIT] Stats actuales - Felicidad: ${companion.happiness}, Salud: ${companion.hunger}');
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes simular tiempo para ${companion.displayName} porque no es tuyo',
          action: 'simulating',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN MEJORADA: Solo simular si hay espacio para reducir
      if (companion.happiness <= 15 && companion.hunger <= 15) {
        emit(CompanionActionsError(
          message: '📊 ${companion.displayName} ya está en estadísticas muy bajas (H:${companion.happiness}, S:${companion.hunger})',
          action: 'simulating',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'simulating',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'simulating',
        ));
        return;
      }
      
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para simular tiempo: $petId');
      debugPrint('🔄 [ACTIONS_CUBIT] Llamando a repository.simulateTimePassage...');
      
      // 🔥 USAR EL NUEVO MÉTODO QUE OBTIENE STATS REALES
      final result = await simulateTimePassageUseCase(
        SimulateTimePassageParams(
          userId: userId,
          petId: petId,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error simulando tiempo: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'simulating',
          ));
        },
        (updatedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] === SIMULACIÓN DE TIEMPO EXITOSA CON STATS REALES ===');
          debugPrint('❤️ [ACTIONS_CUBIT] Felicidad: ${companion.happiness} → ${updatedCompanion.happiness}');
          debugPrint('🏥 [ACTIONS_CUBIT] Salud: ${companion.hunger} → ${updatedCompanion.hunger}');
          
          final happinessLoss = companion.happiness - updatedCompanion.happiness;
          final healthLoss = companion.hunger - updatedCompanion.hunger;
          
          String message = '⏰ ¡Ha pasado el tiempo!';
          if (happinessLoss > 0 || healthLoss > 0) {
            message += ' ${updatedCompanion.displayName}';
            if (happinessLoss > 0) message += ' -$happinessLoss felicidad';
            if (healthLoss > 0) message += ' -$healthLoss salud';
            message += ' - ¡Necesita cuidados!';
          }
          
          emit(CompanionActionsSuccess(
            action: 'simulating',
            companion: updatedCompanion,
            message: message,
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado simulando tiempo: $e');
      emit(CompanionActionsError(
        message: '❌ Error inesperado simulando tiempo para ${companion.displayName}',
        action: 'simulating',
      ));
    }
  }

  // ==================== 🔥 EVOLUCIÓN CORREGIDA ====================
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === INICIANDO EVOLUCIÓN CORREGIDA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName} ${companion.stage.name}');
      debugPrint('📊 [ACTIONS_CUBIT] Nivel: ${companion.level}, EXP: ${companion.experience}/${companion.experienceNeededForNextStage}');
      debugPrint('✅ [ACTIONS_CUBIT] Puede evolucionar: ${companion.canEvolve}');
      
      // 🔥 VALIDACIONES MEJORADAS
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

      // 🔥 OBTENER PET ID CORRECTO
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID extraído: $petId');
      
      // 🔥 LLAMAR ENDPOINT DE EVOLUCIÓN CORRECTO
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

  // ==================== 🔥 VALIDACIÓN DE EVOLUCIÓN MEJORADA ====================
  ValidationResult _validateEvolution(CompanionEntity companion) {
    debugPrint('🎯 [VALIDATION] === VALIDANDO EVOLUCIÓN ===');
    debugPrint('🐾 [VALIDATION] Mascota: ${companion.displayName}');
    debugPrint('📊 [VALIDATION] EXP: ${companion.experience}/${companion.experienceNeededForNextStage}');
    debugPrint('🏆 [VALIDATION] Etapa actual: ${companion.stage.name}');
    debugPrint('✅ [VALIDATION] Es poseída: ${companion.isOwned}');
    debugPrint('🔄 [VALIDATION] Puede evolucionar: ${companion.canEvolve}');
    
    if (!companion.isOwned) {
      return ValidationResult(false, '🔒 No puedes evolucionar a ${companion.displayName} porque no es tuyo');
    }
    
    if (companion.stage == CompanionStage.adult) {
      return ValidationResult(false, '🏆 ${companion.displayName} ya está en su máxima evolución');
    }
    
    // 🔥 VERIFICACIÓN CORREGIDA: Usar canEvolve del entity
    if (!companion.canEvolve) {
      final needed = companion.experienceNeededForNextStage - companion.experience;
      debugPrint('📉 [VALIDATION] Faltan $needed puntos de experiencia');
      return ValidationResult(false, '📊 ${companion.displayName} necesita $needed puntos más de experiencia');
    }
    
    debugPrint('✅ [VALIDATION] Validación exitosa - puede evolucionar');
    return ValidationResult(true, '');
  }

  // ==================== 🔥 EXTRACCIÓN DE PET ID MEJORADA ====================
  String _extractPetId(CompanionEntity companion) {
    debugPrint('🔍 [PET_ID] === EXTRAYENDO PET ID ===');
    debugPrint('🐾 [PET_ID] Companion ID: ${companion.id}');
    debugPrint('🔧 [PET_ID] Tipo de companion: ${companion.runtimeType}');
    
    // 1. Intentar extraer de CompanionModelWithPetId
    if (companion is CompanionModelWithPetId) {
      debugPrint('✅ [PET_ID] Es CompanionModelWithPetId, petId: ${companion.petId}');
      return companion.petId;
    }
    
    // 2. Intentar extraer del JSON de CompanionModel
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          final petId = json['petId'] as String;
          debugPrint('✅ [PET_ID] Extraído del JSON: $petId');
          return petId;
        }
      } catch (e) {
        debugPrint('⚠️ [PET_ID] Error accediendo JSON: $e');
      }
    }
    
    // 3. Mapeo por defecto basado en tipo y etapa
    final mappedPetId = _mapCompanionToDefaultPetId(companion);
    debugPrint('🗺️ [PET_ID] Usando mapeo por defecto: $mappedPetId');
    return mappedPetId;
  }
  
  String _mapCompanionToDefaultPetId(CompanionEntity companion) {
    // 🔥 MAPEO CORRECTO PARA LA API
    final typeMap = {
      CompanionType.dexter: 'chihuahua',
      CompanionType.elly: 'panda', 
      CompanionType.paxolotl: 'axolotl',
      CompanionType.yami: 'jaguar',
    };
    
    final stageMap = {
      CompanionStage.baby: '1',
      CompanionStage.young: '2', 
      CompanionStage.adult: '3',
    };
    
    final typeName = typeMap[companion.type] ?? 'chihuahua';
    final stageNumber = stageMap[companion.stage] ?? '2';
    
    // 🔥 FORMATO ESPERADO POR TU API
    final petId = '${typeName}_$stageNumber';
    debugPrint('🏗️ [MAPPING] Generado: $petId para ${companion.type.name}_${companion.stage.name}');
    return petId;
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
      
      final petId = _extractPetId(companion);
      
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

  // ==================== 🆕 MÉTODOS DE ESTADÍSTICAS DIRECTOS ====================
  Future<void> decreaseCompanionStats(
    CompanionEntity companion, {
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📉 [ACTIONS_CUBIT] === REDUCIENDO STATS DIRECTAMENTE ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('😢 [ACTIONS_CUBIT] Reducir felicidad: ${happiness ?? 0}');
      debugPrint('🩹 [ACTIONS_CUBIT] Reducir salud: ${health ?? 0}');
      
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
      
      final petId = _extractPetId(companion);
      
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
          debugPrint('✅ [ACTIONS_CUBIT] Stats reducidas exitosamente');
          debugPrint('📊 [ACTIONS_CUBIT] Nuevas stats - H:${updatedCompanion.happiness}, S:${updatedCompanion.hunger}');
          
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
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('😊 [ACTIONS_CUBIT] Aumentar felicidad: ${happiness ?? 0}');
      debugPrint('❤️ [ACTIONS_CUBIT] Aumentar salud: ${health ?? 0}');
      
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
      
      final petId = _extractPetId(companion);
      
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
          debugPrint('✅ [ACTIONS_CUBIT] Stats aumentadas exitosamente');
          debugPrint('📊 [ACTIONS_CUBIT] Nuevas stats - H:${updatedCompanion.happiness}, S:${updatedCompanion.hunger}');
          
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