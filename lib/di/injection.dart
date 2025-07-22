import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

import '../core/network/api_client.dart';
import '../core/services/token_manager.dart';

// Content imports
import '../features/learning/data/datasources/content_remote_datasource.dart';
import '../features/learning/data/repositories/content_repository_impl.dart';
import '../features/learning/domain/repositories/content_repository.dart';
import '../features/learning/domain/usecases/get_topics_usecase.dart';
import '../features/learning/domain/usecases/get_content_by_id_usecase.dart';
import '../features/learning/domain/usecases/get_contents_by_topic_usecase.dart';
import '../features/learning/presentation/cubit/content_cubit.dart';
import '../features/learning/presentation/cubit/topic_contents_cubit.dart';

// Learning imports
import '../features/learning/data/datasources/learning_remote_datasource.dart';
import '../features/learning/data/repositories/learning_repository_impl.dart';
import '../features/learning/domain/repositories/learning_repository.dart';
import '../features/learning/domain/usecases/get_categories_usecase.dart';
import '../features/learning/domain/usecases/get_lessons_by_category_usecase.dart';
import '../features/learning/domain/usecases/get_lesson_content_usecase.dart';
import '../features/learning/domain/usecases/update_lesson_progress_usecase.dart';
import '../features/learning/domain/usecases/complete_lesson_usecase.dart';
import '../features/learning/domain/usecases/search_lessons_usecase.dart';
import '../features/learning/presentation/cubit/learning_cubit.dart';
import '../features/learning/presentation/cubit/lesson_list_cubit.dart';
import '../features/learning/presentation/cubit/lesson_content_cubit.dart';

// Media imports
import '../features/learning/data/datasources/media_remote_datasource.dart';

// 🆕 COMPANION IMPORTS - INTEGRACIÓN CON API REAL Y NUEVOS USE CASES
import '../features/companion/data/datasources/companion_remote_datasource.dart';
import '../features/companion/data/datasources/companion_local_datasource.dart';
import '../features/companion/data/repositories/companion_repository_impl.dart';
import '../features/companion/domain/repositories/companion_repository.dart';
import '../features/companion/domain/usecases/get_user_companions_usecase.dart';
import '../features/companion/domain/usecases/get_available_companions_usecase.dart';
import '../features/companion/domain/usecases/get_companion_shop_usecase.dart';
import '../features/companion/domain/usecases/purchase_companion_usecase.dart';
import '../features/companion/domain/usecases/evolve_companion_usecase.dart';
import '../features/companion/domain/usecases/feed_companion_usecase.dart';
import '../features/companion/domain/usecases/love_companion_usecase.dart';
// 🔧 NUEVOS IMPORTS - USE CASES AGREGADOS
import '../features/companion/domain/usecases/evolve_companion_via_api_usecase.dart';
import '../features/companion/domain/usecases/feature_companion_usecase.dart';
import '../features/companion/presentation/cubit/companion_cubit.dart';
import '../features/companion/presentation/cubit/companion_shop_cubit.dart';
import '../features/companion/presentation/cubit/companion_detail_cubit.dart';

// News feature imports
import '../features/news/data/datasources/news_remote_datasource.dart';
import '../features/news/data/datasources/news_local_datasource.dart';
import '../features/news/data/repositories/news_repository_impl.dart';
import '../features/news/domain/repositories/news_repository.dart';
import '../features/news/domain/usecases/get_climate_news_usecase.dart';
import '../features/news/domain/usecases/get_cached_news_usecase.dart';
import '../features/news/domain/usecases/refresh_news_usecase.dart';
import '../features/news/presentation/cubit/news_cubit.dart';

// 🆕 QUIZ IMPORTS - INTEGRACIÓN CON QUIZ API
import '../features/trivia/data/datasources/quiz_remote_datasource.dart';
import '../features/trivia/data/repositories/quiz_repository_impl.dart';
import '../features/trivia/domain/repositories/quiz_repository.dart';
import '../features/trivia/domain/usecases/start_quiz_session_usecase.dart';
import '../features/trivia/domain/usecases/submit_quiz_answer_usecase.dart';
import '../features/trivia/domain/usecases/get_quiz_results_usecase.dart';
import '../features/trivia/domain/usecases/get_quiz_questions_usecase.dart';
import '../features/trivia/presentation/cubit/quiz_session_cubit.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  print('🔧 [INJECTION] === STARTING DEPENDENCY CONFIGURATION WITH QUIZ INTEGRATION ===');
  
  try {
    // 1. PRIMERO: Configurar dependencias básicas con @injectable
    print('🔧 [INJECTION] Step 1: Configuring auto-generated dependencies...');
    await getIt.init();
    print('✅ [INJECTION] Step 1: Auto-generated dependencies configured');
    
    // 2. SEGUNDO: Registrar MediaRemoteDataSource ANTES de usarlo
    print('🔧 [INJECTION] Step 2: Registering media dependencies...');
    _registerMediaDependencies();
    print('✅ [INJECTION] Step 2: Media dependencies registered');
    
    // 3. TERCERO: Registrar dependencias de contenido con media
    print('🔧 [INJECTION] Step 3: Registering content dependencies with media...');
    _registerContentDependencies();
    print('✅ [INJECTION] Step 3: Content dependencies registered');
    
    // 4. CUARTO: 🆕 REGISTRAR DEPENDENCIAS DE COMPANION CON API REAL Y NUEVOS USE CASES
    print('🔧 [INJECTION] Step 4: Registering companion dependencies with enhanced API integration...');
    _registerCompanionDependencies();
    print('✅ [INJECTION] Step 4: Companion dependencies registered with new use cases');
    
    // 5. QUINTO: Registrar dependencias de learning modificadas
    print('🔧 [INJECTION] Step 5: Registering learning dependencies...');
    _registerLearningDependencies();
    print('✅ [INJECTION] Step 5: Learning dependencies registered');
    
    // 6. SEXTO: Registrar dependencias de news
    print('🔧 [INJECTION] Step 6: Registering news dependencies...');
    _registerNewsDependencies();
    print('✅ [INJECTION] Step 6: News dependencies registered');
    
    // 7. 🆕 SÉPTIMO: Registrar dependencias de QUIZ
    print('🔧 [INJECTION] Step 7: Registering quiz dependencies...');
    _registerQuizDependencies();
    print('✅ [INJECTION] Step 7: Quiz dependencies registered');
    
    // 8. VERIFICACIÓN FINAL
    print('🔍 [INJECTION] Step 8: Final verification with enhanced features...');
    _verifyDependencies();
    print('✅ [INJECTION] Step 8: All dependencies verified including quiz');
    
    print('🎉 [INJECTION] === DEPENDENCY CONFIGURATION COMPLETED WITH QUIZ INTEGRATION ===');
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] CRITICAL ERROR in configureDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== MEDIA DEPENDENCIES - PRIMERO ====================

