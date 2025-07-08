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
import '../features/auth/data/datasources/auth_local_datasource.dart' as _i182;
import '../features/auth/data/datasources/auth_remote_datasource.dart' as _i130;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i570;
import '../features/auth/domain/repositories/auth_repository.dart' as _i869;
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
import '../features/challenges/domain/usecases/update_challenge_progress_usecase.dart'
    as _i1056;
import '../features/challenges/presentation/cubit/challenge_detail_cubit.dart'
    as _i366;
import '../features/challenges/presentation/cubit/challenges_cubit.dart'
    as _i314;
import '../features/home/data/datasources/home_local_datasource.dart' as _i819;
import '../features/home/data/datasources/home_remote_datasource.dart' as _i75;
import '../features/home/data/repositories/home_repository_impl.dart' as _i6;
import '../features/home/domain/repositories/home_repository.dart' as _i66;
import '../features/home/domain/usecases/get_daily_tip_usecase.dart' as _i957;
import '../features/home/domain/usecases/get_user_stats_usecase.dart' as _i762;
import '../features/home/domain/usecases/update_user_activity_usecase.dart'
    as _i604;
import '../features/home/presentation/cubit/home_cubit.dart' as _i1017;
import '../features/learning/data/datasources/learning_local_datasource.dart'
    as _i195;
import '../features/learning/data/datasources/learning_remote_datasource.dart'
    as _i506;
import '../features/learning/data/repositories/learning_repository_impl.dart'
    as _i378;
import '../features/learning/domain/repositories/learning_repository.dart'
    as _i852;
import '../features/learning/domain/usecases/complete_lesson_usecase.dart'
    as _i412;
import '../features/learning/domain/usecases/get_categories_usecase.dart'
    as _i80;
import '../features/learning/domain/usecases/get_lesson_content_usecase.dart'
    as _i391;
import '../features/learning/domain/usecases/get_lessons_by_category_usecase.dart'
    as _i194;
import '../features/learning/domain/usecases/search_lessons_usecase.dart'
    as _i420;
import '../features/learning/domain/usecases/update_lesson_progress_usecase.dart'
    as _i813;
import '../features/learning/presentation/cubit/learning_cubit.dart' as _i992;
import '../features/learning/presentation/cubit/lesson_content_cubit.dart'
    as _i803;
import '../features/learning/presentation/cubit/lesson_list_cubit.dart'
    as _i568;
