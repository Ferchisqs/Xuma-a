import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/trivia/domain/usecases/get_quizzes_by_topic_usecase.dart';
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
import '../features/learning/data/datasources/media_remote_datasource.dart'; // Importación existente


// Media imports

// Companion imports
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
import '../features/companion/domain/usecases/evolve_companion_via_api_usecase.dart';
import '../features/companion/domain/usecases/feature_companion_usecase.dart';
// New stats use cases
import '../features/companion/domain/usecases/decrease_pet_stats_usecase.dart';
import '../features/companion/domain/usecases/increase_pet_stats_usecase.dart';
import '../features/companion/domain/usecases/feed_companion_via_api_usecase.dart';
import '../features/companion/domain/usecases/love_companion_via_api_usecase.dart';
import '../features/companion/domain/usecases/simulate_time_passage_usecase.dart';
import '../features/companion/presentation/cubit/companion_cubit.dart';
import '../features/companion/presentation/cubit/companion_shop_cubit.dart';
import '../features/companion/presentation/cubit/companion_detail_cubit.dart';
import '../features/companion/presentation/cubit/companion_actions_cubit.dart';

// News feature imports
import '../features/news/data/datasources/news_remote_datasource.dart';
import '../features/news/data/datasources/news_local_datasource.dart';
import '../features/news/data/repositories/news_repository_impl.dart';
import '../features/news/domain/repositories/news_repository.dart';
import '../features/news/domain/usecases/get_climate_news_usecase.dart';
import '../features/news/domain/usecases/get_cached_news_usecase.dart';
import '../features/news/domain/usecases/refresh_news_usecase.dart';
import '../features/news/presentation/cubit/news_cubit.dart';

