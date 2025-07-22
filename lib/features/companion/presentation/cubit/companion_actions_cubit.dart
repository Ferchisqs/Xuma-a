// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 CONECTADO A API REAL + ARREGLADO ALIMENTAR/AMOR

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import '../../../../core/services/token_manager.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/repositories/companion_repository.dart';

// ==================== STATES ====================
abstract class CompanionActionsState extends Equatable {
  const CompanionActionsState();
  
  @override
  List<Object?> get props => [];
}

class CompanionActionsInitial extends CompanionActionsState {}

class CompanionActionsLoading extends CompanionActionsState {
  final String action; // 'evolving', 'featuring', 'feeding', 'loving'
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

// ==================== CUBIT MEJORADO ====================
@injectable
class CompanionActionsCubit extends Cubit<CompanionActionsState> {
  final CompanionRepository repository;
  final TokenManager tokenManager;
  
  CompanionActionsCubit({
    required this.repository,
    required this.tokenManager,
  }) : super(CompanionActionsInitial());
  
  // 🔥 EVOLUCIONAR MASCOTA VIA API REAL
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🎯 [ACTIONS_CUBIT] Tipo: ${companion.type.name}, Etapa: ${companion.stage.name}');
      
      // 🔥 VALIDACIONES ANTES DE EVOLUCIONAR
      if (companion.stage == CompanionStage.adult) {
        emit(CompanionActionsError(
          message: '${companion.displayName} ya está en su máxima evolución',
          action: 'evolving',
        ));
        return;
      }
      
