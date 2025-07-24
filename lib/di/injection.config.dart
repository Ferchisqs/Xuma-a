// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/network/api_client.dart' as _i510;
import '../core/network/network_info.dart' as _i6;
import '../core/services/cache_service.dart' as _i800;
import '../core/services/token_manager.dart' as _i497;
import '../features/auth/data/datasources/auth_local_datasource.dart' as _i182;
import '../features/auth/data/datasources/auth_remote_datasource.dart' as _i130;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i570;
import '../features/auth/domain/repositories/auth_repository.dart' as _i869;
import '../features/auth/domain/services/auth_service.dart' as _i88;
import '../features/auth/domain/usecases/login_usecase.dart' as _i406;
import '../features/auth/domain/usecases/register_usecase.dart' as _i819;
import '../features/auth/presentation/cubit/auth_cubit.dart' as _i70;
import '../features/challenges/data/datasources/challenges_local_datasource.dart'
    as _i422;
import '../features/challenges/data/datasources/challenges_remote_datasource.dart'
    as _i252;
import '../features/challenges/data/repositories/challenges_repository_impl.dart'
    as _i285;
import '../features/challenges/domain/repositories/challenges_repository.dart'
    as _i959;
import '../features/challenges/domain/usecases/complete_challenge_usecase.dart'
    as _i522;
import '../features/challenges/domain/usecases/get_active_challenges_usecase.dart'
    as _i929;
import '../features/challenges/domain/usecases/get_challenge_categories_usecase.dart'
    as _i229;
import '../features/challenges/domain/usecases/get_challenges_usecase.dart'
    as _i1010;
import '../features/challenges/domain/usecases/get_user_challenge_stats_usecase.dart'
    as _i31;
import '../features/challenges/domain/usecases/get_user_progress_usecase.dart'
    as _i287;
import '../features/challenges/domain/usecases/join_challenge_usecase.dart'
    as _i79;
import '../features/challenges/domain/usecases/start_challenge_usecase.dart'
    as _i23;
import '../features/challenges/domain/usecases/submit_evidence_usecase.dart'
    as _i1042;
import '../features/challenges/domain/usecases/update_challenge_progress_usecase.dart'
    as _i1056;
import '../features/challenges/presentation/cubit/challenge_detail_cubit.dart'
    as _i366;
import '../features/challenges/presentation/cubit/challenges_cubit.dart'
    as _i314;
import '../features/challenges/presentation/cubit/evidence_submission_cubit.dart'
    as _i64;
import '../features/companion/data/datasources/companion_local_datasource.dart'
    as _i1032;
import '../features/companion/data/datasources/companion_remote_datasource.dart'
    as _i115;
import '../features/companion/data/repositories/companion_repository_impl.dart'
    as _i904;
import '../features/companion/domain/repositories/companion_repository.dart'
    as _i770;
import '../features/companion/domain/usecases/evolve_companion_usecase.dart'
    as _i108;
import '../features/companion/domain/usecases/evolve_companion_via_api_usecase.dart'
    as _i711;
import '../features/companion/domain/usecases/feature_companion_usecase.dart'
    as _i913;
import '../features/companion/domain/usecases/feed_companion_usecase.dart'
    as _i960;
import '../features/companion/domain/usecases/get_available_companions_usecase.dart'
    as _i720;
import '../features/companion/domain/usecases/get_companion_shop_usecase.dart'
    as _i76;
import '../features/companion/domain/usecases/get_user_companions_usecase.dart'
    as _i574;
import '../features/companion/domain/usecases/love_companion_usecase.dart'
    as _i820;
import '../features/companion/domain/usecases/purchase_companion_usecase.dart'
    as _i395;
import '../features/companion/presentation/cubit/companion_actions_cubit.dart'
    as _i238;
import '../features/companion/presentation/cubit/companion_cubit.dart' as _i917;
import '../features/companion/presentation/cubit/companion_detail_cubit.dart'
    as _i0;
import '../features/companion/presentation/cubit/companion_shop_cubit.dart'
    as _i717;
