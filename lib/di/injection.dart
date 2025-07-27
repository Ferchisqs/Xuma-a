import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/trivia/domain/usecases/get_quizzes_by_topic_usecase.dart';
import 'injection.config.dart';

import '../core/network/api_client.dart';
import '../core/services/token_manager.dart';
import '../core/services/media_upload_service.dart';

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
  await getIt.init();
  _registerMediaUploadService();
  _registerMediaDependencies();
  _registerContentDependencies();
  _registerCompanionDependencies();
  _registerLearningDependencies();
  _registerNewsDependencies();
  _registerQuizDependencies();
}

void _registerMediaUploadService() {
  if (!getIt.isRegistered<MediaUploadService>()) {
    getIt.registerLazySingleton<MediaUploadService>(
      () => MediaUploadService(getIt<ApiClient>()),
    );
  }
}

void _registerMediaDependencies() {
  if (!getIt.isRegistered<MediaRemoteDataSource>()) {
    getIt.registerLazySingleton<MediaRemoteDataSource>(
      () => MediaRemoteDataSourceImpl(getIt<ApiClient>()),
    );
  }
}

void _registerContentDependencies() {
  if (!getIt.isRegistered<ContentRemoteDataSource>()) {
    getIt.registerLazySingleton<ContentRemoteDataSource>(
      () => ContentRemoteDataSourceImpl(
        getIt<ApiClient>(),
        getIt<MediaRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<ContentRepository>()) {
    getIt.registerLazySingleton<ContentRepository>(
      () => ContentRepositoryImpl(
        remoteDataSource: getIt<ContentRemoteDataSource>(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<GetTopicsUseCase>()) {
    getIt.registerLazySingleton<GetTopicsUseCase>(
      () => GetTopicsUseCase(getIt<ContentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetContentByIdUseCase>()) {
    getIt.registerLazySingleton<GetContentByIdUseCase>(
      () => GetContentByIdUseCase(getIt<ContentRepository>()),
    );
  }

  if (!getIt.isRegistered<GetContentsByTopicUseCase>()) {
    getIt.registerLazySingleton<GetContentsByTopicUseCase>(
      () => GetContentsByTopicUseCase(getIt<ContentRepository>()),
    );
  }

  if (!getIt.isRegistered<ContentCubit>()) {
    getIt.registerFactory<ContentCubit>(
      () => ContentCubit(
        getTopicsUseCase: getIt<GetTopicsUseCase>(),
        getContentByIdUseCase: getIt<GetContentByIdUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<TopicContentsCubit>()) {
    getIt.registerFactory<TopicContentsCubit>(
      () => TopicContentsCubit(
        getContentsByTopicUseCase: getIt<GetContentsByTopicUseCase>(),
      ),
    );
  }
}

void _registerCompanionDependencies() {
  if (!getIt.isRegistered<CompanionRemoteDataSource>()) {
    getIt.registerLazySingleton<CompanionRemoteDataSource>(
      () => CompanionRemoteDataSourceImpl(
        getIt<ApiClient>(),
        getIt<TokenManager>(),
      ),
    );
  }

  if (!getIt.isRegistered<CompanionLocalDataSource>()) {
    getIt.registerLazySingleton<CompanionLocalDataSource>(
      () => CompanionLocalDataSourceImpl(getIt()),
    );
  }

  if (!getIt.isRegistered<CompanionRepository>()) {
    getIt.registerLazySingleton<CompanionRepository>(
      () => CompanionRepositoryImpl(
        remoteDataSource: getIt<CompanionRemoteDataSource>(),
        localDataSource: getIt<CompanionLocalDataSource>(),
        networkInfo: getIt(),
        tokenManager: getIt<TokenManager>(),
      ),
    );
  }

  // Use Cases
  if (!getIt.isRegistered<GetUserCompanionsUseCase>()) {
    getIt.registerLazySingleton<GetUserCompanionsUseCase>(
      () => GetUserCompanionsUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetAvailableCompanionsUseCase>()) {
    getIt.registerLazySingleton<GetAvailableCompanionsUseCase>(
      () => GetAvailableCompanionsUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCompanionShopUseCase>()) {
    getIt.registerLazySingleton<GetCompanionShopUseCase>(
      () => GetCompanionShopUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<PurchaseCompanionUseCase>()) {
    getIt.registerLazySingleton<PurchaseCompanionUseCase>(
      () => PurchaseCompanionUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<EvolveCompanionUseCase>()) {
    getIt.registerLazySingleton<EvolveCompanionUseCase>(
      () => EvolveCompanionUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<FeedCompanionUseCase>()) {
    getIt.registerLazySingleton<FeedCompanionUseCase>(
      () => FeedCompanionUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<LoveCompanionUseCase>()) {
    getIt.registerLazySingleton<LoveCompanionUseCase>(
      () => LoveCompanionUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<EvolveCompanionViaApiUseCase>()) {
    getIt.registerLazySingleton<EvolveCompanionViaApiUseCase>(
      () => EvolveCompanionViaApiUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<FeatureCompanionUseCase>()) {
    getIt.registerLazySingleton<FeatureCompanionUseCase>(
      () => FeatureCompanionUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<DecreasePetStatsUseCase>()) {
    getIt.registerLazySingleton<DecreasePetStatsUseCase>(
      () => DecreasePetStatsUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<IncreasePetStatsUseCase>()) {
    getIt.registerLazySingleton<IncreasePetStatsUseCase>(
      () => IncreasePetStatsUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<FeedCompanionViaApiUseCase>()) {
    getIt.registerLazySingleton<FeedCompanionViaApiUseCase>(
      () => FeedCompanionViaApiUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<LoveCompanionViaApiUseCase>()) {
    getIt.registerLazySingleton<LoveCompanionViaApiUseCase>(
      () => LoveCompanionViaApiUseCase(getIt<CompanionRepository>()),
    );
  }

  if (!getIt.isRegistered<SimulateTimePassageUseCase>()) {
    getIt.registerLazySingleton<SimulateTimePassageUseCase>(
      () => SimulateTimePassageUseCase(getIt<CompanionRepository>()),
    );
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
  }

  if (!getIt.isRegistered<CompanionShopCubit>()) {
    getIt.registerFactory<CompanionShopCubit>(
      () => CompanionShopCubit(
        getCompanionShopUseCase: getIt<GetCompanionShopUseCase>(),
        purchaseCompanionUseCase: getIt<PurchaseCompanionUseCase>(),
        tokenManager: getIt<TokenManager>(),
      ),
    );
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
  }

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
  }
}

void _registerLearningDependencies() {
  if (!getIt.isRegistered<LearningRemoteDataSource>()) {
    getIt.registerLazySingleton<LearningRemoteDataSource>(
      () => LearningRemoteDataSourceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<LearningRepository>()) {
    getIt.registerLazySingleton<LearningRepository>(
      () => LearningRepositoryImpl(
        remoteDataSource: getIt<LearningRemoteDataSource>(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<GetCategoriesUseCase>()) {
    getIt.registerLazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<GetLessonsByCategoryUseCase>()) {
    getIt.registerLazySingleton<GetLessonsByCategoryUseCase>(
      () => GetLessonsByCategoryUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<GetLessonContentUseCase>()) {
    getIt.registerLazySingleton<GetLessonContentUseCase>(
      () => GetLessonContentUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateLessonProgressUseCase>()) {
    getIt.registerLazySingleton<UpdateLessonProgressUseCase>(
      () => UpdateLessonProgressUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<CompleteLessonUseCase>()) {
    getIt.registerLazySingleton<CompleteLessonUseCase>(
      () => CompleteLessonUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<SearchLessonsUseCase>()) {
    getIt.registerLazySingleton<SearchLessonsUseCase>(
      () => SearchLessonsUseCase(getIt<LearningRepository>()),
    );
  }

  if (!getIt.isRegistered<LearningCubit>()) {
    getIt.registerFactory<LearningCubit>(
      () => LearningCubit(
        getTopicsUseCase: getIt<GetTopicsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<LessonListCubit>()) {
    getIt.registerFactory<LessonListCubit>(
      () => LessonListCubit(
        getLessonsByCategoryUseCase: getIt<GetLessonsByCategoryUseCase>(),
        searchLessonsUseCase: getIt<SearchLessonsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<LessonContentCubit>()) {
    getIt.registerFactory<LessonContentCubit>(
      () => LessonContentCubit(
        getLessonContentUseCase: getIt<GetLessonContentUseCase>(),
        updateLessonProgressUseCase: getIt<UpdateLessonProgressUseCase>(),
        completeLessonUseCase: getIt<CompleteLessonUseCase>(),
      ),
    );
  }
}

void _registerNewsDependencies() {
  if (!getIt.isRegistered<NewsRemoteDataSource>()) {
    getIt.registerLazySingleton<NewsRemoteDataSource>(
      () => NewsRemoteDataSourceImpl(),
    );
  }

  if (!getIt.isRegistered<NewsLocalDataSource>()) {
    getIt.registerLazySingleton<NewsLocalDataSource>(
      () => NewsLocalDataSourceImpl(getIt()),
    );
  }

  if (!getIt.isRegistered<NewsRepository>()) {
    getIt.registerLazySingleton<NewsRepository>(
      () => NewsRepositoryImpl(
        getIt<NewsRemoteDataSource>(),
        getIt<NewsLocalDataSource>(),
        getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<GetClimateNewsUseCase>()) {
    getIt.registerLazySingleton<GetClimateNewsUseCase>(
      () => GetClimateNewsUseCase(getIt<NewsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCachedNewsUseCase>()) {
    getIt.registerLazySingleton<GetCachedNewsUseCase>(
      () => GetCachedNewsUseCase(getIt<NewsRepository>()),
    );
  }

  if (!getIt.isRegistered<RefreshNewsUseCase>()) {
    getIt.registerLazySingleton<RefreshNewsUseCase>(
      () => RefreshNewsUseCase(getIt<NewsRepository>()),
    );
  }

  if (!getIt.isRegistered<NewsCubit>()) {
    getIt.registerFactory<NewsCubit>(
      () => NewsCubit(
        getClimateNewsUseCase: getIt<GetClimateNewsUseCase>(),
        getCachedNewsUseCase: getIt<GetCachedNewsUseCase>(),
        refreshNewsUseCase: getIt<RefreshNewsUseCase>(),
      ),
    );
  }
}

void _registerQuizDependencies() {
  if (!getIt.isRegistered<QuizRemoteDataSource>()) {
    getIt.registerLazySingleton<QuizRemoteDataSource>(
      () => QuizRemoteDataSourceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<QuizRepository>()) {
    getIt.registerLazySingleton<QuizRepository>(
      () => QuizRepositoryImpl(
        remoteDataSource: getIt<QuizRemoteDataSource>(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<StartQuizSessionUseCase>()) {
    getIt.registerLazySingleton<StartQuizSessionUseCase>(
      () => StartQuizSessionUseCase(getIt<QuizRepository>()),
    );
  }

  if (!getIt.isRegistered<SubmitQuizAnswerUseCase>()) {
    getIt.registerLazySingleton<SubmitQuizAnswerUseCase>(
      () => SubmitQuizAnswerUseCase(getIt<QuizRepository>()),
    );
  }

  if (!getIt.isRegistered<GetQuizResultsUseCase>()) {
    getIt.registerLazySingleton<GetQuizResultsUseCase>(
      () => GetQuizResultsUseCase(getIt<QuizRepository>()),
    );
  }

  if (!getIt.isRegistered<GetQuizQuestionsUseCase>()) {
    getIt.registerLazySingleton<GetQuizQuestionsUseCase>(
      () => GetQuizQuestionsUseCase(getIt<QuizRepository>()),
    );
  }

  if (!getIt.isRegistered<GetQuizzesByTopicUseCase>()) {
    getIt.registerLazySingleton<GetQuizzesByTopicUseCase>(
      () => GetQuizzesByTopicUseCase(getIt<QuizRepository>()),
    );
  }

  if (!getIt.isRegistered<QuizSessionCubit>()) {
    getIt.registerFactory<QuizSessionCubit>(
      () => QuizSessionCubit(
        startQuizSessionUseCase: getIt<StartQuizSessionUseCase>(),
        submitQuizAnswerUseCase: getIt<SubmitQuizAnswerUseCase>(),
        getQuizResultsUseCase: getIt<GetQuizResultsUseCase>(),
        getQuizQuestionsUseCase: getIt<GetQuizQuestionsUseCase>(),
      ),
    );
  }
}