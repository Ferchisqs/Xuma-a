import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_progress_model.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/lesson_entity.dart';

abstract class LearningLocalDataSource {
  Future<List<CategoryModel>> getCachedCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<List<LessonModel>> getCachedLessonsByCategory(String categoryId);
  Future<void> cacheLessonsByCategory(String categoryId, List<LessonModel> lessons);
  Future<LessonModel?> getCachedLessonContent(String lessonId);
  Future<void> cacheLessonContent(LessonModel lesson);
  Future<LessonProgressModel?> getCachedLessonProgress(String lessonId, String userId);
  Future<void> cacheLessonProgress(LessonProgressModel progress);
  Future<List<LessonModel>> searchCachedLessons(String query, String? categoryId);
}

@Injectable(as: LearningLocalDataSource)
class LearningLocalDataSourceImpl implements LearningLocalDataSource {
  final CacheService cacheService;
  
  static const String _categoriesKey = 'learning_categories';
  static const String _lessonsPrefix = 'learning_lessons_';
  static const String _lessonContentPrefix = 'learning_content_';
  static const String _progressPrefix = 'learning_progress_';

  LearningLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final categoriesJson = await cacheService.getList(_categoriesKey);
      if (categoriesJson == null || categoriesJson.isEmpty) {
        return _getMockCategories();
      }
      return categoriesJson
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockCategories();
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final categoriesJson = categories.map((category) => category.toJson()).toList();
      await cacheService.setList(_categoriesKey, categoriesJson);
    } catch (e) {
      throw CacheException('Error caching categories: ${e.toString()}');
    }
  }

  @override
  Future<List<LessonModel>> getCachedLessonsByCategory(String categoryId) async {
    try {
      final lessonsJson = await cacheService.getList('$_lessonsPrefix$categoryId');
      if (lessonsJson == null || lessonsJson.isEmpty) {
        return _getMockLessonsByCategory(categoryId);
      }
      return lessonsJson
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockLessonsByCategory(categoryId);
    }
  }

  @override
  Future<void> cacheLessonsByCategory(String categoryId, List<LessonModel> lessons) async {
    try {
      final lessonsJson = lessons.map((lesson) => lesson.toJson()).toList();
      await cacheService.setList('$_lessonsPrefix$categoryId', lessonsJson);
    } catch (e) {
      throw CacheException('Error caching lessons: ${e.toString()}');
    }
  }

  @override
  Future<LessonModel?> getCachedLessonContent(String lessonId) async {
    try {
      final lessonJson = await cacheService.get('$_lessonContentPrefix$lessonId');
      if (lessonJson == null) {
        return _getMockLessonContent(lessonId);
      }
      return LessonModel.fromJson(lessonJson);
    } catch (e) {
      return _getMockLessonContent(lessonId);
    }
  }

  @override
  Future<void> cacheLessonContent(LessonModel lesson) async {
    try {
      await cacheService.set('$_lessonContentPrefix${lesson.id}', lesson.toJson());
    } catch (e) {
      throw CacheException('Error caching lesson content: ${e.toString()}');
    }
  }

  @override
  Future<LessonProgressModel?> getCachedLessonProgress(String lessonId, String userId) async {
    try {
      final progressJson = await cacheService.get('$_progressPrefix${lessonId}_$userId');
      if (progressJson == null) return null;
      return LessonProgressModel.fromJson(progressJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheLessonProgress(LessonProgressModel progress) async {
    try {
      await cacheService.set(
        '$_progressPrefix${progress.lessonId}_${progress.userId}',
        progress.toJson(),
      );
    } catch (e) {
      throw CacheException('Error caching lesson progress: ${e.toString()}');
    }
  }

  @override
  Future<List<LessonModel>> searchCachedLessons(String query, String? categoryId) async {
    try {
      final allLessons = <LessonModel>[];
      
      if (categoryId != null) {
        allLessons.addAll(await getCachedLessonsByCategory(categoryId));
      } else {
        final categories = await getCachedCategories();
        for (final category in categories) {
          final lessons = await getCachedLessonsByCategory(category.id);
          allLessons.addAll(lessons);
        }
      }
      
      return allLessons
          .where((lesson) =>
              lesson.title.toLowerCase().contains(query.toLowerCase()) ||
              lesson.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Mock Data para desarrollo
  List<CategoryModel> _getMockCategories() {
    return [
      CategoryModel(
        id: 'cat_1',
        title: 'Introducción al reciclaje',
        description: 'Aprende los conceptos básicos del reciclaje y su importancia',
        imageUrl: 'assets/images/recycling_intro.jpg',
        iconCode: 0xe567, // Icons.recycling
        lessonsCount: 8,
        completedLessons: 0,
        estimatedTime: '2 horas',
        difficulty: DifficultyLevel.beginner,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      CategoryModel(
        id: 'cat_2',
        title: 'Tipos de Residuos',
        description: 'Conoce los diferentes tipos de residuos y cómo clasificarlos',
        imageUrl: 'assets/images/waste_types.jpg',
        iconCode: 0xe872, // Icons.delete_outline
        lessonsCount: 6,
        completedLessons: 0,
        estimatedTime: '1.5 horas',
        difficulty: DifficultyLevel.beginner,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      CategoryModel(
        id: 'cat_3',
        title: 'Cuidado del Agua',
        description: 'Aprende a conservar y proteger nuestros recursos hídricos',
        imageUrl: 'assets/images/water_care.jpg',
        iconCode: 0xe798, // Icons.water_drop
        lessonsCount: 7,
        completedLessons: 0,
        estimatedTime: '2.5 horas',
        difficulty: DifficultyLevel.intermediate,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      CategoryModel(
        id: 'cat_4',
        title: 'Energía y Sostenibilidad',
        description: 'Descubre cómo usar la energía de manera sostenible',
        imageUrl: 'assets/images/energy_sustainability.jpg',
        iconCode: 0xe1ac, // Icons.energy_savings_leaf
        lessonsCount: 9,
        completedLessons: 0,
        estimatedTime: '3 horas',
        difficulty: DifficultyLevel.intermediate,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      CategoryModel(
        id: 'cat_5',
        title: 'Huella de carbono y cambio climático',
        description: 'Entiende tu impacto ambiental y cómo reducirlo',
        imageUrl: 'assets/images/carbon_footprint.jpg',
        iconCode: 0xe1b0, // Icons.co2
        lessonsCount: 10,
        completedLessons: 0,
        estimatedTime: '4 horas',
        difficulty: DifficultyLevel.advanced,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      CategoryModel(
        id: 'cat_6',
        title: 'Reutilización y Creatividad',
        description: 'Transforma residuos en objetos útiles y creativos',
        imageUrl: 'assets/images/reuse_creativity.jpg',
        iconCode: 0xe1d8, // Icons.auto_fix_high
        lessonsCount: 5,
        completedLessons: 0,
        estimatedTime: '1 hora',
        difficulty: DifficultyLevel.beginner,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<LessonModel> _getMockLessonsByCategory(String categoryId) {
    final baseLessons = <LessonModel>[];
    
    switch (categoryId) {
      case 'cat_1':
        baseLessons.addAll([
          LessonModel(
            id: 'lesson_1_1',
            categoryId: categoryId,
            title: 'Reciclaje',
            description: 'Conceptos fundamentales del reciclaje',
            content: 'El reciclaje es el proceso de transformar materiales usados...',
            duration: 10,
            order: 1,
            isCompleted: false,
            points: 50,
            type: LessonType.text,
            createdAt: DateTime.now(),
          ),
          LessonModel(
            id: 'lesson_1_2',
            categoryId: categoryId,
            title: 'Reciclaje',
            description: 'Beneficios ambientales del reciclaje',
            content: 'Los beneficios del reciclaje incluyen...',
            duration: 15,
            order: 2,
            isCompleted: false,
            points: 75,
            type: LessonType.video,
            createdAt: DateTime.now(),
          ),
        ]);
        break;
      default:
        for (int i = 1; i <= 6; i++) {
          baseLessons.add(
            LessonModel(
              id: 'lesson_${categoryId}_$i',
              categoryId: categoryId,
              title: 'Reciclaje',
              description: 'Lección $i de la categoría',
              content: 'Contenido de la lección $i...',
              duration: 10 + (i * 2),
              order: i,
              isCompleted: false,
              points: 50 + (i * 10),
              type: i % 2 == 0 ? LessonType.video : LessonType.text,
              createdAt: DateTime.now(),
            ),
          );
        }
    }
    
    return baseLessons;
  }

  LessonModel? _getMockLessonContent(String lessonId) {
    return LessonModel(
      id: lessonId,
      categoryId: 'cat_1',
      title: 'Título',
      description: 'Descripción de la lección',
      content: '''
# Contenido de la Lección

Este es el contenido detallado de la lección con información educativa sobre el tema.

## Puntos importantes:
- Punto 1
- Punto 2
- Punto 3

¡Aprende y protege el medio ambiente!
      ''',
      imageUrl: 'assets/images/lesson_placeholder.jpg',
      duration: 15,
      order: 1,
      isCompleted: false,
      points: 100,
      type: LessonType.text,
      createdAt: DateTime.now(),
    );
  }
}