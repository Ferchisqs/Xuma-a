// lib/features/companion/presentation/cubit/companion_shop_cubit.dart
// 🔥 LÓGICA DE ETAPAS + MENSAJES CORREGIDOS + VALIDACIONES MEJORADAS

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/di/injection.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// ==================== STATES (sin cambios) ====================
abstract class CompanionShopState extends Equatable {
  const CompanionShopState();
  @override
  List<Object?> get props => [];
}

class CompanionShopInitial extends CompanionShopState {}

class CompanionShopLoading extends CompanionShopState {}

class CompanionShopLoaded extends CompanionShopState {
  final List<CompanionEntity> availableCompanions;
  final List<CompanionEntity> purchasableCompanions;
  final CompanionStatsEntity userStats;
  final Map<String, String> availablePetIds;
  final List<CompanionEntity> userOwnedCompanions; // 🆕 AGREGAR MASCOTAS DEL USUARIO

  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
    required this.availablePetIds,
    required this.userOwnedCompanions, // 🆕
  });

  @override
  List<Object> get props => [
    availableCompanions, 
    purchasableCompanions, 
    userStats, 
    availablePetIds, 
    userOwnedCompanions
  ];
}

class CompanionShopPurchasing extends CompanionShopState {
  final CompanionEntity companion;
  const CompanionShopPurchasing({required this.companion});
  @override
  List<Object> get props => [companion];
}

class CompanionShopPurchaseSuccess extends CompanionShopState {
  final CompanionEntity purchasedCompanion;
  final String message;

  const CompanionShopPurchaseSuccess({
    required this.purchasedCompanion,
    required this.message,
  });

  @override
  List<Object> get props => [purchasedCompanion, message];
}

class CompanionShopError extends CompanionShopState {
  final String message;
  const CompanionShopError({required this.message});
  @override
  List<Object> get props => [message];
}

