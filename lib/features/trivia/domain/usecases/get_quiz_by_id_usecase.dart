// lib/features/trivia/domain/usecases/get_quiz_by_id_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class GetQuizByIdParams extends Equatable {
  final String quizId;

  const GetQuizByIdParams({required this.quizId});

  @override
  List<Object> get props => [quizId];
}

@injectable
class GetQuizByIdUseCase implements UseCase<Map<String, dynamic>, GetQuizByIdParams> {
  final QuizRepository repository;

  GetQuizByIdUseCase(this.repository) {
    print('✅ [GET QUIZ BY ID USE CASE] Constructor called');
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetQuizByIdParams params) {
    print('🎯 [GET QUIZ BY ID USE CASE] Executing for quiz: ${params.quizId}');
    return repository.getQuizById(params.quizId);
  }
}



