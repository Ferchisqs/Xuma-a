// lib/features/companion/domain/repositories/companion_repository.dart - ACTUALIZADO
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../entities/companion_stats_entity.dart';

abstract class CompanionRepository {
  // 🔥 MÉTODO DE ADOPCIÓN ACTUALIZADO
  Future<Either<Failure, CompanionEntity>> adoptCompanion({
    required String userId,
    required String petId,
    String? nickname,
  });

  // OTROS MÉTODOS EXISTENTES
  Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId);
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions();
  Future<Either<Failure, CompanionStatsEntity>> getCompanionStats(String userId);
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId);
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId);
  Future<Either<Failure, CompanionEntity>> loveCompanion(String userId, String companionId);
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId);

  // 🔧 MANTENER EL MÉTODO LEGACY PARA COMPATIBILIDAD
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    return adoptCompanion(userId: userId, petId: companionId);
  }
}

