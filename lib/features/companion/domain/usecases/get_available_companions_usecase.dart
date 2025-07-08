import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

@injectable
class GetAvailableCompanionsUseCase implements NoParamsUseCase<List<CompanionEntity>> {
  final CompanionRepository repository;

  GetAvailableCompanionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CompanionEntity>>> call() {
    return repository.getAvailableCompanions();
  }
}