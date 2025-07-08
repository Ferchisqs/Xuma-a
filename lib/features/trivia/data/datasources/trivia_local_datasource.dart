// lib/features/trivia/data/datasources/trivia_local_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trivia_category_model.dart';
import '../models/trivia_question_model.dart';
import '../models/trivia_result_model.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';

abstract class TriviaLocalDataSource {
  Future<List<TriviaCategoryModel>> getCachedCategories();
  Future<void> cacheCategories(List<TriviaCategoryModel> categories);
  Future<List<TriviaQuestionModel>> getCachedQuestions(String categoryId);
  Future<void> cacheQuestions(String categoryId, List<TriviaQuestionModel> questions);
  Future<List<TriviaResultModel>> getCachedResults(String userId);
  Future<void> cacheResult(TriviaResultModel result);
}

@Injectable(as: TriviaLocalDataSource)
class TriviaLocalDataSourceImpl implements TriviaLocalDataSource {
  final CacheService cacheService;
  
  static const String _categoriesKey = 'trivia_categories';
  static const String _questionsPrefix = 'trivia_questions_';
  static const String _resultsPrefix = 'trivia_results_';

  TriviaLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<TriviaCategoryModel>> getCachedCategories() async {
    try {
      final categoriesJson = await cacheService.getList(_categoriesKey);
      if (categoriesJson == null || categoriesJson.isEmpty) {
        return _getMockCategories();
      }
      return categoriesJson
          .map((json) => TriviaCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockCategories();
    }
  }

  @override
  Future<void> cacheCategories(List<TriviaCategoryModel> categories) async {
    try {
      final categoriesJson = categories.map((category) => category.toJson()).toList();
      await cacheService.setList(_categoriesKey, categoriesJson);
    } catch (e) {
      throw CacheException('Error caching trivia categories: ${e.toString()}');
    }
  }

  @override
  Future<List<TriviaQuestionModel>> getCachedQuestions(String categoryId) async {
    try {
      final questionsJson = await cacheService.getList('$_questionsPrefix$categoryId');
      if (questionsJson == null || questionsJson.isEmpty) {
        return _getMockQuestions(categoryId);
      }
      return questionsJson
          .map((json) => TriviaQuestionModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockQuestions(categoryId);
    }
  }

  @override
  Future<void> cacheQuestions(String categoryId, List<TriviaQuestionModel> questions) async {
    try {
      final questionsJson = questions.map((question) => question.toJson()).toList();
      await cacheService.setList('$_questionsPrefix$categoryId', questionsJson);
    } catch (e) {
      throw CacheException('Error caching trivia questions: ${e.toString()}');
    }
  }

  @override
  Future<List<TriviaResultModel>> getCachedResults(String userId) async {
    try {
      final resultsJson = await cacheService.getList('$_resultsPrefix$userId');
      if (resultsJson == null) return [];
      return resultsJson
          .map((json) => TriviaResultModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheResult(TriviaResultModel result) async {
    try {
      // Obtener resultados existentes
      final existingResults = await getCachedResults(result.userId);
      existingResults.add(result);
      
      // Guardar lista actualizada
      final resultsJson = existingResults.map((r) => r.toJson()).toList();
      await cacheService.setList('${_resultsPrefix}${result.userId}', resultsJson);
    } catch (e) {
      throw CacheException('Error caching trivia result: ${e.toString()}');
    }
  }

  // 🎯 MOCK DATA COMPLETO
  List<TriviaCategoryModel> _getMockCategories() {
    return [
      TriviaCategoryModel(
        id: 'trivia_cat_1',
        title: 'Composta en casa',
        description: 'Aprende sobre compostaje doméstico y sus beneficios para el medio ambiente',
        imageUrl: 'assets/images/compost_trivia.jpg',
        iconCode: 0xe1b1, // Icons.compost
        questionsCount: 15,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.easy,
        pointsPerQuestion: 5,
        timePerQuestion: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TriviaCategoryModel(
        id: 'trivia_cat_2',
        title: 'Reciclaje Básico',
        description: 'Conoce los fundamentos del reciclaje y clasificación de residuos',
        imageUrl: 'assets/images/recycling_trivia.jpg',
        iconCode: 0xe567, // Icons.recycling
        questionsCount: 15,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.easy,
        pointsPerQuestion: 5,
        timePerQuestion: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TriviaCategoryModel(
        id: 'trivia_cat_3',
        title: 'Ahorro de Energía',
        description: 'Aprende técnicas para ahorrar energía en tu hogar',
        imageUrl: 'assets/images/energy_trivia.jpg',
        iconCode: 0xe1ac, // Icons.energy_savings_leaf
        questionsCount: 12,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.medium,
        pointsPerQuestion: 8,
        timePerQuestion: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TriviaCategoryModel(
        id: 'trivia_cat_4',
        title: 'Cuidado del Agua',
        description: 'Conservación y uso responsable del agua',
        imageUrl: 'assets/images/water_trivia.jpg',
        iconCode: 0xe798, // Icons.water_drop
        questionsCount: 10,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.medium,
        pointsPerQuestion: 7,
        timePerQuestion: 28,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TriviaQuestionModel> _getMockQuestions(String categoryId) {
    switch (categoryId) {
      case 'trivia_cat_1': // Composta en casa
        return [
          TriviaQuestionModel(
            id: 'q1_composta_1',
            categoryId: categoryId,
            question: '¿Para qué sirve el realizar composta en casa?',
            options: [
              'Para poder usarlo como fertilizante',
              'Para decorar el jardín',
              'Para alimentar mascotas',
              'Para hacer artesanías'
            ],
            correctAnswerIndex: 0,
            explanation: 'La composta es un excelente fertilizante natural que mejora la calidad del suelo y ayuda al crecimiento de las plantas.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
          TriviaQuestionModel(
            id: 'q1_composta_2',
            categoryId: categoryId,
            question: '¿Cuáles materiales NO deben ir en la composta?',
            options: [
              'Cáscaras de frutas',
              'Carnes y lácteos',
              'Hojas secas',
              'Restos de verduras'
            ],
            correctAnswerIndex: 1,
            explanation: 'Las carnes y lácteos pueden atraer plagas y generar malos olores en la composta.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
          TriviaQuestionModel(
            id: 'q1_composta_3',
            categoryId: categoryId,
            question: '¿Cuánto tiempo tarda en estar lista una composta casera?',
            options: [
              '1-2 semanas',
              '3-6 meses',
              '1 año',
              '2-3 días'
            ],
            correctAnswerIndex: 1,
            explanation: 'Una composta casera típicamente tarda entre 3-6 meses en descomponerse completamente y estar lista para usar.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.medium,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
        ];

      case 'trivia_cat_2': // Reciclaje Básico
        return [
          TriviaQuestionModel(
            id: 'q2_recicle_1',
            categoryId: categoryId,
            question: '¿En qué contenedor se depositan las botellas de plástico?',
            options: [
              'Contenedor amarillo',
              'Contenedor azul',
              'Contenedor verde',
              'Contenedor gris'
            ],
            correctAnswerIndex: 0,
            explanation: 'Las botellas de plástico van en el contenedor amarillo destinado a envases y plásticos.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
          TriviaQuestionModel(
            id: 'q2_recicle_2',
            categoryId: categoryId,
            question: '¿Cuál es el símbolo del reciclaje?',
            options: [
              'Un círculo verde',
              'Tres flechas formando un triángulo',
              'Una hoja',
              'Un corazón'
            ],
            correctAnswerIndex: 1,
            explanation: 'El símbolo del reciclaje son tres flechas que forman un triángulo, representando el ciclo de reutilización.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
        ];

      case 'trivia_cat_3': // Ahorro de Energía
        return [
          TriviaQuestionModel(
            id: 'q3_energia_1',
            categoryId: categoryId,
            question: '¿Qué tipo de bombillas consumen menos energía?',
            options: [
              'Bombillas incandescentes',
              'Bombillas LED',
              'Bombillas halógenas',
              'Bombillas fluorescentes'
            ],
            correctAnswerIndex: 1,
            explanation: 'Las bombillas LED consumen hasta 80% menos energía que las incandescentes tradicionales.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 8,
            timeLimit: 25,
            createdAt: DateTime.now(),
          ),
        ];

      case 'trivia_cat_4': // Cuidado del Agua
        return [
          TriviaQuestionModel(
            id: 'q4_agua_1',
            categoryId: categoryId,
            question: '¿Aproximadamente cuánta agua se gasta en una ducha de 5 minutos?',
            options: [
              '50-75 litros',
              '10-20 litros',
              '100-150 litros',
              '200-300 litros'
            ],
            correctAnswerIndex: 0,
            explanation: 'Una ducha promedio de 5 minutos consume entre 50-75 litros de agua.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.medium,
            points: 7,
            timeLimit: 28,
            createdAt: DateTime.now(),
          ),
        ];

      default:
        return [
          TriviaQuestionModel(
            id: 'default_question',
            categoryId: categoryId,
            question: '¿Cuál es una acción importante para cuidar el medio ambiente?',
            options: [
              'Reciclar correctamente',
              'Desperdiciar recursos',
              'Contaminar el agua',
              'Talar árboles'
            ],
            correctAnswerIndex: 0,
            explanation: 'Reciclar correctamente es una de las acciones más importantes para cuidar nuestro planeta.',
            type: QuestionType.multipleChoice,
            difficulty: TriviaDifficulty.easy,
            points: 5,
            timeLimit: 30,
            createdAt: DateTime.now(),
          ),
        ];
    }
  }
}