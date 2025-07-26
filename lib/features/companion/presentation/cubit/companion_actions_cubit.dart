// lib/features/companion/presentation/cubit/companion_actions_cubit.dart
// 🔥 ACTUALIZADO: Integración con estadísticas reales desde pet details + Evolución funcional

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/data/datasources/companion_remote_datasource.dart';
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
      debugPrint(
          '🍎 [ACTIONS_CUBIT] === ALIMENTANDO CON idUserPet CORRECTO ===');

      // 🔥 VALIDACIÓN CRÍTICA
      if (!_hasValidUserPetId(companion)) {
        debugPrint('❌ [ACTIONS_CUBIT] No se encontró idUserPet válido');
        emit(CompanionActionsError(
          message: '🔧 Error: Esta mascota necesita ser re-adoptada. '
              'Visita la tienda para obtener el idUserPet correcto.',
          action: 'feeding',
        ));
        return;
      }

      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message:
              '🔒 No puedes alimentar a ${companion.displayName} porque no es tuyo',
          action: 'feeding',
        ));
        return;
      }

      if (companion.hunger >= 98) {
        emit(CompanionActionsError(
          message:
              '🍽️ ${companion.displayName} está muy bien alimentado (${companion.hunger}/100)',
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

      // 🔥 EXTRAER idUserPet CORRECTO
      final idUserPet = _extractPetId(companion);
      debugPrint('🎯 [ACTIONS_CUBIT] idUserPet para alimentar: $idUserPet');

      // 🔥 USAR MÉTODO CORREGIDO QUE ESPERA idUserPet
      final result = await feedCompanionViaApiUseCase(
        FeedCompanionViaApiParams(
          userId: userId,
          petId: idUserPet, // ✅ AHORA ES idUserPet
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
          debugPrint('✅ [ACTIONS_CUBIT] === ALIMENTACIÓN EXITOSA ===');

          // 🔥 ACTUALIZAR COMPANION ORIGINAL CON NUEVAS STATS
          final updatedCompanion =
              _updateCompanionStats(companion, fedCompanion);

          final healthGain = updatedCompanion.hunger - companion.hunger;
          final message = healthGain > 0
              ? '🍎 ¡${updatedCompanion.displayName} ha sido alimentado! +$healthGain salud (${updatedCompanion.hunger}/100)'
              : '🍎 ¡${updatedCompanion.displayName} ha sido alimentado! (${updatedCompanion.hunger}/100)';

          emit(CompanionActionsSuccess(
            action: 'feeding',
            companion: updatedCompanion,
            message: message,
          ));
        },
      );
    } catch (e) {
      debugPrint('💥 [ACTIONS_CUBIT] Error inesperado: $e');
      emit(CompanionActionsError(
        message: e.toString().contains('idUserPet')
            ? '🔧 ${e.toString()}'
            : '❌ Error inesperado alimentando a ${companion.displayName}',
        action: 'feeding',
      ));
    }
  }

  // ==================== 🔥 DAR AMOR VIA API CON STATS REALES ====================
  Future<void> loveCompanionViaApi(CompanionEntity companion) async {
    try {
      debugPrint(
          '💖 [ACTIONS_CUBIT] === DANDO AMOR VIA API CON STATS REALES ===');
      debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName}');
      debugPrint(
          '❤️ [ACTIONS_CUBIT] Felicidad actual: ${companion.happiness}/100');

      if (!companion.isOwned) {
        emit(CompanionActionsError(
          message:
              '🔒 No puedes dar amor a ${companion.displayName} porque no es tuyo',
          action: 'loving',
        ));
        return;
      }

      // 🔥 VALIDACIÓN CORREGIDA: Permitir amar hasta 98 (no 95)
      if (companion.happiness >= 98) {
        // ✅ CAMBIAR DE 95 A 98 PARA SER MÁS PERMISIVO
        emit(CompanionActionsError(
          message:
              '❤️ ${companion.displayName} ya está muy feliz (${companion.happiness}/100)',
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
      debugPrint(
          '🔄 [ACTIONS_CUBIT] Llamando a repository.loveCompanionViaApi...');

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
          debugPrint(
              '❤️ [ACTIONS_CUBIT] Felicidad anterior: ${companion.happiness} → Nueva: ${lovedCompanion.happiness}');
          debugPrint(
              '📈 [ACTIONS_CUBIT] Ganancia de felicidad: +${lovedCompanion.happiness - companion.happiness}');

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

  // ==================== 🔥 EVOLUCIÓN CORREGIDA ====================
  Future<void> evolveCompanion(CompanionEntity companion) async {
  try {
    debugPrint('🦋 [ACTIONS_CUBIT] === EVOLUCIÓN CON ENDPOINT CORRECTO ===');
    debugPrint('🐾 [ACTIONS_CUBIT] Mascota: ${companion.displayName} ${companion.stage.name}');
    debugPrint('📊 [ACTIONS_CUBIT] Nivel: ${companion.level}, EXP: ${companion.experience}');

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

    // 🔥 EXTRAER idUserPet CORRECTO PARA EVOLUCIÓN
    final idUserPet = _extractIdUserPetForEvolution(companion);
    debugPrint('🔑 [ACTIONS_CUBIT] idUserPet para evolución: $idUserPet');

    // 🔥 LLAMAR AL ENDPOINT CORRECTO DE EVOLUCIÓN
    final result = await repository.evolveCompanionViaApi(
      userId: userId,
      petId: idUserPet, // ✅ USAR idUserPet PARA EVOLUCIÓN
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
  debugPrint('🏆 [VALIDATION] Etapa actual: ${companion.stage.name}');
  debugPrint('✅ [VALIDATION] Es poseída: ${companion.isOwned}');

  if (!companion.isOwned) {
    return ValidationResult(false,
        '🔒 No puedes evolucionar a ${companion.displayName} porque no es tuyo');
  }

  if (companion.stage == CompanionStage.adult) {
    return ValidationResult(
        false, '🏆 ${companion.displayName} ya está en su máxima evolución');
  }

  // 🔥 SIMPLIFICAR: Solo verificar que pueda evolucionar
  if (!companion.canEvolve) {
    return ValidationResult(false,
        '📊 ${companion.displayName} necesita más experiencia para evolucionar');
  }

  debugPrint('✅ [VALIDATION] Validación exitosa - puede evolucionar');
  return ValidationResult(true, '');
}

  // ==================== 🔥 EXTRACCIÓN DE PET ID MEJORADA ====================
  String _extractPetId(CompanionEntity companion) {
    debugPrint('🔍 [PET_ID] === EXTRAYENDO idUserPet PARA STATS ===');
    debugPrint('🐾 [PET_ID] Companion: ${companion.displayName}');
    debugPrint('🆔 [PET_ID] Local ID: ${companion.id}');
    debugPrint('🔧 [PET_ID] Tipo: ${companion.runtimeType}');

    // 1. 🔥 SI ES CompanionModelWithBothIds, USAR idUserPet
    if (companion is CompanionModelWithBothIds) {
      final idUserPet = companion.idUserPet;
      debugPrint('✅ [PET_ID] Es CompanionModelWithBothIds');
      debugPrint('🎯 [PET_ID] idUserPet encontrado: "$idUserPet"');

      if (idUserPet.isNotEmpty &&
          idUserPet != 'unknown' &&
          idUserPet != '' &&
          !idUserPet.startsWith('FALLBACK_')) {
        debugPrint('✅ [PET_ID] idUserPet válido para stats: $idUserPet');
        return idUserPet; // ✅ RETORNAR idUserPet PARA ESTADÍSTICAS
      } else {
        debugPrint('⚠️ [PET_ID] idUserPet inválido: "$idUserPet"');
      }
    }

    // 2. 🔥 SI ES CompanionModelWithPetId (legacy), INTENTAR EXTRAER
    if (companion is CompanionModelWithPetId) {
      final petId = companion.petId;
      debugPrint('✅ [PET_ID] Es CompanionModelWithPetId (legacy)');
      debugPrint('🎯 [PET_ID] Pet ID legacy: "$petId"');

      if (petId.isNotEmpty &&
          petId != 'unknown' &&
          petId != '' &&
          !petId.startsWith('FALLBACK_')) {
        debugPrint('⚠️ [PET_ID] Usando Pet ID legacy como idUserPet: $petId');
        return petId; // ⚠️ PUEDE FUNCIONAR SI ES EL MISMO
      }
    }

    // 3. 🔥 INTENTAR EXTRAER DEL JSON
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        debugPrint('📄 [PET_ID] Buscando idUserPet en JSON...');
        debugPrint('🗝️ [PET_ID] Keys disponibles: ${json.keys.toList()}');

        // 🔥 BUSCAR ESPECÍFICAMENTE idUserPet
        if (json.containsKey('idUserPet') && json['idUserPet'] != null) {
          final idUserPet = json['idUserPet'] as String;
          debugPrint('🎯 [PET_ID] idUserPet del JSON: "$idUserPet"');

          if (idUserPet.isNotEmpty &&
              idUserPet != 'unknown' &&
              !idUserPet.startsWith('FALLBACK_')) {
            debugPrint('✅ [PET_ID] idUserPet del JSON válido: $idUserPet');
            return idUserPet;
          }
        }

        // 🔥 FALLBACK: Buscar otros campos
        final possibleKeys = ['petId', 'userPetId', 'user_pet_id'];
        for (final key in possibleKeys) {
          if (json.containsKey(key) && json[key] != null) {
            final fallbackId = json[key] as String;
            debugPrint('⚠️ [PET_ID] Fallback encontrado $key: "$fallbackId"');

            if (fallbackId.isNotEmpty &&
                fallbackId != 'unknown' &&
                !fallbackId.startsWith('FALLBACK_')) {
              debugPrint('⚠️ [PET_ID] Usando fallback: $fallbackId');
              return fallbackId;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [PET_ID] Error accediendo JSON: $e');
      }
    }

    // 4. 🆘 ERROR CRÍTICO - NO SE ENCONTRÓ idUserPet
    debugPrint('🆘 [PET_ID] === ERROR CRÍTICO: NO SE ENCONTRÓ idUserPet ===');
    debugPrint('❌ [PET_ID] Esto significa que:');
    debugPrint('   1. El companion no se creó con CompanionModelWithBothIds');
    debugPrint('   2. No se obtuvo el idUserPet del endpoint de detalles');
    debugPrint('   3. La mascota no está correctamente adoptada');

    // 🚨 LANZAR EXCEPCIÓN EN LUGAR DE RETORNAR ID INVÁLIDO
    throw Exception(
        '❌ No se encontró idUserPet válido para ${companion.displayName}. '
        'Asegúrate de que la mascota esté adoptada y tenga idUserPet.');
  }

  // 🔥 MÉTODO HELPER MEJORADO PARA VALIDAR idUserPet
  bool _hasValidUserPetId(CompanionEntity companion) {
    try {
      final idUserPet = _extractPetId(companion);
      return idUserPet.isNotEmpty &&
          idUserPet != 'unknown' &&
          !idUserPet.startsWith('ERROR_') &&
          !idUserPet.startsWith('FALLBACK_');
    } catch (e) {
      debugPrint('❌ [VALIDATION] Error validando idUserPet: $e');
      return false;
    }
  }

  // 🔥 MÉTODO HELPER PARA ACTUALIZAR STATS PRESERVANDO DATOS ORIGINALES
  CompanionEntity _updateCompanionStats(
      CompanionEntity original, CompanionEntity updated) {
    if (original is CompanionModelWithBothIds) {
      return original.copyWith(
        happiness: updated.happiness,
        hunger: updated.hunger,
        energy: updated.energy,
        currentMood: updated.currentMood,
        lastFeedTime: DateTime.now(),
      );
    } else if (original is CompanionModel) {
      return original.copyWith(
        happiness: updated.happiness,
        hunger: updated.hunger,
        energy: updated.energy,
        currentMood: updated.currentMood,
        lastFeedTime: DateTime.now(),
      );
    }

    // Fallback
    return updated;
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
          message:
              '🔒 No puedes destacar a ${companion.displayName} porque no es tuyo',
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
          debugPrint(
              '📊 [ACTIONS_CUBIT] Nuevas stats - H:${updatedCompanion.happiness}, S:${updatedCompanion.hunger}');

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
          debugPrint(
              '📊 [ACTIONS_CUBIT] Nuevas stats - H:${updatedCompanion.happiness}, S:${updatedCompanion.hunger}');

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

  String _extractIdUserPetForEvolution(CompanionEntity companion) {
  debugPrint('🔍 [EVOLUTION_ID] === EXTRAYENDO idUserPet PARA EVOLUCIÓN ===');
  debugPrint('🐾 [EVOLUTION_ID] Companion: ${companion.displayName}');

  // 1. 🔥 SI ES CompanionModelWithBothIds, USAR idUserPet
  if (companion is CompanionModelWithBothIds) {
    final idUserPet = companion.idUserPet;
    debugPrint('✅ [EVOLUTION_ID] idUserPet encontrado: "$idUserPet"');

    if (idUserPet.isNotEmpty && idUserPet != 'unknown' && idUserPet != 'pending') {
      debugPrint('✅ [EVOLUTION_ID] idUserPet válido para evolución: $idUserPet');
      return idUserPet;
    }
  }

  // 2. 🔥 FALLBACK: Buscar en JSON
  if (companion is CompanionModel) {
    try {
      final json = companion.toJson();
      if (json.containsKey('idUserPet') && json['idUserPet'] != null) {
        final idUserPet = json['idUserPet'] as String;
        if (idUserPet.isNotEmpty && idUserPet != 'unknown') {
          debugPrint('✅ [EVOLUTION_ID] idUserPet del JSON: $idUserPet');
          return idUserPet;
        }
      }
    } catch (e) {
      debugPrint('❌ [EVOLUTION_ID] Error accediendo JSON: $e');
    }
  }

  // 3. 🆘 ERROR CRÍTICO
  debugPrint('🆘 [EVOLUTION_ID] === ERROR: NO SE ENCONTRÓ idUserPet ===');
  throw Exception(
    '❌ No se encontró idUserPet válido para evolucionar ${companion.displayName}. '
    'Asegúrate de que la mascota esté correctamente adoptada.');
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
