
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class FeedCompanionViaApiParams extends Equatable {
  final String userId;
  final String petId;

  const FeedCompanionViaApiParams({
    required this.userId,
    required this.petId,
  });

  @override
  List<Object> get props => [userId, petId];
}

@injectable
class FeedCompanionViaApiUseCase implements UseCase<CompanionEntity, FeedCompanionViaApiParams> {
  final CompanionRepository repository;

  FeedCompanionViaApiUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(FeedCompanionViaApiParams params) {
    return repository.feedCompanionViaApi(
      userId: params.userId,
      petId: params.petId,
    );
  }
}
  