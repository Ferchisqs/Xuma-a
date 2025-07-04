import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_progress_model.dart';

abstract class LearningRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<LessonModel>> getLessonsByCategory(String categoryId);
  Future<LessonModel> getLessonContent(String lessonId);
  Future<LessonProgressModel> getLessonProgress(String lessonId, String userId);
  Future<void> updateLessonProgress(LessonProgressModel progress);
  Future<void> completeLesson(String lessonId, String userId);
  Future<List<LessonModel>> searchLessons(String query, String? categoryId);
}

@Injectable(as: LearningRemoteDataSource)
class LearningRemoteDataSourceImpl implements LearningRemoteDataSource {
  final ApiClient apiClient;

  LearningRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get('/learning/categories');
      final List<dynamic> categoriesJson = response.data['data'];
      return categoriesJson
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching categories: ${e.toString()}');
    }
  }

  @override
  Future<List<LessonModel>> getLessonsByCategory(String categoryId) async {
    try {
      final response = await apiClient.get('/learning/categories/$categoryId/lessons');
      final List<dynamic> lessonsJson = response.data['data'];
      return lessonsJson
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching lessons: ${e.toString()}');
    }
  }

  @override
  Future<LessonModel> getLessonContent(String lessonId) async {
    try {
      final response = await apiClient.get('/learning/lessons/$lessonId');
      return LessonModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error fetching lesson content: ${e.toString()}');
    }
  }

  @override
  Future<LessonProgressModel> getLessonProgress(String lessonId, String userId) async {
    try {
      final response = await apiClient.get('/learning/progress/$lessonId/$userId');
      return LessonProgressModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error fetching lesson progress: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLessonProgress(LessonProgressModel progress) async {
    try {
      await apiClient.put(
        '/learning/progress/${progress.lessonId}',
        data: progress.toJson(),
      );
    } catch (e) {
      throw ServerException('Error updating lesson progress: ${e.toString()}');
    }
  }

  @override
  Future<void> completeLesson(String lessonId, String userId) async {
    try {
      await apiClient.post(
        '/learning/lessons/$lessonId/complete',
        data: {'userId': userId},
      );
    } catch (e) {
      throw ServerException('Error completing lesson: ${e.toString()}');
    }
  }

  @override
  Future<List<LessonModel>> searchLessons(String query, String? categoryId) async {
    try {
      final Map<String, dynamic> queryParams = {'q': query};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      
      final response = await apiClient.get(
        '/learning/search',
        queryParameters: queryParams,
      );
      
      final List<dynamic> lessonsJson = response.data['data'];
      return lessonsJson
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error searching lessons: ${e.toString()}');
    }
  }
}