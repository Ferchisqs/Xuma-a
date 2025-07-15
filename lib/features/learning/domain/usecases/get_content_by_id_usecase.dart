import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/content_repository.dart';

class GetContentByIdParams extends Equatable {
  final String id;

  const GetContentByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}

@injectable
class GetContentByIdUseCase implements UseCase<ContentEntity, GetContentByIdParams> {
  final ContentRepository repository;

  GetContentByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ContentEntity>> call(GetContentByIdParams params) {
    return repository.getContentById(params.id);
  }
}