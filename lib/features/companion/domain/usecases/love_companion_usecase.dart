import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class LoveCompanionParams extends Equatable {
  final String userId;
  final String companionId;

  const LoveCompanionParams({
    required this.userId,
    required this.companionId,
  });

  @override
  List<Object> get props => [userId, companionId];
}

@injectable
class LoveCompanionUseCase implements UseCase<CompanionEntity, LoveCompanionParams> {
  final CompanionRepository repository;

  LoveCompanionUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(LoveCompanionParams params) {
    return repository.loveCompanion(params.userId, params.companionId);
  }
}