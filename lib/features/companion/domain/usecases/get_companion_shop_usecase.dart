// lib/features/companion/domain/usecases/get_companion_shop_usecase.dart - CORREGIDO
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
      debugPrint('🏪 [SHOP_USECASE] === OBTENIENDO TIENDA ===');
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

      // 🔥 2. OBTENER TODAS LAS MASCOTAS DISPONIBLES
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
              // 🔥 4. MARCAR MASCOTAS YA ADOPTADAS Y FILTRAR PARA TIENDA
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
              
              // 🔥 5. FILTRAR SOLO MASCOTAS NO ADOPTADAS PARA LA TIENDA
              final storeCompanions = updatedCompanions.where((c) => !c.isOwned).toList();
              
              // 🔧 AGREGAR DEXTER JOVEN GRATIS SI NO LO TIENE
              final hasDexterYoung = userCompanions.any((c) => 
                c.type == CompanionType.dexter && c.stage == CompanionStage.young
              );
              
              if (!hasDexterYoung) {
                debugPrint('🎁 [SHOP_USECASE] Agregando Dexter joven gratis');
                // Crear o encontrar Dexter joven y marcarlo como disponible
                var dexterYoung = storeCompanions.firstWhere(
                  (c) => c.type == CompanionType.dexter && c.stage == CompanionStage.young,
                  orElse: () => _createDexterYoung(),
                );
                
                if (!storeCompanions.contains(dexterYoung)) {
                  storeCompanions.insert(0, dexterYoung);
                }
              }
              
              // 🔧 ORDENAR POR PRECIO
              storeCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
              
              debugPrint('🛍️ [SHOP_USECASE] === RESULTADO FINAL ===');
              debugPrint('🏠 [SHOP_USECASE] Mascotas del usuario: ${userCompanions.length}');
              debugPrint('🛒 [SHOP_USECASE] Mascotas en tienda: ${storeCompanions.length}');
              debugPrint('💰 [SHOP_USECASE] Puntos disponibles: ${stats.availablePoints}');
              
              return Right(CompanionShopData(
                availableCompanions: storeCompanions, // 🔥 SOLO MASCOTAS NO ADOPTADAS
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
  
  // 🔧 CREAR DEXTER JOVEN POR DEFECTO
  CompanionEntity _createDexterYoung() {
    return CompanionModel(
      id: 'dexter_young',
      type: CompanionType.dexter,
      stage: CompanionStage.young,
      name: 'Dexter',
      description: 'Tu primer compañero gratuito',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }
}