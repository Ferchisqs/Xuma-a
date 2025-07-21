import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class GetUserCompanionsParams extends Equatable {
  final String userId;

  const GetUserCompanionsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetUserCompanionsUseCase
    implements UseCase<List<CompanionEntity>, GetUserCompanionsParams> {
  final CompanionRepository repository;

  GetUserCompanionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CompanionEntity>>> call(
      GetUserCompanionsParams params) {
    return repository.getUserCompanions(params.userId);
  }
}
