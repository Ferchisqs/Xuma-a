// lib/features/challenges/domain/usecases/get_challenge_categories_usecase.dart - NUEVO
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../learning/data/models/topic_model.dart';
import '../repositories/challenges_repository.dart';

@injectable
class GetChallengeCategoriesUseCase implements NoParamsUseCase<List<TopicModel>> {
  final ChallengesRepository repository;

  GetChallengeCategoriesUseCase(this.repository) {
    print('✅ [GET CHALLENGE CATEGORIES USE CASE] Constructor - Using topics as categories');
  }

  @override
  Future<Either<Failure, List<TopicModel>>> call() {
    print('🎯 [GET CHALLENGE CATEGORIES USE CASE] Executing - fetching topics as challenge categories');
    
    // Necesitamos agregar este método al repository
    // return repository.getChallengeCategories();
    
    // Por ahora, hacer un cast del repository para acceder al método
    final repositoryImpl = repository as dynamic;
    return repositoryImpl.getChallengeCategories();
  }
}