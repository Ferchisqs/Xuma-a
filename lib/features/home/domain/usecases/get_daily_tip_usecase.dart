import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/eco_tip_entity.dart';
import '../repositories/home_repository.dart';

@lazySingleton
class GetDailyTipUseCase implements NoParamsUseCase<EcoTipEntity> {
  final HomeRepository _repository;

  GetDailyTipUseCase(this._repository);

  @override
  Future<Either<Failure, EcoTipEntity>> call() async {
    return await _repository.getDailyTip();
  }
}