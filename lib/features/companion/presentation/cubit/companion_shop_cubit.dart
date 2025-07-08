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
  
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    if (state is! CompanionShopLoaded) return;
    
    final currentState = state as CompanionShopLoaded;
    
    // Verificar si tiene suficientes puntos
    if (currentState.userStats.availablePoints < companion.purchasePrice) {
      emit(CompanionShopError(
        message: 'No tienes suficientes puntos. Necesitas ${companion.purchasePrice} puntos.',
      ));
      return;
    }
    
    emit(CompanionShopPurchasing(companion: companion));
    
    final result = await purchaseCompanionUseCase(
      PurchaseCompanionParams(
        userId: _defaultUserId,
        companionId: companion.id,
      ),
    );
    
    result.fold(
      (failure) => emit(CompanionShopError(message: failure.message)),
      (purchasedCompanion) {
        emit(CompanionShopPurchaseSuccess(
          purchasedCompanion: purchasedCompanion,
          message: '¡Felicidades! Has adquirido a ${purchasedCompanion.displayName}',
        ));
        
        // Recargar la tienda después de la compra
        Future.delayed(const Duration(seconds: 2), () {
          loadShop();
        });
      },
    );
  }
  
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