import '../features/home/data/datasources/home_local_datasource.dart' as _i819;
import '../features/home/data/datasources/home_remote_datasource.dart' as _i75;
import '../features/home/data/repositories/home_repository_impl.dart' as _i6;
import '../features/home/domain/repositories/home_repository.dart' as _i66;
import '../features/home/domain/usecases/get_daily_tip_usecase.dart' as _i957;
import '../features/home/domain/usecases/get_user_stats_usecase.dart' as _i762;
import '../features/home/domain/usecases/update_user_activity_usecase.dart'
    as _i604;
import '../features/home/presentation/cubit/home_cubit.dart' as _i1017;
import '../features/learning/data/datasources/content_remote_datasource.dart'
    as _i605;
import '../features/learning/data/datasources/learning_local_datasource.dart'
    as _i195;
import '../features/learning/data/datasources/learning_remote_datasource.dart'
    as _i506;
import '../features/learning/data/datasources/media_remote_datasource.dart'
    as _i807;
import '../features/learning/data/repositories/content_repository_impl.dart'
    as _i577;
import '../features/learning/data/repositories/learning_repository_impl.dart'
    as _i378;
import '../features/learning/domain/repositories/content_repository.dart'
    as _i19;
import '../features/learning/domain/repositories/learning_repository.dart'
    as _i852;
import '../features/learning/domain/usecases/complete_lesson_usecase.dart'
    as _i412;
import '../features/learning/domain/usecases/get_categories_usecase.dart'
    as _i80;
import '../features/learning/domain/usecases/get_content_by_id_usecase.dart'
    as _i677;
import '../features/learning/domain/usecases/get_contents_by_topic_usecase.dart'
    as _i582;
import '../features/learning/domain/usecases/get_lesson_content_usecase.dart'
    as _i391;
import '../features/learning/domain/usecases/get_lessons_by_category_usecase.dart'
    as _i194;
import '../features/learning/domain/usecases/get_topics_usecase.dart' as _i175;
import '../features/learning/domain/usecases/search_lessons_usecase.dart'
    as _i420;
import '../features/learning/domain/usecases/update_lesson_progress_usecase.dart'
    as _i813;
import '../features/learning/presentation/cubit/content_cubit.dart' as _i921;
import '../features/learning/presentation/cubit/learning_cubit.dart' as _i992;
import '../features/learning/presentation/cubit/lesson_content_cubit.dart'
    as _i803;
import '../features/learning/presentation/cubit/lesson_list_cubit.dart'
    as _i568;
import '../features/navigation/presentation/cubit/navigation_cubit.dart'
    as _i630;
import '../features/news/data/datasources/news_local_datasource.dart' as _i445;
import '../features/news/data/datasources/news_remote_datasource.dart' as _i98;
import '../features/news/data/repositories/news_repository_impl.dart' as _i979;
import '../features/news/domain/repositories/news_repository.dart' as _i828;
import '../features/news/domain/usecases/get_cached_news_usecase.dart' as _i827;
import '../features/news/domain/usecases/get_climate_news_usecase.dart' as _i55;
import '../features/news/domain/usecases/refresh_news_usecase.dart' as _i136;
import '../features/news/presentation/cubit/news_cubit.dart' as _i464;
import '../features/profile/data/datasources/profile_remote_datasource.dart'
    as _i850;
import '../features/profile/data/repositories/profile_repository_impl.dart'
    as _i13;
import '../features/profile/domain/repositories/profile_repository.dart'
    as _i386;
import '../features/profile/domain/services/profile_service.dart' as _i92;
import '../features/profile/domain/usecases/get_user_profile_usecase.dart'
    as _i65;
import '../features/profile/domain/usecases/update_user_avatar_usecase.dart'
    as _i186;
import '../features/profile/presentation/cubit/profile_cubit.dart' as _i300;
import '../features/tips/data/datasources/tips_remote_datasource.dart' as _i652;
import '../features/tips/data/repositories/tips_repository_impl.dart' as _i397;
import '../features/tips/domain/repositories/tips_repository.dart' as _i406;
import '../features/tips/domain/usecases/get_random_tip_usecase.dart' as _i22;
import '../features/tips/presentation/cubit/tips_cubit.dart' as _i441;
import '../features/trivia/data/datasources/quiz_remote_datasource.dart'
    as _i964;
import '../features/trivia/data/datasources/trivia_local_datasource.dart'
    as _i430;
