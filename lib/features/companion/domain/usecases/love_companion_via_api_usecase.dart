import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class LoveCompanionViaApiParams extends Equatable {
  final String userId;
  final String petId;

  const LoveCompanionViaApiParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class LoveCompanionViaApiUseCase implements UseCase<CompanionEntity, LoveCompanionViaApiParams> {
  final CompanionRepository repository;

  LoveCompanionViaApiUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(LoveCompanionViaApiParams params) {
    return repository.loveCompanionViaApi(
      userId: params.userId,
      petId: params.petId,
    );
  }
}
