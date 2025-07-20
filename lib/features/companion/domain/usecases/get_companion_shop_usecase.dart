// lib/features/companion/domain/usecases/get_companion_shop_usecase.dart - API CONECTADA
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
    // 🚀 OBTENER TIENDA DESDE TU API
    final companionsResult = await repository.getAvailableCompanions();
    final statsResult = await repository.getCompanionStats(params.userId);

    return companionsResult.fold(
      (failure) => Left(failure),
      (companions) => statsResult.fold(
        (failure) => Left(failure),
        (stats) => Right(CompanionShopData(
          availableCompanions: companions,
          userStats: stats,
        )),
      ),
    );
  }
}