import '../features/trivia/data/datasources/trivia_remote_datasource.dart'
    as _i614;
import '../features/trivia/data/repositories/quiz_repository_impl.dart'
    as _i852;
import '../features/trivia/data/repositories/trivia_repository_impl.dart'
    as _i121;
import '../features/trivia/domain/repositories/quiz_repository.dart' as _i992;
import '../features/trivia/domain/repositories/trivia_repository.dart' as _i416;
import '../features/trivia/domain/usecases/get_question_by_id_usecase.dart'
    as _i852;
import '../features/trivia/domain/usecases/get_quiz_by_id_usecase.dart'
    as _i714;
import '../features/trivia/domain/usecases/get_quiz_questions_usecase.dart'
    as _i806;
import '../features/trivia/domain/usecases/get_quiz_results_usecase.dart'
    as _i907;
import '../features/trivia/domain/usecases/get_quizzes_by_topic_usecase.dart'
    as _i865;
import '../features/trivia/domain/usecases/get_trivia_categories_usecase.dart'
    as _i828;
import '../features/trivia/domain/usecases/get_trivia_questions_usecase.dart'
    as _i9;
import '../features/trivia/domain/usecases/get_user_quiz_progress_usecase.dart'
    as _i462;
import '../features/trivia/domain/usecases/get_user_trivia_history_usecase.dart'
    as _i919;
import '../features/trivia/domain/usecases/start_quiz_session_usecase.dart'
    as _i112;
import '../features/trivia/domain/usecases/submit_quiz_answer_usecase.dart'
    as _i591;
import '../features/trivia/domain/usecases/submit_trivia_answer_usecase.dart'
    as _i381;
import '../features/trivia/domain/usecases/submit_trivia_result_usecase.dart'
    as _i157;
