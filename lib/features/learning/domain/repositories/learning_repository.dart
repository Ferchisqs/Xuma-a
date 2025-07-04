import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../entities/lesson_entity.dart';
import '../entities/lesson_progress_entity.dart';

abstract class LearningRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(String categoryId);
  Future<Either<Failure, LessonEntity>> getLessonContent(String lessonId);
  Future<Either<Failure, LessonProgressEntity>> getLessonProgress(String lessonId, String userId);
  Future<Either<Failure, void>> updateLessonProgress(LessonProgressEntity progress);
  Future<Either<Failure, void>> completeLesson(String lessonId, String userId);
  Future<Either<Failure, List<LessonEntity>>> searchLessons(String query, String? categoryId);
}
