// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 CREAR ESTE NUEVO ARCHIVO

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

// ==================== CUBIT ====================
@injectable
class CompanionActionsCubit extends Cubit<CompanionActionsState> {
  final CompanionRepository repository;
  final TokenManager tokenManager;
  
  CompanionActionsCubit({
    required this.repository,
    required this.tokenManager,
  }) : super(CompanionActionsInitial());
  
  // 🔥 EVOLUCIONAR MASCOTA VIA API
  Future<void> evolveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIONANDO MASCOTA ===');
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
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID: $petId');
      
      final result = await repository.evolveCompanionViaApi(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error evolución: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'evolving',
          ));
        },
        (evolvedCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Evolución exitosa: ${evolvedCompanion.displayName}');
          emit(CompanionActionsSuccess(
            action: 'evolving',
            companion: evolvedCompanion,
            message: '¡${evolvedCompanion.displayName} ha evolucionado a ${evolvedCompanion.stageDisplayName}!',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado: ${e.toString()}',
        action: 'evolving',
      ));
    }
  }
  
  // 🔥 DESTACAR MASCOTA VIA API (MARCAR COMO ACTIVA)
  Future<void> featureCompanion(CompanionEntity companion) async {
    try {
      debugPrint('⭐ [ACTIONS_CUBIT] === DESTACANDO MASCOTA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
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
      debugPrint('🆔 [ACTIONS_CUBIT] Pet ID: $petId');
      
      final result = await repository.featureCompanion(
        userId: userId,
        petId: petId,
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [ACTIONS_CUBIT] Error destacando: ${failure.message}');
          emit(CompanionActionsError(
            message: failure.message,
            action: 'featuring',
          ));
        },
        (featuredCompanion) {
          debugPrint('✅ [ACTIONS_CUBIT] Destacado exitoso: ${featuredCompanion.displayName}');
          emit(CompanionActionsSuccess(
            action: 'featuring',
            companion: featuredCompanion,
            message: '¡${featuredCompanion.displayName} ahora es tu compañero activo!',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado: ${e.toString()}',
        action: 'featuring',
      ));
    }
  }
  
  // 🔥 ALIMENTAR MASCOTA (LOCAL)
  Future<void> feedCompanion(CompanionEntity companion) async {
    try {
      debugPrint('🍎 [ACTIONS_CUBIT] === ALIMENTANDO MASCOTA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
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
      
      final result = await repository.feedCompanion(userId, companion.id);
      
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
          emit(CompanionActionsSuccess(
            action: 'feeding',
            companion: fedCompanion,
            message: '¡${fedCompanion.displayName} ha sido alimentado!',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado: ${e.toString()}',
        action: 'feeding',
      ));
    }
  }
  
  // 🔥 DAR AMOR A MASCOTA (LOCAL)
  Future<void> loveCompanion(CompanionEntity companion) async {
    try {
      debugPrint('💖 [ACTIONS_CUBIT] === DANDO AMOR A MASCOTA ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      
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
      
      final result = await repository.loveCompanion(userId, companion.id);
      
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
          emit(CompanionActionsSuccess(
            action: 'loving',
            companion: lovedCompanion,
            message: '¡${lovedCompanion.displayName} se siente amado!',
          ));
        },
      );
      
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado: $e');
      emit(CompanionActionsError(
        message: 'Error inesperado: ${e.toString()}',
        action: 'loving',
      ));
    }
  }
  
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
  
  // 🔧 MAPEO DE FALLBACK PARA PET ID
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
}