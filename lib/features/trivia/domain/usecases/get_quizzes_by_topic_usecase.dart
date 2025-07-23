// lib/features/trivia/domain/usecases/get_quizzes_by_topic_usecase.dart - NUEVO
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class GetQuizzesByTopicParams extends Equatable {
  final String topicId;

  const GetQuizzesByTopicParams({required this.topicId});

  @override
  List<Object> get props => [topicId];
}

@injectable
class GetQuizzesByTopicUseCase implements UseCase<List<Map<String, dynamic>>, GetQuizzesByTopicParams> {
  final QuizRepository repository;

  GetQuizzesByTopicUseCase(this.repository) {
    print('✅ [GET QUIZZES BY TOPIC USE CASE] Constructor called');
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetQuizzesByTopicParams params) {
    print('🎯 [GET QUIZZES BY TOPIC USE CASE] Executing for topic: ${params.topicId}');
    return repository.getQuizzesByTopic(params.topicId);
  }
}