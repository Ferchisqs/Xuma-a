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
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA COMPLETA ===');
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

          // 🔥 NUEVA LÓGICA: MOSTRAR TODAS LAS ETAPAS CON ESTADOS
          final completePurchasableCompanions = _buildCompleteShop(_userOwnedCompanions);

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

  // 🔥 NUEVA LÓGICA: MOSTRAR TODAS LAS ETAPAS (DESBLOQUEADAS Y BLOQUEADAS)
  List<CompanionEntity> _buildCompleteShop(List<CompanionEntity> userOwnedCompanions) {
    debugPrint('🏗️ [COMPLETE_SHOP] === CONSTRUYENDO TIENDA COMPLETA ===');
    
    final shopCompanions = <CompanionEntity>[];
    
    // 🎁 1. DEXTER JOVEN GRATIS - SIEMPRE DISPONIBLE SI NO LO TIENE
    final hasDexterYoung = userOwnedCompanions.any((c) =>
        c.type == CompanionType.dexter && c.stage == CompanionStage.young);

    if (!hasDexterYoung) {
      debugPrint('🎁 [COMPLETE_SHOP] Agregando Dexter joven GRATIS');
      shopCompanions.add(_createDexterYoungFree());
    }

    // 🔥 2. PARA CADA TIPO, MOSTRAR TODAS LAS ETAPAS CON SU ESTADO
    for (final type in [CompanionType.dexter, CompanionType.elly, CompanionType.paxolotl, CompanionType.yami]) {
      // Obtener qué etapas tiene el usuario de este tipo
      final userStagesOfType = userOwnedCompanions
          .where((c) => c.type == type)
          .map((c) => c.stage)
          .toSet();
      
      debugPrint('🔍 [COMPLETE_SHOP] ${type.name}: Usuario tiene etapas: $userStagesOfType');
      
      // 🔥 MOSTRAR TODAS LAS ETAPAS (BABY, YOUNG, ADULT)
      for (final stage in CompanionStage.values) {
        final companion = _createCompanionForShop(type, stage, userStagesOfType);
        
        // 🔥 SKIP DEXTER YOUNG SI YA LO AGREGAMOS GRATIS
        if (type == CompanionType.dexter && stage == CompanionStage.young && !hasDexterYoung) {
          continue; // Ya lo agregamos gratis arriba
        }
        
        shopCompanions.add(companion);
        
        final statusIcon = _getCompanionStatusIcon(companion);
        debugPrint('$statusIcon [COMPLETE_SHOP] ${type.name} ${stage.name}: ${_getCompanionStatus(companion)}');
      }
    }

    // 🔥 ORDENAR: Desbloqueadas primero, luego por tipo y etapa
    shopCompanions.sort((a, b) {
      // Primero por disponibilidad
      final aCanBuy = _canBuyCompanion(a, userOwnedCompanions);
      final bCanBuy = _canBuyCompanion(b, userOwnedCompanions);
      
      if (aCanBuy != bCanBuy) {
        return aCanBuy ? -1 : 1; // Disponibles primero
      }
      
      // Luego por tipo
      final typeComparison = a.type.index.compareTo(b.type.index);
      if (typeComparison != 0) return typeComparison;
      
      // Finalmente por etapa
      return a.stage.index.compareTo(b.stage.index);
    });

    debugPrint('🏪 [COMPLETE_SHOP] === TIENDA FINAL COMPLETA ===');
    debugPrint('🛒 [COMPLETE_SHOP] Total items: ${shopCompanions.length}');
    
    for (final companion in shopCompanions) {
      final status = _getCompanionStatus(companion);
      final icon = _getCompanionStatusIcon(companion);
      debugPrint('$icon ${companion.displayName} ${companion.stage.name}: $status');
    }

    return shopCompanions;
  }

  // 🔥 CREAR COMPANION PARA TIENDA CON ESTADO CORRECTO
  CompanionEntity _createCompanionForShop(
    CompanionType type, 
    CompanionStage stage, 
    Set<CompanionStage> userStages
  ) {
    final prices = _getPricesForType(type);
    final hasThisStage = userStages.contains(stage);
    final canBuy = _canBuyStage(stage, userStages);
    
    return CompanionModel(
      id: '${type.name}_${stage.name}',
      type: type,
      stage: stage,
      name: _getNameForType(type),
      description: _getDescriptionForShop(type, stage, hasThisStage, canBuy),
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

  // 🔥 LÓGICA PARA DETERMINAR SI PUEDE COMPRAR UNA ETAPA
  bool _canBuyStage(CompanionStage targetStage, Set<CompanionStage> userStages) {
    switch (targetStage) {
      case CompanionStage.baby:
        return !userStages.contains(CompanionStage.baby); // Puede comprar si no la tiene
      
      case CompanionStage.young:
        return userStages.contains(CompanionStage.baby) && // Debe tener baby
               !userStages.contains(CompanionStage.young);  // Y no tener young
      
      case CompanionStage.adult:
        return userStages.contains(CompanionStage.young) && // Debe tener young
               !userStages.contains(CompanionStage.adult);  // Y no tener adult
    }
  }

  // 🔥 VERIFICAR SI PUEDE COMPRAR UN COMPANION
  bool _canBuyCompanion(CompanionEntity companion, List<CompanionEntity> userOwnedCompanions) {
    // Si ya lo tiene, no puede comprarlo
    if (companion.isOwned) return false;
    
    // Dexter gratis siempre se puede
    if (companion.type == CompanionType.dexter && 
        companion.stage == CompanionStage.young && 
        companion.purchasePrice == 0) {
      return true;
    }
    
    // Obtener etapas que tiene de este tipo
    final userStagesOfType = userOwnedCompanions
        .where((c) => c.type == companion.type)
        .map((c) => c.stage)
        .toSet();
    
    return _canBuyStage(companion.stage, userStagesOfType);
  }

  // 🔥 OBTENER ESTADO DEL COMPANION PARA DISPLAY
  String _getCompanionStatus(CompanionEntity companion) {
    if (companion.isOwned) {
      return 'YA TIENES';
    }
    
    if (companion.type == CompanionType.dexter && 
        companion.stage == CompanionStage.young && 
        companion.purchasePrice == 0) {
      return 'GRATIS';
    }
    
    if (_canBuyCompanion(companion, _userOwnedCompanions)) {
      return 'DISPONIBLE';
    } else {
      switch (companion.stage) {
        case CompanionStage.baby:
          return 'DISPONIBLE';
        case CompanionStage.young:
          return 'NECESITAS BABY';
        case CompanionStage.adult:
          return 'NECESITAS YOUNG';
      }
    }
  }

  String _getCompanionStatusIcon(CompanionEntity companion) {
    if (companion.isOwned) return '✅';
    if (companion.purchasePrice == 0) return '🎁';
    if (_canBuyCompanion(companion, _userOwnedCompanions)) return '🔓';
    return '🔒';
  }

  // 🔥 CREAR DEXTER JOVEN GRATIS
  CompanionEntity _createDexterYoungFree() {
    return CompanionModel(
      id: 'dexter_young_free',
      type: CompanionType.dexter,
      stage: CompanionStage.young,
      name: 'Dexter',
      description: '🎁 Tu primer compañero gratuito',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔥 GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }

  // 🔥 ADOPCIÓN CON VALIDACIONES MEJORADAS
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO ADOPCIÓN ===');
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

    // 🔥 VALIDACIÓN: Puede comprarlo (etapa anterior)
    if (!_canBuyCompanion(companion, currentState.userOwnedCompanions)) {
      final requirement = _getRequirementMessage(companion);
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
      String apiPetId;
      if (companion.id == 'dexter_young_free') {
        apiPetId = 'dexter_young_free';
      } else {
        apiPetId = currentState.availablePetIds[companion.id] ?? 
                   '${companion.type.name}_${companion.stage.index + 1}';
      }

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
          
          final message = companion.purchasePrice == 0
              ? '🎁 ¡Bienvenido ${adoptedCompanion.displayName}! Tu primer compañero'
              : '🎉 ¡Has adoptado a ${adoptedCompanion.displayName} ${companion.stage.name}!';
          
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

  String _getRequirementMessage(CompanionEntity companion) {
    switch (companion.stage) {
      case CompanionStage.baby:
        return '🔓 Puedes adoptar a ${companion.displayName} baby';
      case CompanionStage.young:
        return '🔒 Necesitas tener ${companion.displayName} baby primero';
      case CompanionStage.adult:
        return '🔒 Necesitas tener ${companion.displayName} young primero';
    }
  }

  // 🔧 MÉTODOS HELPER
  Map<CompanionStage, int> _getPricesForType(CompanionType type) {
    final basePrices = {
      CompanionType.dexter: {
        CompanionStage.baby: 50,
        CompanionStage.young: 100,
        CompanionStage.adult: 150,
      },
      CompanionType.elly: {
        CompanionStage.baby: 200,
        CompanionStage.young: 300,
        CompanionStage.adult: 400,
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

  String _getDescriptionForShop(CompanionType type, CompanionStage stage, bool hasStage, bool canBuy) {
    final name = _getNameForType(type);
    final stageName = stage.name;
    
    if (hasStage) {
      return '✅ Ya tienes $name $stageName';
    } else if (canBuy) {
      return '🔓 $name $stageName - Disponible para adoptar';
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