import '../features/navigation/presentation/cubit/navigation_cubit.dart'
    as _i630;
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
    gh.lazySingleton<_i819.HomeLocalDataSource>(
        () => _i819.HomeLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i130.AuthRemoteDataSource>(
        () => _i130.AuthRemoteDataSourceImpl());
    gh.lazySingleton<_i182.AuthLocalDataSource>(
        () => _i182.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()));
    gh.factory<_i422.ChallengesLocalDataSource>(
        () => _i422.ChallengesLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i869.AuthRepository>(() => _i570.AuthRepositoryImpl(
          gh<_i130.AuthRemoteDataSource>(),
          gh<_i182.AuthLocalDataSource>(),
        ));
    gh.factory<_i195.LearningLocalDataSource>(
        () => _i195.LearningLocalDataSourceImpl(gh<_i800.CacheService>()));
    gh.lazySingleton<_i6.NetworkInfo>(
        () => _i6.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i406.LoginUseCase>(
        () => _i406.LoginUseCase(gh<_i869.AuthRepository>()));
    gh.lazySingleton<_i819.RegisterUseCase>(
        () => _i819.RegisterUseCase(gh<_i869.AuthRepository>()));
    gh.lazySingleton<_i510.ApiClient>(
        () => _i510.ApiClient(gh<_i6.NetworkInfo>()));
    gh.lazySingleton<_i75.HomeRemoteDataSource>(
        () => _i75.HomeRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i70.AuthCubit>(() => _i70.AuthCubit(
          loginUseCase: gh<_i406.LoginUseCase>(),
          registerUseCase: gh<_i819.RegisterUseCase>(),
        ));
    gh.lazySingleton<_i66.HomeRepository>(() => _i6.HomeRepositoryImpl(
          gh<_i75.HomeRemoteDataSource>(),
          gh<_i819.HomeLocalDataSource>(),
          gh<_i6.NetworkInfo>(),
        ));
    gh.lazySingleton<_i957.GetDailyTipUseCase>(
        () => _i957.GetDailyTipUseCase(gh<_i66.HomeRepository>()));
    gh.lazySingleton<_i762.GetUserStatsUseCase>(
        () => _i762.GetUserStatsUseCase(gh<_i66.HomeRepository>()));
    gh.lazySingleton<_i604.UpdateUserActivityUseCase>(
        () => _i604.UpdateUserActivityUseCase(gh<_i66.HomeRepository>()));
    gh.factory<_i252.ChallengesRemoteDataSource>(
        () => _i252.ChallengesRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i506.LearningRemoteDataSource>(
        () => _i506.LearningRemoteDataSourceImpl(gh<_i510.ApiClient>()));
    gh.factory<_i1017.HomeCubit>(() => _i1017.HomeCubit(
          getDailyTipUseCase: gh<_i957.GetDailyTipUseCase>(),
          getUserStatsUseCase: gh<_i762.GetUserStatsUseCase>(),
        ));
    gh.factory<_i959.ChallengesRepository>(() => _i285.ChallengesRepositoryImpl(
          remoteDataSource: gh<_i252.ChallengesRemoteDataSource>(),
          localDataSource: gh<_i422.ChallengesLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i852.LearningRepository>(() => _i378.LearningRepositoryImpl(
          remoteDataSource: gh<_i506.LearningRemoteDataSource>(),
          localDataSource: gh<_i195.LearningLocalDataSource>(),
          networkInfo: gh<_i6.NetworkInfo>(),
        ));
    gh.factory<_i522.CompleteChallengeUseCase>(
        () => _i522.CompleteChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i929.GetActiveChallengesUseCase>(() =>
        _i929.GetActiveChallengesUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i1010.GetChallengesUseCase>(
        () => _i1010.GetChallengesUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i31.GetUserChallengeStatsUseCase>(() =>
        _i31.GetUserChallengeStatsUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i287.GetUserProgressUseCase>(
        () => _i287.GetUserProgressUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i79.StartChallengeUseCase>(
        () => _i79.StartChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i23.StartChallengeUseCase>(
        () => _i23.StartChallengeUseCase(gh<_i959.ChallengesRepository>()));
    gh.factory<_i1056.UpdateChallengeProgressUseCase>(() =>
        _i1056.UpdateChallengeProgressUseCase(
            gh<_i959.ChallengesRepository>()));
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
    gh.factory<_i366.ChallengeDetailCubit>(() => _i366.ChallengeDetailCubit(
          startChallengeUseCase: gh<_i23.StartChallengeUseCase>(),
          completeChallengeUseCase: gh<_i522.CompleteChallengeUseCase>(),
          updateChallengeProgressUseCase:
              gh<_i1056.UpdateChallengeProgressUseCase>(),
        ));
    gh.factory<_i992.LearningCubit>(() => _i992.LearningCubit(
        getCategoriesUseCase: gh<_i80.GetCategoriesUseCase>()));
    gh.factory<_i314.ChallengesCubit>(() => _i314.ChallengesCubit(
          getChallengesUseCase: gh<_i1010.GetChallengesUseCase>(),
          getUserProgressUseCase: gh<_i287.GetUserProgressUseCase>(),
        ));
    gh.factory<_i803.LessonContentCubit>(() => _i803.LessonContentCubit(
          getLessonContentUseCase: gh<_i391.GetLessonContentUseCase>(),
          updateLessonProgressUseCase: gh<_i813.UpdateLessonProgressUseCase>(),
          completeLessonUseCase: gh<_i412.CompleteLessonUseCase>(),
        ));
    gh.factory<_i568.LessonListCubit>(() => _i568.LessonListCubit(
          getLessonsByCategoryUseCase: gh<_i194.GetLessonsByCategoryUseCase>(),
          searchLessonsUseCase: gh<_i420.SearchLessonsUseCase>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i649.ExternalModule {}
