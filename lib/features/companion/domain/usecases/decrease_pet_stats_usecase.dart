import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class DecreasePetStatsParams extends Equatable {
  final String userId;
  final String petId;
  final int? happiness;
  final int? health;

  const DecreasePetStatsParams({
    required this.userId,
    required this.petId,
    this.happiness,
    this.health,
  });

  @override
  List<Object?> get props => [userId, petId, happiness, health];
}

@injectable
class DecreasePetStatsUseCase implements UseCase<CompanionEntity, DecreasePetStatsParams> {
  final CompanionRepository repository;

  DecreasePetStatsUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(DecreasePetStatsParams params) {
    return repository.decreasePetStats(
      userId: params.userId,
      petId: params.petId,
      happiness: params.happiness,
      health: params.health,
    );
  }
}