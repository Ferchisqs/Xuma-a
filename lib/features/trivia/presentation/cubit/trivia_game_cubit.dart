// lib/features/trivia/presentation/cubit/trivia_game_cubit.dart - CON FALLBACK
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/trivia_result_entity.dart';
import '../../domain/usecases/get_trivia_questions_usecase.dart';
import '../../domain/usecases/submit_trivia_result_usecase.dart';

// States
abstract class TriviaGameState extends Equatable {
  const TriviaGameState();

  @override
  List<Object?> get props => [];
}

class TriviaGameInitial extends TriviaGameState {}

class TriviaGameLoading extends TriviaGameState {}

class TriviaGameReady extends TriviaGameState {
  final TriviaCategoryEntity category;
  final List<TriviaQuestionEntity> questions;
  final int currentQuestionIndex;
  final int? selectedAnswer;
  final int timeRemaining;
  final bool isAnswered;

  const TriviaGameReady({
    required this.category,
    required this.questions,
    required this.currentQuestionIndex,
    this.selectedAnswer,
    required this.timeRemaining,
    required this.isAnswered,
  });

  TriviaQuestionEntity get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  double get progress => (currentQuestionIndex + 1) / questions.length;

  @override
  List<Object?> get props => [
    category, questions, currentQuestionIndex, selectedAnswer, 
    timeRemaining, isAnswered
  ];
}

class TriviaGameCompleted extends TriviaGameState {
  final TriviaResultEntity result;

  const TriviaGameCompleted({required this.result});

  @override
  List<Object> get props => [result];
}

class TriviaGameError extends TriviaGameState {
  final String message;

