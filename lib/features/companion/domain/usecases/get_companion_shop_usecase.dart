// lib/features/companion/domain/usecases/get_companion_shop_usecase.dart
// 🔥 CORREGIDO: Sin Dexter gratis, todas las mascotas se compran

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../entities/companion_stats_entity.dart';
import '../repositories/companion_repository.dart';
import '../../data/models/companion_model.dart';

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
      debugPrint('🏪 [SHOP_USECASE] === OBTENIENDO TIENDA SIN DEXTER GRATIS ===');
      debugPrint('👤 [SHOP_USECASE] User ID: ${params.userId}');

      // 🔥 1. OBTENER MASCOTAS YA ADOPTADAS DEL USUARIO
      debugPrint('📡 [SHOP_USECASE] Obteniendo mascotas del usuario...');
      final userCompanionsResult = await repository.getUserCompanions(params.userId);
      
      List<CompanionEntity> userCompanions = [];
      userCompanionsResult.fold(
        (failure) {
          debugPrint('⚠️ [SHOP_USECASE] Error obteniendo mascotas usuario: ${failure.message}');
          // No fallar aquí, solo continuar con lista vacía
        },
        (companions) {
          userCompanions = companions;
          debugPrint('✅ [SHOP_USECASE] Mascotas del usuario: ${userCompanions.length}');
        }
      );

      // 🔥 2. OBTENER TODAS LAS MASCOTAS DISPONIBLES DESDE LA API
      debugPrint('📡 [SHOP_USECASE] Obteniendo mascotas disponibles...');
      final allCompanionsResult = await repository.getAvailableCompanions();
      
      return allCompanionsResult.fold(
        (failure) => Left(failure),
        (allCompanions) async {
          debugPrint('✅ [SHOP_USECASE] Total mascotas disponibles: ${allCompanions.length}');
          
          // 🔥 3. OBTENER ESTADÍSTICAS DEL USUARIO
          debugPrint('📊 [SHOP_USECASE] Obteniendo stats del usuario...');
          final statsResult = await repository.getCompanionStats(params.userId);
          
          return statsResult.fold(
            (failure) => Left(failure),
            (stats) {
              // 🔥 4. MARCAR MASCOTAS YA ADOPTADAS
              final adoptedIds = userCompanions.map((c) => c.id).toSet();
              debugPrint('🔍 [SHOP_USECASE] IDs adoptados: $adoptedIds');
              
              final updatedCompanions = allCompanions.map((companion) {
                final isOwned = adoptedIds.contains(companion.id);
                
                // 🔧 ACTUALIZAR EL ESTADO DE PROPIEDAD
                if (companion is CompanionModel) {
                  return companion.copyWith(isOwned: isOwned);
                }
                
                return companion;
              }).toList();
              
              // 🔥 5. LA TIENDA MOSTRARÁ SOLO LAS MASCOTAS NO ADOPTADAS
              // (La lógica de filtrado se hace en el cubit con la nueva lógica progresiva)
              
              debugPrint('🛍️ [SHOP_USECASE] === RESULTADO FINAL SIN DEXTER GRATIS ===');
              debugPrint('🏠 [SHOP_USECASE] Mascotas del usuario: ${userCompanions.length}');
              debugPrint('🛒 [SHOP_USECASE] Total mascotas disponibles: ${updatedCompanions.length}');
              debugPrint('💰 [SHOP_USECASE] Puntos disponibles: ${stats.availablePoints}');
              
              return Right(CompanionShopData(
                availableCompanions: updatedCompanions, // 🔥 TODAS LAS MASCOTAS MARCADAS
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