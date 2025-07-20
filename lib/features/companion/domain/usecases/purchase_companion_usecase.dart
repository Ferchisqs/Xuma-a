import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/companion_entity.dart';
import '../repositories/companion_repository.dart';

class PurchaseCompanionParams extends Equatable {
  final String userId;
  final String companionId;
  final String? nickname;   

  const PurchaseCompanionParams({
    required this.userId,
    required this.companionId,
    this.nickname,
  });

  @override
  List<Object?> get props => [userId, companionId, nickname];
}

@injectable
class PurchaseCompanionUseCase implements UseCase<CompanionEntity, PurchaseCompanionParams> {
  final CompanionRepository repository;

  PurchaseCompanionUseCase(this.repository);

  @override
  Future<Either<Failure, CompanionEntity>> call(PurchaseCompanionParams params) async {
    // 🔥 USAR EL MÉTODO DE ADOPCIÓN ACTUALIZADO
    return repository.adoptCompanion(
      userId: params.userId,
      petId: params.companionId,
      nickname: params.nickname,
    );
  }
}