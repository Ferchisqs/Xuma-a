import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trivia_category_model.dart';
import '../models/trivia_question_model.dart';

abstract class TriviaRemoteDataSource {
  Future<List<TriviaCategoryModel>> getCategories();
  Future<List<TriviaQuestionModel>> getQuestionsByCategory(String categoryId);
}

@Injectable(as: TriviaRemoteDataSource)
class TriviaRemoteDataSourceImpl implements TriviaRemoteDataSource {
  final ApiClient apiClient;

  TriviaRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TriviaCategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get('/trivia/categories');
      final List<dynamic> categoriesJson = response.data['data'];
      return categoriesJson
          .map((json) => TriviaCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching trivia categories: ${e.toString()}');
    }
  }

  @override
  Future<List<TriviaQuestionModel>> getQuestionsByCategory(String categoryId) async {
    try {
      final response = await apiClient.get('/trivia/categories/$categoryId/questions');
      final List<dynamic> questionsJson = response.data['data'];
      return questionsJson
          .map((json) => TriviaQuestionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching trivia questions: ${e.toString()}');
    }
  }
}