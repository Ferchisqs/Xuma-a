import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class SimulateTimePassageParams extends Equatable {
  final String userId;
  final String petId;

  const SimulateTimePassageParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class SimulateTimePassageUseCase implements UseCase<CompanionEntity, SimulateTimePassageParams> {
  final CompanionRepository repository;

  SimulateTimePassageUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(SimulateTimePassageParams params) {
    return repository.simulateTimePassage(
      userId: params.userId,
      petId: params.petId,
    );
  }
}