void _registerMediaDependencies() {
  try {
    // 🆕 REGISTRAR MediaRemoteDataSource PRIMERO
    if (!getIt.isRegistered<MediaRemoteDataSource>()) {
      getIt.registerLazySingleton<MediaRemoteDataSource>(
        () => MediaRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] MediaRemoteDataSource registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerMediaDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== CONTENT DEPENDENCIES - CON MEDIA ====================

void _registerContentDependencies() {
  try {
    // Data Sources - AHORA CON MEDIA DEPENDENCY
    if (!getIt.isRegistered<ContentRemoteDataSource>()) {
      getIt.registerLazySingleton<ContentRemoteDataSource>(
        () => ContentRemoteDataSourceImpl(
          getIt<ApiClient>(),
          getIt<MediaRemoteDataSource>(), // 🆕 INYECTAR MEDIA DATASOURCE
        ),
      );
      print('✅ [INJECTION] ContentRemoteDataSource registered WITH MEDIA');
    }
    
    // Repository
    if (!getIt.isRegistered<ContentRepository>()) {
      getIt.registerLazySingleton<ContentRepository>(
        () => ContentRepositoryImpl(
          remoteDataSource: getIt<ContentRemoteDataSource>(),
          localDataSource: getIt(),
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] ContentRepository registered');
    }
    
    // Use Cases
    if (!getIt.isRegistered<GetTopicsUseCase>()) {
      getIt.registerLazySingleton<GetTopicsUseCase>(
        () => GetTopicsUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetTopicsUseCase registered');
    }
    
    if (!getIt.isRegistered<GetContentByIdUseCase>()) {
      getIt.registerLazySingleton<GetContentByIdUseCase>(
        () => GetContentByIdUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentByIdUseCase registered');
    }
    
    if (!getIt.isRegistered<GetContentsByTopicUseCase>()) {
      getIt.registerLazySingleton<GetContentsByTopicUseCase>(
        () => GetContentsByTopicUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentsByTopicUseCase registered');
    }
    
    // Cubits
    if (!getIt.isRegistered<ContentCubit>()) {
      getIt.registerFactory<ContentCubit>(
        () => ContentCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(),
          getContentByIdUseCase: getIt<GetContentByIdUseCase>(),
        ),
      );
      print('✅ [INJECTION] ContentCubit registered');
    }
    
    // 🎯 REGISTRO CRÍTICO: TopicContentsCubit
    if (!getIt.isRegistered<TopicContentsCubit>()) {
      getIt.registerFactory<TopicContentsCubit>(
        () {
          print('🏭 [INJECTION] Creating TopicContentsCubit instance...');
          return TopicContentsCubit(
            getContentsByTopicUseCase: getIt<GetContentsByTopicUseCase>(),
          );
        },
      );
      print('✅ [INJECTION] TopicContentsCubit registered as factory');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerContentDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== 🆕 COMPANION DEPENDENCIES - CON API REAL Y NUEVOS USE CASES ====================

void _registerCompanionDependencies() {
  try {
    print('🐾 [INJECTION] === REGISTERING COMPANION DEPENDENCIES WITH ENHANCED API ===');

    // 🆕 Data Sources - REMOTE CON API REAL Y TOKEN MANAGER
    if (!getIt.isRegistered<CompanionRemoteDataSource>()) {
      getIt.registerLazySingleton<CompanionRemoteDataSource>(
        () => CompanionRemoteDataSourceImpl(
          getIt<ApiClient>(),
          getIt<TokenManager>(), // 🔧 INYECTAR TOKEN MANAGER
        ),
      );
      print('✅ [INJECTION] CompanionRemoteDataSource registered WITH API CLIENT AND TOKEN MANAGER');
    }

    // 🆕 Data Sources - LOCAL (ya registrado en injection.config.dart si usa @injectable)
    if (!getIt.isRegistered<CompanionLocalDataSource>()) {
      getIt.registerLazySingleton<CompanionLocalDataSource>(
        () => CompanionLocalDataSourceImpl(getIt()),
      );
      print('✅ [INJECTION] CompanionLocalDataSource registered');
    }

    // 🆕 Repository CON TOKEN MANAGER
    if (!getIt.isRegistered<CompanionRepository>()) {
      getIt.registerLazySingleton<CompanionRepository>(
        () => CompanionRepositoryImpl(
          remoteDataSource: getIt<CompanionRemoteDataSource>(),
          localDataSource: getIt<CompanionLocalDataSource>(),
          networkInfo: getIt(),
          tokenManager: getIt<TokenManager>(), // 🔧 INYECTAR TOKEN MANAGER
        ),
      );
      print('✅ [INJECTION] CompanionRepository registered WITH TOKEN MANAGER');
    }

    // 🆕 Use Cases - EXISTENTES
    if (!getIt.isRegistered<GetUserCompanionsUseCase>()) {
      getIt.registerLazySingleton<GetUserCompanionsUseCase>(
        () => GetUserCompanionsUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] GetUserCompanionsUseCase registered');
    }

    if (!getIt.isRegistered<GetAvailableCompanionsUseCase>()) {
      getIt.registerLazySingleton<GetAvailableCompanionsUseCase>(
        () => GetAvailableCompanionsUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] GetAvailableCompanionsUseCase registered');
    }

    if (!getIt.isRegistered<GetCompanionShopUseCase>()) {
      getIt.registerLazySingleton<GetCompanionShopUseCase>(
        () => GetCompanionShopUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] GetCompanionShopUseCase registered');
    }

    if (!getIt.isRegistered<PurchaseCompanionUseCase>()) {
      getIt.registerLazySingleton<PurchaseCompanionUseCase>(
        () => PurchaseCompanionUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] PurchaseCompanionUseCase registered');
    }

    if (!getIt.isRegistered<EvolveCompanionUseCase>()) {
      getIt.registerLazySingleton<EvolveCompanionUseCase>(
        () => EvolveCompanionUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] EvolveCompanionUseCase registered');
    }

    if (!getIt.isRegistered<FeedCompanionUseCase>()) {
      getIt.registerLazySingleton<FeedCompanionUseCase>(
        () => FeedCompanionUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] FeedCompanionUseCase registered');
    }

    if (!getIt.isRegistered<LoveCompanionUseCase>()) {
      getIt.registerLazySingleton<LoveCompanionUseCase>(
        () => LoveCompanionUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] LoveCompanionUseCase registered');
    }

    // 🔧 NUEVOS USE CASES - REGISTROS AGREGADOS
    if (!getIt.isRegistered<EvolveCompanionViaApiUseCase>()) {
      getIt.registerLazySingleton<EvolveCompanionViaApiUseCase>(
        () => EvolveCompanionViaApiUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] EvolveCompanionViaApiUseCase registered');
    }

    if (!getIt.isRegistered<FeatureCompanionUseCase>()) {
      getIt.registerLazySingleton<FeatureCompanionUseCase>(
        () => FeatureCompanionUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] FeatureCompanionUseCase registered');
    }

    // 🆕 Cubits - ACTUALIZADOS CON TOKEN MANAGER Y NUEVOS USE CASES
    if (!getIt.isRegistered<CompanionCubit>()) {
      getIt.registerFactory<CompanionCubit>(
        () => CompanionCubit(
          getUserCompanionsUseCase: getIt<GetUserCompanionsUseCase>(),
          getCompanionShopUseCase: getIt<GetCompanionShopUseCase>(),
          tokenManager: getIt<TokenManager>(), repository: getIt<CompanionRepository>(), // 🔥 AGREGAR TOKEN MANAGER
        ),
      );
      print('✅ [INJECTION] CompanionCubit registered WITH TOKEN MANAGER');
    }

    if (!getIt.isRegistered<CompanionShopCubit>()) {
      getIt.registerFactory<CompanionShopCubit>(
        () => CompanionShopCubit(
          getCompanionShopUseCase: getIt<GetCompanionShopUseCase>(),
          purchaseCompanionUseCase: getIt<PurchaseCompanionUseCase>(),
          tokenManager: getIt<TokenManager>(), // 🔥 AGREGAR TOKEN MANAGER
        ),
      );
      print('✅ [INJECTION] CompanionShopCubit registered WITH TOKEN MANAGER');
    }

    if (!getIt.isRegistered<CompanionDetailCubit>()) {
      getIt.registerFactory<CompanionDetailCubit>(
        () => CompanionDetailCubit(
          feedCompanionUseCase: getIt<FeedCompanionUseCase>(),
          loveCompanionUseCase: getIt<LoveCompanionUseCase>(),
          evolveCompanionUseCase: getIt<EvolveCompanionUseCase>(),
          // 🔧 NUEVOS USE CASES AGREGADOS AL CUBIT
          evolveCompanionViaApiUseCase: getIt<EvolveCompanionViaApiUseCase>(),
          featureCompanionUseCase: getIt<FeatureCompanionUseCase>(),
          tokenManager: getIt<TokenManager>(), // 🔥 AGREGAR TOKEN MANAGER
        ),
      );
      print('✅ [INJECTION] CompanionDetailCubit registered WITH TOKEN MANAGER AND NEW USE CASES');
    }


    print('🎉 [INJECTION] === COMPANION DEPENDENCIES REGISTERED SUCCESSFULLY WITH ENHANCED FEATURES ===');
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerCompanionDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== LEARNING DEPENDENCIES ====================

void _registerLearningDependencies() {
  try {
    // ⚠️ IMPORTANTE: NO registrar LearningLocalDataSource manualmente
    // Ya está registrado por @injectable en injection.config.dart
    
    // Data Sources - Solo remote
    if (!getIt.isRegistered<LearningRemoteDataSource>()) {
      getIt.registerLazySingleton<LearningRemoteDataSource>(
        () => LearningRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] LearningRemoteDataSource registered');
    }
    
    // Repository
    if (!getIt.isRegistered<LearningRepository>()) {
      getIt.registerLazySingleton<LearningRepository>(
        () => LearningRepositoryImpl(
          remoteDataSource: getIt<LearningRemoteDataSource>(),
          localDataSource: getIt(), // Obtenido de injection.config.dart
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] LearningRepository registered');
    }
    
    // Use Cases (solo si no están registrados por @injectable)
    if (!getIt.isRegistered<GetCategoriesUseCase>()) {
      getIt.registerLazySingleton<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetCategoriesUseCase registered');
    }
    
    if (!getIt.isRegistered<GetLessonsByCategoryUseCase>()) {
      getIt.registerLazySingleton<GetLessonsByCategoryUseCase>(
        () => GetLessonsByCategoryUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetLessonsByCategoryUseCase registered');
    }
    
    if (!getIt.isRegistered<GetLessonContentUseCase>()) {
      getIt.registerLazySingleton<GetLessonContentUseCase>(
        () => GetLessonContentUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetLessonContentUseCase registered');
    }
    
    if (!getIt.isRegistered<UpdateLessonProgressUseCase>()) {
      getIt.registerLazySingleton<UpdateLessonProgressUseCase>(
        () => UpdateLessonProgressUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] UpdateLessonProgressUseCase registered');
    }
    
    if (!getIt.isRegistered<CompleteLessonUseCase>()) {
      getIt.registerLazySingleton<CompleteLessonUseCase>(
        () => CompleteLessonUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] CompleteLessonUseCase registered');
    }
    
    if (!getIt.isRegistered<SearchLessonsUseCase>()) {
      getIt.registerLazySingleton<SearchLessonsUseCase>(
        () => SearchLessonsUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] SearchLessonsUseCase registered');
    }
    
    // Learning Cubit MODIFICADO para usar topics
    if (!getIt.isRegistered<LearningCubit>()) {
      getIt.registerFactory<LearningCubit>(
        () => LearningCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(), // USA TOPICS EN LUGAR DE CATEGORIES
        ),
      );
      print('✅ [INJECTION] LearningCubit registered (using topics)');
    }
    
    // Otros cubits
    if (!getIt.isRegistered<LessonListCubit>()) {
      getIt.registerFactory<LessonListCubit>(
        () => LessonListCubit(
          getLessonsByCategoryUseCase: getIt<GetLessonsByCategoryUseCase>(),
          searchLessonsUseCase: getIt<SearchLessonsUseCase>(),
        ),
      );
      print('✅ [INJECTION] LessonListCubit registered');
    }
    
    if (!getIt.isRegistered<LessonContentCubit>()) {
      getIt.registerFactory<LessonContentCubit>(
        () => LessonContentCubit(
          getLessonContentUseCase: getIt<GetLessonContentUseCase>(),
          updateLessonProgressUseCase: getIt<UpdateLessonProgressUseCase>(),
          completeLessonUseCase: getIt<CompleteLessonUseCase>(),
        ),
      );
      print('✅ [INJECTION] LessonContentCubit registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerLearningDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== NEWS DEPENDENCIES ====================

void _registerNewsDependencies() {
  try {
    // Data Sources
    if (!getIt.isRegistered<NewsRemoteDataSource>()) {
      getIt.registerLazySingleton<NewsRemoteDataSource>(
        () => NewsRemoteDataSourceImpl(),
      );
      print('✅ [INJECTION] NewsRemoteDataSource registered');
    }
    
    if (!getIt.isRegistered<NewsLocalDataSource>()) {
      getIt.registerLazySingleton<NewsLocalDataSource>(
        () => NewsLocalDataSourceImpl(getIt()), // CacheService desde injection.config.dart
      );
      print('✅ [INJECTION] NewsLocalDataSource registered');
    }
    
    // Repository
    if (!getIt.isRegistered<NewsRepository>()) {
      getIt.registerLazySingleton<NewsRepository>(
        () => NewsRepositoryImpl(
          getIt<NewsRemoteDataSource>(),
          getIt<NewsLocalDataSource>(),
          getIt(), // NetworkInfo desde injection.config.dart
        ),
      );
      print('✅ [INJECTION] NewsRepository registered');
    }
    
    // Use Cases
    if (!getIt.isRegistered<GetClimateNewsUseCase>()) {
      getIt.registerLazySingleton<GetClimateNewsUseCase>(
        () => GetClimateNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] GetClimateNewsUseCase registered');
    }
    
    if (!getIt.isRegistered<GetCachedNewsUseCase>()) {
      getIt.registerLazySingleton<GetCachedNewsUseCase>(
        () => GetCachedNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] GetCachedNewsUseCase registered');
    }
    
    if (!getIt.isRegistered<RefreshNewsUseCase>()) {
      getIt.registerLazySingleton<RefreshNewsUseCase>(
        () => RefreshNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] RefreshNewsUseCase registered');
    }
    
    // Cubit
    if (!getIt.isRegistered<NewsCubit>()) {
      getIt.registerFactory<NewsCubit>(
        () => NewsCubit(
          getClimateNewsUseCase: getIt<GetClimateNewsUseCase>(),
          getCachedNewsUseCase: getIt<GetCachedNewsUseCase>(),
          refreshNewsUseCase: getIt<RefreshNewsUseCase>(),
        ),
      );
      print('✅ [INJECTION] NewsCubit registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerNewsDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== 🆕 QUIZ DEPENDENCIES ====================

void _registerQuizDependencies() {
  try {
    print('🧠 [INJECTION] === REGISTERING QUIZ DEPENDENCIES ===');

    // 🆕 Data Sources - QUIZ REMOTE
    if (!getIt.isRegistered<QuizRemoteDataSource>()) {
      getIt.registerLazySingleton<QuizRemoteDataSource>(
        () => QuizRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] QuizRemoteDataSource registered');
    }

    // 🆕 Repository - QUIZ REPOSITORY (actualizar referencia)
    if (!getIt.isRegistered<QuizRepository>()) {
      getIt.registerLazySingleton<QuizRepository>(
        () => QuizRepositoryImpl(
          remoteDataSource: getIt<QuizRemoteDataSource>(),
          localDataSource: getIt(), // TriviaLocalDataSource desde injection.config.dart
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] QuizRepository registered');
    }

    // 🆕 Use Cases - QUIZ SESSION USE CASES
    if (!getIt.isRegistered<StartQuizSessionUseCase>()) {
      getIt.registerLazySingleton<StartQuizSessionUseCase>(
        () => StartQuizSessionUseCase(getIt<QuizRepository>()),
      );
      print('✅ [INJECTION] StartQuizSessionUseCase registered');
    }

    if (!getIt.isRegistered<SubmitQuizAnswerUseCase>()) {
      getIt.registerLazySingleton<SubmitQuizAnswerUseCase>(
        () => SubmitQuizAnswerUseCase(getIt<QuizRepository>()),
      );
      print('✅ [INJECTION] SubmitQuizAnswerUseCase registered');
    }

    if (!getIt.isRegistered<GetQuizResultsUseCase>()) {
      getIt.registerLazySingleton<GetQuizResultsUseCase>(
        () => GetQuizResultsUseCase(getIt<QuizRepository>()),
      );
      print('✅ [INJECTION] GetQuizResultsUseCase registered');
    }

    if (!getIt.isRegistered<GetQuizQuestionsUseCase>()) {
      getIt.registerLazySingleton<GetQuizQuestionsUseCase>(
        () => GetQuizQuestionsUseCase(getIt<QuizRepository>()),
      );
      print('✅ [INJECTION] GetQuizQuestionsUseCase registered');
    }

    // 🆕 Cubit - QUIZ SESSION CUBIT
    if (!getIt.isRegistered<QuizSessionCubit>()) {
      getIt.registerFactory<QuizSessionCubit>(
        () => QuizSessionCubit(
          startQuizSessionUseCase: getIt<StartQuizSessionUseCase>(),
          submitQuizAnswerUseCase: getIt<SubmitQuizAnswerUseCase>(),
          getQuizResultsUseCase: getIt<GetQuizResultsUseCase>(),
          getQuizQuestionsUseCase: getIt<GetQuizQuestionsUseCase>(),
        ),
      );
      print('✅ [INJECTION] QuizSessionCubit registered');
    }

    print('🎉 [INJECTION] === QUIZ DEPENDENCIES REGISTERED SUCCESSFULLY ===');
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerQuizDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== VERIFICATION ====================

void _verifyDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY VERIFICATION WITH QUIZ INTEGRATION ===');
  
  // Verificar dependencias críticas INCLUYENDO QUIZ
  final criticalDeps = [
    'ApiClient',
    'TokenManager',
    'MediaRemoteDataSource',
    'ContentRemoteDataSource',
    'ContentRepository', 
    'GetTopicsUseCase',
    'GetContentByIdUseCase',
    'GetContentsByTopicUseCase',
    'ContentCubit',
    'TopicContentsCubit',
    // 🆕 COMPANION API DEPENDENCIES
    'CompanionRemoteDataSource',
    'CompanionLocalDataSource',
    'CompanionRepository',
    'GetUserCompanionsUseCase',
    'GetAvailableCompanionsUseCase',
    'GetCompanionShopUseCase',
    'PurchaseCompanionUseCase',
    'EvolveCompanionUseCase',
    'FeedCompanionUseCase',
    'LoveCompanionUseCase',
    // 🔧 NUEVOS USE CASES
    'EvolveCompanionViaApiUseCase',
    'FeatureCompanionUseCase',
    'CompanionCubit',
    'CompanionShopCubit',
    'CompanionDetailCubit',
    // LEARNING & NEWS
    'LearningCubit',
    'NewsRemoteDataSource',
    'NewsLocalDataSource',
    'NewsRepository',
    'GetClimateNewsUseCase',
    'GetCachedNewsUseCase',
    'RefreshNewsUseCase',
    'NewsCubit',
    // 🆕 QUIZ DEPENDENCIES
    'QuizRemoteDataSource',
    'QuizRepository',
    'StartQuizSessionUseCase',
    'SubmitQuizAnswerUseCase',
    'GetQuizResultsUseCase',
    'GetQuizQuestionsUseCase',
    'QuizSessionCubit',
  ];
  
  for (final dep in criticalDeps) {
    bool isRegistered = false;
    
    switch (dep) {
      case 'ApiClient':
        isRegistered = getIt.isRegistered<ApiClient>();
        break;
      case 'TokenManager':
        isRegistered = getIt.isRegistered<TokenManager>();
        break;
      case 'MediaRemoteDataSource':
        isRegistered = getIt.isRegistered<MediaRemoteDataSource>();
        break;
      case 'ContentRemoteDataSource':
        isRegistered = getIt.isRegistered<ContentRemoteDataSource>();
        break;
      case 'ContentRepository':
        isRegistered = getIt.isRegistered<ContentRepository>();
        break;
      case 'GetTopicsUseCase':
        isRegistered = getIt.isRegistered<GetTopicsUseCase>();
        break;
      case 'GetContentByIdUseCase':
        isRegistered = getIt.isRegistered<GetContentByIdUseCase>();
        break;
      case 'GetContentsByTopicUseCase':
        isRegistered = getIt.isRegistered<GetContentsByTopicUseCase>();
        break;
      case 'ContentCubit':
        isRegistered = getIt.isRegistered<ContentCubit>();
        break;
      case 'TopicContentsCubit':
        isRegistered = getIt.isRegistered<TopicContentsCubit>();
        break;
      // 🆕 COMPANION CASES
      case 'CompanionRemoteDataSource':
        isRegistered = getIt.isRegistered<CompanionRemoteDataSource>();
        break;
      case 'CompanionLocalDataSource':
        isRegistered = getIt.isRegistered<CompanionLocalDataSource>();
        break;
      case 'CompanionRepository':
        isRegistered = getIt.isRegistered<CompanionRepository>();
        break;
      case 'GetUserCompanionsUseCase':
        isRegistered = getIt.isRegistered<GetUserCompanionsUseCase>();
        break;
      case 'GetAvailableCompanionsUseCase':
        isRegistered = getIt.isRegistered<GetAvailableCompanionsUseCase>();
        break;
      case 'GetCompanionShopUseCase':
        isRegistered = getIt.isRegistered<GetCompanionShopUseCase>();
        break;
      case 'PurchaseCompanionUseCase':
        isRegistered = getIt.isRegistered<PurchaseCompanionUseCase>();
        break;
      case 'EvolveCompanionUseCase':
        isRegistered = getIt.isRegistered<EvolveCompanionUseCase>();
        break;
      case 'FeedCompanionUseCase':
        isRegistered = getIt.isRegistered<FeedCompanionUseCase>();
        break;
      case 'LoveCompanionUseCase':
        isRegistered = getIt.isRegistered<LoveCompanionUseCase>();
        break;
      // 🔧 NUEVOS USE CASES
      case 'EvolveCompanionViaApiUseCase':
        isRegistered = getIt.isRegistered<EvolveCompanionViaApiUseCase>();
        break;
      case 'FeatureCompanionUseCase':
        isRegistered = getIt.isRegistered<FeatureCompanionUseCase>();
        break;
      case 'CompanionCubit':
        isRegistered = getIt.isRegistered<CompanionCubit>();
        break;
      case 'CompanionShopCubit':
        isRegistered = getIt.isRegistered<CompanionShopCubit>();
        break;
      case 'CompanionDetailCubit':
        isRegistered = getIt.isRegistered<CompanionDetailCubit>();
        break;
      // LEARNING & NEWS CASES
      case 'LearningCubit':
        isRegistered = getIt.isRegistered<LearningCubit>();
        break;
      case 'NewsRemoteDataSource':
        isRegistered = getIt.isRegistered<NewsRemoteDataSource>();
        break;
      case 'NewsLocalDataSource':
        isRegistered = getIt.isRegistered<NewsLocalDataSource>();
        break;
      case 'NewsRepository':
        isRegistered = getIt.isRegistered<NewsRepository>();
        break;
      case 'GetClimateNewsUseCase':
        isRegistered = getIt.isRegistered<GetClimateNewsUseCase>();
        break;
      case 'GetCachedNewsUseCase':
        isRegistered = getIt.isRegistered<GetCachedNewsUseCase>();
        break;
      case 'RefreshNewsUseCase':
        isRegistered = getIt.isRegistered<RefreshNewsUseCase>();
        break;
      case 'NewsCubit':
        isRegistered = getIt.isRegistered<NewsCubit>();
        break;
      // 🆕 QUIZ CASES
      case 'QuizRemoteDataSource':
        isRegistered = getIt.isRegistered<QuizRemoteDataSource>();
        break;
      case 'QuizRepository':
        isRegistered = getIt.isRegistered<QuizRepository>();
        break;
      case 'StartQuizSessionUseCase':
        isRegistered = getIt.isRegistered<StartQuizSessionUseCase>();
        break;
      case 'SubmitQuizAnswerUseCase':
        isRegistered = getIt.isRegistered<SubmitQuizAnswerUseCase>();
        break;
      case 'GetQuizResultsUseCase':
        isRegistered = getIt.isRegistered<GetQuizResultsUseCase>();
        break;
      case 'GetQuizQuestionsUseCase':
        isRegistered = getIt.isRegistered<GetQuizQuestionsUseCase>();
        break;
      case 'QuizSessionCubit':
        isRegistered = getIt.isRegistered<QuizSessionCubit>();
        break;
    }
    
    if (isRegistered) {
      print('✅ [INJECTION] $dep: REGISTERED');
    } else {
      print('❌ [INJECTION] $dep: NOT REGISTERED');
      throw Exception('Critical dependency $dep is not registered');
    }
  }
  
  // 🆕 Test de resolución para CompanionCubit
  try {
    final testCompanionCubit = getIt<CompanionCubit>();
    print('✅ [INJECTION] CompanionCubit can be resolved successfully');
    testCompanionCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving CompanionCubit: $e');
    throw Exception('Cannot resolve CompanionCubit: $e');
  }
  
  // 🆕 Test de resolución para CompanionShopCubit
  try {
    final testShopCubit = getIt<CompanionShopCubit>();
    print('✅ [INJECTION] CompanionShopCubit can be resolved successfully');
    testShopCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving CompanionShopCubit: $e');
    throw Exception('Cannot resolve CompanionShopCubit: $e');
  }
  
  // 🔧 Test de resolución para CompanionDetailCubit CON NUEVOS USE CASES
  try {
    final testDetailCubit = getIt<CompanionDetailCubit>();
    print('✅ [INJECTION] CompanionDetailCubit can be resolved successfully WITH NEW USE CASES');
    testDetailCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving CompanionDetailCubit: $e');
    throw Exception('Cannot resolve CompanionDetailCubit: $e');
  }
  
  // Test de resolución para TopicContentsCubit
  try {
    final testCubit = getIt<TopicContentsCubit>();
    print('✅ [INJECTION] TopicContentsCubit can be resolved successfully');
    testCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving TopicContentsCubit: $e');
    throw Exception('Cannot resolve TopicContentsCubit: $e');
  }
  
  // Test de resolución para NewsCubit
  try {
    final testNewsCubit = getIt<NewsCubit>();
    print('✅ [INJECTION] NewsCubit can be resolved successfully');
    testNewsCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving NewsCubit: $e');
    throw Exception('Cannot resolve NewsCubit: $e');
  }
  
  // 🆕 Test de resolución para QuizSessionCubit
  try {
    final testQuizCubit = getIt<QuizSessionCubit>();
    print('✅ [INJECTION] QuizSessionCubit can be resolved successfully');
    testQuizCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving QuizSessionCubit: $e');
    throw Exception('Cannot resolve QuizSessionCubit: $e');
  }
  
  // 🆕 Test de resolución para CompanionRemoteDataSource
  try {
    final testCompanionDataSource = getIt<CompanionRemoteDataSource>();
    print('✅ [INJECTION] CompanionRemoteDataSource can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving CompanionRemoteDataSource: $e');
    throw Exception('Cannot resolve CompanionRemoteDataSource: $e');
  }
  
  // Test de resolución para MediaRemoteDataSource
  try {
    final testMediaDataSource = getIt<MediaRemoteDataSource>();
    print('✅ [INJECTION] MediaRemoteDataSource can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving MediaRemoteDataSource: $e');
    throw Exception('Cannot resolve MediaRemoteDataSource: $e');
  }
  
  // 🔧 Test de resolución para NUEVOS USE CASES
  try {
    final testEvolveViaApi = getIt<EvolveCompanionViaApiUseCase>();
    print('✅ [INJECTION] EvolveCompanionViaApiUseCase can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving EvolveCompanionViaApiUseCase: $e');
    throw Exception('Cannot resolve EvolveCompanionViaApiUseCase: $e');
  }
  
  try {
    final testFeatureCompanion = getIt<FeatureCompanionUseCase>();
    print('✅ [INJECTION] FeatureCompanionUseCase can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving FeatureCompanionUseCase: $e');
    throw Exception('Cannot resolve FeatureCompanionUseCase: $e');
  }
  
  // 🆕 Test de resolución para QuizRemoteDataSource
  try {
    final testQuizDataSource = getIt<QuizRemoteDataSource>();
    print('✅ [INJECTION] QuizRemoteDataSource can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving QuizRemoteDataSource: $e');
    throw Exception('Cannot resolve QuizRemoteDataSource: $e');
  }
  
  print('🔍 [INJECTION] === VERIFICATION COMPLETED WITH QUIZ INTEGRATION ===');
}

// ==================== DEBUG HELPERS ====================

void debugDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY DEBUG WITH QUIZ INTEGRATION ===');
  print('🔍 ApiClient: ${getIt.isRegistered<ApiClient>()}');
  print('🔍 TokenManager: ${getIt.isRegistered<TokenManager>()}');
  print('🔍 MediaRemoteDataSource: ${getIt.isRegistered<MediaRemoteDataSource>()}');
  print('🔍 ContentRemoteDataSource: ${getIt.isRegistered<ContentRemoteDataSource>()}');
  print('🔍 ContentRepository: ${getIt.isRegistered<ContentRepository>()}');
  print('🔍 GetTopicsUseCase: ${getIt.isRegistered<GetTopicsUseCase>()}');
  print('🔍 GetContentByIdUseCase: ${getIt.isRegistered<GetContentByIdUseCase>()}');
  print('🔍 GetContentsByTopicUseCase: ${getIt.isRegistered<GetContentsByTopicUseCase>()}');
  print('🔍 ContentCubit: ${getIt.isRegistered<ContentCubit>()}');
  print('🔍 TopicContentsCubit: ${getIt.isRegistered<TopicContentsCubit>()}');
  print('🔍 CompanionRemoteDataSource: ${getIt.isRegistered<CompanionRemoteDataSource>()}');
  print('🔍 CompanionLocalDataSource: ${getIt.isRegistered<CompanionLocalDataSource>()}');
  print('🔍 CompanionRepository: ${getIt.isRegistered<CompanionRepository>()}');
  print('🔍 GetUserCompanionsUseCase: ${getIt.isRegistered<GetUserCompanionsUseCase>()}');
  print('🔍 GetAvailableCompanionsUseCase: ${getIt.isRegistered<GetAvailableCompanionsUseCase>()}');
  print('🔍 GetCompanionShopUseCase: ${getIt.isRegistered<GetCompanionShopUseCase>()}');
  print('🔍 PurchaseCompanionUseCase: ${getIt.isRegistered<PurchaseCompanionUseCase>()}');
  print('🔍 EvolveCompanionUseCase: ${getIt.isRegistered<EvolveCompanionUseCase>()}');
  print('🔍 FeedCompanionUseCase: ${getIt.isRegistered<FeedCompanionUseCase>()}');
  print('🔍 LoveCompanionUseCase: ${getIt.isRegistered<LoveCompanionUseCase>()}');
  print('🔍 EvolveCompanionViaApiUseCase: ${getIt.isRegistered<EvolveCompanionViaApiUseCase>()}');
  print('🔍 FeatureCompanionUseCase: ${getIt.isRegistered<FeatureCompanionUseCase>()}');
  print('🔍 CompanionCubit: ${getIt.isRegistered<CompanionCubit>()}');
  print('🔍 CompanionShopCubit: ${getIt.isRegistered<CompanionShopCubit>()}');
  print('🔍 CompanionDetailCubit: ${getIt.isRegistered<CompanionDetailCubit>()}');
  print('🔍 LearningRemoteDataSource: ${getIt.isRegistered<LearningRemoteDataSource>()}');
  print('🔍 LearningRepository: ${getIt.isRegistered<LearningRepository>()}');
  print('🔍 GetCategoriesUseCase: ${getIt.isRegistered<GetCategoriesUseCase>()}');
  print('🔍 GetLessonsByCategoryUseCase: ${getIt.isRegistered<GetLessonsByCategoryUseCase>()}');
  print('🔍 GetLessonContentUseCase: ${getIt.isRegistered<GetLessonContentUseCase>()}');
  print('🔍 UpdateLessonProgressUseCase: ${getIt.isRegistered<UpdateLessonProgressUseCase>()}');
  print('🔍 CompleteLessonUseCase: ${getIt.isRegistered<CompleteLessonUseCase>()}');
  print('🔍 SearchLessonsUseCase: ${getIt.isRegistered<SearchLessonsUseCase>()}');
  print('🔍 LearningCubit: ${getIt.isRegistered<LearningCubit>()}');
  print('🔍 LessonListCubit: ${getIt.isRegistered<LessonListCubit>()}');
  print('🔍 LessonContentCubit: ${getIt.isRegistered<LessonContentCubit>()}');
  print('🔍 NewsRemoteDataSource: ${getIt.isRegistered<NewsRemoteDataSource>()}');
  print('🔍 NewsLocalDataSource: ${getIt.isRegistered<NewsLocalDataSource>()}');
  print('🔍 NewsRepository: ${getIt.isRegistered<NewsRepository>()}');
  print('🔍 GetClimateNewsUseCase: ${getIt.isRegistered<GetClimateNewsUseCase>()}');
  print('🔍 GetCachedNewsUseCase: ${getIt.isRegistered<GetCachedNewsUseCase>()}');
  print('🔍 RefreshNewsUseCase: ${getIt.isRegistered<RefreshNewsUseCase>()}');
  print('🔍 NewsCubit: ${getIt.isRegistered<NewsCubit>()}');
  // 🆕 QUIZ DEBUG
  print('🔍 QuizRemoteDataSource: ${getIt.isRegistered<QuizRemoteDataSource>()}');
  print('🔍 QuizRepository: ${getIt.isRegistered<QuizRepository>()}');
  print('🔍 StartQuizSessionUseCase: ${getIt.isRegistered<StartQuizSessionUseCase>()}');
  print('🔍 SubmitQuizAnswerUseCase: ${getIt.isRegistered<SubmitQuizAnswerUseCase>()}');
  print('🔍 GetQuizResultsUseCase: ${getIt.isRegistered<GetQuizResultsUseCase>()}');
  print('🔍 GetQuizQuestionsUseCase: ${getIt.isRegistered<GetQuizQuestionsUseCase>()}');
  print('🔍 QuizSessionCubit: ${getIt.isRegistered<QuizSessionCubit>()}');
  print('🔍 [INJECTION] === DEBUG COMPLETE ===');
}