      if (!companion.canEvolve) {
        final needed = companion.experienceNeededForNextStage - companion.experience;
        emit(CompanionActionsError(
          message: '${companion.displayName} necesita $needed puntos más de experiencia para evolucionar',
          action: 'evolving',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'evolving',
        companion: companion,
      ));
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: 'Usuario no autenticado',
          action: 'evolving',
        ));
        return;
      }

      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para evolución: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT REAL DE EVOLUCIÓN
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error evolución API: ${failure.message}');
          
          // 🔥 MENSAJES ESPECÍFICOS SEGÚN EL ERROR
          String userMessage = failure.message;
          if (failure.message.contains('puntos')) {
            userMessage = 'No tienes suficientes puntos para evolucionar a ${companion.displayName}';
          } else if (failure.message.contains('máxima')) {
            userMessage = '${companion.displayName} ya está en su máxima evolución';
          } else if (failure.message.contains('experiencia')) {
            userMessage = '${companion.displayName} necesita más experiencia';
          } else if (failure.message.contains('no encontrada')) {
            userMessage = 'No se pudo encontrar a ${companion.displayName} en tu colección';
          }
          
          emit(CompanionActionsError(
            message: userMessage,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Evolución exitosa: ${evolvedCompanion.displayName}');
          
          // 🎉 MENSAJE PERSONALIZADO CON NOMBRE REAL
          final nextStageName = _getNextStageName(companion.stage);
          emit(CompanionActionsSuccess(
            action: 'evolving',
            companion: evolvedCompanion,
            message: '¡${companion.displayName} ha evolucionado a $nextStageName! 🎉',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado en evolución: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado evolucionando a ${companion.displayName}',
        action: 'evolving',
      ));
    }
  }
  
  // 🔥 DESTACAR MASCOTA VIA API REAL (MARCAR COMO ACTIVA)
  Future<void> featureCompanion(CompanionEntity companion) async {
    try {
      debugPrint('⭐ [ACTIONS_CUBIT] === DESTACANDO MASCOTA VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
      if (companion.isSelected) {
        emit(CompanionActionsError(
          message: '${companion.displayName} ya es tu compañero activo',
          action: 'featuring',
        ));
        return;
      }
      
      emit(CompanionActionsLoading(
        action: 'featuring',
        companion: companion,
      ));
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: 'Usuario no autenticado',
          action: 'featuring',
        ));
        return;
      }
      
      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para destacar: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT REAL DE FEATURE
      final result = await repository.featureCompanion(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error destacando: ${failure.message}');
          
          String userMessage = failure.message;
          if (failure.message.contains('no encontrada')) {
            userMessage = 'No se pudo encontrar a ${companion.displayName}';
          } else if (failure.message.contains('ya destacada')) {
            userMessage = '${companion.displayName} ya está destacado';
          }
          
          emit(CompanionActionsError(
            message: userMessage,
            action: 'featuring',
          ));
        },
        (featuredCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Destacado exitoso: ${featuredCompanion.displayName}');
          emit(CompanionActionsSuccess(
            action: 'featuring',
            companion: featuredCompanion,
            message: '¡${companion.displayName} ahora es tu compañero activo! ⭐',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado destacando: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado destacando a ${companion.displayName}',
        action: 'featuring',
      ));
    }
  }
  
  // 🔥 ALIMENTAR MASCOTA (LOCAL - ARREGLADO)
  Future<void> feedCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO MASCOTA (LOCAL ARREGLADO) ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🍽️ [ACTIONS_CUBIT] Hambre actual: ${companion.hunger}/100');
      
      // 🔥 VALIDACIONES MEJORADAS
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: 'No puedes alimentar a ${companion.displayName} porque no es tuyo',
          action: 'feeding',
        ));
        return;
      }
      
      if (companion.hunger >= 90) {
        emit(CompanionActionsError(
          message: '${companion.displayName} no tiene hambre ahora (${companion.hunger}/100)',
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
          message: 'Usuario no autenticado',
          action: 'feeding',
        ));
        return;
      }
      
      // 🔥 LLAMAR AL MÉTODO LOCAL ARREGLADO (no API, es mecánica local)
      final result = await repository.feedCompanion(userId, companion.id);
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error alimentando: ${failure.message}');
          emit(CompanionActionsError(
            message: 'No se pudo alimentar a ${companion.displayName}',
            action: 'feeding',
          ));
        },
        (fedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Alimentación exitosa: ${fedCompanion.displayName}');
          debugPrint('🍽️ [ACTIONS_CUBIT] Nueva hambre: ${fedCompanion.hunger}/100');
          
          emit(CompanionActionsSuccess(
            action: 'feeding',
            companion: fedCompanion,
            message: '¡${companion.displayName} ha sido alimentado! 🍎 (+25 EXP)',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado alimentando: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado alimentando a ${companion.displayName}',
        action: 'feeding',
      ));
    }
  }
  
  // 🔥 DAR AMOR A MASCOTA (LOCAL - ARREGLADO)
  Future<void> loveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR A MASCOTA (LOCAL ARREGLADO) ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
      
      // 🔥 VALIDACIONES MEJORADAS
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: 'No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }
      
      if (companion.happiness >= 95) {
        emit(CompanionActionsError(
          message: '${companion.displayName} ya está muy feliz (${companion.happiness}/100)',
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
          message: 'Usuario no autenticado',
          action: 'loving',
        ));
        return;
      }
      
      // 🔥 LLAMAR AL MÉTODO LOCAL ARREGLADO (no API, es mecánica local)
      final result = await repository.loveCompanion(userId, companion.id);
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error dando amor: ${failure.message}');
          emit(CompanionActionsError(
            message: 'No se pudo dar amor a ${companion.displayName}',
            action: 'loving',
          ));
        },
        (lovedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Amor exitoso: ${lovedCompanion.displayName}');
          debugPrint('❤️ [ACTIONS_CUBIT] Nueva felicidad: ${lovedCompanion.happiness}/100');
          
          emit(CompanionActionsSuccess(
            action: 'loving',
            companion: lovedCompanion,
            message: '¡${companion.displayName} se siente amado! 💖 (+20 EXP)',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado dando amor: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado dando amor a ${companion.displayName}',
        action: 'loving',
      ));
    }
  }
  
  // 🆕 EVOLUCIONAR MASCOTA POSEÍDA (ENDPOINT ALTERNATIVO)
  Future<void> evolveOwnedCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA POSEÍDA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
      if (!companion.canEvolve) {
        emit(CompanionActionsError(
          message: '${companion.displayName} necesita más experiencia para evolucionar',
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
          message: 'Usuario no autenticado',
          action: 'evolving',
        ));
        return;
      }

      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para evolución owned: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT DE EVOLUCIÓN OWNED
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error evolución owned: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Evolución owned exitosa: ${evolvedCompanion.displayName}');
          
          final nextStageName = _getNextStageName(companion.stage);
          emit(CompanionActionsSuccess(
            action: 'evolving',
            companion: evolvedCompanion,
            message: '¡${companion.displayName} ha evolucionado a $nextStageName! 🎉',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado en evolución owned: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado evolucionando a ${companion.displayName}',
        action: 'evolving',
      ));
    }
  }
  
  // 🆕 CAMBIAR ETAPA VISUALIZADA
  Future<void> selectCompanionStage(CompanionEntity companion, CompanionStage targetStage) async {
    try {
      debugPrint('🎭 [ACTIONS_CUBIT] === CAMBIANDO ETAPA VISUALIZADA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🎯 [ACTIONS_CUBIT] Etapa objetivo: ${targetStage.name}');
      
      emit(CompanionActionsLoading(
        action: 'selecting_stage',
        companion: companion,
      ));
      
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: 'Usuario no autenticado',
          action: 'selecting_stage',
        ));
        return;
      }

      final petId = _extractPetId(companion);
      final stageInt = _mapStageToInt(targetStage);
      
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID: $petId, Stage: $stageInt');
      
      // Llamar al endpoint de selección de etapa (cuando esté implementado)
      // Por ahora simular éxito
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Crear companion con nueva etapa visualizada
      final updatedCompanion = _createCompanionWithStage(companion, targetStage);
      
      emit(CompanionActionsSuccess(
        action: 'selecting_stage',
        companion: updatedCompanion,
        message: '¡Ahora visualizas a ${companion.displayName} en etapa ${targetStage.name}!',
      ));
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error cambiando etapa: $e');
      emit(CompanionActionsError(
        message: 'Error cambiando etapa de ${companion.displayName}',
        action: 'selecting_stage',
      ));
    }
  }
  
  // ==================== 🔧 MÉTODOS HELPER MEJORADOS ====================
  
  /// Extraer Pet ID real de la mascota
  String _extractPetId(CompanionEntity companion) {
    debugPrint('🔍 [ACTIONS_CUBIT] === EXTRAYENDO PET ID ===');
    debugPrint('🐾 [ACTIONS_CUBIT] Companion ID: ${companion.id}');
    debugPrint('🐾 [ACTIONS_CUBIT] Companion Type: ${companion.displayName}');
    
    // 1. Si es CompanionModelWithPetId, usar el petId directo
    if (companion is CompanionModelWithPetId) {
      debugPrint('✅ [ACTIONS_CUBIT] Found real petId: ${companion.petId}');
      return companion.petId;
    }
    
    // 2. Si es CompanionModel, verificar si tiene petId en JSON
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          final petId = json['petId'] as String;
          debugPrint('✅ [ACTIONS_CUBIT] Found petId in JSON: $petId');
          return petId;
        }
      } catch (e) {
        debugPrint('⚠️ [ACTIONS_CUBIT] Error accessing JSON: $e');
      }
    }
    
    // 3. Mapeo de fallback basado en tipo y etapa
    final fallbackPetId = _mapCompanionToDefaultPetId(companion);
    debugPrint('🔧 [ACTIONS_CUBIT] Using fallback petId: $fallbackPetId');
    return fallbackPetId;
  }
  
  /// Mapeo de fallback para Pet ID
  String _mapCompanionToDefaultPetId(CompanionEntity companion) {
    // Mapeo basado en el patrón de tu API
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
    
    // Formato esperado por tu API: tipo_etapa
    final petId = '${typeName}_$stageNumber';
    debugPrint('🗺️ [ACTIONS_CUBIT] Generated fallback petId: $petId');
    return petId;
  }
  
  /// Obtener nombre de la siguiente etapa
  String _getNextStageName(CompanionStage currentStage) {
    switch (currentStage) {
      case CompanionStage.baby:
        return 'Joven';
      case CompanionStage.young:
        return 'Adulto';
      case CompanionStage.adult:
        return 'Máximo'; // No debería llegar aquí
    }
  }
  
  /// Mapear etapa a int para API
  int _mapStageToInt(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 1;
      case CompanionStage.young:
        return 2;
      case CompanionStage.adult:
        return 3;
    }
  }
  
  /// Crear companion con nueva etapa (para selección de etapa)
  CompanionEntity _createCompanionWithStage(CompanionEntity companion, CompanionStage newStage) {
    if (companion is CompanionModel) {
      return companion.copyWith(
        stage: newStage,
        id: '${companion.type.name}_${newStage.name}',
      );
    }
    
    // Fallback: crear nuevo CompanionModel
    return CompanionModel(
      id: '${companion.type.name}_${newStage.name}',
      type: companion.type,
      stage: newStage,
      name: companion.name,
      description: companion.description,
      level: companion.level,
      experience: companion.experience,
      happiness: companion.happiness,
      hunger: companion.hunger,
      energy: companion.energy,
      isOwned: companion.isOwned,
      isSelected: companion.isSelected,
      purchasedAt: companion.purchasedAt,
      lastFeedTime: companion.lastFeedTime,
      lastLoveTime: companion.lastLoveTime,
      currentMood: companion.currentMood,
      purchasePrice: companion.purchasePrice,
      evolutionPrice: companion.evolutionPrice,
      unlockedAnimations: companion.unlockedAnimations,
      createdAt: companion.createdAt,
    );
  }
  
  // 🔥 MÉTODO PARA RESETEAR ESTADO
  void resetState() {
    emit(CompanionActionsInitial());
  }
  
  // 🔥 MÉTODO PARA VERIFICAR SI UNA ACCIÓN ESTÁ EN PROGRESO
  bool get isLoading => state is CompanionActionsLoading;
  
  String? get currentAction {
    final currentState = state;
    if (currentState is CompanionActionsLoading) {
      return currentState.action;
    }
    return null;
  }
}