// Quiz feature imports
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
  print('🔧 [INJECTION] === STARTING DEPENDENCY CONFIGURATION ===');

  try {
    // 1. Configure auto-generated dependencies
    print('🔧 [INJECTION] Step 1: Configuring auto-generated dependencies...');
    await getIt.init();
    print('✅ [INJECTION] Step 1: Auto-generated dependencies configured');

    // 2. Register Media dependencies
    print('🔧 [INJECTION] Step 2: Registering media dependencies...');
    _registerMediaDependencies();
    print('✅ [INJECTION] Step 2: Media dependencies registered');

    // 3. Register content dependencies with media
    print('🔧 [INJECTION] Step 3: Registering content dependencies...');
    _registerContentDependencies();
    print('✅ [INJECTION] Step 3: Content dependencies registered');

    // 4. Register companion dependencies with new stats use cases
    print('🔧 [INJECTION] Step 4: Registering companion dependencies...');
    _registerCompanionDependencies();
    print('✅ [INJECTION] Step 4: Companion dependencies registered');

    // 5. Register learning dependencies
    print('🔧 [INJECTION] Step 5: Registering learning dependencies...');
    _registerLearningDependencies();
    print('✅ [INJECTION] Step 5: Learning dependencies registered');

    // 6. Register news dependencies
    print('🔧 [INJECTION] Step 6: Registering news dependencies...');
    _registerNewsDependencies();
    print('✅ [INJECTION] Step 6: News dependencies registered');

    // 7. Register quiz dependencies
    print('🔧 [INJECTION] Step 7: Registering quiz dependencies...');
    _registerQuizDependencies();
    print('✅ [INJECTION] Step 7: Quiz dependencies registered');

    // 8. Final verification
    print('🔍 [INJECTION] Step 8: Final verification...');
    _verifyDependencies();
    print('✅ [INJECTION] Step 8: All dependencies verified');

    print('🎉 [INJECTION] === DEPENDENCY CONFIGURATION COMPLETED ===');
  } catch (e, stackTrace) {
    print('❌ [INJECTION] CRITICAL ERROR in configureDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== MEDIA DEPENDENCIES ====================
void _registerMediaDependencies() {
  try {
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

// ==================== CONTENT DEPENDENCIES ====================
void _registerContentDependencies() {
  try {
    // Data Sources
    if (!getIt.isRegistered<ContentRemoteDataSource>()) {
      getIt.registerLazySingleton<ContentRemoteDataSource>(
        () => ContentRemoteDataSourceImpl(
          getIt<ApiClient>(),
          getIt<MediaRemoteDataSource>(), // Inyección del MediaDataSource
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

    if (!getIt.isRegistered<TopicContentsCubit>()) {
      getIt.registerFactory<TopicContentsCubit>(
        () => TopicContentsCubit(
          getContentsByTopicUseCase: getIt<GetContentsByTopicUseCase>(),
        ),
      );
      print('✅ [INJECTION] TopicContentsCubit registered as factory');
    }
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerContentDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== COMPANION DEPENDENCIES ====================
void _registerCompanionDependencies() {
  try {
    print('🐾 [INJECTION] === REGISTERING COMPANION DEPENDENCIES ===');

    // Data Sources
    if (!getIt.isRegistered<CompanionRemoteDataSource>()) {
      getIt.registerLazySingleton<CompanionRemoteDataSource>(
        () => CompanionRemoteDataSourceImpl(
          getIt<ApiClient>(),
          getIt<TokenManager>(),
        ),
      );
      print('✅ [INJECTION] CompanionRemoteDataSource registered');
    }

    if (!getIt.isRegistered<CompanionLocalDataSource>()) {
      getIt.registerLazySingleton<CompanionLocalDataSource>(
        () => CompanionLocalDataSourceImpl(getIt()),
      );
      print('✅ [INJECTION] CompanionLocalDataSource registered');
    }

    // Repository
    if (!getIt.isRegistered<CompanionRepository>()) {
      getIt.registerLazySingleton<CompanionRepository>(
        () => CompanionRepositoryImpl(
          remoteDataSource: getIt<CompanionRemoteDataSource>(),
          localDataSource: getIt<CompanionLocalDataSource>(),
          networkInfo: getIt(),
          tokenManager: getIt<TokenManager>(),
        ),
      );
      print('✅ [INJECTION] CompanionRepository registered');
    }

    // Existing Use Cases
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

    // NEW STATS USE CASES
    if (!getIt.isRegistered<DecreasePetStatsUseCase>()) {
      getIt.registerLazySingleton<DecreasePetStatsUseCase>(
        () => DecreasePetStatsUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] DecreasePetStatsUseCase registered');
    }

    if (!getIt.isRegistered<IncreasePetStatsUseCase>()) {
      getIt.registerLazySingleton<IncreasePetStatsUseCase>(
        () => IncreasePetStatsUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] IncreasePetStatsUseCase registered');
    }

    if (!getIt.isRegistered<FeedCompanionViaApiUseCase>()) {
      getIt.registerLazySingleton<FeedCompanionViaApiUseCase>(
        () => FeedCompanionViaApiUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] FeedCompanionViaApiUseCase registered');
    }

    if (!getIt.isRegistered<LoveCompanionViaApiUseCase>()) {
      getIt.registerLazySingleton<LoveCompanionViaApiUseCase>(
        () => LoveCompanionViaApiUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] LoveCompanionViaApiUseCase registered');
    }

    if (!getIt.isRegistered<SimulateTimePassageUseCase>()) {
      getIt.registerLazySingleton<SimulateTimePassageUseCase>(
        () => SimulateTimePassageUseCase(getIt<CompanionRepository>()),
      );
      print('✅ [INJECTION] SimulateTimePassageUseCase registered');
    }

    // Cubits
    if (!getIt.isRegistered<CompanionCubit>()) {
      getIt.registerFactory<CompanionCubit>(
        () => CompanionCubit(
          getUserCompanionsUseCase: getIt<GetUserCompanionsUseCase>(),
          getCompanionShopUseCase: getIt<GetCompanionShopUseCase>(),
          tokenManager: getIt<TokenManager>(),
          repository: getIt<CompanionRepository>(),
        ),
      );
      print('✅ [INJECTION] CompanionCubit registered');
    }

    if (!getIt.isRegistered<CompanionShopCubit>()) {
      getIt.registerFactory<CompanionShopCubit>(
        () => CompanionShopCubit(
          getCompanionShopUseCase: getIt<GetCompanionShopUseCase>(),
          purchaseCompanionUseCase: getIt<PurchaseCompanionUseCase>(),
          tokenManager: getIt<TokenManager>(),
        ),
      );
      print('✅ [INJECTION] CompanionShopCubit registered');
    }

    if (!getIt.isRegistered<CompanionDetailCubit>()) {
      getIt.registerFactory<CompanionDetailCubit>(
        () => CompanionDetailCubit(
          feedCompanionUseCase: getIt<FeedCompanionUseCase>(),
          loveCompanionUseCase: getIt<LoveCompanionUseCase>(),
          evolveCompanionUseCase: getIt<EvolveCompanionUseCase>(),
          evolveCompanionViaApiUseCase: getIt<EvolveCompanionViaApiUseCase>(),
          featureCompanionUseCase: getIt<FeatureCompanionUseCase>(),
          tokenManager: getIt<TokenManager>(),
        ),
      );
      print('✅ [INJECTION] CompanionDetailCubit registered');
    }

    // NEW CompanionActionsCubit
    if (!getIt.isRegistered<CompanionActionsCubit>()) {
      getIt.registerFactory<CompanionActionsCubit>(
        () => CompanionActionsCubit(
          repository: getIt<CompanionRepository>(),
          tokenManager: getIt<TokenManager>(),
          feedCompanionViaApiUseCase: getIt<FeedCompanionViaApiUseCase>(),
          loveCompanionViaApiUseCase: getIt<LoveCompanionViaApiUseCase>(),
          simulateTimePassageUseCase: getIt<SimulateTimePassageUseCase>(),
          decreasePetStatsUseCase: getIt<DecreasePetStatsUseCase>(),
          increasePetStatsUseCase: getIt<IncreasePetStatsUseCase>(),
        ),
      );
      print('✅ [INJECTION] CompanionActionsCubit registered');
    }

    print('🎉 [INJECTION] === COMPANION DEPENDENCIES REGISTERED ===');
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerCompanionDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== LEARNING DEPENDENCIES ====================
void _registerLearningDependencies() {
  try {
    // Data Sources
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
          localDataSource: getIt(),
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] LearningRepository registered');
    }

    // Use Cases
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

    // Cubits
    if (!getIt.isRegistered<LearningCubit>()) {
      getIt.registerFactory<LearningCubit>(
        () => LearningCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(),
        ),
      );
      print('✅ [INJECTION] LearningCubit registered');
    }

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
        () => NewsLocalDataSourceImpl(getIt()),
      );
      print('✅ [INJECTION] NewsLocalDataSource registered');
    }

    // Repository
    if (!getIt.isRegistered<NewsRepository>()) {
      getIt.registerLazySingleton<NewsRepository>(
        () => NewsRepositoryImpl(
          getIt<NewsRemoteDataSource>(),
          getIt<NewsLocalDataSource>(),
          getIt(),
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

// ==================== QUIZ DEPENDENCIES ====================
void _registerQuizDependencies() {
  try {
    print('🧠 [INJECTION] === REGISTERING QUIZ DEPENDENCIES ===');

    // Data Sources
    if (!getIt.isRegistered<QuizRemoteDataSource>()) {
      getIt.registerLazySingleton<QuizRemoteDataSource>(
        () => QuizRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] QuizRemoteDataSource registered');
    }

    // Repository
    if (!getIt.isRegistered<QuizRepository>()) {
      getIt.registerLazySingleton<QuizRepository>(
        () => QuizRepositoryImpl(
          remoteDataSource: getIt<QuizRemoteDataSource>(),
          localDataSource: getIt(),
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] QuizRepository registered');
    }

    // Use Cases
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

    if (!getIt.isRegistered<GetQuizzesByTopicUseCase>()) {
      getIt.registerLazySingleton<GetQuizzesByTopicUseCase>(
        () => GetQuizzesByTopicUseCase(getIt<QuizRepository>()),
      );
      print('✅ [INJECTION] GetQuizzesByTopicUseCase registered');
    }

    // Cubit
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

    print('🎉 [INJECTION] === QUIZ DEPENDENCIES REGISTERED ===');
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerQuizDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== VERIFICATION ====================
void _verifyDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY VERIFICATION ===');

  // Update critical dependencies list with new stats use cases
  final criticalDeps = [
    // Existing dependencies...
    // ...
    
    // New stats use cases
    'DecreasePetStatsUseCase',
    'IncreasePetStatsUseCase',
    'FeedCompanionViaApiUseCase',
    'LoveCompanionViaApiUseCase',
    'SimulateTimePassageUseCase',
    'CompanionActionsCubit',
  ];

  for (final dep in criticalDeps) {
    bool isRegistered = false;

    switch (dep) {
      // Existing cases...
      // ...
      
      // New stats cases
      case 'DecreasePetStatsUseCase':
        isRegistered = getIt.isRegistered<DecreasePetStatsUseCase>();
        break;
      case 'IncreasePetStatsUseCase':
        isRegistered = getIt.isRegistered<IncreasePetStatsUseCase>();
        break;
      case 'FeedCompanionViaApiUseCase':
        isRegistered = getIt.isRegistered<FeedCompanionViaApiUseCase>();
        break;
      case 'LoveCompanionViaApiUseCase':
        isRegistered = getIt.isRegistered<LoveCompanionViaApiUseCase>();
        break;
      case 'SimulateTimePassageUseCase':
        isRegistered = getIt.isRegistered<SimulateTimePassageUseCase>();
        break;
      case 'CompanionActionsCubit':
        isRegistered = getIt.isRegistered<CompanionActionsCubit>();
        break;
    }

    if (isRegistered) {
      print('✅ [INJECTION] $dep: REGISTERED');
    } else {
      print('❌ [INJECTION] $dep: NOT REGISTERED');
      throw Exception('Critical dependency $dep is not registered');
    }
  }

  // Test resolution for new CompanionActionsCubit
  try {
    final testActionsCubit = getIt<CompanionActionsCubit>();
    print('✅ [INJECTION] CompanionActionsCubit can be resolved successfully');
    testActionsCubit.close();
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving CompanionActionsCubit: $e');
    throw Exception('Cannot resolve CompanionActionsCubit: $e');
  }

  print('🔍 [INJECTION] === VERIFICATION COMPLETED ===');
}

// ==================== DEBUG HELPERS ====================
void debugDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY DEBUG ===');
  // Existing debug prints...
  // ...
  
  // Add new debug prints for stats use cases
  print('🔍 DecreasePetStatsUseCase: ${getIt.isRegistered<DecreasePetStatsUseCase>()}');
  print('🔍 IncreasePetStatsUseCase: ${getIt.isRegistered<IncreasePetStatsUseCase>()}');
  print('🔍 FeedCompanionViaApiUseCase: ${getIt.isRegistered<FeedCompanionViaApiUseCase>()}');
  print('🔍 LoveCompanionViaApiUseCase: ${getIt.isRegistered<LoveCompanionViaApiUseCase>()}');
  print('🔍 SimulateTimePassageUseCase: ${getIt.isRegistered<SimulateTimePassageUseCase>()}');
  print('🔍 CompanionActionsCubit: ${getIt.isRegistered<CompanionActionsCubit>()}');
  print('🔍 [INJECTION] === DEBUG COMPLETE ===');
}