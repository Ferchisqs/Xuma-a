// lib/features/learning/domain/usecases/get_contents_by_topic_usecase.dart - CORREGIDO
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/content_entity.dart';
import '../repositories/content_repository.dart';

class GetContentsByTopicParams extends Equatable {
  final String topicId;
  final int page;
  final int limit;

  const GetContentsByTopicParams({
    required this.topicId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object> get props => [topicId, page, limit];
}

// 🔧 ASEGURAR QUE TENGA @injectable
@injectable
class GetContentsByTopicUseCase implements UseCase<List<ContentEntity>, GetContentsByTopicParams> {
  final ContentRepository repository;

  GetContentsByTopicUseCase(this.repository) {
    print('✅ [GET CONTENTS BY TOPIC USE CASE] Constructor called - UseCase created successfully');
  }

  @override
  Future<Either<Failure, List<ContentEntity>>> call(GetContentsByTopicParams params) {
    print('🎯 [GET CONTENTS BY TOPIC USE CASE] Executing with params: topicId=${params.topicId}, page=${params.page}, limit=${params.limit}');
    return repository.getContentsByTopicId(
      params.topicId, 
      params.page, 
      params.limit,
    );
  }
}