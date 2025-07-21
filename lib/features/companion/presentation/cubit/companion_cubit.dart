// 🔧 REEMPLAZAR CompanionCubit en lib/features/companion/presentation/cubit/companion_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
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
  
  get repository => null;

  // 🔧 MÉTODO MEJORADO CON USER ID REAL
  // 🔧 MÉTODO MEJORADO CON MANEJO CORRECTO DE DATOS
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
      
      // 🔥 OBTENER MASCOTAS DEL USUARIO DIRECTAMENTE
      debugPrint('📡 [COMPANION_CUBIT] Obteniendo mascotas del usuario...');
      final userCompanionsResult = await getUserCompanionsUseCase(
        GetUserCompanionsParams(userId: userId),
      );

      List<CompanionEntity> ownedCompanions = [];
      
      userCompanionsResult.fold(
        (failure) {
          debugPrint('⚠️ [COMPANION_CUBIT] Error obteniendo mascotas usuario: ${failure.message}');
          // Continuar sin mascotas del usuario
        },
        (companions) {
          ownedCompanions = companions;
          debugPrint('✅ [COMPANION_CUBIT] Mascotas del usuario cargadas: ${ownedCompanions.length}');
          
          // Debug detallado
          for (int i = 0; i < ownedCompanions.length; i++) {
            final companion = ownedCompanions[i];
            debugPrint('🐾 [COMPANION_CUBIT] [$i] ${companion.displayName} (${companion.id}): ${companion.type.name}_${companion.stage.name}');
          }
        },
      );
      
      // 🔥 OBTENER ESTADÍSTICAS
      debugPrint('📊 [COMPANION_CUBIT] Obteniendo estadísticas...');
      final statsResult = await repository.getCompanionStats(userId);
      
      statsResult.fold(
        (failure) {
          debugPrint('❌ [COMPANION_CUBIT] Error obteniendo stats: ${failure.message}');
          emit(CompanionError(message: 'Error obteniendo estadísticas: ${failure.message}'));
        },
        (stats) {
          debugPrint('✅ [COMPANION_CUBIT] Stats obtenidas: ${stats.availablePoints} puntos, ${stats.ownedCompanions} mascotas');
          
         
          
          // 🔧 ASEGURAR QUE TENGA AL MENOS UNA MASCOTA ACTIVA
          if (!ownedCompanions.any((c) => c.isSelected)) {
            debugPrint('⭐ [COMPANION_CUBIT] No hay mascota activa, activando la primera');
            if (ownedCompanions.isNotEmpty) {
              // Actualizar la primera mascota como activa
              final firstCompanion = ownedCompanions[0];
              if (firstCompanion is CompanionModel) {
                ownedCompanions[0] = firstCompanion.copyWith(isSelected: true);
              }
            }
          }
          
          final activeCompanion = ownedCompanions.where((c) => c.isSelected).isNotEmpty 
              ? ownedCompanions.firstWhere((c) => c.isSelected)
              : ownedCompanions.first;
              
          debugPrint('⭐ [COMPANION_CUBIT] Compañero activo: ${activeCompanion.displayName}');
          
          // 🔥 OBTENER TIENDA (mascotas disponibles para comprar)
          debugPrint('🏪 [COMPANION_CUBIT] Obteniendo tienda...');
          
          repository.getAvailableCompanions().then((availableResult) {
            availableResult.fold(
              (failure) {
                debugPrint('⚠️ [COMPANION_CUBIT] Error obteniendo tienda: ${failure.message}');
                
                // Emitir resultado sin tienda
                emit(CompanionLoaded(
                  allCompanions: [], // Sin tienda por error
                  ownedCompanions: ownedCompanions,
                  activeCompanion: activeCompanion,
                  userStats: stats,
                ));
              },
              (storeCompanions) {
                debugPrint('🛍️ [COMPANION_CUBIT] Tienda obtenida: ${storeCompanions.length} mascotas');
                
                // 🎯 EMITIR ESTADO FINAL CON TODOS LOS DATOS
                emit(CompanionLoaded(
                  allCompanions: storeCompanions,
                  ownedCompanions: ownedCompanions,
                  activeCompanion: activeCompanion,
                  userStats: stats,
                ));
                
                debugPrint('🎉 [COMPANION_CUBIT] === CARGA COMPLETADA EXITOSAMENTE ===');
                debugPrint('🏠 [COMPANION_CUBIT] Mascotas del usuario: ${ownedCompanions.length}');
                debugPrint('🛒 [COMPANION_CUBIT] Mascotas en tienda: ${storeCompanions.length}');
                debugPrint('💰 [COMPANION_CUBIT] Puntos disponibles: ${stats.availablePoints}');
              },
            );
          });
        },
      );
      
    } catch (e) {
      debugPrint('💥 [COMPANION_CUBIT] Error inesperado: $e');
      emit(CompanionError(message: 'Error inesperado: ${e.toString()}'));
    }
  }


  Future<void> _loadUserCompanions(String userId, dynamic shopData) async {
    try {
      debugPrint('🔍 [COMPANION_CUBIT] === OBTENIENDO MASCOTAS DEL USUARIO ===');
      
      // Obtener mascotas del usuario directamente desde el repository
      final userCompanionsResult = await getUserCompanionsUseCase(
        GetUserCompanionsParams(userId: userId),
      );
      
      userCompanionsResult.fold(
        (failure) {
          debugPrint('⚠️ [COMPANION_CUBIT] Error obteniendo mascotas usuario: ${failure.message}');
          
          
          
         
        },
        (userCompanions) {
          debugPrint('✅ [COMPANION_CUBIT] Mascotas del usuario: ${userCompanions.length}');
          
          // Verificar que tenga al menos una mascota
          List<CompanionEntity> finalOwnedCompanions = List.from(userCompanions);
          
      
          
          // 🔧 ENCONTRAR COMPAÑERO ACTIVO
          final activeCompanion = finalOwnedCompanions
              .where((c) => c.isSelected)
              .isNotEmpty 
              ? finalOwnedCompanions.firstWhere((c) => c.isSelected)
              : finalOwnedCompanions.first;
              
          debugPrint('⭐ [COMPANION_CUBIT] Compañero activo: ${activeCompanion.displayName}');
          
          // Debug detallado de las mascotas
          for (final companion in finalOwnedCompanions) {
            debugPrint('🐾 [COMPANION_CUBIT] - ${companion.displayName} (${companion.id}): Owned=${companion.isOwned}, Selected=${companion.isSelected}');
          }

          emit(CompanionLoaded(
            allCompanions: shopData.availableCompanions,
            ownedCompanions: finalOwnedCompanions,
            activeCompanion: activeCompanion,
            userStats: shopData.userStats,
          ));
          
          debugPrint('🎯 [COMPANION_CUBIT] === CARGA COMPLETADA ===');
        },
      );
      
    } catch (e) {
      debugPrint('💥 [COMPANION_CUBIT] Error cargando mascotas usuario: $e');
      emit(CompanionError(message: 'Error cargando tus mascotas: ${e.toString()}'));
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