// ==================== CUBIT MEJORADO CON LÓGICA DE ETAPAS ====================
@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  final TokenManager tokenManager;

  // 🆕 MAPEO DINÁMICO + MASCOTAS DEL USUARIO
  Map<String, String> _localIdToApiPetId = {};
  Map<String, Map<String, dynamic>> _apiPetIdToInfo = {};
  List<CompanionEntity> _userOwnedCompanions = [];

  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
    required this.tokenManager,
  }) : super(CompanionShopInitial());

  Future<void> loadShop() async {
    try {
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA CON LÓGICA DE ETAPAS ===');
      emit(CompanionShopLoading());

      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        emit(CompanionShopError(message: 'Usuario no autenticado'));
        return;
      }

      debugPrint('👤 [SHOP_CUBIT] Usuario autenticado: $userId');

      final result = await getCompanionShopUseCase(
        GetCompanionShopParams(userId: userId),
      );

      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error API: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [SHOP_CUBIT] === TIENDA API CARGADA ===');
          debugPrint('💰 [SHOP_CUBIT] Puntos usuario: ${shopData.userStats.availablePoints}');
          debugPrint('🛍️ [SHOP_CUBIT] Mascotas disponibles: ${shopData.availableCompanions.length}');

          // 🔥 OBTENER MASCOTAS DEL USUARIO PARA LÓGICA DE ETAPAS
          _userOwnedCompanions = _extractUserOwnedCompanions(shopData.availableCompanions);
          debugPrint('🏠 [SHOP_CUBIT] Mascotas del usuario: ${_userOwnedCompanions.length}');
          
          // Extraer mapeo dinámico
          _buildDynamicMapping(shopData.availableCompanions);

          // 🔥 APLICAR LÓGICA DE ETAPAS PARA FILTRAR TIENDA
          final purchasableCompanions = _applyStageLogicToShop(
            shopData.availableCompanions, 
            _userOwnedCompanions
          );

          debugPrint('🛒 [SHOP_CUBIT] En tienda (después de lógica etapas): ${purchasableCompanions.length}');
          debugPrint('🗺️ [SHOP_CUBIT] Pet IDs encontrados: ${_localIdToApiPetId.length}');

          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: purchasableCompanions,
            userStats: shopData.userStats,
            availablePetIds: Map.from(_localIdToApiPetId),
            userOwnedCompanions: _userOwnedCompanions, // 🆕
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  // 🔥 LÓGICA DE ETAPAS: Solo mostrar siguiente etapa disponible
  List<CompanionEntity> _applyStageLogicToShop(
    List<CompanionEntity> allCompanions, 
    List<CompanionEntity> userOwnedCompanions
  ) {
    debugPrint('🎯 [STAGE_LOGIC] === APLICANDO LÓGICA DE ETAPAS ===');
    
    final validCompanions = <CompanionEntity>[];
    
    // Agrupar por tipo de companion
    final companionsByType = <CompanionType, List<CompanionEntity>>{};
    for (final companion in allCompanions) {
      if (!companionsByType.containsKey(companion.type)) {
        companionsByType[companion.type] = [];
      }
      companionsByType[companion.type]!.add(companion);
    }
    
    // Para cada tipo, verificar qué etapas puede comprar
    for (final type in CompanionType.values) {
      final companionsOfType = companionsByType[type] ?? [];
      if (companionsOfType.isEmpty) continue;
      
      // Ordenar por etapa (baby -> young -> adult)
      companionsOfType.sort((a, b) => a.stage.index.compareTo(b.stage.index));
      
      debugPrint('🔍 [STAGE_LOGIC] Analizando tipo: ${type.name}');
      
      // Verificar qué tiene el usuario de este tipo
      final userCompanionsOfType = userOwnedCompanions
          .where((c) => c.type == type)
          .toList();
      
      if (userCompanionsOfType.isEmpty) {
        // 🔥 NO TIENE NINGUNA: Solo puede comprar BABY o YOUNG (dependiendo de disponibilidad)
        debugPrint('🆕 [STAGE_LOGIC] ${type.name}: Usuario no tiene ninguna, puede comprar inicial');
        
        // Preferir young si está disponible, sino baby
        final youngStage = companionsOfType.firstWhere(
          (c) => c.stage == CompanionStage.young,
          orElse: () => companionsOfType.firstWhere(
            (c) => c.stage == CompanionStage.baby,
            orElse: () => companionsOfType.first,
          ),
        );
        
        if (!youngStage.isOwned) {
          validCompanions.add(youngStage);
          debugPrint('✅ [STAGE_LOGIC] ${type.name}: Agregando ${youngStage.stage.name} como inicial');
        }
        
      } else {
        // 🔥 YA TIENE ALGUNA: Solo puede comprar SIGUIENTE ETAPA
        final userHighestStage = userCompanionsOfType
            .map((c) => c.stage.index)
            .reduce((a, b) => a > b ? a : b);
        
        final nextStageIndex = userHighestStage + 1;
        
        debugPrint('🔼 [STAGE_LOGIC] ${type.name}: Etapa más alta: ${CompanionStage.values[userHighestStage].name}');
        
        if (nextStageIndex < CompanionStage.values.length) {
          final nextStage = CompanionStage.values[nextStageIndex];
          final nextCompanion = companionsOfType.firstWhere(
            (c) => c.stage == nextStage,
            orElse: () => CompanionEntity(
              id: '', type: type, stage: nextStage, name: '', description: '',
              level: 1, experience: 0, happiness: 100, hunger: 100, energy: 100,
              isOwned: false, isSelected: false, currentMood: CompanionMood.happy,
              purchasePrice: 0, evolutionPrice: 0, unlockedAnimations: [], createdAt: DateTime.now(),
            ),
          );
          
          if (nextCompanion.id.isNotEmpty && !nextCompanion.isOwned) {
            validCompanions.add(nextCompanion);
            debugPrint('✅ [STAGE_LOGIC] ${type.name}: Agregando siguiente etapa: ${nextStage.name}');
          } else {
            debugPrint('⚠️ [STAGE_LOGIC] ${type.name}: No hay siguiente etapa disponible');
          }
        } else {
          debugPrint('🏆 [STAGE_LOGIC] ${type.name}: Ya tiene todas las etapas');
        }
      }
    }
    
    // 🔥 AGREGAR DEXTER JOVEN GRATIS SI NO LO TIENE
    final hasDexterYoung = userOwnedCompanions.any((c) =>
        c.type == CompanionType.dexter && c.stage == CompanionStage.young);

    if (!hasDexterYoung) {
      debugPrint('🎁 [STAGE_LOGIC] Usuario no tiene Dexter joven, agregándolo gratis');
      
      final dexterYoung = allCompanions.firstWhere(
        (c) => c.type == CompanionType.dexter && c.stage == CompanionStage.young,
        orElse: () => _createDexterYoungForStore(),
      );
      
      if (!validCompanions.any((c) => c.id == dexterYoung.id)) {
        validCompanions.insert(0, dexterYoung);
        debugPrint('✅ [STAGE_LOGIC] Dexter joven agregado a la tienda');
      }
    }
    
    // Ordenar por precio
    validCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
    
    debugPrint('🏁 [STAGE_LOGIC] === RESULTADO FINAL ===');
    debugPrint('🛒 [STAGE_LOGIC] Companions válidos para comprar: ${validCompanions.length}');
    
    for (final companion in validCompanions) {
      debugPrint('🏪 [STAGE_LOGIC] - ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★');
    }
    
    return validCompanions;
  }

  // 🔥 ADOPCIÓN CON VALIDACIONES MEJORADAS
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO ADOPCIÓN CON VALIDACIONES ===');
    debugPrint('🐾 [SHOP_CUBIT] Companion: ${companion.displayName} ${companion.stage.name}');
    debugPrint('💰 [SHOP_CUBIT] Precio: ${companion.purchasePrice}★');

    if (state is! CompanionShopLoaded) {
      debugPrint('❌ [SHOP_CUBIT] Estado incorrecto para adopción');
      emit(CompanionShopError(message: 'Error: Estado de tienda no válido'));
      return;
    }

    final currentState = state as CompanionShopLoaded;

    // 🔥 VALIDACIÓN 1: Verificar puntos suficientes
    if (currentState.userStats.availablePoints < companion.purchasePrice) {
      final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
      debugPrint('❌ [SHOP_CUBIT] Puntos insuficientes: faltan $faltantes');
      emit(CompanionShopError(
        message: 'No tienes suficientes puntos. Necesitas $faltantes puntos más para adoptar a ${companion.displayName}.',
      ));
      return;
    }

    // 🔥 VALIDACIÓN 2: Verificar lógica de etapas
    final stageValidation = _validateStageLogic(companion, currentState.userOwnedCompanions);
    if (!stageValidation.isValid) {
      debugPrint('❌ [SHOP_CUBIT] Error de etapa: ${stageValidation.message}');
      emit(CompanionShopError(message: stageValidation.message));
      return;
    }

    // 🔥 VALIDACIÓN 3: Verificar que no esté ya adoptado
    final alreadyOwned = currentState.userOwnedCompanions.any((c) => 
        c.type == companion.type && c.stage == companion.stage);
    
    if (alreadyOwned) {
      debugPrint('❌ [SHOP_CUBIT] Ya adoptado: ${companion.displayName} ${companion.stage.name}');
      emit(CompanionShopError(
        message: 'Ya tienes a ${companion.displayName} en etapa ${companion.stage.name}.',
      ));
      return;
    }

    debugPrint('⏳ [SHOP_CUBIT] Todas las validaciones pasadas, enviando adopción...');
    emit(CompanionShopPurchasing(companion: companion));

    try {
      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ [SHOP_CUBIT] Sin usuario autenticado');
        emit(CompanionShopError(
            message: 'Debes estar autenticado para adoptar mascotas'));
        return;
      }

      debugPrint('👤 [SHOP_CUBIT] Usuario autenticado: $userId');

      // Obtener Pet ID dinámicamente
      final apiPetId = currentState.availablePetIds[companion.id];
      debugPrint('🗺️ [SHOP_CUBIT] Pet ID para ${companion.id}: $apiPetId');

      if (apiPetId == null || apiPetId.isEmpty) {
        debugPrint('❌ [SHOP_CUBIT] No se encontró Pet ID para: ${companion.id}');
        emit(CompanionShopError(
            message: 'Error: No se pudo obtener información de ${companion.displayName} desde la API'));
        return;
      }

      // 🚀 LLAMADA A LA API CON PET ID REAL
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: apiPetId,
          nickname: companion.displayName,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error en adopción API: ${failure.message}');

          // 🔥 MANEJO MEJORADO DE ERRORES ESPECÍFICOS
          String userMessage = _parseApiError(failure.message, companion);
          emit(CompanionShopError(message: userMessage));
        },
        (adoptedCompanion) {
          debugPrint('🎉 [SHOP_CUBIT] === ADOPCIÓN EXITOSA ===');
          debugPrint('✅ [SHOP_CUBIT] Mascota adoptada: ${adoptedCompanion.displayName}');

          // 🔥 MENSAJE PERSONALIZADO CON NOMBRE REAL DE LA MASCOTA
          final personalizedMessage = _createSuccessMessage(companion, adoptedCompanion);
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: personalizedMessage,
          ));

          debugPrint('🔄 [SHOP_CUBIT] Recargando tienda...');
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Excepción durante adopción: $e');
      emit(CompanionShopError(
          message: 'Error inesperado adoptando a ${companion.displayName}: ${e.toString()}'));
    }
  }

  // 🔥 VALIDACIÓN DE LÓGICA DE ETAPAS
  StageValidationResult _validateStageLogic(
    CompanionEntity companion, 
    List<CompanionEntity> userOwnedCompanions
  ) {
    debugPrint('🎯 [STAGE_VALIDATION] Validando etapa para: ${companion.displayName} ${companion.stage.name}');
    
    final userCompanionsOfType = userOwnedCompanions
        .where((c) => c.type == companion.type)
        .toList();
    
    // Si es Dexter joven, siempre permitir (es gratis inicial)
    if (companion.type == CompanionType.dexter && 
        companion.stage == CompanionStage.young &&
        companion.purchasePrice == 0) {
      return StageValidationResult(true, '');
    }
    
    if (userCompanionsOfType.isEmpty) {
      // No tiene ninguna de este tipo
      if (companion.stage == CompanionStage.adult) {
        return StageValidationResult(
          false, 
          'No puedes adoptar directamente a ${companion.displayName} adulto. Primero debes tener la etapa anterior.'
        );
      }
      return StageValidationResult(true, '');
    }
    
    // Ya tiene alguna de este tipo
    final userHighestStage = userCompanionsOfType
        .map((c) => c.stage.index)
        .reduce((a, b) => a > b ? a : b);
    
    final expectedNextStage = userHighestStage + 1;
    
    if (companion.stage.index != expectedNextStage) {
      final currentStageName = CompanionStage.values[userHighestStage].name;
      final expectedStageName = expectedNextStage < CompanionStage.values.length 
          ? CompanionStage.values[expectedNextStage].name 
          : 'máxima';
      
      if (companion.stage.index < expectedNextStage) {
        return StageValidationResult(
          false,
          'Ya tienes a ${companion.displayName} en una etapa superior a ${companion.stage.name}.'
        );
      } else {
        return StageValidationResult(
          false,
          'Para adoptar a ${companion.displayName} ${companion.stage.name}, primero debes tener la etapa $expectedStageName.'
        );
      }
    }
    
    return StageValidationResult(true, '');
  }

  // 🔥 PARSEAR ERRORES DE API CON MENSAJES ESPECÍFICOS
  String _parseApiError(String apiErrorMessage, CompanionEntity companion) {
    final errorLower = apiErrorMessage.toLowerCase();
    
    if (errorLower.contains('already') ||
        errorLower.contains('adoptada') ||
        errorLower.contains('ya tienes') ||
        errorLower.contains('duplicate')) {
      return 'Ya has adoptado a ${companion.displayName} anteriormente';
    } else if (errorLower.contains('insufficient') ||
               errorLower.contains('puntos') ||
               errorLower.contains('not enough')) {
      return 'No tienes suficientes puntos para adoptar a ${companion.displayName}';
    } else if (errorLower.contains('not found') ||
               errorLower.contains('encontrada') ||
               errorLower.contains('no existe')) {
      return '${companion.displayName} no está disponible en este momento';
    } else if (errorLower.contains('stage') ||
               errorLower.contains('etapa') ||
               errorLower.contains('evolution')) {
      return 'Debes tener la etapa anterior de ${companion.displayName} antes de adoptar esta';
    } else if (errorLower.contains('authentication') ||
               errorLower.contains('unauthorized') ||
               errorLower.contains('401')) {
      return 'Error de autenticación. Por favor, reinicia sesión';
    } else {
      return 'Error adoptando a ${companion.displayName}. Intenta de nuevo';
    }
  }

  // 🔥 CREAR MENSAJE DE ÉXITO PERSONALIZADO
  String _createSuccessMessage(CompanionEntity requestedCompanion, CompanionEntity adoptedCompanion) {
    // Usar el nombre real de la mascota adoptada, no el genérico
    final realName = adoptedCompanion.displayName.isNotEmpty 
        ? adoptedCompanion.displayName 
        : requestedCompanion.displayName;
    
    final stageName = requestedCompanion.stage.name;
    final typeDescription = requestedCompanion.typeDescription;
    
    if (requestedCompanion.purchasePrice == 0) {
      return '¡Felicidades! ${realName} se ha unido a tu equipo como tu primer compañero 🎉';
    } else {
      return '¡Felicidades! Has adoptado a ${realName} ${stageName} (${typeDescription}) 🎉';
    }
  }

  // Extraer mascotas del usuario desde shopData
  List<CompanionEntity> _extractUserOwnedCompanions(List<CompanionEntity> allCompanions) {
    return allCompanions.where((c) => c.isOwned).toList();
  }

  // Construir mapeo dinámico (sin cambios del archivo anterior)
  void _buildDynamicMapping(List<CompanionEntity> companions) {
    debugPrint('🗺️ [MAPPING] === CONSTRUYENDO MAPEO DINÁMICO ===');

    _localIdToApiPetId.clear();
    _apiPetIdToInfo.clear();

    for (final companion in companions) {
      final apiPetId = _extractApiPetIdFromCompanion(companion);

      if (apiPetId != null && apiPetId.isNotEmpty) {
        final localId = companion.id;
        _localIdToApiPetId[localId] = apiPetId;
        _apiPetIdToInfo[apiPetId] = {
          'name': companion.name,
          'type': companion.type.name,
          'description': companion.description,
          'stage': companion.stage.name,
        };
        debugPrint('🗺️ [MAPPING] $localId -> $apiPetId (${companion.name})');
      } else {
        debugPrint('⚠️ [MAPPING] No se pudo extraer Pet ID para: ${companion.id}');
      }
    }

    debugPrint('✅ [MAPPING] Mapeo dinámico completado: ${_localIdToApiPetId.length} entries');
  }

  String? _extractApiPetIdFromCompanion(CompanionEntity companion) {
    if (companion is CompanionModelWithPetId) {
      return companion.petId;
    }

    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          return json['petId'] as String;
        }
      } catch (e) {
        debugPrint('⚠️ [MAPPING] Error accediendo JSON: $e');
      }
    }

    if (companion.id.length > 20 && companion.id.contains('-')) {
      return companion.id;
    }

    return null;
  }

  CompanionEntity _createDexterYoungForStore() {
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
      purchasePrice: 0,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

  Future<void> _reloadShopAfterPurchase() async {
    try {
      debugPrint('🔄 Recargando después de adopción...');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (isClosed) return;
      await loadShop();
      debugPrint('✅ Recarga completada');
    } catch (e) {
      debugPrint('❌ Error durante recarga: $e');
    }
  }

  void refreshShop() {
    debugPrint('🔄 [SHOP_CUBIT] Refresh manual solicitado');
    loadShop();
  }

  // Métodos de utilidad
  List<CompanionEntity> getCompanionsByType(CompanionType type) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.type == type)
          .toList();
    }
    return [];
  }

  bool canAffordCompanion(CompanionEntity companion) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.userStats.availablePoints >= companion.purchasePrice;
    }
    return false;
  }

  String getCompanionMessage(CompanionEntity companion) {
    if (state is! CompanionShopLoaded) return 'Cargando...';
    
    final currentState = state as CompanionShopLoaded;
    
    // Verificar lógica de etapas
    final stageValidation = _validateStageLogic(companion, currentState.userOwnedCompanions);
    if (!stageValidation.isValid) {
      return stageValidation.message;
    }
    
    if (companion.isOwned) {
      return 'Ya lo tienes';
    }

    if (currentState.userStats.availablePoints >= companion.purchasePrice) {
      return 'Disponible para adoptar';
    } else {
      final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
      return 'Necesitas $faltantes puntos más';
    }
  }
}

// 🔧 CLASE HELPER PARA VALIDACIÓN DE ETAPAS
class StageValidationResult {
  final bool isValid;
  final String message;
  
  StageValidationResult(this.isValid, this.message);
}