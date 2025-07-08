import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class EvolveCompanionParams extends Equatable {
  final String userId;
  final String companionId;

  const EvolveCompanionParams({
    required this.userId,
    required this.companionId,
  });

  @override
  List<Object> get props => [userId, companionId];
}

@injectable
class EvolveCompanionUseCase implements UseCase<CompanionEntity, EvolveCompanionParams> {
  final CompanionRepository repository;

  EvolveCompanionUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(EvolveCompanionParams params) {
    return repository.evolveCompanion(params.userId, params.companionId);
  }
}