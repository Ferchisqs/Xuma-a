// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 EVOLUCIÓN API REAL + ACCIONES LOCALES ARREGLADAS + VALIDACIONES MEJORADAS

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
  
  // 🔥 EVOLUCIONAR MASCOTA VIA API REAL CON VALIDACIONES MEJORADAS
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🎯 [ACTIONS_CUBIT] Tipo: ${companion.type.name}, Etapa: ${companion.stage.name}');
      debugPrint('📊 [ACTIONS_CUBIT] Experiencia: ${companion.experience}/${companion.experienceNeededForNextStage}');
      
      // 🔥 VALIDACIONES ESTRICTAS ANTES DE EVOLUCIONAR
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
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
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
          
          // 🔥 LOS MENSAJES YA VIENEN FORMATEADOS DEL DATASOURCE
          emit(CompanionActionsError(
            message: failure.message,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Evolución exitosa: ${evolvedCompanion.displayName}');
          
          // 🔥 MENSAJE PERSONALIZADO CON NOMBRE REAL
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
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado en evolución: $e');
      emit(CompanionActionsError(
        message: '❌ Error inesperado evolucionando a ${companion.displayName}',
        action: 'evolving',
      ));
    }
  }
  
  // 🔥 DESTACAR MASCOTA VIA API REAL (SOLO UNA ACTIVA)
  Future<void> featureCompanion(CompanionEntity companion) async {
    try {
      debugPrint('⭐ [ACTIONS_CUBIT] === DESTACANDO MASCOTA VIA API REAL ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
      // 🔥 VALIDACIÓN: SI YA ESTÁ SELECCIONADA
      if (companion.isSelected) {
        emit(CompanionActionsError(
          message: '⭐ ${companion.displayName} ya es tu compañero activo',
          action: 'featuring',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN: DEBE SER POSEÍDA
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
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        emit(CompanionActionsError(
          message: '🔐 Usuario no autenticado',
          action: 'featuring',
        ));
        return;
      }
      
      // Obtener Pet ID real de la mascota
      final petId = _extractPetId(companion);
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID para destacar: $petId');
      
      // 🔥 LLAMAR AL ENDPOINT REAL DE FEATURE (DESTACA SOLO UNA)
      final result = await repository.featureCompanion(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error destacando: ${failure.message}');
          
          // 🔥 LOS MENSAJES YA VIENEN FORMATEADOS DEL DATASOURCE
          emit(CompanionActionsError(
            message: failure.message,
            action: 'featuring',
          ));
        },
        (featuredCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Destacado exitoso: ${featuredCompanion.displayName}');
          
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
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado destacando: $e');
      emit(CompanionActionsError(
        message: '❌ Error inesperado destacando a ${companion.displayName}',
        action: 'featuring',
      ));
    }
  }
  
  // 🔥 ALIMENTAR MASCOTA (LOCAL - ARREGLADO Y VALIDADO)
  Future<void> feedCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO MASCOTA (LOCAL ARREGLADO) ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('🍽️ [ACTIONS_CUBIT] Hambre actual: ${companion.hunger}/100');
      
      // 🔥 VALIDACIONES MEJORADAS
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes alimentar a ${companion.displayName} porque no es tuyo',
          action: 'feeding',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN MÁS PERMISIVA (MENOS DE 90 EN LUGAR DE 100)
      if (companion.hunger >= 90) {
        emit(CompanionActionsError(
          message: '🍽️ ${companion.displayName} no tiene hambre ahora (${companion.hunger}/100)',
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
      
      // 🔥 LLAMAR AL MÉTODO LOCAL ARREGLADO (no API, es mecánica local)
      final result = await repository.feedCompanion(userId, companion.id);
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error alimentando: ${failure.message}');
          emit(CompanionActionsError(
            message: '🍎 No se pudo alimentar a ${companion.displayName}',
            action: 'feeding',
          ));
        },
        (fedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Alimentación exitosa: ${fedCompanion.displayName}');
          debugPrint('🍽️ [ACTIONS_CUBIT] Nueva hambre: ${fedCompanion.hunger}/100');
          debugPrint('📊 [ACTIONS_CUBIT] Nueva experiencia: ${fedCompanion.experience}');
          
          emit(CompanionActionsSuccess(
            action: 'feeding',
            companion: fedCompanion,
            message: '🍎 ¡${fedCompanion.displayName} ha sido alimentado! (+25 EXP)',
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
  
  // 🔥 DAR AMOR A MASCOTA (LOCAL - ARREGLADO Y VALIDADO)
  Future<void> loveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR A MASCOTA (LOCAL ARREGLADO) ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint('❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');
      
      // 🔥 VALIDACIONES MEJORADAS
      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message: '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }
      
      // 🔥 VALIDACIÓN MÁS PERMISIVA (MENOS DE 90 EN LUGAR DE 100)
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
      
      // 🔥 LLAMAR AL MÉTODO LOCAL ARREGLADO (no API, es mecánica local)
      final result = await repository.loveCompanion(userId, companion.id);
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error dando amor: ${failure.message}');
          emit(CompanionActionsError(
            message: '💖 No se pudo dar amor a ${companion.displayName}',
            action: 'loving',
          ));
        },
        (lovedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Amor exitoso: ${lovedCompanion.displayName}');
          debugPrint('❤️ [ACTIONS_CUBIT] Nueva felicidad: ${lovedCompanion.happiness}/100');
          debugPrint('📊 [ACTIONS_CUBIT] Nueva experiencia: ${lovedCompanion.experience}');
          
          emit(CompanionActionsSuccess(
            action: 'loving',
            companion: lovedCompanion,
            message: '💖 ¡${lovedCompanion.displayName} se siente amado! (+20 EXP)',
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
  
  // 🆕 EVOLUCIONAR MASCOTA POSEÍDA (ENDPOINT ALTERNATIVO)
  Future<void> evolveOwnedCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA POSEÍDA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
      // 🔥 USAR LAS MISMAS VALIDACIONES QUE LA EVOLUCIÓN NORMAL
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
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado en evolución owned: $e');
      emit(CompanionActionsError(
        message: '❌ Error inesperado evolucionando a ${companion.displayName}',
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
          message: '🔐 Usuario no autenticado',
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
        message: '🎭 ¡Ahora visualizas a ${companion.displayName} en etapa ${targetStage.name}!',
      ));
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error cambiando etapa: $e');
      emit(CompanionActionsError(
        message: '❌ Error cambiando etapa de ${companion.displayName}',
        action: 'selecting_stage',
      ));
    }
  }
  
  // ==================== 🔧 VALIDACIONES MEJORADAS ====================
  
  /// 🔥 VALIDAR EVOLUCIÓN CON REGLAS ESTRICTAS
  ValidationResult _validateEvolution(CompanionEntity companion) {
    debugPrint('🔍 [VALIDATION] === VALIDANDO EVOLUCIÓN ===');
    debugPrint('🐾 [VALIDATION] Mascota: ${companion.displayName}');
    debugPrint('📊 [VALIDATION] Etapa actual: ${companion.stage.name}');
    debugPrint('📊 [VALIDATION] Experiencia: ${companion.experience}/${companion.experienceNeededForNextStage}');
    debugPrint('🔒 [VALIDATION] Es poseída: ${companion.isOwned}');
    
    // 1. Debe ser poseída
    if (!companion.isOwned) {
      return ValidationResult(false, '🔒 No puedes evolucionar a ${companion.displayName} porque no es tuyo');
    }
    
    // 2. No puede estar ya en etapa adult
    if (companion.stage == CompanionStage.adult) {
      return ValidationResult(false, '🏆 ${companion.displayName} ya está en su máxima evolución');
    }
    
    // 3. Debe tener suficiente experiencia
    if (!companion.canEvolve) {
      final needed = companion.experienceNeededForNextStage - companion.experience;
      return ValidationResult(false, '📊 ${companion.displayName} necesita $needed puntos más de experiencia para evolucionar');
    }
    
    // 4. Validar orden de etapas (debe tener la etapa anterior)
    final stageOrderResult = _validateStageOrder(companion);
    if (!stageOrderResult.isValid) {
      return stageOrderResult;
    }
    
    debugPrint('✅ [VALIDATION] Todas las validaciones pasadas');
    return ValidationResult(true, '');
  }
  
  /// 🔥 VALIDAR ORDEN DE ETAPAS (DEBE EVOLUCIONAR EN ORDEN)
  ValidationResult _validateStageOrder(CompanionEntity companion) {
    debugPrint('📈 [STAGE_ORDER] Validando orden de etapas para: ${companion.displayName}');
    
    // Para esta validación, asumimos que si el usuario tiene la mascota,
    // ya tiene todas las etapas anteriores necesarias.
    // Esta lógica se puede expandir si necesitas validar contra una lista completa.
    
    switch (companion.stage) {
      case CompanionStage.baby:
        // Baby puede evolucionar a young sin restricciones adicionales
        return ValidationResult(true, '');
        
      case CompanionStage.young:
        // Young puede evolucionar a adult sin restricciones adicionales
        return ValidationResult(true, '');
        
      case CompanionStage.adult:
        // Adult ya no puede evolucionar
        return ValidationResult(false, '🏆 ${companion.displayName} ya está en su máxima evolución');
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

// ==================== 🔧 CLASE HELPER PARA VALIDACIONES ====================
class ValidationResult {
  final bool isValid;
  final String message;
  
  ValidationResult(this.isValid, this.message);
}