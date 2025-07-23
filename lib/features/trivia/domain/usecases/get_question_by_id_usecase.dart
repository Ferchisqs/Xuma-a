// lib/features/trivia/domain/usecases/get_question_by_id_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class GetQuestionByIdParams extends Equatable {
  final String questionId;

  const GetQuestionByIdParams({required this.questionId});

  @override
  List<Object> get props => [questionId];
}

@injectable
class GetQuestionByIdUseCase implements UseCase<Map<String, dynamic>, GetQuestionByIdParams> {
  final QuizRepository repository;

  GetQuestionByIdUseCase(this.repository) {
    print('✅ [GET QUESTION BY ID USE CASE] Constructor called');
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetQuestionByIdParams params) {
    print('🎯 [GET QUESTION BY ID USE CASE] Executing for question: ${params.questionId}');
    return repository.getQuestionById(params.questionId);
  }
}