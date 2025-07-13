import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

@lazySingleton
class ProfileService {
  final ProfileRepository _profileRepository;

  ProfileService(this._profileRepository);

  // ==================== GET PROFILE ====================
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId) async {
    return await _profileRepository.getUserProfile(userId);
  }

  // ==================== UPDATE AVATAR ====================
  Future<Either<Failure, UserProfileEntity>> updateUserAvatar(String userId, String avatarUrl) async {
    return await _profileRepository.updateUserAvatar(userId, avatarUrl);
  }

  // ==================== VALIDATE AVATAR URL ====================
  bool isValidAvatarUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;
    
    // Verificar que sea una URL de imagen válida
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowercaseUrl = url.toLowerCase();
    
    return validExtensions.any((ext) => lowercaseUrl.contains(ext)) ||
           lowercaseUrl.contains('avatar') ||
           lowercaseUrl.contains('profile') ||
           lowercaseUrl.contains('cdn');
  }

  // ==================== GET USER LEVEL ====================
  String getUserLevel(int age, int ecoPoints) {
    if (age < 13) {
      if (ecoPoints < 100) return 'Eco Explorer';
      if (ecoPoints < 500) return 'Green Sprout';
      return 'Nature Friend';
    } else if (age < 18) {
      if (ecoPoints < 200) return 'Eco Guardian';
      if (ecoPoints < 1000) return 'Earth Defender';
      return 'Green Hero';
    } else {
      if (ecoPoints < 500) return 'Eco Warrior';
      if (ecoPoints < 2000) return 'Planet Protector';
      return 'Eco Master';
    }
  }

  // ==================== GET ACHIEVEMENTS SUMMARY ====================
  Map<String, dynamic> getAchievementsSummary(UserProfileEntity profile) {
    return {
      'totalPoints': profile.ecoPoints,
      'level': profile.level,
      'achievements': profile.achievementsCount,
      'lessonsCompleted': profile.lessonsCompleted,
      'daysActive': profile.daysActive,
      'isMinor': profile.isMinor,
      'nextLevelPoints': _getNextLevelPoints(profile.ecoPoints),
    };
  }

  int _getNextLevelPoints(int currentPoints) {
    const levelThresholds = [100, 200, 500, 1000, 2000, 5000];
    
    for (final threshold in levelThresholds) {
      if (currentPoints < threshold) {
        return threshold;
      }
    }
    
    return currentPoints + 1000; // Para niveles muy altos
  }
}