import '../features/trivia/presentation/cubit/quiz_session_cubit.dart' as _i499;
import '../features/trivia/presentation/cubit/trivia_cubit.dart' as _i993;
import '../features/trivia/presentation/cubit/trivia_game_cubit.dart' as _i912;
import 'modules/external_module.dart' as _i649;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalModule = _$ExternalModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => externalModule.sharedPreferences,
      preResolve: true,
    );
    gh.factory<_i630.NavigationCubit>(() => _i630.NavigationCubit());
    gh.lazySingleton<_i800.CacheService>(() => _i800.CacheService());
    gh.lazySingleton<_i895.Connectivity>(() => externalModule.connectivity);
    gh.lazySingleton<_i497.TokenManager>(
        () => _i497.TokenManager(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i819.HomeLocalDataSource>(
        () => _i819.HomeLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i445.NewsLocalDataSource>(
        () => _i445.NewsLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i98.NewsRemoteDataSource>(
        () => _i98.NewsRemoteDataSourceImpl());
    gh.factory<_i430.TriviaLocalDataSource>(
        () => _i430.TriviaLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.factory<_i422.ChallengesLocalDataSource>(
        () => _i422.ChallengesLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.factory<_i195.LearningLocalDataSource>(
        () => _i195.LearningLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.factory<_i1032.CompanionLocalDataSource>(
        () => _i1032.CompanionLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i182.AuthLocalDataSource>(
        () => _i182.AuthLocalDataSourceImpl(
              gh<_i460.SharedPreferences>(),
              gh<_i497.TokenManager>(),
            ));
    gh.lazySingleton<_i6.NetworkInfo>(
        () => _i6.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i510.ApiClient>(() => _i510.ApiClient(
          gh<_i6.NetworkInfo>(),
          gh<_i800.CacheService>(),
          gh<_i497.TokenManager>(),
        ));
    gh.factory<_i506.LearningRemoteDataSource>(
        () => _i506.LearningRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.lazySingleton<_i828.NewsRepository>(() => _i979.NewsRepositoryImpl(
          gh<_i98.NewsRemoteDataSource>(),
          gh<_i445.NewsLocalDataSource>(),
          gh<_i6.NetworkInfo>(),
        ));
    gh.lazySingleton<_i827.GetCachedNewsUseCase>(
        () => _i827.GetCachedNewsUseCase(gh<_i828.NewsRepository>()));
    gh.lazySingleton<_i55.GetClimateNewsUseCase>(
        () => _i55.GetClimateNewsUseCase(gh<_i828.NewsRepository>()));
    gh.lazySingleton<_i136.RefreshNewsUseCase>(
        () => _i136.RefreshNewsUseCase(gh<_i828.NewsRepository>()));
    gh.lazySingleton<_i130.AuthRemoteDataSource>(
        () => _i130.AuthRemoteDataSourceImpl(
              gh<_i510.ApiClient>(),
              gh<_i497.TokenManager>(),
            ));
    gh.lazySingleton<_i75.HomeRemoteDataSource>(
        () => _i75.HomeRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i614.TriviaRemoteDataSource>(
        () => _i614.TriviaRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.lazySingleton<_i652.TipsRemoteDataSource>(
        () => _i652.TipsRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.lazySingleton<_i869.AuthRepository>(() => _i570.AuthRepositoryImpl(
          gh<_i130.AuthRemoteDataSource>(),
          gh<_i182.AuthLocalDataSource>(),
          gh<_i497.TokenManager>(),
        ));
    gh.factory<_i964.QuizRemoteDataSource>(
        () => _i964.QuizRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.lazySingleton<_i850.ProfileRemoteDataSource>(
        () => _i850.ProfileRemoteDataSourceImpl(
              gh<_i510.ApiClient>(),
              gh<_i497.TokenManager>(),
            ));
    gh.factory<_i416.TriviaRepository>(() => _i121.TriviaRepositoryImpl(
          remoteDataSource: gh<_i614.TriviaRemoteDataSource>(),
          localDataSource: gh<_i430.TriviaLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.lazySingleton<_i386.ProfileRepository>(
        () => _i13.ProfileRepositoryImpl(gh<_i850.ProfileRemoteDataSource>()));
    gh.lazySingleton<_i66.HomeRepository>(() => _i6.HomeRepositoryImpl(
          gh<_i75.HomeRemoteDataSource>(),
          gh<_i819.HomeLocalDataSource>(),
          gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i115.CompanionRemoteDataSource>(
        () => _i115.CompanionRemoteDataSourceImpl(
              gh<_i510.ApiClient>(),
              gh<_i497.TokenManager>(),
            ));
    gh.lazySingleton<_i406.LoginUseCase>(
        () => _i406.LoginUseCase(gh<_i869.AuthRepository>()));
    gh.lazySingleton<_i819.RegisterUseCase>(
        () => _i819.RegisterUseCase(gh<_i869.AuthRepository>()));
    gh.lazySingleton<_i957.GetDailyTipUseCase>(
        () => _i957.GetDailyTipUseCase(gh<_i66.HomeRepository>()));
    gh.lazySingleton<_i762.GetUserStatsUseCase>(
        () => _i762.GetUserStatsUseCase(gh<_i66.HomeRepository>()));
    gh.lazySingleton<_i604.UpdateUserActivityUseCase>(
        () => _i604.UpdateUserActivityUseCase(gh<_i66.HomeRepository>()));
    gh.lazySingleton<_i88.AuthService>(() => _i88.AuthService(
          gh<_i869.AuthRepository>(),
          gh<_i130.AuthRemoteDataSource>(),
        ));
    gh.factory<_i992.QuizRepository>(() => _i852.QuizRepositoryImpl(
          remoteDataSource: gh<_i964.QuizRemoteDataSource>(),
          localDataSource: gh<_i430.TriviaLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i852.LearningRepository>(() => _i378.LearningRepositoryImpl(
          remoteDataSource: gh<_i506.LearningRemoteDataSource>(),
          localDataSource: gh<_i195.LearningLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i828.GetTriviaCategoriesUseCase>(
        () => _i828.GetTriviaCategoriesUseCase(gh<_i416.TriviaRepository>()));
    gh.factory<_i9.GetTriviaQuestionsUseCase>(
        () => _i9.GetTriviaQuestionsUseCase(gh<_i416.TriviaRepository>()));
    gh.factory<_i919.GetUserTriviaHistoryUseCase>(
        () => _i919.GetUserTriviaHistoryUseCase(gh<_i416.TriviaRepository>()));
    gh.factory<_i381.SubmitTriviaResultUseCase>(
        () => _i381.SubmitTriviaResultUseCase(gh<_i416.TriviaRepository>()));
    gh.factory<_i157.SubmitTriviaResultUseCase>(
        () => _i157.SubmitTriviaResultUseCase(gh<_i416.TriviaRepository>()));
    gh.lazySingleton<_i65.GetUserProfileUseCase>(
        () => _i65.GetUserProfileUseCase(gh<_i386.ProfileRepository>()));
    gh.lazySingleton<_i186.UpdateUserAvatarUseCase>(
        () => _i186.UpdateUserAvatarUseCase(gh<_i386.ProfileRepository>()));
    gh.factory<_i807.MediaRemoteDataSource>(
        () => _i807.MediaRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i252.ChallengesRemoteDataSource>(
        () => _i252.ChallengesRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i464.NewsCubit>(() => _i464.NewsCubit(
          getClimateNewsUseCase: gh<_i55.GetClimateNewsUseCase>(),
          getCachedNewsUseCase: gh<_i827.GetCachedNewsUseCase>(),
          refreshNewsUseCase: gh<_i136.RefreshNewsUseCase>(),
        ));
    gh.lazySingleton<_i92.ProfileService>(
        () => _i92.ProfileService(gh<_i386.ProfileRepository>()));
    gh.lazySingleton<_i406.TipsRepository>(() => _i397.TipsRepositoryImpl(
          gh<_i652.TipsRemoteDataSource>(),
          gh<_i800.CacheService>(),
        ));
    gh.factory<_i300.ProfileCubit>(() => _i300.ProfileCubit(
          getUserProfileUseCase: gh<_i65.GetUserProfileUseCase>(),
          updateUserAvatarUseCase: gh<_i186.UpdateUserAvatarUseCase>(),
        ));
    gh.factory<_i770.CompanionRepository>(() => _i904.CompanionRepositoryImpl(
          remoteDataSource: gh<_i115.CompanionRemoteDataSource>(),
          localDataSource: gh<_i1032.CompanionLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
          tokenManager: gh<_i497.TokenManager>(),
        ));
    gh.factory<_i412.CompleteLessonUseCase>(
        () => _i412.CompleteLessonUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i80.GetCategoriesUseCase>(
        () => _i80.GetCategoriesUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i194.GetLessonsByCategoryUseCase>(() =>
        _i194.GetLessonsByCategoryUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i391.GetLessonContentUseCase>(
        () => _i391.GetLessonContentUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i420.SearchLessonsUseCase>(
        () => _i420.SearchLessonsUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i813.UpdateLessonProgressUseCase>(() =>
        _i813.UpdateLessonProgressUseCase(gh<_i852.LearningRepository>()));
    gh.factory<_i852.GetQuestionByIdUseCase>(
        () => _i852.GetQuestionByIdUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i865.GetQuizzesByTopicUseCase>(
        () => _i865.GetQuizzesByTopicUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i714.GetQuizByIdUseCase>(
        () => _i714.GetQuizByIdUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i806.GetQuizQuestionsUseCase>(
        () => _i806.GetQuizQuestionsUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i907.GetQuizResultsUseCase>(
        () => _i907.GetQuizResultsUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i462.GetUserQuizProgressUseCase>(
        () => _i462.GetUserQuizProgressUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i112.StartQuizSessionUseCase>(
        () => _i112.StartQuizSessionUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i591.SubmitQuizAnswerUseCase>(
        () => _i591.SubmitQuizAnswerUseCase(gh<_i992.QuizRepository>()));
    gh.factory<_i22.GetRandomTipUseCase>(
        () => _i22.GetRandomTipUseCase(gh<_i406.TipsRepository>()));
    gh.factory<_i22.GetRandomTipWithoutParamsUseCase>(() =>
        _i22.GetRandomTipWithoutParamsUseCase(gh<_i406.TipsRepository>()));
    gh.factory<_i441.TipsCubit>(
        () => _i441.TipsCubit(gh<_i406.TipsRepository>()));
    gh.factory<_i238.CompanionActionsCubit>(() => _i238.CompanionActionsCubit(
          repository: gh<_i770.CompanionRepository>(),
          tokenManager: gh<_i497.TokenManager>(),
        ));
    gh.factory<_i605.ContentRemoteDataSource>(
        () => _i605.ContentRemoteDataSourceImpl(
              gh<_i510.ApiClient>(),
              gh<_i807.MediaRemoteDataSource>(),
            ));
    gh.factory<_i108.EvolveCompanionUseCase>(
        () => _i108.EvolveCompanionUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i711.EvolveCompanionViaApiUseCase>(() =>
        _i711.EvolveCompanionViaApiUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i913.FeatureCompanionUseCase>(
        () => _i913.FeatureCompanionUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i960.FeedCompanionUseCase>(
        () => _i960.FeedCompanionUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i720.GetAvailableCompanionsUseCase>(() =>
        _i720.GetAvailableCompanionsUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i76.GetCompanionShopUseCase>(
        () => _i76.GetCompanionShopUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i574.GetUserCompanionsUseCase>(
        () => _i574.GetUserCompanionsUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i820.LoveCompanionUseCase>(
        () => _i820.LoveCompanionUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i395.PurchaseCompanionUseCase>(
        () => _i395.PurchaseCompanionUseCase(gh<_i770.CompanionRepository>()));
    gh.factory<_i1017.HomeCubit>(() => _i1017.HomeCubit(
          getDailyTipUseCase: gh<_i957.GetDailyTipUseCase>(),
          getUserStatsUseCase: gh<_i762.GetUserStatsUseCase>(),
        ));
    gh.factory<_i912.TriviaGameCubit>(() => _i912.TriviaGameCubit(
          getTriviaQuestionsUseCase: gh<_i9.GetTriviaQuestionsUseCase>(),
          submitTriviaResultUseCase: gh<_i157.SubmitTriviaResultUseCase>(),
        ));
    gh.factory<_i499.QuizSessionCubit>(() => _i499.QuizSessionCubit(
          startQuizSessionUseCase: gh<_i112.StartQuizSessionUseCase>(),
          submitQuizAnswerUseCase: gh<_i591.SubmitQuizAnswerUseCase>(),
          getQuizResultsUseCase: gh<_i907.GetQuizResultsUseCase>(),
          getQuizQuestionsUseCase: gh<_i806.GetQuizQuestionsUseCase>(),
        ));
    gh.factory<_i959.ChallengesRepository>(() => _i285.ChallengesRepositoryImpl(
          remoteDataSource: gh<_i252.ChallengesRemoteDataSource>(),
          localDataSource: gh<_i422.ChallengesLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i993.TriviaCubit>(() => _i993.TriviaCubit(
          getTriviaCategoriesUseCase: gh<_i828.GetTriviaCategoriesUseCase>(),
          getQuizzesByTopicUseCase: gh<_i865.GetQuizzesByTopicUseCase>(),
          getQuizByIdUseCase: gh<_i714.GetQuizByIdUseCase>(),
          getQuizQuestionsUseCase: gh<_i806.GetQuizQuestionsUseCase>(),
        ));
    gh.factory<_i70.AuthCubit>(() => _i70.AuthCubit(
          loginUseCase: gh<_i406.LoginUseCase>(),
          registerUseCase: gh<_i819.RegisterUseCase>(),
          authService: gh<_i88.AuthService>(),
          profileService: gh<_i92.ProfileService>(),
        ));
    gh.factory<_i522.CompleteChallengeUseCase>(
        () => _i522.CompleteChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i929.GetActiveChallengesUseCase>(() =>
        _i929.GetActiveChallengesUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i1010.GetChallengesUseCase>(
        () => _i1010.GetChallengesUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i229.GetChallengeCategoriesUseCase>(() =>
        _i229.GetChallengeCategoriesUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i31.GetUserChallengeStatsUseCase>(() =>
        _i31.GetUserChallengeStatsUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i287.GetUserProgressUseCase>(
        () => _i287.GetUserProgressUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i79.StartChallengeUseCase>(
        () => _i79.StartChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i23.StartChallengeUseCase>(
        () => _i23.StartChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i1042.SubmitEvidenceUseCase>(
        () => _i1042.SubmitEvidenceUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i1056.UpdateChallengeProgressUseCase>(() =>
        _i1056.UpdateChallengeProgressUseCase(
            gh<_i959.ChallengesRepository>()));
    gh.factory<_i803.LessonContentCubit>(() => _i803.LessonContentCubit(
          getLessonContentUseCase: gh<_i391.GetLessonContentUseCase>(),
          updateLessonProgressUseCase: gh<_i813.UpdateLessonProgressUseCase>(),
          completeLessonUseCase: gh<_i412.CompleteLessonUseCase>(),
        ));
    gh.factory<_i717.CompanionShopCubit>(() => _i717.CompanionShopCubit(
          getCompanionShopUseCase: gh<_i76.GetCompanionShopUseCase>(),
          purchaseCompanionUseCase: gh<_i395.PurchaseCompanionUseCase>(),
          tokenManager: gh<_i497.TokenManager>(),
        ));
    gh.factory<_i366.ChallengeDetailCubit>(() => _i366.ChallengeDetailCubit(
          startChallengeUseCase: gh<_i23.StartChallengeUseCase>(),
          completeChallengeUseCase: gh<_i522.CompleteChallengeUseCase>(),
          updateChallengeProgressUseCase:
              gh<_i1056.UpdateChallengeProgressUseCase>(),
          submitEvidenceUseCase: gh<_i1042.SubmitEvidenceUseCase>(),
        ));
    gh.factory<_i568.LessonListCubit>(() => _i568.LessonListCubit(
          getLessonsByCategoryUseCase: gh<_i194.GetLessonsByCategoryUseCase>(),
          searchLessonsUseCase: gh<_i420.SearchLessonsUseCase>(),
        ));
    gh.factory<_i917.CompanionCubit>(() => _i917.CompanionCubit(
          getUserCompanionsUseCase: gh<_i574.GetUserCompanionsUseCase>(),
          getCompanionShopUseCase: gh<_i76.GetCompanionShopUseCase>(),
          tokenManager: gh<_i497.TokenManager>(),
          repository: gh<_i770.CompanionRepository>(),
        ));
    gh.factory<_i19.ContentRepository>(() => _i577.ContentRepositoryImpl(
          remoteDataSource: gh<_i605.ContentRemoteDataSource>(),
          localDataSource: gh<_i195.LearningLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i314.ChallengesCubit>(() => _i314.ChallengesCubit(
          getChallengesUseCase: gh<_i1010.GetChallengesUseCase>(),
          getUserStatsUseCase: gh<_i31.GetUserChallengeStatsUseCase>(),
          getCategoriesUseCase: gh<_i229.GetChallengeCategoriesUseCase>(),
        ));
    gh.factory<_i0.CompanionDetailCubit>(() => _i0.CompanionDetailCubit(
          feedCompanionUseCase: gh<_i960.FeedCompanionUseCase>(),
          loveCompanionUseCase: gh<_i820.LoveCompanionUseCase>(),
          evolveCompanionUseCase: gh<_i108.EvolveCompanionUseCase>(),
          tokenManager: gh<_i497.TokenManager>(),
          evolveCompanionViaApiUseCase:
              gh<_i711.EvolveCompanionViaApiUseCase>(),
          featureCompanionUseCase: gh<_i913.FeatureCompanionUseCase>(),
        ));
    gh.factory<_i582.GetContentsByTopicUseCase>(
        () => _i582.GetContentsByTopicUseCase(gh<_i19.ContentRepository>()));
    gh.factory<_i677.GetContentByIdUseCase>(
        () => _i677.GetContentByIdUseCase(gh<_i19.ContentRepository>()));
    gh.factory<_i175.GetTopicsUseCase>(
        () => _i175.GetTopicsUseCase(gh<_i19.ContentRepository>()));
    gh.factory<_i64.EvidenceSubmissionCubit>(() => _i64.EvidenceSubmissionCubit(
        submitEvidenceUseCase: gh<_i1042.SubmitEvidenceUseCase>()));
    gh.factory<_i992.LearningCubit>(() =>
        _i992.LearningCubit(getTopicsUseCase: gh<_i175.GetTopicsUseCase>()));
    gh.factory<_i921.ContentCubit>(() => _i921.ContentCubit(
          getTopicsUseCase: gh<_i175.GetTopicsUseCase>(),
          getContentByIdUseCase: gh<_i677.GetContentByIdUseCase>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i649.ExternalModule {}
