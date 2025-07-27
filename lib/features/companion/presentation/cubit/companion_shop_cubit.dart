// lib/features/companion/presentation/cubit/companion_shop_cubit.dart
// 🔥 CORREGIDO: Sin Dexter gratis + Lógica de progresión correcta

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import 'package:xuma_a/features/companion/data/datasources/companion_remote_datasource.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// States (sin cambios)
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
  final List<CompanionEntity> userOwnedCompanions;

  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
    required this.availablePetIds,
    required this.userOwnedCompanions,
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

@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  final TokenManager tokenManager;

  Map<String, String> _localIdToApiPetId = {};
  List<CompanionEntity> _userOwnedCompanions = [];

  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
    required this.tokenManager,
  }) : super(CompanionShopInitial());

  Future<void> loadShop() async {
    try {
      debugPrint('🏦 [SHOP_CUBIT] === CARGANDO TIENDA CORREGIDA ===');
      emit(CompanionShopLoading());

      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        emit(CompanionShopError(message: '🔐 Usuario no autenticado'));
        return;
      }

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
          
          // 🔥 OBTENER MASCOTAS DEL USUARIO (desde availableCompanions donde isOwned = true)
          _userOwnedCompanions = shopData.availableCompanions.where((c) => c.isOwned).toList();
          
          debugPrint('👤 [SHOP_DEBUG] User owned companions: ${_userOwnedCompanions.length}');
          
          final shopCompanions = _buildProgressiveShop(shopData.availableCompanions, _userOwnedCompanions);
          
          // 🔥 CONSTRUIR MAPEO DINÁMICO
          _buildDynamicMapping(shopData.availableCompanions);

          debugPrint('🛍️ [PROGRESSIVE_SHOP] Total items: ${shopCompanions.length}');

          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: shopCompanions,
            userStats: shopData.userStats,
            availablePetIds: Map.from(_localIdToApiPetId),
            userOwnedCompanions: _userOwnedCompanions,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  // 🔥 NUEVA LÓGICA: TIENDA CON PROGRESIÓN CORRECTA
  List<CompanionEntity> _buildProgressiveShop(List<CompanionEntity> availableCompanions, List<CompanionEntity> userOwnedCompanions) {
    debugPrint('🏗️ [PROGRESSIVE_SHOP] === CONSTRUYENDO TIENDA CON TODAS LAS ETAPAS ===');
    
    final shopCompanions = <CompanionEntity>[];
    
    // 🔥 PARA CADA TIPO, MOSTRAR TODAS LAS ETAPAS
    for (final type in [CompanionType.dexter, CompanionType.elly, CompanionType.paxolotl, CompanionType.yami]) {
      // Obtener etapas que el usuario ya tiene de este tipo
      final userStagesOfType = userOwnedCompanions
          .where((c) => c.type == type)
          .map((c) => c.stage)
          .toSet();
      
      debugPrint('🔍 [PROGRESSIVE_SHOP] ${type.name}: Etapas que tiene: $userStagesOfType');
      
      // Agregar todas las etapas (baby, young, adult)
      for (final stage in [CompanionStage.baby, CompanionStage.young, CompanionStage.adult]) {
        final hasThisStage = userStagesOfType.contains(stage);
        final canBuyThisStage = _canBuyStageProgressive(stage, userStagesOfType);
        
        if (!hasThisStage) {  // Solo mostrar si NO la tiene
          // 🔥 CREAR COMPANION CON DESCRIPCIÓN CORRECTA DESDE EL INICIO
          final description = canBuyThisStage 
            ? '🔓 ${_getNameForType(type)} ${stage.name} - Disponible'
            : '🔒 ${_getNameForType(type)} ${stage.name} - Requiere etapa anterior';
            
          final companion = _createCompanionForShopWithDescription(type, stage, description);
          
          shopCompanions.add(companion);
          
          debugPrint('${canBuyThisStage ? "🔓" : "🔒"} ${type.name}_${stage.name}: ${companion.purchasePrice}★');
        }
      }
    }

    // 🔥 ORDENAR: Primero las disponibles, luego por precio
    shopCompanions.sort((a, b) {
      final aCanBuy = _canBuyCompanionProgressive(a, userOwnedCompanions);
      final bCanBuy = _canBuyCompanionProgressive(b, userOwnedCompanions);
      
      if (aCanBuy && !bCanBuy) return -1;
      if (!aCanBuy && bCanBuy) return 1;
      return a.purchasePrice.compareTo(b.purchasePrice);
    });

    debugPrint('🏪 [PROGRESSIVE_SHOP] === TIENDA FINAL CON PROGRESIÓN ===');
    debugPrint('🛒 [PROGRESSIVE_SHOP] Total items: ${shopCompanions.length}');
    
    return shopCompanions;
  }

  CompanionEntity _createCompanionForShop(CompanionType type, CompanionStage stage) {
  final prices = _getPricesForType(type);
  
  return CompanionModel(
    id: '${type.name}_${stage.name}',
    type: type,
    stage: stage,
    name: _getNameForType(type),
    description: '🔓 ${_getNameForType(type)} ${stage.name} - Disponible para adopción',
    level: 1,
    experience: 0,
    happiness: 100,
    hunger: 100,
    energy: 100,
    isOwned: false, // ✅ SIEMPRE FALSE EN TIENDA
    isSelected: false,
    purchasedAt: null,
    currentMood: CompanionMood.happy,
    purchasePrice: prices[stage]!,
    evolutionPrice: 50,
    unlockedAnimations: ['idle', 'blink', 'happy'],
    createdAt: DateTime.now(),
  );
}

  // 🔥 CREAR COMPANION PARA TIENDA CON DESCRIPCIÓN PERSONALIZADA
  CompanionEntity _createCompanionForShopWithDescription(CompanionType type, CompanionStage stage, String description) {
    final prices = _getPricesForType(type);
    
    return CompanionModel(
      id: '${type.name}_${stage.name}',
      type: type,
      stage: stage,
      name: _getNameForType(type),
      description: description, // 🔥 USAR DESCRIPCIÓN PERSONALIZADA
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false, // ✅ SIEMPRE FALSE EN TIENDA
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: prices[stage]!,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

// 🔥 SIMPLIFICAR VALIDACIONES DE COMPRA
Future<void> purchaseCompanion(CompanionEntity companion) async {
  debugPrint('🛒 [SHOP_CUBIT] === ADOPCIÓN CON VALIDACIÓN PROGRESIVA ===');

  if (state is! CompanionShopLoaded) {
    emit(CompanionShopError(message: '❌ Error: Estado de tienda no válido'));
    return;
  }

  final currentState = state as CompanionShopLoaded;

  // 🔥 VALIDACIÓN PROGRESIVA
  if (!_canBuyCompanionProgressive(companion, currentState.userOwnedCompanions)) {
    emit(CompanionShopError(
      message: '🔒 Debes tener la etapa anterior de ${companion.displayName} primero',
    ));
    return;
  }

  // 🔥 VALIDACIÓN DE PUNTOS
  if (currentState.userStats.availablePoints < companion.purchasePrice) {
    final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
    emit(CompanionShopError(
      message: '💰 No tienes suficientes puntos. Necesitas $faltantes puntos más.',
    ));
    return;
  }

  emit(CompanionShopPurchasing(companion: companion));

  try {
    final userId = await tokenManager.getUserId();
    if (userId == null || userId.isEmpty) {
      emit(CompanionShopError(message: '🔐 Usuario no autenticado'));
      return;
    }

    // 🔥 USAR ID CORRECTO PARA LA API
    final apiPetId = currentState.availablePetIds[companion.id] ?? 
                   '${companion.type.name}_${_getStageNumber(companion.stage)}';

    debugPrint('🗺️ [SHOP_CUBIT] Pet ID para adopción: $apiPetId');

    final result = await purchaseCompanionUseCase(
      PurchaseCompanionParams(
        userId: userId,
        companionId: apiPetId,
        nickname: companion.displayName,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ [SHOP_CUBIT] Error en adopción: ${failure.message}');
        emit(CompanionShopError(message: failure.message));
      },
      (adoptedCompanion) {
        debugPrint('🎉 [SHOP_CUBIT] === ADOPCIÓN EXITOSA ===');
        
        // 🔥 ACTUALIZACIÓN INMEDIATA: Agregar a lista de user-owned companions
        debugPrint('🔄 [SHOP_CUBIT] Actualizando lista de user-owned companions...');
        if (!_userOwnedCompanions.any((c) => c.id == adoptedCompanion.id)) {
          _userOwnedCompanions.add(adoptedCompanion);
          debugPrint('✅ [SHOP_CUBIT] Agregado ${adoptedCompanion.displayName} a user-owned (total: ${_userOwnedCompanions.length})');
        } else {
          debugPrint('⚠️ [SHOP_CUBIT] ${adoptedCompanion.displayName} ya estaba en user-owned');
        }
        
        final message = '🎉 ¡Has adoptado a ${adoptedCompanion.displayName}! Ahora puedes evolucionarlo.';
        
        emit(CompanionShopPurchaseSuccess(
          purchasedCompanion: adoptedCompanion,
          message: message,
        ));

        _reloadShopAfterPurchase();
      },
    );
  } catch (e) {
    debugPrint('❌ [SHOP_CUBIT] Error: $e');
    emit(CompanionShopError(message: '❌ Error adoptando: ${e.toString()}'));
  }
}

  // 🔥 LÓGICA PROGRESIVA: Solo puede comprar la siguiente etapa
  bool _canBuyStageProgressive(CompanionStage targetStage, Set<CompanionStage> userStages) {
    switch (targetStage) {
      case CompanionStage.baby:
        // Puede comprar baby si no tiene ninguna etapa
        return userStages.isEmpty;
      
      case CompanionStage.young:
        // Puede comprar young si tiene baby pero no young
        return userStages.contains(CompanionStage.baby) && 
               !userStages.contains(CompanionStage.young);
      
      case CompanionStage.adult:
        // Puede comprar adult si tiene young pero no adult
        return userStages.contains(CompanionStage.young) && 
               !userStages.contains(CompanionStage.adult);
    }
  }

  // 🔥 VERIFICAR SI PUEDE COMPRAR CON LÓGICA PROGRESIVA
  bool _canBuyCompanionProgressive(CompanionEntity companion, List<CompanionEntity> userOwnedCompanions) {
    debugPrint('🔍 [PROGRESSIVE_VALIDATION] === VALIDANDO COMPRA PROGRESIVA ===');
    debugPrint('🐾 [PROGRESSIVE_VALIDATION] Companion a comprar: ${companion.displayName} ${companion.stage.name}');
    debugPrint('👤 [PROGRESSIVE_VALIDATION] Total user owned companions: ${userOwnedCompanions.length}');
    
    // Debug: Mostrar todas las mascotas que tiene el usuario
    for (int i = 0; i < userOwnedCompanions.length; i++) {
      final owned = userOwnedCompanions[i];
      debugPrint('  [$i] ${owned.displayName} ${owned.stage.name} (${owned.type.name}) - isOwned: ${owned.isOwned}');
    }
    
    // Si ya lo tiene, no puede comprarlo
    if (companion.isOwned) {
      debugPrint('❌ [PROGRESSIVE_VALIDATION] Ya posee esta mascota');
      return false;
    }
    
    // Obtener etapas que tiene de este tipo
    final userStagesOfType = userOwnedCompanions
        .where((c) => c.type == companion.type)
        .map((c) => c.stage)
        .toSet();
    
    debugPrint('🔍 [PROGRESSIVE_VALIDATION] Etapas de ${companion.type.name} que posee: $userStagesOfType');
    
    final canBuy = _canBuyStageProgressive(companion.stage, userStagesOfType);
    debugPrint('${canBuy ? "✅" : "❌"} [PROGRESSIVE_VALIDATION] Puede comprar ${companion.stage.name}: $canBuy');
    
    return canBuy;
  }

  // 🔥 OBTENER ESTADO PROGRESIVO DEL COMPANION
  String _getCompanionStatusProgressive(CompanionEntity companion, List<CompanionEntity> userOwnedCompanions) {
    if (companion.isOwned) {
      return 'YA TIENES';
    }
    
    if (_canBuyCompanionProgressive(companion, userOwnedCompanions)) {
      return 'DISPONIBLE';
    } else {
      // Determinar qué necesita
      final userStagesOfType = userOwnedCompanions
          .where((c) => c.type == companion.type)
          .map((c) => c.stage)
          .toSet();
          
      switch (companion.stage) {
        case CompanionStage.baby:
          return 'PRIMERA ETAPA';
        case CompanionStage.young:
          if (userStagesOfType.isEmpty) {
            return 'NECESITAS BABY PRIMERO';
          } else {
            return 'DISPONIBLE';
          }
        case CompanionStage.adult:
          if (!userStagesOfType.contains(CompanionStage.young)) {
            return 'NECESITAS YOUNG PRIMERO';
          } else {
            return 'DISPONIBLE';
          }
      }
    }
  }

  String _getCompanionStatusIcon(CompanionEntity companion, List<CompanionEntity> userOwnedCompanions) {
    if (companion.isOwned) return '✅';
    if (_canBuyCompanionProgressive(companion, userOwnedCompanions)) return '🔓';
    return '🔒';
  }

  // 🔥 DESCRIPCIÓN PROGRESIVA
  String _getDescriptionProgressive(CompanionType type, CompanionStage stage, bool hasStage, bool canBuy) {
    final name = _getNameForType(type);
    final stageName = stage.name;
    
    if (hasStage) {
      return '✅ Ya tienes $name $stageName';
    } else if (canBuy) {
      switch (stage) {
        case CompanionStage.baby:
          return '🔓 $name $stageName - Primera etapa disponible';
        case CompanionStage.young:
          return '🔓 $name $stageName - Siguiente etapa disponible';
        case CompanionStage.adult:
          return '🔓 $name $stageName - Etapa final disponible';
      }
    } else {
      switch (stage) {
        case CompanionStage.baby:
          return '$name $stageName - Primera etapa';
        case CompanionStage.young:
          return '🔒 $name $stageName - Necesitas baby primero';
        case CompanionStage.adult:
          return '🔒 $name $stageName - Necesitas young primero';
      }
    }
  }

 

  String _getRequirementMessageProgressive(CompanionEntity companion, List<CompanionEntity> userOwnedCompanions) {
    final userStagesOfType = userOwnedCompanions
        .where((c) => c.type == companion.type)
        .map((c) => c.stage)
        .toSet();

    switch (companion.stage) {
      case CompanionStage.baby:
        return '🔓 Puedes adoptar a ${companion.displayName} baby como primera etapa';
      case CompanionStage.young:
        if (userStagesOfType.isEmpty) {
          return '🔒 Necesitas adoptar ${companion.displayName} baby primero';
        }
        return '🔓 Puedes adoptar a ${companion.displayName} young (siguiente etapa)';
      case CompanionStage.adult:
        if (!userStagesOfType.contains(CompanionStage.young)) {
          return '🔒 Necesitas adoptar ${companion.displayName} young primero';
        }
        return '🔓 Puedes adoptar a ${companion.displayName} adult (etapa final)';
    }
  }

  // 🔧 MÉTODOS HELPER ACTUALIZADOS
  Map<CompanionStage, int> _getPricesForType(CompanionType type) {
    final basePrices = {
      CompanionType.dexter: {
        CompanionStage.baby: 100,    // 🔥 DEXTER YA NO ES GRATIS
        CompanionStage.young: 200,
        CompanionStage.adult: 300,
      },
      CompanionType.elly: {
        CompanionStage.baby: 200,
        CompanionStage.young: 350,
        CompanionStage.adult: 500,
      },
      CompanionType.paxolotl: {
        CompanionStage.baby: 600,
        CompanionStage.young: 800,
        CompanionStage.adult: 1000,
      },
      CompanionType.yami: {
        CompanionStage.baby: 2500,
        CompanionStage.young: 3000,
        CompanionStage.adult: 3500,
      },
    };
    
    return basePrices[type]!;
  }

  String _getNameForType(CompanionType type) {
    switch (type) {
      case CompanionType.dexter: return 'Dexter';
      case CompanionType.elly: return 'Elly';
      case CompanionType.paxolotl: return 'Paxolotl';
      case CompanionType.yami: return 'Yami';
    }
  }

  // Métodos helper existentes (sin cambios importantes)
  List<CompanionEntity> _extractUserOwnedCompanions(List<CompanionEntity> allCompanions) {
    return allCompanions.where((c) => c.isOwned).toList();
  }

  void _buildDynamicMapping(List<CompanionEntity> companions) {
    _localIdToApiPetId.clear();
    for (final companion in companions) {
      final apiPetId = _extractApiPetIdFromCompanion(companion);
      if (apiPetId != null && apiPetId.isNotEmpty) {
        _localIdToApiPetId[companion.id] = apiPetId;
      }
    }
  }

  String? _extractApiPetIdFromCompanion(CompanionEntity companion) {
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

  Future<void> _reloadShopAfterPurchase() async {
    debugPrint('🔄 [SHOP_RELOAD] === INICIANDO RECARGA DESPUÉS DE COMPRA ===');
    debugPrint('⏰ [SHOP_RELOAD] Esperando 1.5 segundos para que API se actualice...');
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (isClosed) {
      debugPrint('❌ [SHOP_RELOAD] Cubit cerrado, cancelando recarga');
      return;
    }
    
    debugPrint('🔄 [SHOP_RELOAD] Recargando tienda...');
    await loadShop();
    debugPrint('✅ [SHOP_RELOAD] Recarga completada');
  }

  void refreshShop() {
    loadShop();
  }

// 🔥 MÉTODO HELPER PARA OBTENER NÚMERO DE ETAPA
int _getStageNumber(CompanionStage stage) {
  switch (stage) {
    case CompanionStage.baby:
      return 1;
    case CompanionStage.young:
      return 2;
    case CompanionStage.adult:
      return 3;
  }
}
}