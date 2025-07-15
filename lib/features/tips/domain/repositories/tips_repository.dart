// lib/features/tips/domain/repositories/tips_repository.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/tip_entity.dart';

abstract class TipsRepository {
  /// Obtiene todos los tips con paginación
  Future<Either<Failure, List<TipEntity>>> getAllTips({
    int page = 1,
    int limit = 50,
  });

  /// Obtiene un tip por ID
  Future<Either<Failure, TipEntity>> getTipById(String id);

  /// Obtiene tips por categoría
  Future<Either<Failure, List<TipEntity>>> getTipsByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  });

  /// Obtiene un tip aleatorio
  Future<Either<Failure, TipEntity>> getRandomTip({
    String? category,
  });

  /// Obtiene tips desde caché local
  Future<Either<Failure, List<TipEntity>>> getCachedTips();

  /// Guarda tips en caché local
  Future<Either<Failure, bool>> cacheTips(List<TipEntity> tips);
}