// lib/features/trivia/domain/usecases/get_user_quiz_progress_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class GetUserQuizProgressParams extends Equatable {
  final String userId;

  const GetUserQuizProgressParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetUserQuizProgressUseCase implements UseCase<Map<String, dynamic>, GetUserQuizProgressParams> {
  final QuizRepository repository;

  GetUserQuizProgressUseCase(this.repository) {
    print('✅ [GET USER QUIZ PROGRESS USE CASE] Constructor called');
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetUserQuizProgressParams params) {
    print('🎯 [GET USER QUIZ PROGRESS USE CASE] Executing for user: ${params.userId}');
    return repository.getUserQuizProgress(params.userId);
  }
}