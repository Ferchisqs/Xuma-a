// lib/features/companion/domain/usecases/refresh_companion_stats_usecase.dart
// 🔥 USE CASE PARA REFRESCAR ESTADÍSTICAS REALES DESDE LA API

import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:xuma_a/core/errors/exceptions.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/token_manager.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';
import '../../data/datasources/companion_remote_datasource.dart';

class RefreshCompanionStatsParams extends Equatable {
  final String userId;
  final String petId;

  const RefreshCompanionStatsParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class RefreshCompanionStatsUseCase implements UseCase<CompanionEntity, RefreshCompanionStatsParams> {
  final CompanionRemoteDataSource remoteDataSource;
  final TokenManager tokenManager;

  RefreshCompanionStatsUseCase({
    required this.remoteDataSource,
    required this.tokenManager,
  });

  @override
  Future<Either<Failure, CompanionEntity>> call(RefreshCompanionStatsParams params) async {
    try {
      debugPrint('🔄 [REFRESH_STATS] === REFRESCANDO ESTADÍSTICAS REALES ===');
      debugPrint('👤 [REFRESH_STATS] User ID: ${params.userId}');
      debugPrint('🆔 [REFRESH_STATS] Pet ID: ${params.petId}');

      // Verificar autenticación
      final hasValidToken = await tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        debugPrint('❌ [REFRESH_STATS] Token inválido');
        return Left(AuthFailure('Token de autenticación inválido o expirado'));
      }

      // 🔥 OBTENER DETALLES COMPLETOS CON ESTADÍSTICAS REALES
      try {
        final companionWithRealStats = await remoteDataSource.getPetDetails(
          petId: params.petId,
          userId: params.userId,
        );

        debugPrint('✅ [REFRESH_STATS] === ESTADÍSTICAS REFRESCADAS EXITOSAMENTE ===');
        debugPrint('🐾 [REFRESH_STATS] Mascota: ${companionWithRealStats.displayName}');
        debugPrint('❤️ [REFRESH_STATS] Felicidad actual: ${companionWithRealStats.happiness}/100');
        debugPrint('🏥 [REFRESH_STATS] Salud actual: ${companionWithRealStats.hunger}/100');
        debugPrint('⭐ [REFRESH_STATS] Nivel: ${companionWithRealStats.level}');
        debugPrint('🎯 [REFRESH_STATS] EXP: ${companionWithRealStats.experience}');

        return Right(companionWithRealStats);

      } on ServerException catch (e) {
        debugPrint('❌ [REFRESH_STATS] Error del servidor: ${e.message}');
        return Left(ServerFailure(e.message));
      } catch (e) {
        debugPrint('❌ [REFRESH_STATS] Error inesperado: $e');
        return Left(ServerFailure('Error obteniendo estadísticas actualizadas: ${e.toString()}'));
      }
      
    } catch (e) {
      debugPrint('💥 [REFRESH_STATS] Error general: $e');
      return Left(UnknownFailure('Error refrescando estadísticas: ${e.toString()}'));
    }
  }
}

// 🔥 USE CASE PARA OBTENER MÚLTIPLES MASCOTAS CON STATS ACTUALIZADAS
class RefreshAllUserCompanionsParams extends Equatable {
  final String userId;

  const RefreshAllUserCompanionsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class RefreshAllUserCompanionsUseCase implements UseCase<List<CompanionEntity>, RefreshAllUserCompanionsParams> {
  final CompanionRepository repository;

  RefreshAllUserCompanionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CompanionEntity>>> call(RefreshAllUserCompanionsParams params) async {
    try {
      debugPrint('🔄 [REFRESH_ALL] === REFRESCANDO TODAS LAS MASCOTAS CON STATS REALES ===');
      debugPrint('👤 [REFRESH_ALL] User ID: ${params.userId}');

      // 🔥 OBTENER MASCOTAS CON ESTADÍSTICAS ACTUALIZADAS DESDE LA API
      final result = await repository.getUserCompanions(params.userId);

      return result.fold(
        (failure) {
          debugPrint('❌ [REFRESH_ALL] Error: ${failure.message}');
          return Left(failure);
        },
        (companions) {
          debugPrint('✅ [REFRESH_ALL] === TODAS LAS MASCOTAS REFRESCADAS ===');
          debugPrint('🐾 [REFRESH_ALL] Total mascotas: ${companions.length}');
          
          // Log de estadísticas actualizadas
          for (int i = 0; i < companions.length; i++) {
            final companion = companions[i];
            debugPrint('📊 [REFRESH_ALL] [$i] ${companion.displayName}: H:${companion.happiness}, S:${companion.hunger}');
          }

          return Right(companions);
        },
      );
      
    } catch (e) {
      debugPrint('💥 [REFRESH_ALL] Error general: $e');
      return Left(UnknownFailure('Error refrescando todas las mascotas: ${e.toString()}'));
    }
  }
}