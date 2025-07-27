// lib/features/companion/domain/usecases/get_companion_shop_usecase.dart
// 🔥 CORREGIDO: Sin crear companions locales, usar solo lo que viene de la API

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../entities/companion_stats_entity.dart';
import '../repositories/companion_repository.dart';

class CompanionShopData {
  final List<CompanionEntity> availableCompanions;
  final CompanionStatsEntity userStats;

  CompanionShopData({
    required this.availableCompanions,
    required this.userStats,
  });
}

class GetCompanionShopParams {
  final String userId;

  const GetCompanionShopParams({required this.userId});
}

@injectable
class GetCompanionShopUseCase implements UseCase<CompanionShopData, GetCompanionShopParams> {
  final CompanionRepository repository;

  GetCompanionShopUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionShopData>> call(GetCompanionShopParams params) async {
    try {
      debugPrint('🏪 [SHOP_USECASE] === OBTENIENDO TIENDA SOLO DE API ===');
      debugPrint('👤 [SHOP_USECASE] User ID: ${params.userId}');

      // 🔥 1. OBTENER TODAS LAS MASCOTAS DISPONIBLES DESDE LA API
      debugPrint('📡 [SHOP_USECASE] Obteniendo mascotas disponibles desde API...');
      final availableCompanionsResult = await repository.getAvailableCompanions();
      
      return availableCompanionsResult.fold(
        (failure) {
          debugPrint('❌ [SHOP_USECASE] Error obteniendo mascotas disponibles: ${failure.message}');
          return Left(failure);
        },
        (availableCompanions) async {
          debugPrint('✅ [SHOP_USECASE] Mascotas disponibles: ${availableCompanions.length}');
          
          // 🔥 2. OBTENER ESTADÍSTICAS DEL USUARIO
          debugPrint('📊 [SHOP_USECASE] Obteniendo stats del usuario...');
          final statsResult = await repository.getCompanionStats(params.userId);
          
          return statsResult.fold(
            (failure) {
              debugPrint('❌ [SHOP_USECASE] Error obteniendo stats: ${failure.message}');
              return Left(failure);
            },
            (stats) {
              debugPrint('✅ [SHOP_USECASE] === RESULTADO FINAL ===');
              debugPrint('🛍️ [SHOP_USECASE] Total mascotas de API: ${availableCompanions.length}');
              debugPrint('💰 [SHOP_USECASE] Puntos disponibles: ${stats.availablePoints}');
              
              // 🔥 DEBUG: Mostrar detalles de cada mascota
              for (int i = 0; i < availableCompanions.length; i++) {
                final companion = availableCompanions[i];
                final status = companion.isOwned ? "YA TIENE" : "DISPONIBLE";
                debugPrint('[$i] ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★ ($status)');
              }
              
              return Right(CompanionShopData(
                availableCompanions: availableCompanions, // 🔥 USAR DIRECTAMENTE LO QUE VIENE DE LA API
                userStats: stats,
              ));
            },
          );
        },
      );
      
    } catch (e) {
      debugPrint('❌ [SHOP_USECASE] Error inesperado: $e');
      return Left(UnknownFailure('Error obteniendo tienda: ${e.toString()}'));
    }
  }
}