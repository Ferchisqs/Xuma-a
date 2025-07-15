// lib/features/tips/domain/usecases/get_random_tip_usecase.dart
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tip_entity.dart';
import '../repositories/tips_repository.dart';

// Parámetros para el use case
class GetRandomTipParams {
  final String? category;
  final bool forceRefresh;
  
  const GetRandomTipParams({
    this.category,
    this.forceRefresh = false,
  });
}

@injectable
class GetRandomTipUseCase implements UseCase<TipEntity, GetRandomTipParams> {
  final TipsRepository _repository;
  
  GetRandomTipUseCase(this._repository);
  
  @override
  Future<Either<Failure, TipEntity>> call(GetRandomTipParams params) async {
    try {
      print('🎲 [GET RANDOM TIP] Getting random tip...');
      print('🎲 [GET RANDOM TIP] Category: ${params.category}');
      print('🎲 [GET RANDOM TIP] Force refresh: ${params.forceRefresh}');
      
      return await _repository.getRandomTip(category: params.category);
    } catch (e) {
      print('❌ [GET RANDOM TIP] Exception: $e');
      return const Left(ServerFailure('Error obteniendo tip aleatorio'));
    }
  }
}

// Use case sin parámetros para obtener cualquier tip aleatorio
@injectable
class GetRandomTipWithoutParamsUseCase implements NoParamsUseCase<TipEntity> {
  final TipsRepository _repository;
  
  GetRandomTipWithoutParamsUseCase(this._repository);
  
  @override
  Future<Either<Failure, TipEntity>> call() async {
    try {
      print('🎲 [GET RANDOM TIP NO PARAMS] Getting random tip...');
      return await _repository.getRandomTip();
    } catch (e) {
      print('❌ [GET RANDOM TIP NO PARAMS] Exception: $e');
      return const Left(ServerFailure('Error obteniendo tip aleatorio'));
    }
  }
}