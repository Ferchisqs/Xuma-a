// lib/features/companion/presentation/cubit/companion_shop_cubit.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// States
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
  
  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
  });
  
  @override
  List<Object> get props => [availableCompanions, purchasableCompanions, userStats];
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

// Cubit
@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  
  static const String _defaultUserId = 'user_123';
  
  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
  }) : super(CompanionShopInitial());
  
  Future<void> loadShop() async {
    try {
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA ===');
      emit(CompanionShopLoading());
      
      final result = await getCompanionShopUseCase(
        const GetCompanionShopParams(userId: _defaultUserId),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error cargando tienda: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [SHOP_CUBIT] Tienda cargada exitosamente');
          debugPrint('📊 [SHOP_CUBIT] Stats: ${shopData.userStats.availablePoints} puntos disponibles');
          debugPrint('🐾 [SHOP_CUBIT] Total companions: ${shopData.availableCompanions.length}');
          
          // 🔧 FILTRAR COMPANIONS PARA TIENDA
          final purchasableCompanions = _filterCompanionsForShop(shopData.availableCompanions);
          
          debugPrint('🛍️ [SHOP_CUBIT] Companions en tienda: ${purchasableCompanions.length}');
          
          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: purchasableCompanions,
            userStats: shopData.userStats,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado cargando tienda: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }
  
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO COMPRA ===');
    debugPrint('🛒 [SHOP_CUBIT] Companion: ${companion.displayName}');
    debugPrint('🛒 [SHOP_CUBIT] ID: ${companion.id}');
    debugPrint('🛒 [SHOP_CUBIT] Precio: ${companion.purchasePrice}');
    debugPrint('🛒 [SHOP_CUBIT] Estado actual: ${state.runtimeType}');
    
    if (state is! CompanionShopLoaded) {
      debugPrint('❌ [SHOP_CUBIT] Estado incorrecto para compra: ${state.runtimeType}');
      emit(CompanionShopError(message: 'Error: Estado de tienda no válido'));
      return;
    }
    
    final currentState = state as CompanionShopLoaded;
    
    // 🔧 VERIFICAR SI ES DEXTER JOVEN (YA DESBLOQUEADO)
    if (_isDexterYoung(companion)) {
      debugPrint('🔧 [SHOP_CUBIT] Dexter joven detectado - ya desbloqueado');
      emit(CompanionShopPurchaseSuccess(
        purchasedCompanion: companion,
        message: '¡${companion.displayName} ya está desbloqueado! Es tu primer compañero.',
      ));
      
      // Recargar inmediatamente
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isClosed) loadShop();
      });
      return;
    }
    
    debugPrint('💰 [SHOP_CUBIT] Puntos disponibles: ${currentState.userStats.availablePoints}');
    debugPrint('🏷️ [SHOP_CUBIT] Precio del companion: ${companion.purchasePrice}');
    
    // Verificar puntos suficientes
    if (currentState.userStats.availablePoints < companion.purchasePrice) {
      final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
      debugPrint('❌ [SHOP_CUBIT] PUNTOS INSUFICIENTES');
      debugPrint('💸 [SHOP_CUBIT] Faltan: $faltantes puntos');
      emit(CompanionShopError(
        message: 'No tienes suficientes puntos. Necesitas $faltantes puntos más.',
      ));
      return;
    }
    
    debugPrint('⏳ [SHOP_CUBIT] Cambiando estado a PURCHASING...');
    emit(CompanionShopPurchasing(companion: companion));
    
    try {
      debugPrint('🚀 [SHOP_CUBIT] Llamando al USE CASE...');
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: _defaultUserId,
          companionId: companion.id,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] ERROR EN USE CASE: ${failure.message}');
          debugPrint('🔍 [SHOP_CUBIT] Tipo de falla: ${failure.runtimeType}');
          emit(CompanionShopError(message: failure.message));
        },
        (purchasedCompanion) {
          debugPrint('✅ [SHOP_CUBIT] === COMPRA EXITOSA ===');
          debugPrint('🎉 [SHOP_CUBIT] Companion adquirido: ${purchasedCompanion.displayName}');
          debugPrint('✨ [SHOP_CUBIT] isOwned: ${purchasedCompanion.isOwned}');
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: purchasedCompanion,
            message: '¡Felicidades! Has adquirido a ${purchasedCompanion.displayName}',
          ));
          
          // 🔧 RECARGAR TIENDA DESPUÉS DE COMPRA EXITOSA
          debugPrint('🔄 [SHOP_CUBIT] RECARGANDO TIENDA...');
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Excepción durante compra: $e');
      emit(CompanionShopError(message: 'Error inesperado durante la compra: ${e.toString()}'));
    }
  }

  /// Recargar tienda después de una compra exitosa
  Future<void> _reloadShopAfterPurchase() async {
    try {
      debugPrint('🔄 [SHOP_CUBIT] Iniciando recarga post-compra...');
      
      // Pequeña pausa para asegurar que el cache se actualice
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (isClosed) {
        debugPrint('⚠️ [SHOP_CUBIT] Cubit cerrado, saltando recarga');
        return;
      }
      
      debugPrint('🔄 [SHOP_CUBIT] Ejecutando loadShop()...');
      await loadShop();
      
      debugPrint('✅ [SHOP_CUBIT] Recarga completada');
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error durante recarga: $e');
    }
  }

  /// Filtrar companions para mostrar en la tienda
  List<CompanionEntity> _filterCompanionsForShop(List<CompanionEntity> allCompanions) {
    debugPrint('🔧 [SHOP_CUBIT] Filtrando companions para tienda');
    
    final filtered = allCompanions.where((companion) {
      // 🔧 MOSTRAR DEXTER JOVEN COMO "YA DESBLOQUEADO" (NO PARA COMPRAR)
      if (_isDexterYoung(companion)) {
        debugPrint('🔧 [SHOP_CUBIT] Dexter joven: mostrar como desbloqueado');
        return true; // Mostrar pero con indicador especial
      }
      
      // Mostrar solo los no poseídos
      final shouldShow = !companion.isOwned;
      debugPrint('🔧 [SHOP_CUBIT] ${companion.displayName}: ${shouldShow ? "MOSTRAR" : "OCULTAR"} (owned: ${companion.isOwned})');
      return shouldShow;
    }).toList();
    
    // Ordenar por tipo y luego por etapa
    filtered.sort((a, b) {
      final typeComparison = a.type.index.compareTo(b.type.index);
      if (typeComparison != 0) return typeComparison;
      return a.stage.index.compareTo(b.stage.index);
    });
    
    debugPrint('🔧 [SHOP_CUBIT] Companions filtrados: ${filtered.length}');
    return filtered;
  }
  
  /// Verificar si un companion es Dexter joven
  bool _isDexterYoung(CompanionEntity companion) {
    return companion.type == CompanionType.dexter && 
           companion.stage == CompanionStage.young;
  }
  
  void refreshShop() {
    debugPrint('🔄 [SHOP_CUBIT] Refresh manual solicitado');
    loadShop();
  }
  
  // Método para filtrar companions por tipo
  List<CompanionEntity> getCompanionsByType(CompanionType type) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.type == type)
          .toList();
    }
    return [];
  }
  
  // Método para obtener companions por rango de precio
  List<CompanionEntity> getCompanionsByPriceRange(int minPrice, int maxPrice) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.purchasePrice >= minPrice && c.purchasePrice <= maxPrice)
          .toList();
    }
    return [];
  }
  
  // Verificar si un companion puede ser comprado
  bool canAffordCompanion(CompanionEntity companion) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      
      // Dexter joven siempre es "asequible" (ya desbloqueado)
      if (_isDexterYoung(companion)) {
        return true;
      }
      
      return currentState.userStats.availablePoints >= companion.purchasePrice;
    }
    return false;
  }
  
  // Obtener mensaje para companion específico
  String getCompanionMessage(CompanionEntity companion) {
    if (_isDexterYoung(companion)) {
      return '¡Ya desbloqueado!';
    }
    
    if (companion.isOwned) {
      return 'Ya lo tienes';
    }
    
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      if (currentState.userStats.availablePoints >= companion.purchasePrice) {
        return 'Disponible para adoptar';
      } else {
        final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
        return 'Necesitas $faltantes puntos más';
      }
    }
    
    return 'Cargando...';
  }
}