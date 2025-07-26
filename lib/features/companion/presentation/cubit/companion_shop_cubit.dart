// lib/features/companion/presentation/cubit/companion_shop_cubit.dart
// 🔥 CORREGIDO: Sin Dexter gratis + Lógica de progresión correcta

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
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
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA CORREGIDA ===');
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
          
          // 🔥 OBTENER MASCOTAS DEL USUARIO
          _userOwnedCompanions = _extractUserOwnedCompanions(shopData.availableCompanions);
          debugPrint('🏠 [SHOP_CUBIT] Mascotas del usuario: ${_userOwnedCompanions.length}');
          
          // 🔥 CONSTRUIR MAPEO DINÁMICO
          _buildDynamicMapping(shopData.availableCompanions);

          // 🔥 NUEVA LÓGICA: MOSTRAR TODAS LAS ETAPAS CON ESTADOS CORRECTOS
          final completePurchasableCompanions = _buildProgressiveShop(_userOwnedCompanions);

          debugPrint('🛒 [SHOP_CUBIT] Tienda completa: ${completePurchasableCompanions.length} items');

          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: completePurchasableCompanions,
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
  List<CompanionEntity> _buildProgressiveShop(List<CompanionEntity> userOwnedCompanions) {
    debugPrint('🏗️ [PROGRESSIVE_SHOP] === CONSTRUYENDO TIENDA CON PROGRESIÓN ===');
    
    final shopCompanions = <CompanionEntity>[];
    
    // 🔥 PARA CADA TIPO, MOSTRAR SOLO LA SIGUIENTE ETAPA DISPONIBLE
    for (final type in [CompanionType.dexter, CompanionType.elly, CompanionType.paxolotl, CompanionType.yami]) {
      // Obtener qué etapas tiene el usuario de este tipo
      final userStagesOfType = userOwnedCompanions
          .where((c) => c.type == type)
          .map((c) => c.stage)
          .toSet();
      
      debugPrint('🔍 [PROGRESSIVE_SHOP] ${type.name}: Usuario tiene etapas: $userStagesOfType');
      
      // 🔥 DETERMINAR QUÉ MOSTRAR PARA ESTE TIPO
      if (userStagesOfType.isEmpty) {
        // NO TIENE NADA: Mostrar solo BABY para comprar
        debugPrint('📦 [PROGRESSIVE_SHOP] ${type.name}: Mostrar BABY (primera compra)');
        shopCompanions.add(_createCompanionForShop(type, CompanionStage.baby, userStagesOfType));
        
      } else if (userStagesOfType.contains(CompanionStage.baby) && !userStagesOfType.contains(CompanionStage.young)) {
        // TIENE BABY: Mostrar YOUNG para comprar
        debugPrint('🔄 [PROGRESSIVE_SHOP] ${type.name}: Mostrar YOUNG (siguiente compra)');
        shopCompanions.add(_createCompanionForShop(type, CompanionStage.young, userStagesOfType));
        
      } else if (userStagesOfType.contains(CompanionStage.young) && !userStagesOfType.contains(CompanionStage.adult)) {
        // TIENE YOUNG: Mostrar ADULT para comprar
        debugPrint('👑 [PROGRESSIVE_SHOP] ${type.name}: Mostrar ADULT (compra final)');
        shopCompanions.add(_createCompanionForShop(type, CompanionStage.adult, userStagesOfType));
        
      } else if (userStagesOfType.contains(CompanionStage.adult)) {
        // TIENE ADULT: No mostrar nada (colección completa para este tipo)
        debugPrint('✅ [PROGRESSIVE_SHOP] ${type.name}: Colección completa, no mostrar');
        
      } else {
        // CASO EXTRAÑO: Mostrar baby por defecto
        debugPrint('⚠️ [PROGRESSIVE_SHOP] ${type.name}: Caso extraño, mostrar baby');
        shopCompanions.add(_createCompanionForShop(type, CompanionStage.baby, userStagesOfType));
      }
    }

    // 🔥 ORDENAR: Primero por disponibilidad, luego por tipo
    shopCompanions.sort((a, b) {
      // Primero por disponibilidad para comprar
      final aCanBuy = _canBuyCompanionProgressive(a, userOwnedCompanions);
      final bCanBuy = _canBuyCompanionProgressive(b, userOwnedCompanions);
      
      if (aCanBuy != bCanBuy) {
        return aCanBuy ? -1 : 1; // Disponibles primero
      }
      
      // Luego por tipo (dexter, elly, paxolotl, yami)
      return a.type.index.compareTo(b.type.index);
    });

    debugPrint('🏪 [PROGRESSIVE_SHOP] === TIENDA FINAL PROGRESIVA ===');
    debugPrint('🛒 [PROGRESSIVE_SHOP] Total items: ${shopCompanions.length}');
    
    for (final companion in shopCompanions) {
      final status = _getCompanionStatusProgressive(companion, userOwnedCompanions);
      final icon = _getCompanionStatusIcon(companion, userOwnedCompanions);
      debugPrint('$icon ${companion.displayName} ${companion.stage.name}: $status');
    }

    return shopCompanions;
  }

  // 🔥 CREAR COMPANION PARA TIENDA CON ESTADO PROGRESIVO
  CompanionEntity _createCompanionForShop(
    CompanionType type, 
    CompanionStage stage, 
    Set<CompanionStage> userStages
  ) {
    final prices = _getPricesForType(type);
    final hasThisStage = userStages.contains(stage);
    final canBuy = _canBuyStageProgressive(stage, userStages);
    
    return CompanionModel(
      id: '${type.name}_${stage.name}',
      type: type,
      stage: stage,
      name: _getNameForType(type),
      description: _getDescriptionProgressive(type, stage, hasThisStage, canBuy),
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: hasThisStage, // 🔥 MARCAR SI YA LO TIENE
      isSelected: false,
      purchasedAt: hasThisStage ? DateTime.now() : null,
      currentMood: CompanionMood.happy,
      purchasePrice: prices[stage]!,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
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
    // Si ya lo tiene, no puede comprarlo
    if (companion.isOwned) return false;
    
    // Obtener etapas que tiene de este tipo
    final userStagesOfType = userOwnedCompanions
        .where((c) => c.type == companion.type)
        .map((c) => c.stage)
        .toSet();
    
    return _canBuyStageProgressive(companion.stage, userStagesOfType);
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

  // 🔥 ADOPCIÓN CON VALIDACIONES PROGRESIVAS
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO ADOPCIÓN PROGRESIVA ===');
    debugPrint('🐾 [SHOP_CUBIT] Companion: ${companion.displayName} ${companion.stage.name}');
    debugPrint('💰 [SHOP_CUBIT] Precio: ${companion.purchasePrice}★');

    if (state is! CompanionShopLoaded) {
      emit(CompanionShopError(message: '❌ Error: Estado de tienda no válido'));
      return;
    }

    final currentState = state as CompanionShopLoaded;

    // 🔥 VALIDACIÓN: Ya lo tiene
    if (companion.isOwned) {
      emit(CompanionShopError(
        message: '✅ Ya tienes a ${companion.displayName} ${companion.stage.name}.',
      ));
      return;
    }

    // 🔥 VALIDACIÓN: Puede comprarlo (progresión correcta)
    if (!_canBuyCompanionProgressive(companion, currentState.userOwnedCompanions)) {
      final requirement = _getRequirementMessageProgressive(companion, currentState.userOwnedCompanions);
      emit(CompanionShopError(message: requirement));
      return;
    }

    // 🔥 VALIDACIÓN: Puntos suficientes
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

      // 🔥 OBTENER PET ID
      final apiPetId = currentState.availablePetIds[companion.id] ?? 
                     '${companion.type.name}_${companion.stage.index + 1}';

      debugPrint('🗺️ [SHOP_CUBIT] Pet ID para API: $apiPetId');

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
          
          final message = '🎉 ¡Has adoptado a ${adoptedCompanion.displayName} ${companion.stage.name}!';
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: message,
          ));

          // Recargar tienda
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error: $e');
      emit(CompanionShopError(message: '❌ Error adoptando: ${e.toString()}'));
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
    await Future.delayed(const Duration(milliseconds: 1500));
    if (isClosed) return;
    await loadShop();
  }

  void refreshShop() {
    loadShop();
  }
}