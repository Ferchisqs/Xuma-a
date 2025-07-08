import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class FeedCompanionParams extends Equatable {
  final String userId;
  final String companionId;

  const FeedCompanionParams({
    required this.userId,
    required this.companionId,
  });

  @override
  List<Object> get props => [userId, companionId];
}

@injectable
class FeedCompanionUseCase implements UseCase<CompanionEntity, FeedCompanionParams> {
  final CompanionRepository repository;

  FeedCompanionUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(FeedCompanionParams params) {
    return repository.feedCompanion(params.userId, params.companionId);
  }
}