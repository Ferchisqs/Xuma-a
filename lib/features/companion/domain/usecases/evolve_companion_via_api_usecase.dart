
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class EvolveCompanionViaApiParams extends Equatable {
  final String userId;
  final String petId;

  const EvolveCompanionViaApiParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class EvolveCompanionViaApiUseCase implements UseCase<CompanionEntity, EvolveCompanionViaApiParams> {
  final CompanionRepository repository;

  EvolveCompanionViaApiUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(EvolveCompanionViaApiParams params) {
    return repository.evolveCompanionViaApi(
      userId: params.userId,
      petId: params.petId,
    );
  }
}