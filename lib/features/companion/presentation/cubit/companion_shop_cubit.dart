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
    emit(CompanionShopLoading());
    
    final result = await getCompanionShopUseCase(
      const GetCompanionShopParams(userId: _defaultUserId),
    );
    
    result.fold(
      (failure) => emit(CompanionShopError(message: failure.message)),
      (shopData) {
        // Filtrar solo los compañeros que no son propiedad del usuario
        final purchasableCompanions = shopData.availableCompanions
            .where((companion) => !companion.isOwned)
            .toList();
        
        // Agrupar por tipo para mostrar mejor en la tienda
        final sortedCompanions = _sortCompanionsByTypeAndStage(purchasableCompanions);
        
        emit(CompanionShopLoaded(
          availableCompanions: shopData.availableCompanions,
          purchasableCompanions: sortedCompanions,
          userStats: shopData.userStats,
        ));
      },
    );
  }
  
  
// 🔧 ARREGLAR COMPANION_SHOP_CUBIT.dart - purchaseCompanion method

Future<void> purchaseCompanion(CompanionEntity companion) async {
  debugPrint('🛒 [CUBIT] === INICIANDO COMPRA ===');
  debugPrint('🛒 [CUBIT] Compañero: ${companion.displayName}');
  debugPrint('🛒 [CUBIT] Estado actual: ${state.runtimeType}');
  
  if (state is! CompanionShopLoaded) {
    debugPrint('❌ [CUBIT] Estado incorrecto para compra: ${state.runtimeType}');
    return;
  }
  
  final currentState = state as CompanionShopLoaded;
  
  debugPrint('💰 [CUBIT] Puntos disponibles actuales: ${currentState.userStats.availablePoints}');
  debugPrint('🏷️ [CUBIT] Precio del compañero: ${companion.purchasePrice}');
  
  // Verificar si tiene suficientes puntos
  if (currentState.userStats.availablePoints < companion.purchasePrice) {
    debugPrint('❌ [CUBIT] PUNTOS INSUFICIENTES');
    debugPrint('💸 [CUBIT] Faltan: ${companion.purchasePrice - currentState.userStats.availablePoints} puntos');
    emit(CompanionShopError(
      message: 'No tienes suficientes puntos. Necesitas ${companion.purchasePrice} puntos.',
    ));
    return;
  }
  
  debugPrint('⏳ [CUBIT] Cambiando estado a PURCHASING...');
  emit(CompanionShopPurchasing(companion: companion));
  
  debugPrint('🚀 [CUBIT] Llamando al USE CASE...');
  final result = await purchaseCompanionUseCase(
    PurchaseCompanionParams(
      userId: _defaultUserId,
      companionId: companion.id,
    ),
  );
  
  result.fold(
    (failure) {
      debugPrint('❌ [CUBIT] ERROR EN USE CASE: ${failure.message}');
      debugPrint('🔍 [CUBIT] Tipo de falla: ${failure.runtimeType}');
      emit(CompanionShopError(message: failure.message));
    },
    (purchasedCompanion) {
      debugPrint('✅ [CUBIT] === COMPRA EXITOSA ===');
      debugPrint('🎉 [CUBIT] Compañero adquirido: ${purchasedCompanion.displayName}');
      debugPrint('✨ [CUBIT] isOwned: ${purchasedCompanion.isOwned}');
      
      emit(CompanionShopPurchaseSuccess(
        purchasedCompanion: purchasedCompanion,
        message: '¡Felicidades! Has adquirido a ${purchasedCompanion.displayName}',
      ));
      
      // 🔧 RECARGAR INMEDIATAMENTE LA TIENDA
      debugPrint('🔄 [CUBIT] RECARGANDO TIENDA INMEDIATAMENTE...');
      _reloadShopAfterPurchase();
    },
  );
}

// 🔧 MÉTODO ESPECÍFICO PARA RECARGAR DESPUÉS DE COMPRA
Future<void> _reloadShopAfterPurchase() async {
  debugPrint('🔄 [CUBIT] Iniciando recarga post-compra...');
  
  // Pequeña pausa para que se complete el guardado
  await Future.delayed(const Duration(milliseconds: 500));
  
  if (isClosed) {
    debugPrint('⚠️ [CUBIT] Cubit cerrado, saltando recarga');
    return;
  }
  
  debugPrint('🔄 [CUBIT] Ejecutando loadShop()...');
  await loadShop();
}

// 🔧 MÉTODO loadShop MEJORADO

  List<CompanionEntity> _sortCompanionsByTypeAndStage(List<CompanionEntity> companions) {
    // Ordenar por tipo primero, luego por etapa
    companions.sort((a, b) {
      final typeComparison = a.type.index.compareTo(b.type.index);
      if (typeComparison != 0) return typeComparison;
      return a.stage.index.compareTo(b.stage.index);
    });
    
    return companions;
  }
  
  void refreshShop() => loadShop();
  
  // Método para filtrar compañeros por tipo
  List<CompanionEntity> getCompanionsByType(CompanionType type) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.type == type)
          .toList();
    }
    return [];
  }
  
  // Método para obtener compañeros por rango de precio
  List<CompanionEntity> getCompanionsByPriceRange(int minPrice, int maxPrice) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.purchasePrice >= minPrice && c.purchasePrice <= maxPrice)
          .toList();
    }
    return [];
  }
}