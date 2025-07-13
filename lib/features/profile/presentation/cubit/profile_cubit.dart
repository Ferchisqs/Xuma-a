import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_avatar_usecase.dart';
import '../../../../core/utils/error_handler.dart';

// ==================== ESTADOS ====================
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileEntity profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileUpdating extends ProfileState {
  final UserProfileEntity currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object> get props => [currentProfile];
}

class ProfileUpdated extends ProfileState {
  final UserProfileEntity profile;
  final String successMessage;

  const ProfileUpdated(this.profile, this.successMessage);

  @override
  List<Object> get props => [profile, successMessage];
}

// ==================== CUBIT ====================
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserAvatarUseCase _updateUserAvatarUseCase;

  ProfileCubit({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserAvatarUseCase updateUserAvatarUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserAvatarUseCase = updateUserAvatarUseCase,
        super(ProfileInitial());

  // ==================== LOAD PROFILE ====================
  Future<void> loadUserProfile(String userId) async {
    emit(ProfileLoading());

    try {
      print('🔍 Loading profile for userId: $userId'); // Para debug

      final params = GetUserProfileParams(userId: userId);
      final result = await _getUserProfileUseCase(params);

      await result.fold(
        (failure) async {
          print('❌ Profile load failed: ${failure.message}'); // Para debug
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(ProfileError(userFriendlyMessage));
        },
        (profile) async {
          print('✅ Profile loaded successfully: ${profile.fullName}'); // Para debug
          emit(ProfileLoaded(profile));
        },
      );
    } catch (e) {
      print('❌ Profile load exception: $e'); // Para debug
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(ProfileError(userFriendlyMessage));
    }
  }

  // ==================== UPDATE AVATAR ====================
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('No hay perfil cargado para actualizar'));
      return;
    }

    emit(ProfileUpdating(currentState.profile));

    try {
      print('🔍 Updating avatar for userId: $userId'); // Para debug
      print('🔍 New avatar URL: $avatarUrl'); // Para debug

      final params = UpdateUserAvatarParams(
        userId: userId,
        avatarUrl: avatarUrl,
      );
      final result = await _updateUserAvatarUseCase(params);

      await result.fold(
        (failure) async {
          print('❌ Avatar update failed: ${failure.message}'); // Para debug
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(ProfileError(userFriendlyMessage));
        },
        (updatedProfile) async {
          print('✅ Avatar updated successfully'); // Para debug
          emit(ProfileUpdated(updatedProfile, 'Avatar actualizado correctamente'));
          
          // Después de un momento, cambiar a ProfileLoaded
          await Future.delayed(const Duration(seconds: 1));
          emit(ProfileLoaded(updatedProfile));
        },
      );
    } catch (e) {
      print('❌ Avatar update exception: $e'); // Para debug
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(ProfileError(userFriendlyMessage));
    }
  }

  // ==================== REFRESH PROFILE ====================
  Future<void> refreshProfile(String userId) async {
    // Si ya hay un perfil cargado, mantenerlo mientras carga el nuevo
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentState.profile));
    } else {
      emit(ProfileLoading());
    }

    await loadUserProfile(userId);
  }

  // ==================== HANDLE UPDATE SUCCESS ====================
  void acknowledgeUpdate() {
    final currentState = state;
    if (currentState is ProfileUpdated) {
      emit(ProfileLoaded(currentState.profile));
    }
  }

  // ==================== RESET STATE ====================
  void reset() {
    emit(ProfileInitial());
  }

  // ==================== GETTERS ====================
  UserProfileEntity? get currentProfile {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profile;
    } else if (currentState is ProfileUpdating) {
      return currentState.currentProfile;
    } else if (currentState is ProfileUpdated) {
      return currentState.profile;
    }
    return null;
  }

  bool get isLoading => state is ProfileLoading || state is ProfileUpdating;
  bool get hasProfile => currentProfile != null;
  bool get hasError => state is ProfileError;
  
  String? get errorMessage {
    final currentState = state;
    if (currentState is ProfileError) {
      return currentState.message;
    }
    return null;
  }
}