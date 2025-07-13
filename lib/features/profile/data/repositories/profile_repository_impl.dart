import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId) async {
    try {
      final profile = await _remoteDataSource.getUserProfile(userId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado obteniendo perfil: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      final updatedProfile = await _remoteDataSource.updateUserAvatar(userId, avatarUrl);
      return Right(updatedProfile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado actualizando avatar: $e'));
    }
  }
}