  const TriviaGameError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class TriviaGameCubit extends Cubit<TriviaGameState> {
  final GetTriviaQuestionsUseCase getTriviaQuestionsUseCase;
  final SubmitTriviaResultUseCase submitTriviaResultUseCase;

  static const String _defaultUserId = 'user_123';
  
  List<int> _userAnswers = [];
  DateTime? _startTime;

  TriviaGameCubit({
    required this.getTriviaQuestionsUseCase,
    required this.submitTriviaResultUseCase,
  }) : super(TriviaGameInitial());

  Future<void> startTrivia(TriviaCategoryEntity category) async {
    emit(TriviaGameLoading());
    _startTime = DateTime.now();
    _userAnswers.clear();

    print('🎯 [TRIVIA GAME] Starting trivia for category: ${category.id}');

    // Intentar obtener preguntas del API
    final result = await getTriviaQuestionsUseCase(
      GetTriviaQuestionsParams(categoryId: category.id),
    );

    result.fold(
      (failure) {
        print('⚠️ [TRIVIA GAME] API failed, using mock questions: ${failure.message}');
        // Usar datos mock como fallback
        final mockQuestions = _createMockQuestions(category);
        _startTriviaWithQuestions(category, mockQuestions);
      },
      (questions) {
        print('✅ [TRIVIA GAME] API questions loaded: ${questions.length}');
        _startTriviaWithQuestions(category, questions);
      },
    );
  }

  void _startTriviaWithQuestions(TriviaCategoryEntity category, List<TriviaQuestionEntity> questions) {
    if (questions.isEmpty) {
      emit(const TriviaGameError(message: 'No hay preguntas disponibles'));
      return;
    }

    _userAnswers = List.filled(questions.length, -1);
    emit(TriviaGameReady(
      category: category,
      questions: questions,
      currentQuestionIndex: 0,
      timeRemaining: category.timePerQuestion,
      isAnswered: false,
    ));
  }

  void selectAnswer(int answerIndex) {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    _userAnswers[currentState.currentQuestionIndex] = answerIndex;

    emit(TriviaGameReady(
      category: currentState.category,
      questions: currentState.questions,
      currentQuestionIndex: currentState.currentQuestionIndex,
      selectedAnswer: answerIndex,
      timeRemaining: currentState.timeRemaining,
      isAnswered: true,
    ));
  }

  void nextQuestion() {
    final currentState = state;
    if (currentState is! TriviaGameReady) return;

    if (currentState.isLastQuestion) {
      _completeTrivia();
    } else {
      emit(TriviaGameReady(
        category: currentState.category,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        timeRemaining: currentState.category.timePerQuestion,
        isAnswered: false,
      ));
    }
  }

  void timeUp() {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    // Auto-select -1 (no answer) when time is up
    _userAnswers[currentState.currentQuestionIndex] = -1;

    emit(TriviaGameReady(
      category: currentState.category,
      questions: currentState.questions,
      currentQuestionIndex: currentState.currentQuestionIndex,
      selectedAnswer: -1,
      timeRemaining: 0,
      isAnswered: true,
    ));
  }

  Future<void> _completeTrivia() async {
    final currentState = state;
    if (currentState is! TriviaGameReady) return;

    final totalTime = DateTime.now().difference(_startTime!);
    
    // Intentar enviar resultado al API
    final result = await submitTriviaResultUseCase(
      SubmitTriviaResultParams(
        userId: _defaultUserId,
        categoryId: currentState.category.id,
        questionIds: currentState.questions.map((q) => q.id).toList(),
        userAnswers: _userAnswers,
        totalTime: totalTime,
      ),
    );

    result.fold(
      (failure) {
        print('⚠️ [TRIVIA GAME] Submit failed, creating local result: ${failure.message}');
        // Crear resultado local como fallback
        final localResult = _createLocalResult(currentState, totalTime);
        emit(TriviaGameCompleted(result: localResult));
      },
      (triviaResult) {
        print('✅ [TRIVIA GAME] Result submitted successfully');
        emit(TriviaGameCompleted(result: triviaResult));
      },
    );
  }

  void updateTimer(int timeRemaining) {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    if (timeRemaining <= 0) {
      timeUp();
    } else {
      emit(TriviaGameReady(
        category: currentState.category,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex,
        selectedAnswer: currentState.selectedAnswer,
        timeRemaining: timeRemaining,
        isAnswered: currentState.isAnswered,
      ));
    }
  }

  // ==================== MÉTODOS MOCK PARA FALLBACK ====================

  List<TriviaQuestionEntity> _createMockQuestions(TriviaCategoryEntity category) {
    print('🎯 [TRIVIA GAME] Creating mock questions for category: ${category.id}');
    
    switch (category.id) {
      case 'trivia_cat_1':
      case 'a90d3ede-42ae-4b81-a185-9336ea6e195b': // Cuidado del agua
        return _createWaterQuestions(category.id);
      case 'trivia_cat_2':
        return _createRecyclingQuestions(category.id);
      case 'trivia_cat_3':
        return _createEnergyQuestions(category.id);
      case 'trivia_cat_4':
        return _createCompostQuestions(category.id);
      default:
        return _createGeneralQuestions(category.id);
    }
  }

  List<TriviaQuestionEntity> _createWaterQuestions(String categoryId) {
    return [
      TriviaQuestionEntity(
        id: '${categoryId}_q1',
        categoryId: categoryId,
        question: '¿Para qué sirve el realizar composta en casa?',
        options: [
          'Para poder usarlo como fertilizante',
          'Para decorar el jardín',
          'Para alimentar mascotas',
          'Para hacer artesanías'
        ],
        correctAnswerIndex: 0,
        explanation: 'La composta es un excelente fertilizante natural que mejora la calidad del suelo.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 5,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionEntity(
        id: '${categoryId}_q2',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q3',
        categoryId: categoryId,
        question: '¿Cuánto tiempo tarda en estar lista una composta casera?',
        options: [
          '1-2 semanas',
          '3-6 meses',
          '1 año',
          '2-3 días'
        ],
        correctAnswerIndex: 1,
        explanation: 'Una composta casera típicamente tarda entre 3-6 meses en descomponerse completamente.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 5,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionEntity(
        id: '${categoryId}_q4',
        categoryId: categoryId,
        question: '¿Qué beneficios tiene hacer composta en casa?',
        options: [
          'Solo reduce basura',
          'Reduce basura y mejora el suelo',
          'Solo mejora el suelo',
          'No tiene beneficios'
        ],
        correctAnswerIndex: 1,
        explanation: 'La composta reduce los residuos orgánicos y proporciona nutrientes al suelo.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 5,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionEntity(
        id: '${categoryId}_q5',
        categoryId: categoryId,
        question: '¿Cuál es la temperatura ideal para una composta?',
        options: [
          '10-20°C',
          '30-40°C',
          '50-60°C',
          '80-90°C'
        ],
        correctAnswerIndex: 2,
        explanation: 'La temperatura ideal para la composta está entre 50-60°C para una descomposición eficiente.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 7,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TriviaQuestionEntity> _createRecyclingQuestions(String categoryId) {
    return [
      TriviaQuestionEntity(
        id: '${categoryId}_q1',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q2',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q3',
        categoryId: categoryId,
        question: '¿Qué tipo de papel NO se puede reciclar?',
        options: [
          'Papel de periódico',
          'Papel encerado',
          'Papel de revista',
          'Papel de oficina'
        ],
        correctAnswerIndex: 1,
        explanation: 'El papel encerado no se puede reciclar debido a su recubrimiento de cera.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 7,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TriviaQuestionEntity> _createEnergyQuestions(String categoryId) {
    return [
      TriviaQuestionEntity(
        id: '${categoryId}_q1',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q2',
        categoryId: categoryId,
        question: '¿Cuál es una fuente de energía renovable?',
        options: [
          'Petróleo',
          'Carbón',
          'Energía solar',
          'Gas natural'
        ],
        correctAnswerIndex: 2,
        explanation: 'La energía solar es renovable porque proviene del sol, una fuente inagotable.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 8,
        timeLimit: 25,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TriviaQuestionEntity> _createCompostQuestions(String categoryId) {
    return [
      TriviaQuestionEntity(
        id: '${categoryId}_q1',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q2',
        categoryId: categoryId,
        question: '¿Qué porcentaje del planeta Tierra es agua?',
        options: [
          '50%',
          '60%',
          '71%',
          '85%'
        ],
        correctAnswerIndex: 2,
        explanation: 'Aproximadamente el 71% de la superficie terrestre está cubierta de agua.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 7,
        timeLimit: 28,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TriviaQuestionEntity> _createGeneralQuestions(String categoryId) {
    return [
      TriviaQuestionEntity(
        id: '${categoryId}_q1',
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
      TriviaQuestionEntity(
        id: '${categoryId}_q2',
        categoryId: categoryId,
        question: '¿Qué gas es principalmente responsable del efecto invernadero?',
        options: [
          'Oxígeno',
          'Nitrógeno',
          'Dióxido de carbono',
          'Hidrógeno'
        ],
        correctAnswerIndex: 2,
        explanation: 'El dióxido de carbono (CO2) es el principal gas responsable del efecto invernadero.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 7,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionEntity(
        id: '${categoryId}_q3',
        categoryId: categoryId,
        question: '¿Cuántos años tarda en degradarse una botella de plástico?',
        options: [
          '10 años',
          '50 años',
          '100 años',
          '450 años'
        ],
        correctAnswerIndex: 3,
        explanation: 'Una botella de plástico puede tardar hasta 450 años en degradarse completamente.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.hard,
        points: 10,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
    ];
  }

  TriviaResultEntity _createLocalResult(TriviaGameReady state, Duration totalTime) {
    // Calcular respuestas correctas
    int correctCount = 0;
    final correctAnswers = <bool>[];
    
    for (int i = 0; i < _userAnswers.length; i++) {
      final isCorrect = _userAnswers[i] == state.questions[i].correctAnswerIndex;
      correctAnswers.add(isCorrect);
      if (isCorrect) correctCount++;
    }
    
    final totalPoints = state.questions.fold<int>(0, (sum, q) => sum + q.points);
    final earnedPoints = (correctCount / state.questions.length * totalPoints).round();
    
    return TriviaResultEntity(
      id: 'local_result_${DateTime.now().millisecondsSinceEpoch}',
      userId: _defaultUserId,
      categoryId: state.category.id,
      questionIds: state.questions.map((q) => q.id).toList(),
      userAnswers: _userAnswers,
      correctAnswers: correctAnswers,
      totalQuestions: state.questions.length,
      correctCount: correctCount,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints,
      totalTime: totalTime,
      completedAt: DateTime.now(),
    );
  }
}