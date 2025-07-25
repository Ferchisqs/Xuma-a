// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 ACTUALIZADO CON GESTIÓN DE ESTADÍSTICAS VIA API

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

// ==================== STATES (sin cambios) ====================
abstract class CompanionActionsState extends Equatable {
  const CompanionActionsState();
  
  @override
  List<Object?> get props => [];
}

class CompanionActionsInitial extends CompanionActionsState {}

class CompanionActionsLoading extends CompanionActionsState {
  final String action; // 'evolving', 'featuring', 'feeding', 'loving', 'decreasing', 'simulating'
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

// ==================== CUBIT ACTUALIZADO ====================
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
  
  // ==================== 🆕 ALIMENTAR MASCOTA VIA API REAL ====================
  Future<void> feedCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🍽️ [ACTIONS_CUBIT] Salud actual: ${companion.hunger}/100');
      
      // 🔥 VALIDACIONES RELAJADAS - PERMITIR SI ESTÁ BAJO 90
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes alimentar a ${companion.displayName} porque no es tuyo',
          action: 'feeding',
        ));
        return;
      }
      
      if (companion.hunger >= 90) {
        emit(CompanionActionsError(
          message: '🍽️ ${companion.displayName} no necesita comida ahora (${companion.hunger}/100)',
          action: 'feeding',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'feeding',
        companion: companion,
      ));
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'feeding',
        ));
        return;
      }
      
      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para alimentar: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT REAL DE ALIMENTACIÓN (INCREASE HEALTH)
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
          debugPrint('✅ [ACTIONS_CUBIT] Alimentación exitosa: ${fedCompanion.displayName}');
          debugPrint('🍽️ [ACTIONS_CUBIT] Nueva salud: ${fedCompanion.hunger}/100');
          
          emit(CompanionActionsSuccess(
            action: 'feeding',
            companion: fedCompanion,
            message: '🍎 ¡${fedCompanion.displayName} ha sido alimentado! +15 salud',
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
  
  // ==================== 🆕 DAR AMOR VIA API REAL ====================
  Future<void> loveCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
      
      // 🔥 VALIDACIONES RELAJADAS - PERMITIR SI ESTÁ BAJO 90
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }
      
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
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'loving',
        ));
        return;
      }
      
      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para dar amor: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT REAL DE AMOR (INCREASE HAPPINESS)
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
          debugPrint('✅ [ACTIONS_CUBIT] Amor exitoso: ${lovedCompanion.displayName}');
          debugPrint('❤️ [ACTIONS_CUBIT] Nueva felicidad: ${lovedCompanion.happiness}/100');
          
          emit(CompanionActionsSuccess(
            action: 'loving',
            companion: lovedCompanion,
            message: '💖 ¡${lovedCompanion.displayName} se siente amado! +10 felicidad',
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
  
  // ==================== 🆕 SIMULAR PASO DEL TIEMPO ====================
  Future<void> simulateTimePassage(CompanionEntity companion) async {
    try {
      debugPrint('⏰ [ACTIONS_CUBIT] === SIMULANDO PASO DEL TIEMPO ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('📊 [ACTIONS_CUBIT] Stats actuales: ${companion.happiness}❤️ ${companion.hunger}🍽️');
      
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes simular tiempo para ${companion.displayName} porque no es tuyo',
          action: 'simulating',
        ));
        return;
      }
      
      // Verificar que no estén ya al mínimo
      if (companion.happiness <= 15 && companion.hunger <= 15) {
        emit(CompanionActionsError(
          message: '📊 ${companion.displayName} ya está en estadísticas muy bajas',
          action: 'simulating',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'simulating',
        companion: companion,
      ));
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'simulating',
        ));
        return;
      }
      
      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para simular tiempo: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT DE SIMULACIÓN (DECREASE STATS)
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
          debugPrint('✅ [ACTIONS_CUBIT] Simulación exitosa: ${updatedCompanion.displayName}');
          debugPrint('📊 [ACTIONS_CUBIT] Nuevas stats: ${updatedCompanion.happiness}❤️ ${updatedCompanion.hunger}🍽️');
          
          emit(CompanionActionsSuccess(
            action: 'simulating',
            companion: updatedCompanion,
            message: '⏰ ¡Ha pasado el tiempo! ${updatedCompanion.displayName} necesita cuidados',
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
  
  // ==================== 🆕 MÉTODOS ESPECÍFICOS DE ESTADÍSTICAS ====================
  
  /// Reducir estadísticas manualmente (para testing)
  Future<void> decreaseCompanionStats(
    CompanionEntity companion, {
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📉 [ACTIONS_CUBIT] === REDUCIENDO STATS MANUALMENTE ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('😊 [ACTIONS_CUBIT] Reducir felicidad: ${happiness ?? 0}');
      debugPrint('❤️ [ACTIONS_CUBIT] Reducir salud: ${health ?? 0}');
      
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
  
  /// Aumentar estadísticas manualmente (para testing)
  Future<void> increaseCompanionStats(
    CompanionEntity companion, {
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📈 [ACTIONS_CUBIT] === AUMENTANDO STATS MANUALMENTE ===');
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
  
  // ==================== MÉTODOS EXISTENTES ACTUALIZADOS ====================
  
  // 🔥 ALIMENTAR - AHORA USA LA API REAL
  Future<void> feedCompanion(CompanionEntity companion) async {
    await feedCompanionViaApi(companion);
  }
  
  // 🔥 DAR AMOR - AHORA USA LA API REAL
  Future<void> loveCompanion(CompanionEntity companion) async {
    await loveCompanionViaApi(companion);
  }
  
  // MÉTODOS EXISTENTES (evolución, feature, etc.) - SIN CAMBIOS
  
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA VIA API REAL ===');
      // ... código existente de evolución ...
      
      final validationResult = _validateEvolution(companion);
      if (!validationResult.isValid) {
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

      final petId = _extractPetId(companion);
      
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          emit(CompanionActionsError(
            message: failure.message,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
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
      emit(CompanionActionsError(
        message: '❌ Error inesperado evolucionando a ${companion.displayName}',
        action: 'evolving',
      ));
    }
  }
  
  Future<void> featureCompanion(CompanionEntity companion) async {
    try {
      debugPrint('⭐ [ACTIONS_CUBIT] === DESTACANDO MASCOTA VIA API REAL ===');
      // ... código existente de feature ...
      
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
  
  // ==================== 🔧 MÉTODOS HELPER ====================
  
  String _extractPetId(CompanionEntity companion) {
    if (companion is CompanionModelWithPetId) {
      return companion.petId;
    }
    
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          final petId = json['petId'] as String;
          return petId;
        }
      } catch (e) {
        debugPrint('⚠️ [ACTIONS_CUBIT] Error accessing JSON: $e');
      }
    }
    
    return _mapCompanionToDefaultPetId(companion);
  }
  
  String _mapCompanionToDefaultPetId(CompanionEntity companion) {
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
    
    return '${typeName}_$stageNumber';
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
  
  ValidationResult _validateEvolution(CompanionEntity companion) {
    if (!companion.isOwned) {
      return ValidationResult(false, '🔒 No puedes evolucionar a ${companion.displayName} porque no es tuyo');
    }
    
    if (companion.stage == CompanionStage.adult) {
      return ValidationResult(false, '🏆 ${companion.displayName} ya está en su máxima evolución');
    }
    
    if (!companion.canEvolve) {
      final needed = companion.experienceNeededForNextStage - companion.experience;
      return ValidationResult(false, '📊 ${companion.displayName} necesita $needed puntos más de experiencia para evolucionar');
    }
    
    return ValidationResult(true, '');
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