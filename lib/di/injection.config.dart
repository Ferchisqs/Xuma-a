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

import '../features/auth/data/datasources/auth_local_datasource.dart' as _i182;
import '../features/auth/data/datasources/auth_remote_datasource.dart' as _i130;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i570;
import '../features/auth/domain/repositories/auth_repository.dart' as _i869;
import '../features/auth/domain/usecases/login_usecase.dart' as _i406;
import '../features/auth/domain/usecases/register_usecase.dart' as _i819;
import '../features/auth/presentation/cubit/auth_cubit.dart' as _i70;
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
    gh.lazySingleton<_i895.Connectivity>(() => externalModule.connectivity);
    gh.lazySingleton<_i130.AuthRemoteDataSource>(
        () => _i130.AuthRemoteDataSourceImpl());
    gh.lazySingleton<_i182.AuthLocalDataSource>(
        () => _i182.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i869.AuthRepository>(() => _i570.AuthRepositoryImpl(
          gh<_i130.AuthRemoteDataSource>(),
          gh<_i182.AuthLocalDataSource>(),
        ));
    gh.lazySingleton<_i406.LoginUseCase>(
        () => _i406.LoginUseCase(gh<_i869.AuthRepository>()));
    gh.lazySingleton<_i819.RegisterUseCase>(
        () => _i819.RegisterUseCase(gh<_i869.AuthRepository>()));
    gh.factory<_i70.AuthCubit>(() => _i70.AuthCubit(
          loginUseCase: gh<_i406.LoginUseCase>(),
          registerUseCase: gh<_i819.RegisterUseCase>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i649.ExternalModule {}
