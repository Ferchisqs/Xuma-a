
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class FeatureCompanionParams extends Equatable {
  final String userId;
  final String petId;

  const FeatureCompanionParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class FeatureCompanionUseCase implements UseCase<CompanionEntity, FeatureCompanionParams> {
  final CompanionRepository repository;

  FeatureCompanionUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(FeatureCompanionParams params) {
    return repository.featureCompanion(
      userId: params.userId,
      petId: params.petId,
    );
  }
}