// 🔧 REEMPLAZAR CompanionCubit en lib/features/companion/presentation/cubit/companion_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/token_manager.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_user_companions_usecase.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';

// States (sin cambios)
abstract class CompanionState extends Equatable {
  const CompanionState();
  @override
  List<Object?> get props => [];
}

class CompanionInitial extends CompanionState {}
class CompanionLoading extends CompanionState {}

class CompanionLoaded extends CompanionState {
  final List<CompanionEntity> allCompanions;
  final List<CompanionEntity> ownedCompanions;
  final CompanionEntity? activeCompanion;
  final CompanionStatsEntity userStats;

  const CompanionLoaded({
    required this.allCompanions,
    required this.ownedCompanions,
    this.activeCompanion,
    required this.userStats,
  });

  @override
  List<Object?> get props => [allCompanions, ownedCompanions, activeCompanion, userStats];
}

class CompanionError extends CompanionState {
  final String message;
  const CompanionError({required this.message});
  @override
  List<Object> get props => [message];
}

// 🔧 CUBIT MEJORADO CON USER ID REAL
@injectable
class CompanionCubit extends Cubit<CompanionState> {
  final GetUserCompanionsUseCase getUserCompanionsUseCase;
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final TokenManager tokenManager;
   

  CompanionCubit({
    required this.getUserCompanionsUseCase,
    required this.getCompanionShopUseCase,
    required this.tokenManager,
  }) : super(CompanionInitial());

  // 🔧 MÉTODO MEJORADO CON USER ID REAL
  Future<void> loadCompanions() async {
    try {
      debugPrint('🐾 [COMPANION_CUBIT] === CARGANDO COMPAÑEROS CON API REAL ===');
      emit(CompanionLoading());
      
      // 🔥 OBTENER USER ID REAL DEL TOKEN
      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ [COMPANION_CUBIT] No hay usuario autenticado');
        emit(CompanionError(message: 'Debes estar autenticado'));
        return;
      }
      
      debugPrint('👤 [COMPANION_CUBIT] Usuario autenticado: $userId');
      
      // 🔥 LLAMAR AL USE CASE CON USER ID REAL
      final shopResult = await getCompanionShopUseCase(
        GetCompanionShopParams(userId: userId),
      );

      shopResult.fold(
        (failure) {
          debugPrint('❌ [COMPANION_CUBIT] Error: ${failure.message}');
          emit(CompanionError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [COMPANION_CUBIT] === DATOS CARGADOS EXITOSAMENTE ===');
          debugPrint('👤 [COMPANION_CUBIT] Usuario: $userId');
          debugPrint('💰 [COMPANION_CUBIT] Puntos disponibles: ${shopData.userStats.availablePoints}');
          debugPrint('🐾 [COMPANION_CUBIT] Total mascotas: ${shopData.availableCompanions.length}');
          
          // 🔧 FILTRAR MASCOTAS POSEÍDAS
          final ownedCompanions = shopData.availableCompanions
              .where((c) => c.isOwned)
              .toList();
          
          debugPrint('🏠 [COMPANION_CUBIT] Mascotas poseídas: ${ownedCompanions.length}');
          
          // 🔧 ENCONTRAR COMPAÑERO ACTIVO
          final activeCompanion = ownedCompanions
              .where((c) => c.isSelected)
              .isNotEmpty 
              ? ownedCompanions.firstWhere((c) => c.isSelected)
              : null;
              
          if (activeCompanion != null) {
            debugPrint('⭐ [COMPANION_CUBIT] Compañero activo: ${activeCompanion.displayName}');
          } else {
            debugPrint('⚠️ [COMPANION_CUBIT] No hay compañero activo seleccionado');
          }

          emit(CompanionLoaded(
            allCompanions: shopData.availableCompanions,
            ownedCompanions: ownedCompanions,
            activeCompanion: activeCompanion,
            userStats: shopData.userStats,
          ));
          
          debugPrint('🎯 [COMPANION_CUBIT] === CARGA COMPLETADA ===');
        },
      );
      
    } catch (e) {
      debugPrint('💥 [COMPANION_CUBIT] Error inesperado: $e');
      emit(CompanionError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  void refreshCompanions() {
    debugPrint('🔄 [COMPANION_CUBIT] REFRESH solicitado');
    loadCompanions();
  }
  
  // 🔧 MÉTODO PARA DEBUG DE TOKEN
  Future<void> debugTokenInfo() async {
    try {
      final userId = await tokenManager.getUserId();
      final hasToken = await tokenManager.hasValidAccessToken();
      
      debugPrint('🔍 [COMPANION_CUBIT] === TOKEN DEBUG ===');
      debugPrint('👤 [COMPANION_CUBIT] User ID: $userId');
      debugPrint('🔑 [COMPANION_CUBIT] Has valid token: $hasToken');
      debugPrint('🔍 [COMPANION_CUBIT] ========================');
    } catch (e) {
      debugPrint('❌ [COMPANION_CUBIT] Error en debug: $e');
    }
  }
}